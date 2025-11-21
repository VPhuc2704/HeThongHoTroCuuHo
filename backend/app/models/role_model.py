from django.db import models
from .base_model import TimeStampedModel
from .unmanaged_meta import UnmanagedMeta
import uuid

class Role(TimeStampedModel):
    id   = models.UUIDField(primary_key=True, default=uuid.uuid4 )
    code = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=100)
    
    def __str__(self):
        return self.name

    class Meta(TimeStampedModel.Meta ,UnmanagedMeta):
        db_table = "role"