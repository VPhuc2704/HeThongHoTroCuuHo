from ..schemas.rescue_request_schema import RescueRequestSchema
from ..models import RescueRequest, ConditionType
from typing import Optional, List
from ..models import Account
from django.db import transaction

class RescueRequestService():
    def create_request(data: RescueRequestSchema, account: Optional[Account] = None ) -> RescueRequest:

        payload = data.model_dump()  # chuyển Schema sang dict

        if account:
            payload["account"] = account

        # Tạo request bằng repository
        # 2. Thực hiện Logic (có thể bọc trong transaction nếu cần ghi nhiều bảng)
        with transaction.atomic():
            # Gọi thẳng ORM của Django (Đây chính là Repository Pattern tích hợp sẵn)
            instance_request = RescueRequest.objects.create(**payload)
            
            # --- Logic mở rộng ---
            # Ví dụ: Gửi thông báo socket realtime cho admin
            # notify_admin_new_request(instance)
            return instance_request
    
    @staticmethod
    def get_map_points(min_lat: float, max_lat: float, 
                       min_lng: float, max_lng: float, 
                       zoom: int):
        """
        Lấy danh sách điểm cứu hộ tối ưu theo khung nhìn và độ zoom.
        """
        # 1. Logic nghiệp vụ: Tính toán Limit dựa trên Zoom
        limit = 500  # Mặc định (Zoom xa - Toàn quốc)
        if zoom >= 14:       # Zoom rất gần (Cấp Phường/Xã)
            limit = 5000     
        elif zoom >= 10:     # Zoom vừa (Cấp Quận/Huyện)
            limit = 2000
            
        # 2. Logic truy vấn: Tối ưu hoá SQL (Zero Loop)
        qs = RescueRequest.objects.filter(
            latitude__gte=min_lat, latitude__lte=max_lat,
            longitude__gte=min_lng, longitude__lte=max_lng
        ).values(
            'id', 'latitude', 'longitude', 'status'
        ).order_by('-created_at')[:limit]

        # Trả về list dictionary
        return list(qs)
    
    


class ConditionTypeService:
    def create(self, name: str) -> ConditionType:
        return ConditionType.objects.create(name=name)
    
    def get(self, id: str) -> Optional[ConditionType]:
        return ConditionType.objects.filter(id=id).first()
    
    def list(self) -> List[ConditionType]:
        return list(ConditionType.objects.all())
    
    def update(self, id: str, name: str) -> Optional[ConditionType]:
        obj = self.get(id)
        if obj:
            obj.name = name
            obj.save()
        return obj
    
    def delete(self, id: str) -> bool:
        obj = self.get(id)
        if obj:
            obj.delete()
            return True
        return False