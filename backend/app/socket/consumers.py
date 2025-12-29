import json
from channels.generic.websocket import AsyncWebsocketConsumer
from django.contrib.auth.models import AnonymousUser
from app.enum.role_enum import RoleCode  
from ..models import RescueTeam

import json
from uuid import UUID
from datetime import datetime

from channels.db import database_sync_to_async

class RescueMapConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.joined_groups = []

        self.user = self.scope["user"]
        
        if self.user is None or isinstance(self.user, AnonymousUser):
            await self.close()
            return

        user_role_code = await self.get_user_role_code(self.user)

        await self.join_group(f"user_{self.user.id}")

        if user_role_code == RoleCode.ADMIN:
            await self.join_group("rescue_admin")
        
        elif user_role_code == RoleCode.RESCUER:
            team_id = await self.get_team_id(self.user)
            if team_id:
                await self.join_group(f"rescue_team_{team_id}")

        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'joined_groups'):
            for group in self.joined_groups:
                await self.channel_layer.group_discard(group, self.channel_name)

    async def join_group(self, group_name):
        await self.channel_layer.group_add(group_name, self.channel_name)
        self.joined_groups.append(group_name)
        
    async def send_update(self, event):
        data = event['data']
        await self.send(text_data=json.dumps(data, cls=SocketJSONEncoder))
    
    @database_sync_to_async
    def get_team_id(self, user):
        try:
            team = RescueTeam.objects.only('id').get(account=user)
            return team.id
        except RescueTeam.DoesNotExist:
            return None

    @database_sync_to_async
    def get_user_role_code(self, user):
        if hasattr(user, 'role') and user.role:
            return user.role.code
        return None
    

class SocketJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, UUID):
            return str(obj)
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)
