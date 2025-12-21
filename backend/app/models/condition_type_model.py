from django.db import models
from .unmanaged_meta import UnmanagedMeta
import uuid

class ConditionType(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255, unique=True)
    
    class Meta(UnmanagedMeta):
        db_table = "condition_type"
