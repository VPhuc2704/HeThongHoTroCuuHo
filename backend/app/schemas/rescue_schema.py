from ninja import Schema
from pydantic import Field,field_validator
from ..enum.rescue_status import RescueStatus
from typing import Optional, List
from typing import Optional
import uuid
from datetime import datetime
import json

class RescueRequestSchema(Schema):
    code: str
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

class RescueMapPoint(Schema):
    id: uuid.UUID
    code:str
    name: str
    adults: Optional[int] = 0
    children: Optional[int] = 0
    elderly: Optional[int] = 0
    conditions: Optional[str]
    contact_phone: Optional[str]
    latitude: float
    longitude: float
    status: str

class RescueMapPointCluster(Schema):
    latitude: float
    longitude: float
    total: int

class ActiveAssignmentSchema(Schema):
    task_id: uuid.UUID
    status: str
    team_name: Optional[str] = None 
    team_phone: Optional[str] = None 
    team_lat: Optional[float] = None
    team_lng: Optional[float] = None
    updated_at: Optional[datetime] = None
    
class RescueRequestTableRow(Schema):
    id:uuid.UUID
    code: str
    name: str
    contact_phone: str
    adults: int
    children: int
    elderly: int
    people_summary: str
    latitude : float
    longitude : float
    address: str
    status: str
    created_at: datetime
    conditions: List[str] = []
    description_short: str
    media_urls: List[str]=[]
    active_assignment: Optional[ActiveAssignmentSchema] = None
    
    @field_validator('conditions', mode='before')
    @classmethod
    def parse_conditions(cls, value):
        if isinstance(value, str):
            try:
                if not value.strip(): # Trường hợp chuỗi rỗng
                    return []
                return json.loads(value)
            except ValueError:
                # Trường hợp string không phải JSON hợp lệ, trả về list chứa string đó
                # hoặc raise ValueError tùy logic
                return [value] 
        return value
    @field_validator('media_urls', mode='before')
    @classmethod
    def parse_media(cls, value):
        # Nếu DB trả về string '[]' hoặc '[{"url":...}]', ta parse nó ra
        if isinstance(value, str):
            try:
                return json.loads(value)
            except ValueError:
                return []
        # Nếu DB trả về None hoặc null, trả về list rỗng
        if value is None:
            return []
        return value

class RescueTeamOut(Schema):
    id: uuid.UUID
    name: str
    leader_name: str
    latitude: Optional[float]
    longitude: Optional[float]
    contact_phone: Optional[str]
    status: str
    hotline:  Optional[str]
    team_type:  Optional[str]
    address: str 
    primary_area: str 
    created_at: datetime

class RescueTeamUpdate(Schema):
    name: Optional[str] = None
    leader_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    contact_phone: Optional[str] = None
    hotline: Optional[str] = None
    team_type: Optional[str] = None
    address: Optional[str] = None 
    primary_area: Optional[str] = None

class ConditionTypeSchema(Schema):
    name: str

class ConditionTypeOutSchema(Schema):
    id: str
    name: str

class PaginatedRescueResponse(Schema):
    items: List[RescueRequestTableRow]
    total: int
    page: int
    page_size: int