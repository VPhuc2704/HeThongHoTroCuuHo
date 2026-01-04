from abc import ABC, abstractmethod
from ..repositories import  IAccountRepo,AccountRepo,IRoleRepo, RoleRepo, IRescueTeamRepo , RescueTeamRepo
from ..schemas.account_schema import AccountUpdate
from typing import Optional, Dict, Any
from ninja.errors import ValidationError
from ..security.jwt_provider import JwtProvider
from django.db import transaction
from app.enum.role_enum import RoleCode

from app.exception.custom_exceptions import PermissionDenied, ResourceNotFound, BaseAppException 

class IAccountService(ABC):
    @abstractmethod
    def create_account(self, *, phone: Optional[str], email: Optional[str], role_code: str):
        pass
    @abstractmethod
    def get_list_accounts(self, *, limit: int, cursor: Optional[str]) -> Dict[str, Any]:
        pass
    @abstractmethod
    def update_infor(self, current_user, account_id: str, payload: AccountUpdate):
        pass
    @abstractmethod
    def get_profile(self, account_id: str):
        pass

    @abstractmethod
    def lock_account(self, account_id: str):
        pass

    @abstractmethod
    def unlock_account(self, account_id: str):
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

    def update_infor(self, current_user, account_id: str, payload: AccountUpdate):
        self.check_permission(current_user, account_id)

        if payload.email is not None:
            if self.account_repo.exists_by_email(payload.email):
                raise BaseAppException(
                    message="Email đã tồn tại",
                    code=400,
                    details={"email": payload.email}
                )
    
            
        with transaction.atomic():
            account = self.account_repo.get_for_update(account_id=account_id)
            update_fields = []
            
            if payload.email:
                account.email = payload.email
                update_fields.append("email")

            if payload.full_name:
                account.full_name = payload.full_name
                update_fields.append("full_name")

            if payload.password:
                account.password_hash = jwt_provider.hash_password(payload.password)
                update_fields.append("password_hash")

            if update_fields:
                account.save(update_fields=update_fields)
        return account             



    def check_permission(self, current_user, account_id):
        if current_user.role.code != RoleCode.ADMIN:
            if str(current_user.id) != str(account_id):
                raise PermissionError("Không có quyền truy cập tài khoản này")

    def get_profile(self, account_id):
        try:
            account = self.account_repo.get_by_id(account_id)
        except:
            raise BaseAppException(
            message="Tài khoản không tồn tại",
            code=404
        )
        return account

    def lock_account(self, account_id):
        with transaction.atomic():
            account = self.account_repo.get_for_update(account_id)

        if not account.is_active:
            return account
        account.is_active = False
        account.save(update_fields=["is_active"])

        return account
    
    def unlock_account(self, account_id):
        with transaction.atomic():
            account = self.account_repo.get_for_update(account_id)

        account.is_active = True
        account.save(update_fields=["is_active"])

        return account

    


    

