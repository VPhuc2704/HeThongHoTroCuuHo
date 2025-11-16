from ninja import NinjaAPI

from app.schemas.auth_schema import RegisterSchema, LoginSchema, UserOut
from app.services import IAuthService, AuthService


auth_service: IAuthService =  AuthService()
api = NinjaAPI()

@api.post("/register", response={201: dict, 400: dict})
def register(request, payload: RegisterSchema):
    if not payload.email and not payload.phone:
        return 400, {'detail': "Thiếu thông tin đăng nhập"}
    user = auth_service.register(email=payload.email, phone=payload.phone, password=payload.password)
    return 201, {'id': str(user.id)}
    

@api.post("/login", response={200: UserOut, 400: dict})
def login(request, data: LoginSchema):
    if not data.identifier and not data.phone:
        return 400, {'detail': "Thiếu thông tin đăng nhập"}
    user, error = auth_service.login(identifier=data.identifier, password=data.password)
    if error:
        return 400, {"detail": error}
    return {
        "id": str(user.id),
        "email": user.email,
        "phone": user.phone,
    }