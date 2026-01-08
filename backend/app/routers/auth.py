from ninja import Router
from ninja.responses import Response
from ninja.errors import ValidationError
from app.schemas.auth_schema import (
    RegisterRequest, 
    GoogleAuthRequest, 
    LoginSchema, UserOut, 
    GoogleLoginResponse
)
from app.services import IAuthService, AuthService
from app.middleware.auth import JWTBearer
from app.security.permissions import require_role
from app.enum.role_enum import RoleCode
from django.http import JsonResponse
from django.conf import settings

router = Router(tags=["Authen"])

auth_service: IAuthService =  AuthService()
auth_bearer = JWTBearer()

@router.post("/register", response={201: dict, 400: dict, 500: dict})
def register(request, payload: RegisterRequest):
    try:
        user = auth_service.register(
            phone=payload.phone,
            password=payload.password,
            full_name=payload.full_name
        )
        return 201, {
            "status": "success",
            "message": "Đăng ký thành công",
            "data": {
                "id": str(user.id),
                "full_name": user.full_name
            }
        }

    except ValidationError as e:
        return 400, {"detail": str(e)}

    except ValidationError as e:
        return 500, {"detail": "Lỗi hệ thống, vui lòng thử lại sau."}
        

@router.post("/login", response={200: dict, 400: dict})
def login(request, payload: LoginSchema):
    if not payload.identifier:
        return 400, {'detail': "Thiếu thông tin đăng nhập"}
    
    result  = auth_service.login(
        identifier=payload.identifier, 
        password=payload.password
    )
    
    response = Response(
        {
            "id": result["id"],
            "email": result["email"],
            "full_name": result["full_name"],
            "token": {     
                "access_token": result["token"]["access_token"],
            }
        },
        status=200
    )

    response.set_cookie(
        "refresh_token",
        result["token"]["refresh_token"],
        httponly=True,
        secure=False,
        samesite="Lax",
        domain=None,
        max_age=24 * 3600 * settings.REFRESH_EXP_DAYS,
    )
    return response

@router.post("/google", response={200: UserOut, 401: dict})
def login_with_google(request, payload: GoogleAuthRequest):
    try:
        result = auth_service.login_with_google(payload.token)
        return result
    except Exception as e:
        return 401, {"detail": str(e)}


@router.post("/refresh", response={200: dict, 401: dict})
def refresh(request):
    refresh_token = request.COOKIES.get("refresh_token")
    if not refresh_token:
        return 401, {"detail": "Không có refresh token"}

    try:
        new_access = auth_service.refresh_token(refresh_token)
        return {
            "token_type": "bearer",
            "access_token": new_access
        }
    except ValidationError as e:
        return 401, {"detail": str(e)}


@router.post("/logout", response={200:dict, 400: dict})
def logout(request, data: dict = None):
    try:
        refresh_token = request.COOKIES.get("refresh_token")
        auth_service.logout(refresh_token)

        response = Response(
            {"message": "Đăng xuất thành công"},
            status=200
        )
        response.delete_cookie("refresh_token")
        return response

    except Exception as e:
        return 400, {"detail": str(e)}