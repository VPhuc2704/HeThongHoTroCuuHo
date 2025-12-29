from django.db import models
from .unmanaged_meta import UnmanagedMeta
from .account_model import Account
import uuid

class SocialAccount(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    account = models.ForeignKey(Account, on_delete=models.CASCADE, related_name="social_accounts")
    provider = models.CharField(max_length=50)
    provider_id = models.CharField(max_length=255, null=False)
    email = models.EmailField(max_length=255, null=True, blank=True)
     
    class Meta(UnmanagedMeta):
        db_table = "social_accounts"
        unique_together = ('provider', 'provider_id')



