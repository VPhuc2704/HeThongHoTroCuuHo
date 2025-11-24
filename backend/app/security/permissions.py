from ninja.errors import HttpError
from functools import wraps

def require_role(*allowed_roles):
    def decorator(func):
        @wraps(func)
        def wrapper(request, *args, **kwargs):
            user = getattr(request, "user", None)
            if not user:
                raise HttpError(401, "Unauthorized")

            # Convert enum to string
            allowed = [r.value if hasattr(r, "value") else r for r in allowed_roles]

            if not user.role or user.role.code not in allowed:
                raise HttpError(403, "Permission denied")

            return func(request, *args, **kwargs)
        return wrapper
    return decorator

