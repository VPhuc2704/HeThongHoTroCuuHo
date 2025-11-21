
class InvalidToken(Exception):
    """"Token không hợp lệ hoặc hết hạn"""
    pass

class PermissionDenied(Exception):
    """Người dùng không có quyền truy cập"""
    pass
