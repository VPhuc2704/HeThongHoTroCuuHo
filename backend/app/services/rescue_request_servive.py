from ..schemas.rescue_schema import RescueRequestSchema
from ..models import RescueRequest, ConditionType, RescueMedia, Account
from ..enum.rescue_status import RESCUE_STATUS, RescueStatus
from typing import Optional, List, Dict, Any
from django.db import transaction, connection
from django.db.models import Q
from django.utils import timezone
from ninja import UploadedFile
import json
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
    def create_request(data: RescueRequestSchema, account_id: Optional[str] = None ):

        payload = data.model_dump()  # chuyển Schema sang dict

        lat = payload.pop("latitude")
        lng = payload.pop("longitude")

        province_code = payload.pop('code', 'VN')

        if account_id:
            payload["account_id"] = account_id

        with transaction.atomic():
            new_code = RescueRequestService._generate_code(province_code)
            payload['code'] = new_code
            conditions = payload.get("conditions")

            with connection.cursor() as cursor:
                cursor.execute(""" 
                    INSERT INTO rescue_requests (
                                id, code, name,
                                contact_phone, address, 
                                adults, children, elderly, description, 
                                conditions, location, account_id)
                    VALUES( 
                        gen_random_uuid(), %s, %s, %s, %s, %s, %s, %s, %s, %s,
                        ST_SetSRID(ST_MakePoint(%s, %s), 4326), %s
                    )
                    RETURNING id, code , status
                    """,
                    [
                        new_code,
                        payload.get("name"),
                        payload.get("contact_phone"),
                        payload.get("address"),
                        payload.get("adults"),
                        payload.get("children"),
                        payload.get("elderly"),
                        payload.get("description"),
                        json.dumps(conditions),  
                        lng,
                        lat,
                        payload.get("account_id"),
                    ]
                )
                request_id, code, status = cursor.fetchone()
        return {
            "id": request_id,
            "code": code,
            "status": status
        }
            
            # --- Logic mở rộng ---
            # Ví dụ: Gửi thông báo socket realtime cho admin
            # notify_admin_new_request(instance)
            # return instance_request
        
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

    @classmethod
    def _execute_search_query(cls, conditions: List[str], params: Dict[str, Any], page: int, size: int):
        """
        Hàm private dùng chung để chạy câu SQL phức tạp.
        """
        where_clause = " AND ".join(conditions)

        # SQL Query dùng chung
        sql = f"""
            SELECT 
                r.id, r.code ,r.name, r.contact_phone, r.address, r.status, r.created_at, 
                r.latitude, r.longitude, r.conditions,
                r.adults, r.children, r.elderly,
                
                LEFT(COALESCE(r.description, ''), 50) as description_short,
                
                -- Summary số người
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

                -- Media URLs
                COALESCE(
                    (
                        SELECT json_agg(m.file)
                        FROM media m
                        WHERE m.rescue_request_id = r.id
                    ), '[]'::json
                ) as media_urls,
                
                -- Active Assignment
                (
                    SELECT json_build_object(
                        'task_id', a.id,
                        'status', a.status,
                        'updated_at', a.updated_at,
                        'team_name', t.name,
                        'team_phone', t.contact_phone,
                        'team_lat', t.latitude, 
                        'team_lng', t.longitude
                    )
                    FROM rescue_assignments a
                    JOIN rescue_teams t ON a.rescue_team_id = t.id
                    WHERE a.rescue_request_id = r.id
                    AND a.status IN ('Đã điều động', 'Đang di chuyển', 'Đã đến', 'Hoàn thành')
                    ORDER BY a.created_at DESC
                    LIMIT 1
                ) as active_assignment

            FROM rescue_requests r
            WHERE {where_clause}
            ORDER BY r.created_at DESC
            LIMIT %(limit)s OFFSET %(offset)s
        """

        count_sql = f"SELECT COUNT(*) FROM rescue_requests r WHERE {where_clause}"

        with connection.cursor() as cursor:
            # 1. Đếm tổng
            cursor.execute(count_sql, params=params)
            total_items = cursor.fetchone()[0]

            # 2. Lấy dữ liệu
            cursor.execute(sql, params=params)
            results = dictfetchall(cursor)

        return {
            "items": results,
            "total": total_items,
            "page": page,
            "page_size": size
        }

    @classmethod
    def _build_common_params(cls, page: int, size: int, status_filter: RescueStatus = None, search: str = None):
        """Helper để build params cơ bản"""
        vn_status_value = RESCUE_STATUS.get(status_filter) if status_filter else None
        
        params = {
            'limit': size,
            'offset': (page - 1) * size,
            'status': vn_status_value,
            'search': f"%{search}%" if search else None
        }
        
        conditions = []
        
        if status_filter:
            conditions.append("r.status = %(status)s")
            
        if search:
            conditions.append("""
                (r.name ILIKE %(search)s or 
                r.contact_phone ILIKE %(search)s or
                r.address ILIKE %(search)s)
            """)
            
        return params, conditions

    @classmethod
    def get_my_requests(cls, account_id: str, page: int, size: int, status_filter: RescueStatus = None, search: str = None):
        # 1. Lấy params chung
        params, conditions = cls._build_common_params(page, size, status_filter, search)
        
        # 2. Thêm params riêng cho My Request
        params['account_id'] = account_id
        conditions.insert(0, "r.account_id = %(account_id)s")

        # 3. Thực thi
        return cls._execute_search_query(conditions, params, page, size)

    @classmethod
    def get_list_requests_raw_sql(cls, page: int, size: int, status_filter: RescueStatus = None, search: str = None):
        # 1. Lấy params chung
        params, conditions = cls._build_common_params(page, size, status_filter, search)
        
        if not conditions:
            conditions.append("1=1")

        # 3. Thực thi
        return cls._execute_search_query(conditions, params, page, size)
        
    
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
            
        qs = RescueRequest.objects.filter(
            latitude__gte=min_lat, latitude__lte=max_lat,
            longitude__gte=min_lng, longitude__lte=max_lng
        ).values(
            'id', 'latitude', 'longitude', 'status', "code" 
        ).order_by('-created_at')[:limit]

        # Trả về list dictionary
        return list(qs)
    
    @staticmethod
    def _generate_code(province_code: str) -> str:
        """
        Input: 'SG' (Sài Gòn)
        Output: 'SG-20251221-0001'
        """
        p_code = province_code.upper() # sg -> SG   
        today_str = timezone.now().strftime('%Y%m%d')
        
        prefix = f"{p_code}-{today_str}-"
        
        with transaction.atomic():
            last_request = RescueRequest.objects.filter(
                code__startswith=prefix
            ).select_for_update().order_by('-code').first()
            
            if last_request:
                last_seq_str = last_request.code.split('-')[-1]
                new_seq = int(last_seq_str) + 1
            else:
                new_seq = 1
            return f"{prefix}{new_seq:04d}"


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