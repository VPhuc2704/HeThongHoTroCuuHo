from django.db import models
from .base_model import TimeStampedModel
from .account_model import Account
from .unmanaged_meta import UnmanagedMeta
from ..enum.rescue_status import RESCUE_STATUS, RescueStatus
import uuid
from django.utils.timezone import now


class RescueRequest(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    account = models.ForeignKey(Account, null=True, blank=True ,on_delete=models.CASCADE, related_name="rescue_requests")
    # code = models.CharField(max_length=30, unique=True, db_index=True)
    name = models.CharField(max_length=255)
    contact_phone = models.CharField(max_length=20)
    adults = models.IntegerField(default=0)
    children = models.IntegerField(default=0)
    elderly = models.IntegerField(default=0)
    address = models.TextField()
    latitude = models.FloatField()
    longitude = models.FloatField()
    conditions = models.JSONField(default=list, blank=True)
    description = models.TextField()
    status = models.CharField(
        max_length=50,
        choices=[(v, v) for v in RESCUE_STATUS.values()],
        default=RESCUE_STATUS[RescueStatus.PENDING]        
    )

    class Meta(TimeStampedModel.Meta, UnmanagedMeta):
        db_table = "rescue_requests"
        indexes = [
            # models.Index(fields=["code"]),
            models.Index(fields=["created_at"]),
        ]
