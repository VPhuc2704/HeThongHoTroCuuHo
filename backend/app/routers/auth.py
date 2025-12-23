from ninja import Router
from app.schemas.auth_schema import RegisterSchema, LoginSchema, UserOut
from app.services import IAuthService, AuthService
from app.middleware.auth import JWTBearer
from app.security.permissions import require_role
from app.enum.role_enum import RoleCode
from django.http import JsonResponse
from django.conf import settings

router = Router(tags=["Authen"])

auth_service: IAuthService =  AuthService()
auth_bearer = JWTBearer()

@router.post("/register", response={201: dict, 400: dict})
def register(request, data: RegisterSchema):
    if not data.email and not data.phone:
        return 400, {'detail': "Thiếu thông tin đăng nhập"}
    
    user, error = auth_service.register(email=data.email, phone=data.phone, password=data.password)

    if error: 
        return 400, {"detail": error}
    return 201, {
        "status": "success",
        "message": "Đăng ký thành công",
        "data": {
            "id": str(user.id)
        }
    }
    

@router.post("/login", response={200: UserOut, 400: dict})
def login(request, data: LoginSchema):
    if not data.identifier:
        return 400, {'detail': "Thiếu thông tin đăng nhập"}
    user, token, error = auth_service.login(identifier=data.identifier, password=data.password)
    if error:
        return 400, {"detail": error}

    
    access = token["access_token"]
    refresh = token["refresh_token"]

    response_data = {
        "access_token": access,
        "token_type": "bearer",
        "user": {
            "id": str(user.id),
            "email": user.email,
            "phone": user.phone,
        }
    }

    response = JsonResponse(response_data)
    response.set_cookie(
        "refresh_token",
        refresh,
        httponly=True,
        secure=False,
        samesite="Lax",
        domain=None,
        max_age=24 * 3600 * settings.REFRESH_EXP_DAYS,
    )
    return response

@router.post("/refresh", response={200: dict, 401: dict})
def refresh(request):
    refresh_token =  request.COOKIES.get("refresh_token")
    
    if not refresh_token:
        return 401, {"detail": "Không có refresh token"}
    
    new_access, error = auth_service.refresh_token(refresh_token)

    if error:
        return 401, {"detail": error}

    return {
        "access_token": new_access, 
        "token_type": "bearer"
    }


@router.post("/logout", response={200:dict, 400: dict})
def logout(request, data: dict = None):
    refresh_token = request.COOKIES.get("refresh_token")

    ok, error = auth_service.logout(refresh_token)

    if error:
        return 400, {"detail": error}

    response = JsonResponse({"message": "Đăng xuất thành công"})

    if request.COOKIES.get("refresh_token"):
        response.delete_cookie("refresh_token")

    return response
