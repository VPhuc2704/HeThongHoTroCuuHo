from abc import ABC, abstractmethod
from ..repositories import  IAccountRepo,AccountRepo,IRoleRepo, RoleRepo, IRescueTeamRepo , RescueTeamRepo
from typing import Optional, Dict, Any
from ninja.errors import ValidationError
from ..security.jwt_provider import JwtProvider
from django.db import transaction, IntegrityError
from app.enum.role_enum import RoleCode

class IAccountService(ABC):
    @abstractmethod
    def create_account(self, *, phone: Optional[str], email: Optional[str], role_code: str):
        pass
    @abstractmethod
    def get_list_accounts(self, *, limit: int, cursor: Optional[str]) -> Dict[str, Any]:
        pass

jwt_provider = JwtProvider()
class AccountService(IAccountService):
    def __init__(
            self, 
            account_repo: IAccountRepo = None, 
            role_repo: IRoleRepo = None,
            rescue_team_repo: IRescueTeamRepo = None
        ):
        self.account_repo = account_repo or AccountRepo()
        self.role_repo = role_repo or RoleRepo()
        self.rescue_team_repo = rescue_team_repo or RescueTeamRepo()
        

    def create_account(self, *, phone= None, full_name= None, password= None, role_code: str):
        if not phone:
            raise ValidationError("Phải có phone hoặc email")
        
        if phone and self.account_repo.exists_by_phone(phone=phone):
            raise ValidationError(f"Phone {phone} đã tồn tại")

        try:
            role = self.role_repo.get_by_code(code=role_code)
        except:
            raise  ValidationError(f"Role {role_code} không tồn tại.")
        with transaction.atomic():
            account = self.account_repo.create(
                phone=phone,
                full_name=full_name,
                role=role,
                password_hash=jwt_provider.hash_password(password),
            )
            if role.code == RoleCode.RESCUER.value:
                self.rescue_team_repo.create(
                    account=account,
                    name=f"Đội cứu hộ của {phone }",
                    leader_name=full_name,
                    contact_phone=phone,
                    hotline=phone,
                    team_type='CỨU HỘ'
            )
    
        return account

    def get_list_accounts(self, *, limit: int , cursor: Optional[str]):
        items = self.account_repo.get_all_accounts(limit=limit, cursor=cursor)

        next_cursor = None
        if len(items) == limit:
            next_cursor = items[-1].created_at.isoformat()

        return {
            "items":items,
            "next_cursor":next_cursor
        }



