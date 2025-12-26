from django.db import transaction, connection
from django.http import Http404
from django.core.exceptions import ValidationError, PermissionDenied
from django.db.models.expressions import RawSQL
from django.utils import timezone
from ..models import RescueRequest, RescueTeam, RescueAssignments
from ..enum.rescue_status import TeamStatus, TaskStatus, RescueStatus, RESCUE_STATUS
from ..enum.role_enum import RoleCode

class AssignService:
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
            team.save()

            request.status= RESCUE_STATUS[RescueStatus.ASSIGNED]
            request.save()
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
        #Admin: Xem tất cả
        if user.role.code == RoleCode.ADMIN:
            return RescueAssignments.objects.select_related('rescue_request', 'rescue_team')\
                .all().order_by('-created_at')
        
        if user.role.code == RoleCode.RESCUER:
            try:
                team = RescueTeam.objects.get(account=user)
                return RescueAssignments.objects.select_related('rescue_request')\
                    .filter(rescue_team=team).order_by('-created_at')
            except RescueTeam.DoesNotExist:
                return []
        return []
            
        
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
            task.save()

            # ĐỒNG BỘ: cập nhật Rescue Request -> IN_PROGRESS
            # Để người dân thấy trạng thái đổi sang "Đang thực hiện"
            rescue_req = task.rescue_request
            rescue_req.status = RescueStatus.IN_PROGRESS
            rescue_req.save()

            return task
        
    @staticmethod
    def confirm_team_arrived(assignment_id: str, account_id: str):
        """Bước 4: Đội báo đã đến nơi"""
        with transaction.atomic():
            task = AssignService._get_team_task(assignment_id, account_id, TaskStatus.IN_PROGRESS)
            
            task.status = TaskStatus.ARRIVED
            task.save()
            
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
            rescue_req.status = RescueStatus.COMPLETED
            rescue_req.save()

            return task