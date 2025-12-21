from ninja import Router
from typing import List

from ..middleware.auth import JWTBearer
from ..security.permissions import require_role

from ..schemas.rescue_schema import RescueTeamOut, RescueTeamUpdate
from ..schemas.exception_schema import ApiResponse
from ..enum.role_enum import RoleCode

from ..services import RescueService

router = Router(tags=["Rescue Team Manager"], auth=JWTBearer())

@router.get("/", response=ApiResponse[List[RescueTeamOut]])
@require_role(RoleCode.ADMIN)
def list_teams(request):
    data = RescueService.get_teams(request.auth)
    return ApiResponse(
        success=True,
        code=200,
        message="Lấy danh sách thành công",
        data=data
    )

@router.patch("/{team_id}", response=ApiResponse[RescueTeamOut])
def update_rescue_team(request, team_id: str, payload: RescueTeamUpdate):
    update_rescue_team = RescueService.update_rescue_team(request.auth, team_id, payload)

    return ApiResponse(
        success=True,
        code=200,
        message="Cập nhật thông tin thành công",
        data=update_rescue_team
    )

@router.delete("/{team_id}", response=ApiResponse[None])
@require_role(RoleCode.ADMIN)
def delete_team(request, team_id: str):
    RescueService.delete_team(team_id)
    return ApiResponse(
        success=True,
        code=204,
        message="Xóa đội thành công.",
        data=None
    )