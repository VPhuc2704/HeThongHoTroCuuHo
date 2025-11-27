from ..main import api
from app.schemas.rescue_request_schema import RescueRequestSchema, ConditionTypeOutSchema, ConditionTypeSchema
from app.services import RescueRequestService, ConditionTypeService
from app.security.jwt_provider import JwtProvider

rescue_service = RescueRequestService()
condition_service = ConditionTypeService()

@api.post("/rescue")
def create_rescue(request, data: RescueRequestSchema):
    user_account = JwtProvider.get_user_from_jwt(request)
    new_request = rescue_service.create_request(data, account=user_account)
    return {
        "id": str(new_request.id),
        "status": new_request.status
    }



@api.post("/condition", response=ConditionTypeOutSchema)
def create_condition(request, data: ConditionTypeSchema):
    obj = condition_service.create(name=data.name)
    return {"id": str(obj.id), "name": obj.name}

# @api.get("/condition/{id}", response=ConditionTypeOutSchema)
# def get_condition(request, id: str):
#     obj = condition_service.get(id)
#     if not obj:
#         return {"error": "Not found"}
#     return {"id": str(obj.id), "name": obj.name}

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


