from django.db import transaction
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
            
            # Update Task
            task.status = TaskStatus.IN_PROGRESS
            task.accepted_at = timezone.now()
            task.save()

            # ĐỒNG BỘ: Update Rescue Request -> IN_PROGRESS
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
        
    @staticmethod    
    def find_nearest_teams(lat:float, long: float, radius_km: float):
        
        offset = (radius_km / 111.0) * 1.1

        min_lat = lat - offset
        max_lat = lat + offset
        min_long = long - offset
        max_long = long + offset

        haversine_formula = """
            6371* acos(
                least(1.0, greatest(-1.0, 
                    cos(radians(%s)) * cos(radians(latitude)) * cos(radians(longitude) - radians(%s)) + 
                    sin(radians(%s)) * sin(radians(latitude))
                ))
            )
        """

        teams = RescueTeam.objects.filter(
            status=TeamStatus.AVAILABLE,
            latitude__gte=min_lat,
            latitude__lte=max_lat,
            longitude__gte=min_long,
            longitude__lte=max_long
        ).annotate(
            distance=RawSQL(haversine_formula, (lat, long, lat))
        ).filter(
            distance__lte=radius_km 
        ).order_by("distance")

        raw_data =  list(teams.values(
            "id", "name", "contact_phone", "distance"
        ))

        for team in raw_data:
            if team["distance"] is not None:
                team["distance"] = round(team["distance"], 2)
            else: team["distance"] = 0.0
        
        return raw_data
    
    @staticmethod        
    def get_assign(user):
        """Lấy danh sách nhiệm vụ dựa trên Role"""
        #Admin: Xem tất cả
        if user.role.code == RoleCode.ADMIN:
            return RescueAssignments.objects.select_related('rescue_request', 'rescue_team')\
                .all().order_by('-created_at')
        
        #Đội cứu hộ: Xem nhiệm vụ của chính mình
        if user.role.code == RoleCode.RESCUER:
            try:
                team = RescueTeam.objects.get(account=user)
                return RescueAssignments.objects.select_related('rescue_request')\
                    .filter(rescue_team=team).order_by('-created_at')
            except RescueTeam.DoesNotExist:
                return []
        return []
            