from django.db import models
from .base_model import TimeStampedModel
from .role_model import Role
from .unmanaged_meta import UnmanagedMeta
import uuid

class Account(TimeStampedModel):
    id  = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    full_name = models.CharField(max_length=50, null=True, blank=True)
    phone = models.CharField(max_length=20, unique=True, null=True, blank=True)
    password_hash = models.TextField(null=True, blank=True)
    email = models.CharField(max_length=255, unique=True, null=True, blank=True)
    role = models.ForeignKey(Role, on_delete=models.SET_NULL, null=True, related_name='accounts')
    is_active = models.BooleanField(default=True)
    
    class Meta(TimeStampedModel.Meta, UnmanagedMeta):
        db_table = "accounts"