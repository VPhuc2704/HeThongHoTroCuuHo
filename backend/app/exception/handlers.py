from ninja import NinjaAPI
from .custom_exceptions import InvalidToken, PermissionDenied

def global_exception_handlers(api: NinjaAPI):
    @api.exception_handler(InvalidToken)
    def invalid_token_handler(request, exc):
        return api.create_response(request, data={"detail":str(exc)}, status=401)

    @api.exception_handler(PermissionDenied)
    def permission_denied_handler(request, exc):
        return api.create_response(request, data={"detail":str(exc)}, status=403)