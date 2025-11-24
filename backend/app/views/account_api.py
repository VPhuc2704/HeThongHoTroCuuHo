from ..main import api
from ..schemas.account_schema import AccountResponseSchema, AdminCreateAccountSchema, AccountListResponse
from ..services import IAccountService, AccountService
from app.security.jwt_bearer import JWTBearer
from app.security.permissions import require_role
from app.enum.role_enum import RoleCode
from pydantic import ValidationError

account_service: IAccountService = AccountService()
auth_bearer = JWTBearer()

@api.post("/admin/accounts", auth= auth_bearer, response={201: AccountResponseSchema, 400: dict})
@require_role(RoleCode.ADMIN)
def admin_create_account(request, data: AdminCreateAccountSchema):
    if not data.email and not data.phone:
        return 400, {'detail': "Thiếu thông tin tao tai khoan"}
    try:
        account = account_service.create_account(
            phone=data.phone,
            email=data.email,
            role_code=data.role_code
        )
    except ValidationError as e:
        return 400, {"detail": str(e)}

    return 201, {
        "status": "success",
        "message": "Tạo tài khoản thành công",
        "data": account
    }


# @api.get("/admin/accounts", auth=auth_bearer, response={200: PaginatedAccountsSchema})
# @require_role(RoleCode.ADMIN)
# def get_all_accounts(request, page: int = 1, page_size: int = 20):
#     """
#     Lấy tất cả account với pagination
#     """
#     accounts, total = account_service.get_accounts_paginated(page=page, page_size=page_size)

#     return {
#         "status": "success",
#         "message": "Danh sách tài khoản",
#         "total": total,
#         "page": page,
#         "page_size": page_size,
#         "data": accounts
#     }


@api.get("/admin/accounts", response=AccountListResponse)
def list_accounts(request, limit: int = 20, cursor: str = None):
    return account_service.get_list_accounts(limit=limit, cursor=cursor)