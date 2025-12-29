# app/socket/middleware.py
from django.db import close_old_connections
from channels.middleware import BaseMiddleware
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from django.conf import settings
from urllib.parse import parse_qs
import jwt
from app.models import Account # Import model Account của bạn

# app/socket/middleware.py

@database_sync_to_async
def get_user(token_key):
    try:
        payload = jwt.decode(
            token_key, 
            settings.JWT_SECRET, 
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        user_id = payload.get("user_id")
        if not user_id:
            return AnonymousUser()

        close_old_connections() 
        
        # --- SỬA DÒNG NÀY ---
        # Thêm .select_related('role') để lấy luôn bảng Role
        return Account.objects.select_related('role').get(id=user_id) 

    except Exception as e:
        print(f"Socket Auth Error: {e}")
        return AnonymousUser()

class JwtAuthMiddleware(BaseMiddleware):
    async def __call__(self, scope, receive, send):
        # Lấy token từ URL: ws://...?token=XYZ
        query_string = scope.get("query_string", b"").decode("utf-8")
        query_params = parse_qs(query_string)
        token = query_params.get("token")

        if token:
            # Nếu có token thì check
            scope["user"] = await get_user(token[0])
        else:
            # Không có thì thôi
            scope["user"] = AnonymousUser()

        return await super().__call__(scope, receive, send)