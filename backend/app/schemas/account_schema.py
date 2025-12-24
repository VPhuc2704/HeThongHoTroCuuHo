from ..models import Account, Role
from ..enum.role_enum import RoleCode
from ninja import ModelSchema, Schema
from ..schemas.auth_schema import RegisterRequest
from pydantic import field_validator
from typing import List, Optional

class RoleSchema(ModelSchema):
    class Meta:
        model = Role
        fields = ['id', 'name']

class AccountSchema(ModelSchema):
    role: RoleSchema
    class Meta:
        model = Account
        fields = ['id', 'email', 'phone', 'role', 'is_active', 'created_at']
        orm_mode = True

class  AdminCreateAccountSchema(RegisterRequest):
    role_code: RoleCode

class AccountResponseSchema(Schema):
    status: str
    message: str
    data: AccountSchema 

class AccountListResponse(Schema):
    items: List[AccountSchema]
    next_cursor: Optional[str]