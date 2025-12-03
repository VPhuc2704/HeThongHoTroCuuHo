from django.urls import re_path
from .socket.consumers import RescueMapConsumer

websocket_urlpatterns = [
    # Đường dẫn để frontend kết nối: ws://localhost:8000/ws/map/
    re_path(r'ws/map/$', RescueMapConsumer.as_asgi()),
]