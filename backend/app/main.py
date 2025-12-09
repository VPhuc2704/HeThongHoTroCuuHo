from ninja import NinjaAPI
from app.exception.handlers import global_exception_handlers

# Tạo API instance
api = NinjaAPI(title="RescueVN API", version="1.0.0")

# Đăng ký global exception handler
global_exception_handlers(api)

from app.views import auth_api, account_api, resuce_request_api, assign_api