from django.db.models.signals import post_save
from django.dispatch import receiver
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from ..models import RescueRequest


@receiver(post_save, sender=RescueRequest)
def broadcast_new_request(sender, instance, created, **kwargs):
    if created:
        channel_layer = get_channel_layer()

        data = {
            "type": "send_update", 
            "data": {
                "event": "NEW_REQUEST", # Frontend dựa vào field này để if/else
                "id": str(instance.id),
                "latitude": instance.latitude,
                "longitude": instance.longitude,
                "status": instance.status,
                "address": instance.address,
                "time": str(instance.created_at)
            }
        }

        # CHỈ GỬI CHO ADMIN (User thường không cần thấy yêu cầu của người khác)
        async_to_sync(channel_layer.group_send)(
            "rescue_map_admin", 
            data
        )