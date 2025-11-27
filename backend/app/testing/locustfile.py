from locust import HttpUser, task, between

class RescueUser(HttpUser):
    wait_time = between(1, 3)  # thời gian chờ giữa các request
    @task
    def create_rescue(self):
        self.client.post("/api/rescue", json={
            "name": "Test User",
            "contact_phone": "0123456789",
            "adults": 1,
            "children": 0,
            "elderly": 0,
            "address": "123 Street",
            "latitude": 10.1,
            "longitude": 106.7,
            "conditions": [],
            "description": "Test request"
        })
