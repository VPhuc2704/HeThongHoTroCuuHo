from django.db import transaction
from django.http import Http404
from  ..models import RescueRequest, RescueTeam, RescueAssignments
from ..enum.rescue_status import TeamStatus, TaskStatus
from django.db.models.expressions import RawSQL

class AssignService:
    def assign_task(request_id: str, team_id: str, admin_id: str):
        with transaction.atomic():
            team = RescueTeam.objects.select_for_update().get(id=team_id)

            if team.status != TeamStatus.AVAILABLE:
                raise ValueError(f"Đội {team.name} đang nhận nhiệm vụ khác.")
            
            try:
                request = RescueRequest.objects.get(id=request_id)
            except:
                raise Http404("Không tìm thấy yêu cầu cứu hộ")
            
            task = RescueAssignments.objects.create(
                rescue_request = request,
                rescue_team=team,
                assigned_by=admin_id,
                status=TaskStatus.ASSIGNED
            )

            team.status= TeamStatus.BUSY
            team.save()
            return task
        
    def confirm_team_start(assignment_id: str, account_id: str):
        with transaction.atomic():
            try:
                team = RescueTeam.objects.get(account_id=account_id)
            except RescueTeam.DoesNotExist:
                raise ValueError("User này không phải đội cứu hộ")

            task = RescueAssignments.objects.select_for_update().filter(
                id=assignment_id,
                status=TaskStatus.ASSIGNED,
                rescue_team=team
            ).first

            if not task:
                raise ValueError("Nhiệm vụ không tồn tại hoặc đã được xử lý.")
            
            task.status = TaskStatus.IN_PROGRESS
            task.save()

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
            # 4. Lọc tinh (Cắt bỏ 4 góc vuông thừa để thành hình tròn chuẩn)
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
            