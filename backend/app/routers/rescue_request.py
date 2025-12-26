from ninja import Router
from app.schemas.rescue_schema import RescueRequestSchema, ConditionTypeOutSchema, ConditionTypeSchema, RescueMapPoint, PaginatedRescueResponse, RescueMapPointCluster
from app.services import RescueRequestService, ConditionTypeService
from app.security.jwt_provider import JwtProvider
from app.middleware.auth import JWTBearer
from typing import List, Optional, Union
from ninja import UploadedFile, File

router = Router(tags=["Rescue Request"])

rescue_service = RescueRequestService()
condition_service = ConditionTypeService()

auth_bearer = JWTBearer()

# User gửi requets cứu hộ
@router.post("/rescue", auth=auth_bearer)
def create_rescue(request, data: RescueRequestSchema):
    account = request.auth 
    new_request = rescue_service.create_request(data, account_id=str(account.id))
    return new_request

@router.post("/rescue/{rescue_id}/media", response={200: dict, 404: dict})
def upload_rescue_media(request, rescue_id: str, files: List[UploadedFile] = File(...)):
    result = RescueRequestService.upload_media(rescue_id, files)
    if not result:
        return 404, {"message": "Không tìm thấy yêu cầu cứu hộ"}
    
    return {
        "success": True,
        "uploaded_count": len(result)
    }


@router.get("/my-requests/history", auth=JWTBearer(), response=PaginatedRescueResponse)
def list_my_requests(request, page: int = 1, size: int = 20, status: str = None, search: str = None):
    account_id = request.user.id

    return RescueRequestService.get_my_requests(
        account_id=account_id,
        page=page,
        size=size,
        status_filter=status,
        search=search
    )


@router.get("/map-points", response=List[Union[RescueMapPoint, RescueMapPointCluster]])
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

    if zoom > 14:
        return [RescueMapPoint(**p) for p in map_points]
    else:
        return [RescueMapPointCluster(**p) for p in map_points]
    


@router.get("/requests", response=PaginatedRescueResponse)
def list_rescue_requests(request, 
                        page: int = 1, 
                        page_size: int = 20, 
                        status: Optional[str] = None, 
                        search: Optional[str] = None):
    """
    API lấy danh sách cứu hộ dạng bảng.
    - search: Tìm theo Tên, SĐT, Địa chỉ.
    - status: Lọc theo trạng thái (PENDING, IN_PROGRESS...).
    """
    return RescueRequestService.get_list_requests_raw_sql(
        page=page, 
        size=page_size, 
        status_filter=status, 
        search=search
    )


@router.post("/condition", response=ConditionTypeOutSchema)
def create_condition(request, data: ConditionTypeSchema):
    obj = condition_service.create(name=data.name)
    return {"id": str(obj.id), "name": obj.name}

@router.get("/condition", response=list[ConditionTypeOutSchema])
def list_condition(request):
    objs = condition_service.list()
    return [{"id": str(obj.id), "name": obj.name} for obj in objs]

@router.put("/condition/{id}", response=ConditionTypeOutSchema)
def update_condition(request, id: str, data: ConditionTypeSchema):
    obj = condition_service.update(id, data.name)
    if not obj:
        return {"error": "Not found"}
    return {"id": str(obj.id), "name": obj.name}

@router.delete("/condition/{id}")
def delete_condition(request, id: str):
    success = condition_service.delete(id)
    return {"success": success}


