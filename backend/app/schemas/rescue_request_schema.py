from ninja import Schema
from pydantic import Field,field_validator
from ..enum.rescue_status import RescueStatus
from typing import Optional, List
from typing import Optional

class RescueRequestSchema(Schema):
    name: str = Field(..., description="Tên người liên hệ")
    contact_phone: str = Field(..., description="Số điện thoại liên hệ")
    adults: int = 0
    children: int = 0
    elderly: int = 0
    address: str = Field(..., description="Địa chỉ")
    latitude: float = Field(..., description="Vĩ độ")
    longitude: float = Field(..., description="Kinh độ")
    conditions: List[str] = []
    description: Optional[str] = None

    @field_validator("name", "contact_phone", "address")
    def must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError("Trường bắt buộc không được để trống")
        return v

    @field_validator("adults", "children", "elderly")
    def must_be_non_negative(cls, v):
        if v < 0:
            raise ValueError("Số lượng không thể âm")
        return v

    @field_validator("latitude")
    def valid_latitude(cls, v):
        if not (-90 <= v <= 90):
            raise ValueError("Latitude phải nằm trong khoảng -90 đến 90")
        return v

    @field_validator("longitude")
    def valid_longitude(cls, v):
        if not (-180 <= v <= 180):
            raise ValueError("Longitude phải nằm trong khoảng -180 đến 180")
        return v


class ConditionTypeSchema(Schema):
    name: str

class ConditionTypeOutSchema(Schema):
    id: str
    name: str
