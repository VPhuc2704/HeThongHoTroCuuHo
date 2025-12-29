import re

# Hàm viết hoa chữ cái đầu
def to_title_case(v: str) -> str:
    return v.title()

# Hàm viết IN HOA (Upper Case)
def to_upper_case(v: str) -> str:
    return v.upper()

# Hàm kiểm tra không chứa số
def validate_no_digits(v: str) -> str:
    if any( char.isdigit() for char in v):
        raise ValueError("Họ tên khong được chứa số")
    return v

def check_phone_vn(v: str) -> str:
    """Chỉ chấp nhận SĐT Việt Nam, tự động xóa khoảng trắng"""
    if not v: return v
    clean_v = v.replace(' ', '').replace('-', '').replace('.', '')
    
    # Regex: Bắt đầu bằng 0 hoặc 84, theo sau là 9 số
    if not re.fullmatch(r'^(0|84)(3|5|7|8|9)\d{8}$', clean_v):
        raise ValueError("Số điện thoại không đúng định dạng.")
    return clean_v

def check_strong_pass(v: str) -> str:
    """Mật khẩu: 8 ký tự, 1 hoa, 1 thường, 1 số, 1 ký tự đặc biệt"""
    if len(v) < 8:
        raise ValueError("Mật khẩu phải từ 8 ký tự trở lên.")
    if not re.search(r"[A-Z]", v):
        raise ValueError("Thiếu chữ in hoa.")
    if not re.search(r"[a-z]", v):
        raise ValueError("Thiếu chữ thường.")
    if not re.search(r"\d", v):
        raise ValueError("Thiếu số.")
    if not re.search(r"[!@#$%^&*()]", v):
        raise ValueError("Thiếu ký tự đặc biệt.")
    return v

