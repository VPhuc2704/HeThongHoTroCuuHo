import json
from channels.generic.websocket import AsyncWebsocketConsumer

class RescueMapConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.group_name = "rescue_map_group"

        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, close_code):

        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )
        
    # gửi tin nhắn từ Server -> Client
    async def send_new_coordinate(self, event):
        data=event['data']
        await self.send(text_data=json.dumps(data))
        