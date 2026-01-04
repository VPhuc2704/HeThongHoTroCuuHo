from abc import ABC, abstractmethod
from app.models import Account, Role, SocialAccount
from typing import Optional, List
from django.db.models import Q
from django.db import connection, transaction
from django.utils.dateparse import parse_datetime

class IAccountRepo(ABC):
    @abstractmethod
    def get_by_email_or_phone(self, indentifer: str) -> Optional[Account]:
        pass

    @abstractmethod
    def get_by_id(self, account_id: str) -> Optional[Account]:
        pass
    
    @abstractmethod
    def create(self, **kwargs) -> Account:
        pass

    @abstractmethod
    def exists_by_email(self, email: str) -> bool:
        pass
    
    @abstractmethod
    def exists_by_phone(self, phone: str) -> bool:
        pass

    @abstractmethod
    def get_all_accounts(self, *, limit: int, cursor: Optional[str]) -> List[Account]:
        pass

    @abstractmethod
    def get_by_social(self, provider: str, provider_id: str) -> Optional[Account]:
        pass

    @abstractmethod
    def create_with_social(self, email: str, full_name: str, provider: str, provider_id: str, role) -> Account:
        pass

    @abstractmethod
    def add_social_link(self, account: Account, provider: str, provider_id: str, email: str):
        pass

    @abstractmethod
    def get_for_update(self, account_id: str) -> Optional[Account]:
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


    def exists_by_email(self, email: str) -> bool:
        return Account.objects.filter(email=email).exists()
    
    def exists_by_phone(self, phone: str) -> bool:
        return Account.objects.filter(phone=phone).exists()

    def get_by_id(self, account_id) -> Optional[Account]:
        return Account.objects.get(id=account_id)
    

    def get_all_accounts(self, *, limit: int, cursor: Optional[str]) -> List[Account]:
        qs = Account.objects.select_related("role").order_by("-created_at")
        if cursor:
            qs = qs.filter(created_at__lt=parse_datetime(cursor))
        return list(qs[:limit]) 
    
    # --- SOCIAL LOGIN SECTION (Giữ nguyên vì đã chuẩn) ---
    def get_by_social(self, provider: str, provider_id: str) -> Optional[Account]:
        try:
            social = SocialAccount.objects.select_related('account', 'account__role').get(
                provider=provider, 
                provider_id=provider_id
            )
            return social.account
        except SocialAccount.DoesNotExist:
            return None
        
    def create_with_social(self, email: str, full_name: str, provider: str, provider_id: str, role) -> Account:
        with transaction.atomic():
            account = Account.objects.create(
                email=email,
                full_name=full_name,
                phone=None,
                password_hash=None,
                role=role,
                is_active=True
            )
            SocialAccount.objects.create(
                account=account,
                provider=provider,
                provider_id=provider_id,
                email=email
            )
            return account

    def add_social_link(self, account: Account, provider: str, provider_id: str, email: str):
        SocialAccount.objects.get_or_create(
            account=account,
            provider=provider,
            provider_id=provider_id,
            defaults={'email': email}
        )

    def get_for_update(self, account_id: str):
        return Account.objects.select_for_update().get(id=account_id)