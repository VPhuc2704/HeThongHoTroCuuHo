from abc import ABC, abstractmethod
from app.repositories import IAccountRepo, AccountRepo, IRoleRepo,  RoleRepo, RefreshRepo, IRefreshRepo
# from google.oauth2 import id_token
# from google.auth.transport import requests as google_requests
import os
from app.enum.role_enum import RoleCode
from app.security.jwt_provider import JwtProvider

# import logging
# logger = logging.getLogger("app")
# logger.setLevel(logging.DEBUG)

jwt_provider = JwtProvider()

# Interface
class IAuthService(ABC):
    @abstractmethod
    def register(self, email=None, phone=None, password=None):
        pass


    @abstractmethod
    def login(self, identifier: str, password: str):
        pass


    # @abstractmethod
    # def login_google(self, token: str):
    #     pass

    @abstractmethod
    def refresh_token(self, refresh_token: str):
        pass

    @abstractmethod
    def logout(self, refresh_token: str):
        pass


# Implementation
class AuthService(IAuthService):
    def __init__(self, repo: IAccountRepo = None, role_repo: IRoleRepo = None, refresh_repo: IRefreshRepo = None):
        self.repo = repo or AccountRepo()
        self.role_repo = role_repo or RoleRepo()
        self.refresh_repo =  refresh_repo or RefreshRepo()
    
    def register(self, email=None, phone=None, password=None):

        if self.exists_any(email, phone):
            return None, "Email hoặc số điện thoại đã tồn tại"
        
        citizen_role = self.role_repo.get_by_code(RoleCode.CITIZEN.value)

        account = self.repo.create(
            email=email,
            phone=phone,
            password_hash=jwt_provider.hash_password(password),
            role=citizen_role
        )

        return account, None

    def exists_any(self, email=None, phone=None):
        if email and self.repo.exits_by_email(email):
            return True
        if phone and self.repo.exits_by_phone(phone):
            return True
        return False

    def login(self, identifier: str, password: str):
        account = self.repo.get_by_email_or_phone(identifier)
        # logger.debug(f"Repo returned user: {account.__dict__}")
        if not account:
            return None, None, "Thông tin đăng nhập sai"

        if not jwt_provider.verify_password(password, account.password_hash):
            return None, None, "Mật khẩu không đúng"

        access_token = jwt_provider.create_access_tokens(account)
        refresh_token = jwt_provider.create_resfresh_tokens(account)
        
        tokens = {
            "access_token": access_token,
            "refresh_token": refresh_token
        }
        
        return account, tokens, None


    # def login_google(self, token: str):
    #     try:
    #         info = id_token.verify_oauth2_token(token, google_requests.Request(), os.getenv('GOOGLE_CLIENT_ID'))
    #         google_id = info['sub']
    #         email = info.get('email')
    #         user = self.repo.get_by_google_id(google_id)
    #         if not user:
    #             user = self.repo.create(google_id=google_id, email=email)
    #         payload = {'id': str(user.id)}
    #         return self.create_tokens(payload)
    #     except Exception:
    #         return None

    def refresh_token(self, refresh_token: str):
        
        try:
            payload = jwt_provider.verify_refresh(refresh_token)
        except Exception as ex:
            return None, str(ex)
        user = self.repo.get_by_id(account_id=payload["user_id"])
        if not user:
            return None, "User không tồn tại"
        new_access = jwt_provider.create_access_tokens(user)
        return new_access, None

    def logout(self, refresh_token: str):
        
        if not refresh_token:
            return False, "Không có refresh token"

        token =  self.refresh_repo.find_by_token(refresh_token)
        if not token:
            return False, "Refresh token không tồn tại"

        # Đánh dấu token đã bị revoke
        token.revoked = True
        token.save(update_fields=["revoked", "updated_at"])
        return True, None

    
