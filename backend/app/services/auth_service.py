from abc import ABC, abstractmethod
from app.repositories import IAccountRepo, AccountRepo
from django.contrib.auth.hashers import make_password, check_password
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
import os, datetime, jwt

import logging
logger = logging.getLogger("app")
logger.setLevel(logging.DEBUG)


JWT_SECRET = os.getenv('JWT_SECRET', 'change-me')
JWT_ALGORITHM = os.getenv('JWT_ALGORITHM', 'HS256')
ACCESS_EXP_MIN = int(os.getenv('JWT_ACCESS_EXPIRE_MINUTES', '60'))
REFRESH_EXP_DAYS = int(os.getenv('JWT_REFRESH_EXPIRE_DAYS', '7'))


# Interface
class IAuthService(ABC):
    @abstractmethod
    def register(self, email=None, phone=None, password=None):
        pass


    @abstractmethod
    def login(self, identifier: str, password: str):
        pass


    @abstractmethod
    def login_google(self, token: str):
        pass


# Implementation
class AuthService(IAuthService):
    def __init__(self, repo: IAccountRepo = None):
        self.repo = repo or AccountRepo()

    def hash_password(self, password: str) -> str:
        return make_password(password)

    def verify_password(self, password: str, hashed: str) -> bool:
        return check_password(password, hashed)
    
    def _create_tokens(self, payload: dict):
        now = datetime.datetime.utcnow()
        access_payload = payload.copy()
        access_payload.update({
            'exp': now + datetime.timedelta(minutes=ACCESS_EXP_MIN),
            'type': 'access'
        })
        refresh_payload = payload.copy()
        refresh_payload.update({
            'exp': now + datetime.timedelta(days=REFRESH_EXP_DAYS),
            'type': 'refresh'
        })
        access = jwt.encode(access_payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
        refresh = jwt.encode(refresh_payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
        return {'access': access, 'refresh': refresh}


    def register(self, email=None, phone=None, password=None):
        data = {}
        if email:
            data['email'] = email
        if phone:
            data['phone'] = phone
        if password:
            data['password_hash'] = self.hash_password(password)
        return self.repo.create(**data)
    



    def login(self, identifier: str, password: str):
        user = self.repo.get_by_email_or_phone(identifier)
        logger.debug(f"Repo returned user: {user.__dict__}")
        if not user:
            return None, "Thông tin đăng nhập sai"

        if not self.verify_password(password, user.password_hash):
            return None, "Mật khẩu không đúng"
        
        # payload = {'id': str(user.id)}
        # return self._create_tokens(payload)
        return user, None


    def login_google(self, token: str):
        try:
            info = id_token.verify_oauth2_token(token, google_requests.Request(), os.getenv('GOOGLE_CLIENT_ID'))
            google_id = info['sub']
            email = info.get('email')
            user = self.repo.get_by_google_id(google_id)
            if not user:
                user = self.repo.create(google_id=google_id, email=email)
            payload = {'id': str(user.id)}
            return self._create_tokens(payload)
        except Exception:
            return None