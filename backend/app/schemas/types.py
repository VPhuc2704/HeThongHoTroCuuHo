# authentication/types.py
from typing import Annotated
from pydantic import AfterValidator, StringConstraints
from app.middleware.validators import check_phone_vn, check_strong_pass, to_title_case

# 1. Kiểu SĐT Việt Nam
VNPhone = Annotated[
    str, 
    AfterValidator(check_phone_vn)
]

# 2. Kiểu Mật khẩu mạnh
StrongPassword = Annotated[
    str, 
    AfterValidator(check_strong_pass)
]

# 3. Kiểu Họ tên (Tự động viết Hoa chữ cái đầu, xóa khoảng trắng thừa)
CleanName = Annotated[
    str, 
    StringConstraints(strip_whitespace=True, min_length=2, max_length=50),
    AfterValidator(to_title_case),
    AfterValidator(to_title_case)
]