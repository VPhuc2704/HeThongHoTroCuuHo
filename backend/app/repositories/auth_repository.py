from abc import ABC, abstractmethod
from app.models import Account
from typing import Optional
from django.db.models import Q
from django.db import connection

class IAccountRepo(ABC):
    @abstractmethod
    def get_by_email_or_phone(self, indentifer: str) -> Optional[Account]:
        pass
    
    @abstractmethod
    def get_by_google_id(self, google_id: str) -> Optional[Account]:
        pass

    @abstractmethod
    def create(self, **kwargs) -> Account:
        pass

class AccountRepo(IAccountRepo):

    # def get_by_email_or_phone(self, identifier: str) -> Optional[Account]:
    #     return Account.objects.filter(Q(email=identifier) | Q(phone=identifier)).first()

    def get_by_email_or_phone(self, indentifer):
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT id, email, phone, password_hash
                FROM accounts
                WHERE email=%s OR phone=%s
                LIMIT 1
            """, [indentifer, indentifer])

            row = cursor.fetchone()
        if not row:
            return None

        return Account(
            id=row[0],
            email=row[1],
            phone=row[2],
            password_hash=row[3],
        )

    def get_by_google_id(self, google_id: str) -> Optional[Account]:
        return Account.objects.filter(google_id=google_id).first()
    


    def create(self, **kwargs) -> Account:
        return Account.objects.create(**kwargs)


