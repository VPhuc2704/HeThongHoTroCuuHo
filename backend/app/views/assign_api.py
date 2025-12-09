from ..main import api
from ..schemas.assignments_schema import AssignTaskIn, ConfirmStartIn,FindNearest, NearestTeam
from ..services import AssignService
from app.security.jwt_bearer import JWTBearer
from app.security.permissions import require_role
from ..enum.role_enum import RoleCode
from typing import Optional, List

auth_bearer=JWTBearer()

@api.post("/dispatch/assign", auth=auth_bearer, response=({200: dict, 400: dict, 500:dict}))
@require_role(RoleCode.ADMIN)
def assign_task_endpoint(request, payload: AssignTaskIn):
    account_id = request.auth
    try:
        task = AssignService.assign_task(
            request_id=payload.request_id,
            team_id=payload.rescue_team_id,
            admin_id=account_id
        )
        
        return 200, {
            "success": True,
            "message": "Đã điều động đội cứu hộ thành công.",
            # "task_id": task.id,
            "team_status": "Đang bận"
        }

    except ValueError as e:
        return 400, {"success": False, "message": str(e)}
    except Exception as e:
        return 500, {"success": False, "message": "Lỗi hệ thống: " + str(e)}


@api.post("/team/confirm-start", auth=auth_bearer)
@require_role(RoleCode.RESCUER)
def confirm_start_endpoint(request, payload: ConfirmStartIn):
    account_id = request.auth
    try:
        task = AssignService.confirm_team_start(
            assignment_id=payload.assignment_id,
            rescue_id=account_id
        )

        return 200, {
            "success": True,
            "message": "Xác nhận thành công. Bắt đầu tính thời gian di chuyển.",
            "current_status": task.status
        }

    except ValueError as e:
        return 400, {"success": False, "message": str(e)}
    
@api.get("/find-teams", response=List[NearestTeam])
def find_teams_endpoint(request,  payload: FindNearest):
    teams = AssignService.find_nearest_teams(payload.latitude, payload.longitude, payload.radius_km)
    return teams