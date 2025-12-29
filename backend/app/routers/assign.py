from ninja import Router, Query
from django.core.exceptions import ValidationError, PermissionDenied
from django.http import Http404

from ..schemas.assignments_schema import (
    AssignTaskIn, ConfirmStartIn, CompleteTaskIn, 
    FindNearest, NearestTeam, AssignmentOut
)
from ..services import AssignService
from app.middleware.auth import JWTBearer
from app.security.permissions import require_role
from ..enum.role_enum import RoleCode
from typing import List

router = Router(tags=["Dispatch & Rescue Workflow"])
auth_bearer = JWTBearer()


#ADMIN: Điều phối đội
@router.post("/dispatch/assign", auth=auth_bearer, response={200: dict, 400: dict, 404: dict, 500: dict})
@require_role(RoleCode.ADMIN)
def assign_task_endpoint(request, payload: AssignTaskIn):
    account = request.auth 
    try:
        task = AssignService.assign_task(
            request_id=payload.request_id,
            team_id=payload.rescue_team_id,
            admin_id=account.id
        )
        
        return 200, {
            "success": True,
            "message": f"Đã điều động đội {task.rescue_team.name} thành công.",
            "task_id": str(task.id),
            "status": task.status
        }

    except Http404 as e:
        return 404, {"success": False, "message": str(e)}
    except (ValueError, ValidationError) as e:
        return 400, {"success": False, "message": str(e)}
    except Exception as e:
        return 500, {"success": False, "message": f"Lỗi hệ thống: {str(e)}"}
    
    
# Tìm đội gần nhất (Find Teams)
@router.get("/find-teams", response=List[NearestTeam], auth=auth_bearer)
@require_role(RoleCode.ADMIN)
def find_teams_endpoint(request, params: FindNearest = Query(...)):
    """API tìm đội cứu hộ gần nhất"""
    teams = AssignService.find_nearest_teams(
        lat=params.latitude, 
        lng=params.longitude, 
        radius_km=params.radius_km
    )
    return teams


# Lịch sử/Danh sách nhiệm vụ
@router.get("/assignments", response=List[AssignmentOut], auth=auth_bearer)
def get_my_assignments(request):
    """
    - Admin: Xem tất cả
    - Rescuer: Xem nhiệm vụ của mình
    """
    account = request.auth
    tasks = AssignService.get_assign(user=account)
    return tasks


#Đội cứu hộ: Xác nhận xuất phát
@router.post("/task/start", auth=auth_bearer, response={200: dict, 400: dict, 403: dict})
@require_role(RoleCode.RESCUER)
def confirm_start_endpoint(request, payload: ConfirmStartIn):
    account = request.auth
    try:
        task = AssignService.confirm_team_start(
            assignment_id=payload.assignment_id,
            account_id=account.id
        )

        return 200, {
            "success": True,
            "message": "Đã xác nhận xuất phát. Hãy di chuyển nhanh chóng!",
            "status": task.status
        }

    except PermissionDenied as e:
        return 403, {"success": False, "message": str(e)}
    except (ValueError, ValidationError) as e:
        return 400, {"success": False, "message": str(e)}


#Đội cứu hộ: Xác nhận đã đến nơi (Arrived)
@router.post("/task/arrived", auth=auth_bearer, response={200: dict, 400: dict})
@require_role(RoleCode.RESCUER)
def confirm_arrived_endpoint(request, payload: ConfirmStartIn):
    account = request.auth
    try:
        task = AssignService.confirm_team_arrived(
            assignment_id=payload.assignment_id,
            account_id=account.id
        )
        return 200, {
            "success": True, 
            "message": "Đã xác nhận đến hiện trường.",
            "status": task.status
        }
    except Exception as e:
         return 400, {"success": False, "message": str(e)}


# Đội cứu hộ: Hoàn thành nhiệm vụ (Complete)
@router.post("/task/complete", auth=auth_bearer, response={200: dict, 400: dict})
@require_role(RoleCode.RESCUER)
def complete_task_endpoint(request, payload: CompleteTaskIn):
    account = request.auth
    try:
        task = AssignService.complete_task(
            assignment_id=payload.assignment_id,
            account_id=account.id,
            outcome_note=payload.outcome_note
        )
        return 200, {
            "success": True,
            "message": "Nhiệm vụ hoàn tất. Đội đã sẵn sàng cho ca tiếp theo.",
            "status": task.status
        }
    except Exception as e:
        return 400, {"success": False, "message": str(e)}
