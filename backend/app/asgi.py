"""
ASGI config for apidemo project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/4.2/howto/deployment/asgi/
"""

import os

from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'app.settings')

django_asgi_app = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter
from app.socket.middleware import JwtAuthMiddleware
import app.routing

application = ProtocolTypeRouter({
    'http': django_asgi_app,
    'websocket': JwtAuthMiddleware(
        URLRouter(
            app.routing.websocket_urlpatterns
        )
    ),
})