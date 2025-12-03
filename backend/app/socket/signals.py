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
            "type":"send_new_coordinate",
            "data":{
                "id":str(instance.id),
                "latitude": instance.latitude,
                "longitude": instance.longitude,
                "status": instance.status
            }
        }

        async_to_sync(channel_layer.group_send)(
            "rescue_map_group",
            data
        )