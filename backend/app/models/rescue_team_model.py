from django.db import models
from django.db.models import Q
from .base_model import TimeStampedModel
from .account_model import Account
from .unmanaged_meta import UnmanagedMeta
from ..enum.rescue_status import TaskStatus, TeamStatus, TeamType
from .rescue_requests_model import RescueRequest
import uuid

class RescueTeam(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    account = models.OneToOneField(Account,on_delete=models.CASCADE,related_name="rescue_team")
    name = models.CharField(max_length=255)
    leader_name =  models.CharField(max_length=255, null=False)            
    contact_phone = models.CharField(max_length=20, null=False)
    hotline = models.CharField(max_length=20, null=False)
    address = models.CharField(max_length=255)
    primary_area = models.CharField(max_length=100)
    team_type = models.CharField(
        max_length=50,
        choices=[(tag.value, tag.value) for tag in TeamType],
    )
    status = models.CharField(
        max_length=50,
        choices=[(tag.value, tag.value) for tag in TeamStatus],
        default=TeamStatus.AVAILABLE
    )
    class Meta(TimeStampedModel.Meta, UnmanagedMeta):
        db_table = "rescue_teams"


class RescueAssignments(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    rescue_request = models.ForeignKey(RescueRequest, on_delete=models.CASCADE, related_name='assignments')
    rescue_team = models.ForeignKey(RescueTeam, on_delete=models.CASCADE, related_name='assignments')
    assigned_by = models.UUIDField(null=True)
    status = models.CharField(
        max_length=50, 
        choices=[(tag.value, tag.value) for tag in TaskStatus],
        default=TaskStatus.ASSIGNED        
    )
    assigned_at = models.DateTimeField(auto_now_add=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    class Meta:
        db_table = 'rescue_assignments'