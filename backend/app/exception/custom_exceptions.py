
class BaseAppException(Exception):
    """Class cha cho tất cả lỗi logic trong App"""
    def __init__(self, message: str, code: int = 400, details=None):
        self.message = message
        self.code = code
        self.details = details
        super().__init__(message)

class InvalidToken(BaseAppException):
    def __init__(self, message="Token không hợp lệ hoặc hết hạn"):
        super().__init__(message, code=401)

class PermissionDenied(BaseAppException):
    def __init__(self, message="Người dùng không có quyền truy cập"):
        super().__init__(message, code=403)

class ResourceNotFound(BaseAppException):
    """Lỗi không tìm thấy dữ liệu (404)"""
    def __init__(self, message="Không tìm thấy dữ liệu"):
        super().__init__(message, code=404)

class InvalidCredentials(BaseAppException):
    def __init__(self, message="Email hoặc mật khẩu không đúng"):
        super().__init__(message, code=401)