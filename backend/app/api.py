from ninja import NinjaAPI
from app.exception.handlers import global_exception_handlers

# Tạo API instance
api = NinjaAPI(title="RescueVN API", version="1.0.0")

from app.views.auth import router as auth_router
from app.views.account import router as account_router
from app.views.assign import router as assign_task
from app.views.rescue_request import router as rescue_request 
# Đăng ký global exception handler
global_exception_handlers(api)

api.add_router("/auth", auth_router)                # -> /api/auth/...
api.add_router("/accounts", account_router)         # -> /api/accounts/...
api.add_router("/rescue-teams", assign_task)        # -> /api/rescue-teams/...
api.add_router("", rescue_request)         # -> /api/requests/...