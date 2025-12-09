from ..schemas.rescue_schema import RescueRequestSchema
from ..models import RescueRequest, ConditionType, RescueMedia
from typing import Optional, List
from ..models import Account
from django.db import transaction, connection
from django.db.models import Q
from ninja import UploadedFile

def dictfetchall(cursor):
    """
    Return all rows from a cursor as a dict
    """
    columns = [col[0] for col in cursor.description]
    return [
        dict(zip(columns, row))
        for row in cursor.fetchall()
    ]

class RescueRequestService():
    @staticmethod
    def create_request(data: RescueRequestSchema, account: Optional[Account] = None ) -> RescueRequest:

        payload = data.model_dump()  # chuyển Schema sang dict

        if account:
            payload["account"] = account

        with transaction.atomic():
            instance_request = RescueRequest.objects.create(**payload)
            
            # --- Logic mở rộng ---
            # Ví dụ: Gửi thông báo socket realtime cho admin
            # notify_admin_new_request(instance)
            return instance_request
        
    def upload_media(request_id: str, files: List[UploadedFile]):
        try:
            req = RescueRequest.objects.get(id=request_id)

        except RescueRequest.DoesNotExist:
            return None
        saved_media = []
        with transaction.atomic():
            for f in files:
                # Detect loại file
                m_type = RescueMedia.MediaType.IMAGE
                if f.content_type and 'video' in f.content_type:
                    m_type = RescueMedia.MediaType.VIDEO
                
                # Tạo record
                media = RescueMedia.objects.create(
                    rescue_request=req,
                    file=f,
                    file_type=m_type
                )
                saved_media.append(media)
        return saved_media

    
    @staticmethod
    def get_map_points(min_lat: float, max_lat: float, 
                       min_lng: float, max_lng: float, 
                       zoom: int):
        """
        Lấy danh sách điểm cứu hộ tối ưu theo khung nhìn và độ zoom.
        """
        # 1. Logic nghiệp vụ: Tính toán Limit dựa trên Zoom
        limit = 500         # Mặc định (Zoom xa - Toàn quốc)
        if zoom >= 14:      # Zoom rất gần (Cấp Phường/Xã)
            limit = 5000     
        elif zoom >= 10:    # Zoom vừa (Cấp Quận/Huyện)
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

    # @staticmethod
    # def get_list_requests(page: int, size: int, status_filter: Optional[str] = None, search: Optional[str] = None):
    #     qs = RescueRequest.objects.order_by('-created_at')
    #     qs = qs.only(
    #         'id', 'name', 'contact_phone', 'address', 'status', 'created_at', 'latitude', 'longitude',
    #         'adults', 'children', 'elderly', 'conditions', 'description'
    #     )

    #     if status_filter:
    #         qs = qs.filter(status=status_filter)
        
    #     if search:
    #         qs.filter(
    #             Q(name__icontains=search) |
    #             Q(contact_phone__icontains=search) |
    #             Q(address__icontains=search)
    #         )
        
    #     total_items = qs.count()
    #     start = (page - 1) * size
    #     end = start + size

    #     data_list = qs[start:end]
    #     results = []
    #     for item in data_list:
    #         # Logic tạo chuỗi tóm tắt số người
    #         total_people = item.adults + item.children + item.elderly
    #         details = []
    #         if item.adults: details.append(f"{item.adults} lớn")
    #         if item.children: details.append(f"{item.children} nhỏ")
    #         if item.elderly: details.append(f"{item.elderly} già")
    #         summary_str = f"{total_people} ({', '.join(details)})" if details else "0"

    #         # Xử lý description dài quá thì cắt bớt
    #         desc_short = (item.description[:50] + '...') if item.description and len(item.description) > 50 else item.description

    #         results.append({
    #             "id": item.id,
    #             "name": item.name,
    #             "contact_phone": item.contact_phone,
    #             "adults": item.adults,
    #             "children": item.children,
    #             "elderly": item.elderly,
    #             "people_summary": summary_str, # Field tiện ích cho frontend
    #             "latitude":item.latitude,
    #             "longitude":item.longitude,
    #             "address": item.address,
    #             "status": item.status,
    #             "created_at": item.created_at,
    #             "conditions": item.conditions, # Django tự convert JSONField sang list Python
    #             "description_short": desc_short
    #         })
    #     return {
    #         "items": results,
    #         "total": total_items,
    #         "page": page,
    #         "page_size": size
    #     }

    
    def get_list_requests_raw_sql(page: int, size: int, status_filter: str = None, search: str = None):
        params = {
            'limit': size,
            'offset': (page - 1) * size,
            'status':status_filter,
            'search':f"%{search}%" if search else None
        }

        conditions = ["1=1"]

        if status_filter:
            conditions.append("r.status = %(status)s")

        if search:
            conditions.append("""
                (r.name ILIKE %(search)s or 
                r.contact_phone ILIKE %(search)s or
                r.address ILIKE %(search)s)
            """)
                #  or
                # code ILIKE %(search)s
        where_clause = " AND ".join(conditions)

        sql = f"""
            SELECT 
                r.id, r.name, r.contact_phone, r.address, r.status, r.created_at, 
                r.latitude, r.longitude, r.conditions,
                r.adults, r.children, r.elderly,
                
                LEFT(COALESCE(r.description, ''), 50) as description_short,
                
                CASE 
                    WHEN (r.adults + r.children + r.elderly) = 0 THEN '0'
                    ELSE CONCAT(
                        (r.adults + r.children + r.elderly), ' (',
                        CONCAT_WS(', ',
                            NULLIF(CONCAT(r.adults, ' lớn'), '0 lớn'),
                            NULLIF(CONCAT(r.children, ' nhỏ'), '0 nhỏ'),
                            NULLIF(CONCAT(r.elderly, ' già'), '0 già')
                        ), ')'
                    )
                END as people_summary,

                COALESCE(
                    (
                        SELECT json_agg(m.file)
                        FROM media m
                        WHERE m.rescue_request_id = r.id
                    ), '[]'::json
                ) as media_urls

            FROM rescue_requests r
            WHERE {where_clause}
            ORDER BY r.created_at DESC
            LIMIT %(limit)s OFFSET %(offset)s
        """

        const_sql = f"SELECT COUNT(*) FROM rescue_requests r WHERE {where_clause}"

        with connection.cursor() as cursor:
            cursor.execute(const_sql, params=params)
            total_items = cursor.fetchone()[0]

            cursor.execute(sql=sql, params=params)
            results = dictfetchall(cursor)

        return {
            "items": results,
            "total": total_items,
            "page": page,
            "page_size": size
        }
    



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