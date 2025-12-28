from django.db import transaction, connection
from django.http import Http404
from django.core.exceptions import ValidationError, PermissionDenied
from django.db.models.expressions import RawSQL
from django.utils import timezone
from ..models import RescueRequest, RescueTeam, RescueAssignments
from ..enum.rescue_status import TeamStatus, TaskStatus, RescueStatus, RESCUE_STATUS
from ..enum.role_enum import RoleCode
import json


from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

class AssignService:

    @staticmethod
    def _push_update(groups: list, event_name: str, payload_data: dict):
        channel_layer = get_channel_layer()
        message = {
            "type": "send_update",
            "data": {
                "event": event_name,
                "data": payload_data
            }
        }
        try:
            for group in groups:
                if group: 
                    async_to_sync(channel_layer.group_send)(group, message)
        except Exception as e:
            print(f"Socket Error: {e}")

    @staticmethod
    def _build_permission(user):
        if user.role.code == RoleCode.ADMIN:
            return "", []
        if user.role.code == RoleCode.RESCUER:
            return "WHERE rt.account_id = %s", [user.id]
        else:
            return "WHERE 1=0", []
        
    @staticmethod
    def assign_task(request_id: str, team_id: str, admin_id: str):
        with transaction.atomic():
            team = RescueTeam.objects.select_for_update().get(id=team_id)

            if team.status != TeamStatus.AVAILABLE:
                raise ValueError(f"Đội {team.name} đang nhận nhiệm vụ khác.")
            
            try:
                request = RescueRequest.objects.select_for_update().get(id=request_id)
            except:
                raise Http404("Không tìm thấy yêu cầu cứu hộ")
            
            if request.status != RESCUE_STATUS[RescueStatus.PENDING]:
                raise ValidationError("Yêu cầu này đã có người nhận hoặc đã bị hủy.")
            
            task = RescueAssignments.objects.create(
                rescue_request = request,
                rescue_team=team,
                assigned_by=admin_id,
                status=TaskStatus.ASSIGNED,
                assigned_at=timezone.now()
            )

            team.status= TeamStatus.BUSY
            team.save(update_fields=['status'])

            request.status= RESCUE_STATUS[RescueStatus.ASSIGNED]
            request.save(update_fields=['status'])

            # --- Socket Notification ---
            payload = {
                "task_id": task.id,
                "request_id": request.id,
                "team_id": team.id,
                "status": "ASSIGNED",
                "msg": f"Nhiệm vụ mới tại: {request.address}",
            }
            
            target_groups = ["rescue_admin", f"rescue_team_{team.id}"]
            if request.account_id:
                target_groups.append(f"user_{request.account_id}")

            AssignService._push_update(groups=target_groups, event_name="NEW_TASK", payload_data=payload)
            return task
        
        
    @staticmethod    
    def find_nearest_teams(lat: float, lng: float, radius_km: float):
        sql = """
            SELECT id, name, contact_phone,
                ST_Distance(location::geography, ST_MakePoint(%s, %s)::geography) AS distance_m
            FROM rescue_teams
            WHERE status = %s
            AND ST_DWithin(location::geography, ST_MakePoint(%s, %s)::geography, %s)
            ORDER BY distance_m
        """
        params = [lng, lat, TeamStatus.AVAILABLE, lng, lat, radius_km * 1000]

        with connection.cursor() as cursor:
            cursor.execute(sql, params)
            rows = cursor.fetchall()

        result = []
        for r in rows:
            result.append({
                "id": r[0],
                "name": r[1],
                "contact_phone": r[2],
                "distance": round(r[3] / 1000, 2)
            })
        return result

    
    @staticmethod        
    def get_assign(user):
        """Lấy danh sách nhiệm vụ dựa trên Role"""

        where_clause, params = AssignService._build_permission(user)

        BASE_ASSIGNMENT_SQL = """
            SELECT
                ra.id              AS assignment_id,
                ra.status,
                ra.assigned_at,

                -- rescue request
                rr.code,
                rr.name,
                rr.contact_phone,
                rr.adults,
                rr.children,
                rr.elderly,
                rr.address,
                ST_Y(rr.location)  AS latitude,
                ST_X(rr.location)  AS longitude,
                rr.conditions,
                rr.description,

                -- rescue team
                rt.id              AS team_id,
                rt.name            AS team_name,
                rt.hotline         AS team_phone,
                ST_Y(rt.location)  AS team_latitude,
                ST_X(rt.location)  AS team_longitude

            FROM rescue_assignments ra
            JOIN rescue_requests rr ON rr.id = ra.rescue_request_id
            JOIN rescue_teams rt ON rt.id = ra.rescue_team_id
        """
        sql = f"""
            {BASE_ASSIGNMENT_SQL}
            {where_clause}
            ORDER BY ra.created_at DESC
        """
        with connection.cursor() as cursor:
            cursor.execute(sql=sql, params=params)

            rows = cursor.fetchall()
            
            columns = [col[0] for col in cursor.description]
            result = []
            
            for row in rows:
                row_dict = dict(zip(columns, row))

                result.append(AssignService.map_assignment(row_dict))
            return result
    
    @staticmethod   
    def map_assignment(row: dict) -> dict:

        conditions = row["conditions"]

        if isinstance(conditions, str):
            conditions = json.loads(conditions)

        return {
            "id": row["assignment_id"],
            "status": row["status"],
            "assigned_at": row["assigned_at"],

            "rescue_request": {
                "code": row["code"],
                "name": row["name"],
                "contact_phone": row["contact_phone"],
                "adults": row["adults"],
                "children": row["children"],
                "elderly": row["elderly"],
                "address": row["address"],
                "latitude": row["latitude"],
                "longitude": row["longitude"],
                "conditions": conditions,
                "description": row["description"],
            },

            "rescue_team": {
                "team_id": row["team_id"],
                "team_name": row["team_name"],
                "team_latitude": row["team_latitude"],
                "team_longitude": row["team_longitude"],
                "team_phone": row["team_phone"],
            }
        }

            
        
    @staticmethod
    def _get_team_task(assignment_id, account_id, required_status):
        """Hàm phụ trợ để lấy và kiểm tra task của đội"""
        try:
            team = RescueTeam.objects.get(account_id=account_id)
        except RescueTeam.DoesNotExist:
            raise PermissionDenied("User này không phải đội cứu hộ")

        try:
            task = RescueAssignments.objects.select_for_update().get(
                id=assignment_id,
                status=required_status,
                rescue_team=team
            )
            return task
        except RescueAssignments.DoesNotExist:
            raise ValidationError("Nhiệm vụ không tồn tại hoặc sai trạng thái.")
        
    @staticmethod
    def confirm_team_start(assignment_id: str, account_id: str):
        with transaction.atomic():
            task = AssignService._get_team_task(assignment_id, account_id, TaskStatus.ASSIGNED)
            
            # cập nhật task 
            task.status = TaskStatus.IN_PROGRESS
            task.accepted_at = timezone.now()
            task.save(update_fields=['status'])

            # ĐỒNG BỘ: cập nhật Rescue Request -> IN_PROGRESS
            # Để người dân thấy trạng thái đổi sang "Đang thực hiện"
            rescue_req = task.rescue_request
            rescue_req.status = RESCUE_STATUS[RescueStatus.IN_PROGRESS]
            rescue_req.save(update_fields=['status'])
            
            payload = {
                "task_id": task.id, 
                "status": "IN_PROGRESS",
                "msg": "Đội cứu hộ đang di chuyển"
            }
            
            target_groups = ["rescue_admin", f"rescue_team_{task.rescue_team.id}"]
            if rescue_req.account_id:
                target_groups.append(f"user_{rescue_req.account_id}")
                
            AssignService._push_update(groups=target_groups, event_name="TASK_UPDATE", payload_data=payload)
            return task
        
    @staticmethod
    def confirm_team_arrived(assignment_id: str, account_id: str):
        """Bước 4: Đội báo đã đến nơi"""
        with transaction.atomic():
            task = AssignService._get_team_task(assignment_id, account_id, TaskStatus.IN_PROGRESS)
            
            task.status = TaskStatus.ARRIVED
            task.save(update_fields=['status'])
            
            payload = {
                "task_id": task.id, 
                "status": "ARRIVED", 
                "msg": "Đội cứu hộ đã đến vị trí!"
            }

            target_groups = ["rescue_admin", f"rescue_team_{task.rescue_team.id}"]
            if task.rescue_request.account_id:
                target_groups.append(f"user_{task.rescue_request.account_id}")

            AssignService._push_update(groups=target_groups, event_name="TASK_UPDATE", payload_data=payload)

            return task
    
    @staticmethod
    def complete_task(assignment_id: str, account_id: str, outcome_note: str = ""):
        """Bước 5: Hoàn thành nhiệm vụ"""
        with transaction.atomic():
            # Lấy task đang chạy hoặc đã đến nơi
            try:
                team = RescueTeam.objects.get(account_id=account_id)
                task = RescueAssignments.objects.select_for_update().get(
                    id=assignment_id, 
                    rescue_team=team,
                    status__in=[TaskStatus.IN_PROGRESS, TaskStatus.ARRIVED]
                )
            except (RescueTeam.DoesNotExist, RescueAssignments.DoesNotExist):
                raise ValidationError("Không tìm thấy nhiệm vụ hợp lệ để hoàn thành.")

            # Kết thúc Task
            task.status = TaskStatus.COMPLETED
            task.completed_at = timezone.now()
            task.result_note = outcome_note # Lưu ghi chú kết quả nếu có
            task.save()

            # Giải phóng Đội -> AVAILABLE
            team.status = TeamStatus.AVAILABLE
            team.save()

            # Kết thúc Yêu cầu -> COMPLETED
            rescue_req = task.rescue_request
            rescue_req.status = RESCUE_STATUS[RescueStatus.COMPLETED]
            rescue_req.save()

            payload = {
                "task_id": task.id, 
                "request_id": rescue_req.id,
                "status": "COMPLETED",
                "msg": "Nhiệm vụ hoàn thành"
            }

            target_groups = ["rescue_admin", f"rescue_team_{team.id}"]
            if rescue_req.account_id:
                target_groups.append(f"user_{rescue_req.account_id}")

            AssignService._push_update(groups=target_groups, event_name="TASK_COMPLETED", payload_data=payload)

            return task