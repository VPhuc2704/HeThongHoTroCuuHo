from abc import ABC, abstractmethod
from app.models import Account, Role
from typing import Optional, List
from django.db.models import Q
from django.db import connection
from django.utils.dateparse import parse_datetime

class IAccountRepo(ABC):
    @abstractmethod
    def get_by_email_or_phone(self, indentifer: str) -> Optional[Account]:
        pass

    @abstractmethod
    def get_by_id(self, account_id: str) -> Optional[Account]:
        pass
    
    @abstractmethod
    def get_by_google_id(self, google_id: str) -> Optional[Account]:
        pass

    @abstractmethod
    def create(self, **kwargs) -> Account:
        pass

    @abstractmethod
    def exits_by_email(self, email: str) -> bool:
        pass
    
    @abstractmethod
    def exits_by_phone(self, phone: str) -> bool:
        pass

    @abstractmethod
    def get_all_accounts(self, *, limit: int, cursor: Optional[str]) -> List[Account]:
        pass



class AccountRepo(IAccountRepo):

    def create(self, **kwargs) -> Account:
        return Account.objects.create(**kwargs)

    # def get_by_email_or_phone(self, identifier: str) -> Optional[Account]:
    #     return Account.objects.select_related('role').filter(Q(email=identifier) | Q(phone=identifier)).first()

    def get_by_email_or_phone(self, indentifer) -> Optional[Account]:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    a.id, a.email, a.phone, a.password_hash, a.role_id,
                    r.id, r.code, r.name
                FROM accounts a
                LEFT JOIN role r ON a.role_id = r.id
                WHERE a.email=%s OR a.phone=%s
                LIMIT 1
            """, [indentifer, indentifer])
            row = cursor.fetchone()
        if not row:
            return None
        
        role_instance = None
        if row[5]:  # r.id
            role_instance = Role(
                id=row[5],
                code=row[6],
                name=row[7]
            )
        
        return Account(
            id=row[0],
            email=row[1],
            phone=row[2],
            password_hash=row[3],
            role=role_instance,
        )

    def get_by_google_id(self, google_id: str) -> Optional[Account]:
        return Account.objects.filter(google_id=google_id).first()

    def exits_by_email(self, email: str) -> bool:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 1
                FROM accounts
                WHERE email = %s
                LIMIT 1 
            """,[email])
            row =  cursor.fetchone()
        return row is not None
    
    def exits_by_phone(self, phone: str) -> bool:
        return Account.objects.filter(phone=phone).exists()

    def get_by_id(self, account_id) -> Optional[Account]:
        return Account.objects.get(id=account_id)
    

    def get_all_accounts(self, *, limit: int, cursor: Optional[str]) -> List[Account]:
        qs = Account.objects.select_related("role").order_by("-created_at")
        if cursor:
            qs = qs.filter(created_at__lt=parse_datetime(cursor))
        return list(qs[:limit]) 