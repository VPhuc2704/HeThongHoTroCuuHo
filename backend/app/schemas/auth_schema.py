from ninja import Schema
from typing_extensions import Annotated
from typing import Optional
from .types import VNPhone, StrongPassword, CleanName


class RegisterRequest(Schema):
    full_name: CleanName
    phone: VNPhone
    password: StrongPassword
        
class GoogleAuthRequest(Schema):
    token: str

class LoginSchema(Schema):
    identifier: str
    password: str


class GoogleLoginIn(Schema):
    token: str


class TokenOut(Schema):
    access_token: str
    refresh_token: str

class UserOut(Schema):
    id: str
    email: Optional[str] = None 
    full_name:  Optional[str] = None
    token: Optional[TokenOut] = None

class GoogleLoginResponse(Schema):
    success: bool
    code: int
    message: str
    data: UserOut 