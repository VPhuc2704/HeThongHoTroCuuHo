import random
from locust import HttpUser, task, between

class RescueUser(HttpUser):
    wait_time = between(1, 3)  # thời gian chờ giữa các request

    @task
    def create_rescue(self):
        # --- CẤU HÌNH TỌA ĐỘ TP. HỒ CHÍ MINH ---
        # Tọa độ bao quanh (Bounding Box) TP.HCM:
        # Lat: từ khoảng 10.35 (Cần Giờ) đến 11.16 (Củ Chi)
        # Long: từ khoảng 106.33 (Bình Chánh) đến 107.02 (Cần Giờ/Thủ Đức)
        
        min_lat = 10.3500
        max_lat = 11.1600
        min_lon = 106.3300
        max_lon = 107.0200

        # Random vị trí
        random_lat = random.uniform(min_lat, max_lat)
        random_lon = random.uniform(min_lon, max_lon)

        # Random số điện thoại để tránh trùng lặp nếu server có check
        random_phone = f"09{random.randint(10000000, 99999999)}"
        
        # Random số lượng người
        adults = random.randint(1, 4)
        children = random.randint(0, 3)

        payload = {
            "name": f"Test User {random.randint(1, 10000)}",
            "contact_phone": random_phone,
            "adults": adults,
            "children": children,
            "elderly": 0,
            "address": "Random Location in HCMC", # Nếu muốn địa chỉ thật cần tích hợp thư viện Faker
            "latitude": random_lat,
            "longitude": random_lon,
            "conditions": ["Cần thuyền", "lương thực","Nước ngập hơn 2m"],
            "description": f"Emergency test request at coordinates: {random_lat}, {random_lon}"
        }

        # Gửi request
        self.client.post("/api/rescue", json=payload)