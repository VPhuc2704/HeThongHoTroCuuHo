from ninja import Router
from ..schemas.account_schema import AccountResponseSchema, AdminCreateAccountSchema, AccountListResponse, AccountUpdate, AccountSchema
from ..schemas.exception_schema import ApiResponse
from ..services import IAccountService, AccountService
from app.middleware.auth import JWTBearer
from app.security.permissions import require_role
from app.enum.role_enum import RoleCode
from pydantic import ValidationError

router = Router(tags=["Account"])

account_service: IAccountService = AccountService()
auth_bearer = JWTBearer()

@router.post("/admin/accounts", auth= auth_bearer, response={201: AccountResponseSchema, 400: dict})
@require_role(RoleCode.ADMIN)
def admin_create_account(request, data: AdminCreateAccountSchema):
    if not data.phone:
        return 400, {'detail': "Thiếu thông tin tao tai khoan"}
    try:
        account = account_service.create_account(
            full_name=data.full_name,
            phone=data.phone,
            password=data.password,
            role_code=data.role_code
        )
    except ValidationError as e:
        return 400, {"detail": str(e)}

    return 201, {
        "status": "success",
        "message": "Tạo tài khoản thành công",
        "data": account
    }

@router.get("/admin/accounts", auth=auth_bearer, response=AccountListResponse)
@require_role(RoleCode.ADMIN)
def list_accounts(request, limit: int = 20, cursor: str = None):
    return account_service.get_list_accounts(limit=limit, cursor=cursor)


@router.patch("/admin/account/lock/{account_id}",
            auth=auth_bearer,
            response={200: ApiResponse}
)
@require_role(RoleCode.ADMIN)
def lock_account(request, account_id: str):
    account_service.lock_account(account_id)
    return 200, {
        "success": True,
        "code": 200,
        "message": "Khóa tài khoản thành công",
        "data": None,
        "details": None
    }

@router.patch("/admin/account/unlock/{account_id}",
            auth=auth_bearer,
            response={200: ApiResponse}
)
@require_role(RoleCode.ADMIN)
def unlock_account(request, account_id: str):
    account_service.unlock_account(account_id)
    return 200, {
        "success": True,
        "code": 200,
        "message": "Mỡ Khóa tài khoản thành công",
        "data": None,
        "details": None
    }


@router.get("/profile/me", 
            auth= auth_bearer, 
            response={200: ApiResponse[AccountSchema]}
)
def get_profile(request):
    account = request.auth
    result = account_service.get_profile(account.id)

    return 200, {
        "success": True,
        "code": 200,
        "message": "Lấy thông tin tài khoản thành công",
        "data": AccountSchema.from_orm(result),
        "details": None
    }


@router.put(
    "/profile/me",
    auth=auth_bearer,
    response={200: ApiResponse[AccountSchema]}
)
def update_profile(request, payload: AccountUpdate):
    updated = account_service.update_infor(
        current_user=request.auth,
        account_id=request.auth.id,
        payload=payload
    )

    return 200, {
        "success": True,
        "code": 200,
        "message": "Cập nhật thành công",
        "data": AccountSchema.from_orm(updated),
        "details": None
    }


@router.put(
    "/{account_id}",
    auth=JWTBearer(),
    response={200: ApiResponse[AccountSchema]}
)
@require_role(RoleCode.ADMIN)
def admin_update_user(request, account_id: str, payload: AccountUpdate):
    updated = account_service.update_infor(
        current_user=request.auth,
        account_id=account_id,
        payload=payload
    )

    return 200, {
        "success": True,
        "code": 200,
        "message": "Cập nhật tài khoản thành công",
        "data": AccountSchema.from_orm(updated),
        "details": None
    }


