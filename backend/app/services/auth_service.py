from abc import ABC, abstractmethod
from django.conf import settings

from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

from app.repositories import IAccountRepo, AccountRepo, IRoleRepo,  RoleRepo, RefreshRepo, IRefreshRepo
from app.enum.role_enum import RoleCode
from app.security.jwt_provider import JwtProvider
from app.exception.custom_exceptions import InvalidToken, InvalidCredentials


jwt_provider = JwtProvider()

class IAuthService(ABC):
    @abstractmethod
    def register(self, full_name= str, phone= str, password= str) -> None:
        pass
    @abstractmethod
    def login(self, identifier: str, password: str):
        pass
    @abstractmethod
    def login_with_google(self, token: str):
        pass
    @abstractmethod
    def refresh_token(self, refresh_token: str) -> str:
        pass
    @abstractmethod
    def logout(self, refresh_token: str) -> None:
        pass



class AuthService(IAuthService):
    def __init__(self, repo: IAccountRepo = None, role_repo: IRoleRepo = None, refresh_repo: IRefreshRepo = None):
        self.repo = repo or AccountRepo()
        self.role_repo = role_repo or RoleRepo()
        self.refresh_repo =  refresh_repo or RefreshRepo()

    #funtion response dict sau khi login
    def _build_login_result(self, user):
        return {
            "id": str(user.id),
            "email": user.email,
            "full_name":user.full_name,
            "token":{
                "access_token":jwt_provider.create_access_tokens(user),
                "refresh_token":jwt_provider.create_resfresh_tokens(user),
            }
        }
    
    # Người dân đăng kí account
    def register(self, phone= str, password= str, full_name= str):

        if self.repo.exists_by_phone(phone):
            raise ValueError("Số điện thoại đã tồn tại")
        
        citizen_role = self.role_repo.get_by_code(RoleCode.CITIZEN.value)

        account = self.repo.create(
            full_name=full_name,
            phone=phone,
            password_hash=jwt_provider.hash_password(password),
            role=citizen_role
        )

        return account

    # Đăng nhập bằng phone + pass 
    def login(self, identifier: str, password: str):
        account = self.repo.get_by_email_or_phone(identifier)
        if not account:
             raise InvalidCredentials("Thông tin đăng nhập sai")

        if not jwt_provider.verify_password(password, account.password_hash):
             raise InvalidCredentials("Thông tin đăng nhập sai")

        return self._build_login_result(account)

     # Đăng nhập bằng OAuth 2.0
    def login_with_google(self, token: str):
        try:
            info = id_token.verify_oauth2_token(
                token, 
                google_requests.Request(),
                settings.GOOGLE_CLIENT_ID
            )
        except ValueError:
            raise InvalidCredentials("Token Google không hợp lệ hoặc hết hạn.")
        google_id = info['sub']
        email = info.get('email')
        full_name = info.get('name')

        if not email:
            raise InvalidCredentials("Tài khoản Google này không có Email hợp lệ.")

        user = self.repo.get_by_social(provider="google", provider_id=google_id)
        
        if not user:
            user = self.repo.get_by_email_or_phone(email)
            if user:
                self.repo.add_social_link(user, 'google', google_id, email)
            else:
                citizen_role = self.role_repo.get_by_code(RoleCode.CITIZEN.value)
                user = self.repo.create_with_social(
                    email=email,
                    full_name=full_name,
                    provider='google',
                    provider_id=google_id,
                    role=citizen_role
                )
        return self._build_login_result(user)

    # Cấp lại access_token
    def refresh_token(self, refresh_token: str) -> str:
        payload = jwt_provider.verify_refresh(refresh_token)

        user = self.repo.get_by_id(account_id=payload["user_id"])
        if not user:
            raise ValueError("User không tồn tại")

        return jwt_provider.create_access_tokens(user)

    # Đăng xuất
    def logout(self, refresh_token: str) -> None:
        
        if not refresh_token:
            return False, "Không có refresh token"

        token =  self.refresh_repo.find_by_token(refresh_token)
        if not token:
            return False, "Refresh token không tồn tại"

        token.revoked = True
        token.save(update_fields=["revoked", "updated_at"])

    
