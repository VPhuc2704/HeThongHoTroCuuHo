from django.db.models.signals import post_save
from django.dispatch import receiver
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from ..models import RescueRequest


@receiver(post_save, sender=RescueRequest)
def broadcast_new_request(sender, instance, created, **kwargs):
    if created:
        channel_layer = get_channel_layer()

        data_payload = {
            "id": instance.id,
            "latitude": instance.latitude,
            "longitude": instance.longitude,
            "status": instance.status,
            "address": instance.address,
            "time": instance.created_at,
            "code": instance.code, # Thêm code nếu model có
            "name": instance.name  # Thêm name
        }

        # Gửi vào group 'rescue_admin' (Đã đồng bộ)
        async_to_sync(channel_layer.group_send)(
            "rescue_admin", 
            {
                "type": "send_update",
                "data": {
                    "event": "NEW_REQUEST", # Khớp với switch case ở Frontend
                    "data": data_payload    # Khớp với destructuring { data }
                }
            }
        )