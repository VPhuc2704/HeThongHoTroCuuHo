from app.models import RescueTeam
from app.schemas.rescue_schema import RescueTeamUpdate
from app.exception.custom_exceptions import ResourceNotFound, PermissionDenied
from app.enum.role_enum import RoleCode
class RescueService:
    
    def get_teams(user):
        if user.role.code == RoleCode.ADMIN:
            return RescueTeam.objects.select_related('account').all().order_by('-created_at')
        return []


    def update_rescue_team(account, team_id: str, payload: RescueTeamUpdate):
        try:
            team = RescueTeam.objects.get(id=team_id)
        except:
            raise ResourceNotFound("Đội cứu hộ không tồn tại")
        
        is_admin = (account.role.code == RoleCode.ADMIN)
        is_owner = (team.account == account)
        
        if not is_admin and is_owner:
            raise PermissionDenied("Bạn không có quyền sửa đội này.")
        
        data = payload.model_dump(exclude_unset=True)

        for attr, value in data.items():
            setattr(team, attr, value)

        team.save()
        return team
    

    def delete_team(team_id: str):
        try:
            team = RescueTeam.objects.get(id=team_id)
            team.delete()
            return True
        except RescueTeam.DoesNotExist:
            raise ResourceNotFound("Đội cứu hộ không tồn tại")