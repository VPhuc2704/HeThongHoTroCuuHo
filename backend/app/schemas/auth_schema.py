# ...existing code...
from ninja import Schema
from pydantic import EmailStr, constr, field_validator, model_validator
from typing_extensions import Annotated
from typing import Optional
import re


class RegisterSchema(Schema):
    email: Optional[EmailStr] = None
    password: Annotated[str, constr(min_length=6)]
    phone:  Optional[str] = None
    google: Optional[str] = None

    @model_validator(mode='before')
    def check_email_or_phone(cls, value):
        email = getattr(value, 'email', None)
        phone = getattr(value, 'phone', None)
        google = getattr(value, 'google', None)
        if not email and not phone and not google:
            raise ValueError("Thiếu thông tin đăng nhập")
        return value

    @field_validator('phone')
    def phone_validate(cls, v: Optional[str]) -> Optional[str]:
        if v is None: 
            return v
        v_clean = v.replace(' ', '').replace('-', '')
        pattern = r'^(0\d{9}|(\+84)\d{9})$'
        if not re.fullmatch(pattern, v_clean):
            raise ValueError('Số điện thoại không hợp lệ')
        return v_clean
    
    @field_validator('password')
    def pass_validate(cls, v: str) -> str:
        if len(v) < 8: 
            raise ValueError("Mật khẩu phải có ít nhất 8 ký tự")
        if ' ' in v:
            raise ValueError("Mật khẩu không được chứa khoảng trắng")
        if not re.search(r"[A-Z]", v):
            raise ValueError("Mật khẩu phải chứa ít nhất 1 chữ hoa")
        if not re.search(r"[a-z]", v):
            raise ValueError("Mật khẩu phải chứa ít nhất 1 chữ thường")
        if not re.search(r"\d", v):
            raise ValueError("Mật khẩu phải chứa ít nhất 1 chữ số")
        if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", v):
            raise ValueError("Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt")
        return v
        

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
    phone: Optional[str] = None
    token: Optional[TokenOut] = None
