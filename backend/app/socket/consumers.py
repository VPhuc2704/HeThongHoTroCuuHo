import json
from channels.generic.websocket import AsyncWebsocketConsumer
from django.contrib.auth.models import AnonymousUser
from app.enum.role_enum import RoleCode  
from ..models import RescueTeam

class RescueMapConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # 1. Kiểm tra xác thực (Bắt buộc)
        self.user = self.scope["user"]
        if self.user is None or isinstance(self.user, AnonymousUser):
            print("DEBUG: User chưa đăng nhập -> Từ chối kết nối")
            await self.close()
            return

        self.joined_groups = []

        user_role_code = await self.get_user_role_code(self.user)

        # 2. Phân luồng Group dựa trên Role
        # ADMIN: Nghe tin toàn hệ thống (để vẽ bản đồ tổng)
        if user_role_code == RoleCode.ADMIN:
            await self.join_group("rescue_map_admin")
        
        # RESCUER: Nghe tin chỉ đạo cho đội mình
        elif user_role_code == RoleCode.RESCUER:
            # Lấy team_id của user này
            try:
                # Lưu ý: Truy vấn DB trong async cần dùng database_sync_to_async 
                # hoặc logic đơn giản nếu bạn đã cache team_id trong session/token
                # Ở đây giả định user.rescue_team_set.first().id lấy được
                team_id = await self.get_team_id(self.user)
                if team_id:
                    await self.join_group(f"rescue_map_team_{team_id}")
            except:
                pass # Không phải đội trưởng hoặc lỗi data

        # CITIZEN: Có thể join group riêng theo ID của họ để nghe thông báo cá nhân
        await self.join_group(f"rescue_user_{self.user.id}")

        await self.accept()
    async def disconnect(self, close_code):
        for group in self.joined_groups:
            await self.channel_layer.group_discard(group, self.channel_name)


    async def join_group(self, group_name):
        """Hàm phụ để join group và lưu lại danh sách"""
        await self.channel_layer.group_add(group_name, self.channel_name)
        self.joined_groups.append(group_name)
        
    # gửi tin nhắn từ Server -> Client
    async def send_update(self, event):
        """
        Hàm xử lý chung cho mọi loại tin nhắn:
        - Tọa độ mới
        - Cập nhật trạng thái Task
        - Thông báo hoàn thành
        """
        data = event['data']
        # Gửi JSON về client
        await self.send(text_data=json.dumps(data))
    
    from channels.db import database_sync_to_async
    @database_sync_to_async
    def get_team_id(self, user):
        try:
            team = RescueTeam.objects.get(account=user)
            return team.id
        except RescueTeam.DoesNotExist:
            return None
    @database_sync_to_async
    def get_user_role_code(self, user):
        # Truy cập vào DB ở đây an toàn vì đã bọc sync_to_async
        if hasattr(user, 'role') and user.role:
            return user.role.code
        return None