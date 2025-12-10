from ninja.security import HttpBearer
from ninja.errors import HttpError
from app.models import Account
import jwt
from jwt import ExpiredSignatureError, InvalidTokenError
from django.conf import settings

class JWTBearer(HttpBearer):
    """
    Xác thực JWT token cho NinjaAPI.
    Gắn user vào request.user nếu token hợp lệ.
    """

    def __call__(self, request):
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            raise HttpError(401, "Authorization token required")
        
        if not auth_header.startswith("Bearer "):
            raise HttpError(401, "Invalid Authorization header")
        
        token = auth_header.replace("Bearer ", "")
        return self.authenticate(request, token)

    def authenticate(self, request, token):
        try:
            payload = jwt.decode(
                token, 
                settings.JWT_SECRET, 
                algorithms=[settings.JWT_ALGORITHM]
            )

            if payload.get("type") != "access_token":
                raise HttpError(401, "Invalid token type (Access token required)")

            user_id = payload.get("user_id")
            if not user_id:
                raise HttpError(401, "Invalid token payload")

            try:
                account = Account.objects.get(id=user_id)
            except Account.DoesNotExist:
                raise HttpError(401, "User not found")

            request.user = account
            return account

        except ExpiredSignatureError:
            raise HttpError(401, "Token has expired")
        except InvalidTokenError:
            raise HttpError(401, "Invalid token")
        except Exception:
            raise HttpError(401, "Authentication Failed")
