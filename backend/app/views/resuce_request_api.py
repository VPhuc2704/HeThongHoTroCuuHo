from ..main import api
from app.schemas.rescue_request_schema import RescueRequestSchema, ConditionTypeOutSchema, ConditionTypeSchema, RescueMapPoint
from app.services import RescueRequestService, ConditionTypeService
from app.security.jwt_provider import JwtProvider
from typing import List
from app.models import RescueRequest

rescue_service = RescueRequestService()
condition_service = ConditionTypeService()

# User gửi requets cứu hộ
@api.post("/rescue")
def create_rescue(request, data: RescueRequestSchema):
    user_account = JwtProvider.get_user_from_jwt(request)
    new_request = rescue_service.create_request(data, account=user_account)
    return {
        "id": str(new_request.id),
        "status": new_request.status
    }

@api.get("/map-points", response=List[RescueMapPoint])
def get_map_points(request, 
                   min_lat: float, max_lat: float, 
                   min_lng: float, max_lng: float,
                   zoom: int):

    map_points = RescueRequestService.get_map_points(
        min_lat=min_lat,
        max_lat=max_lat,                                             
        min_lng=min_lng,
        max_lng=max_lng,
        zoom=zoom
    )
    
    return map_points


@api.post("/condition", response=ConditionTypeOutSchema)
def create_condition(request, data: ConditionTypeSchema):
    obj = condition_service.create(name=data.name)
    return {"id": str(obj.id), "name": obj.name}

@api.get("/condition", response=list[ConditionTypeOutSchema])
def list_condition(request):
    objs = condition_service.list()
    return [{"id": str(obj.id), "name": obj.name} for obj in objs]

@api.put("/condition/{id}", response=ConditionTypeOutSchema)
def update_condition(request, id: str, data: ConditionTypeSchema):
    obj = condition_service.update(id, data.name)
    if not obj:
        return {"error": "Not found"}
    return {"id": str(obj.id), "name": obj.name}

@api.delete("/condition/{id}")
def delete_condition(request, id: str):
    success = condition_service.delete(id)
    return {"success": success}


