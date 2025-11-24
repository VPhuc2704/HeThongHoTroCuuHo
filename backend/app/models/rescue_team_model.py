from django.db import models
from .base_model import TimeStampedModel
from .account_model import Account
from .unmanaged_meta import UnmanagedMeta
import uuid

class RescueTeam(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    account = models.OneToOneField(Account,on_delete=models.CASCADE,related_name="rescue_team")
    name = models.CharField(max_length=255)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    contact_phone = models.CharField(max_length=20, null=True, blank=True)

    class Meta(TimeStampedModel.Meta, UnmanagedMeta):
        db_table = "rescue_teams"