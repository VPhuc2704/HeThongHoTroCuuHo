from ninja import Schema
import uuid
from typing import Optional
class AssignTaskIn(Schema):
    request_id: str
    rescue_team_id: str

class ConfirmStartIn(Schema):
    assignment_id: str

class FindNearest(Schema):
    latitude: float
    longitude: float
    radius_km: float = 20.0

class NearestTeam(Schema):
    id: uuid.UUID
    name: str
    contact_phone: Optional[str] = None
    distance: float
