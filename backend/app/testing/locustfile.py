import random
from locust import HttpUser, task, between

class RescueUser(HttpUser):
    wait_time = between(1, 3)
    token = None  # Biến lưu token

    # --- 0. BƯỚC KHỞI TẠO: ĐĂNG NHẬP ---
    def on_start(self):
        """Chạy 1 lần khi User ảo bắt đầu để lấy Token"""
        # Thay thế bằng một tài khoản có sẵn trong DB của bạn (Role: Citizen hoặc User thường)
        login_payload = {
            "identifier": "0923456771",  # <--- SỬA LẠI USERNAME THẬT CỦA BẠN
            "password": "Pb2345678@"             # <--- SỬA LẠI PASSWORD THẬT
        }
        
        # Gọi API đăng nhập
        response = self.client.post("/api/auth/login", json=login_payload)
        
        if response.status_code == 200:
            # Lấy token từ response (Sửa key 'access' hoặc 'access_token' tùy API của bạn trả về gì)
            data = response.json()
            # Giả sử API trả về: { "data": { "access_token": "..." } } hoặc { "access": "..." }
            self.token = data.get('access') or data.get('access_token') or data.get('data', {}).get('access_token')
            print(f"✅ Login success. Token: {self.token[:10]}...")
        else:
            print(f"🔴 Login failed: {response.text}")
            self.token = None

    # --- KHO DỮ LIỆU GIẢ LẬP (Giữ nguyên) ---
    ho_list = ["Nguyễn", "Trần", "Lê", "Phạm", "Huỳnh", "Hoàng", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ"]
    dem_list = ["Văn", "Thị", "Minh", "Ngọc", "Thanh", "Đức", "Thuỳ", "Hoàng", "Hữu", "Xuân"]
    ten_list = ["Hùng", "Dũng", "Tuấn", "Nghĩa", "Phúc", "Linh", "Hương", "Bình", "Tâm", "Thảo"]
    duong_list = ["Nguyễn Huệ", "Lê Lợi", "Pasteur", "Nam Kỳ Khởi Nghĩa", "Hai Bà Trưng", "Điện Biên Phủ"]
    
    conditions_data = {
        'Cấp cứu y tế': ["Có người ngất xỉu", "Bị sốt cao"],
        'Tai nạn giao thông': ["Va chạm xe máy", "Tông xe liên hoàn"],
        'Hỏa hoạn': ["Chập điện cháy nhỏ", "Khói bốc lên"],
        'Khác': ["Cần thực phẩm", "Hết pin điện thoại"]
    }
    available_condition_keys = list(conditions_data.keys())

    @task
    def create_rescue(self):
        # Nếu chưa login được thì không spam request lỗi nữa
        if not self.token:
            return

        # --- RANDOM DỮ LIỆU (Giữ nguyên logic của bạn) ---
        min_lat, max_lat = 10.7500, 10.8500 # Gom nhỏ phạm vi lại 1 chút để dễ thấy trên Map
        min_lon, max_lon = 106.6000, 106.7500
        
        random_lat = random.uniform(min_lat, max_lat)
        random_lon = random.uniform(min_lon, max_lon)
        full_name = f"{random.choice(self.ho_list)} {random.choice(self.dem_list)} {random.choice(self.ten_list)}"
        random_phone = f"09{random.randint(10000000, 99999999)}"
        
        primary_condition = random.choice(self.available_condition_keys)
        final_conditions = [primary_condition]
        description = f"{random.choice(self.conditions_data[primary_condition])}. (Locust Test)"
        fake_address = f"Số {random.randint(1,999)} đường {random.choice(self.duong_list)}"

        payload = {
            "name": full_name,
            "code": "SG",
            "contact_phone": random_phone,
            "adults": random.randint(1, 2),
            "children": 0,
            "elderly": 0,
            "address": fake_address,
            "latitude": random_lat,
            "longitude": random_lon,
            "conditions": final_conditions,
            "description": description
        }

        # --- GỬI REQUEST KÈM HEADER AUTHENTICATION ---
        headers = {
            "Authorization": f"Bearer {self.token}"  # <--- QUAN TRỌNG NHẤT
        }
        
        self.client.post("/api/rescue", json=payload, headers=headers)