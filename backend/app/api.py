from ninja import NinjaAPI
from app.exception.handlers import global_exception_handlers
from django.conf import settings
import os

# Tạo API instance
api = NinjaAPI(title="RescueVN API", version="1.0.0", docs_url="/docs")

from app.routers.auth import router as auth_router
from app.routers.account import router as account_router
from app.routers.assign import router as assign_task
from app.routers.rescue_request import router as rescue_request 
from app.routers.rescue import router as rescue


global_exception_handlers(api)

api.add_router("/auth", auth_router)                # -> /api/auth/...
api.add_router("", account_router)         # -> /api/accounts/...
api.add_router("/rescue-teams", assign_task)        # -> /api/rescue-teams/...
api.add_router("", rescue_request)                  # -> /api/requests/...
api.add_router("/rescue_team", rescue)

# Health check endpoint
@api.get("/health")
def health_check(request):
    """Health check endpoint - returns status and environment info"""
    return {
        "status": "ok",
        "env": settings.ENV,
        "debug": settings.DEBUG
    }