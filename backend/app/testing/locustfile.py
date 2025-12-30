import random
from locust import HttpUser, task, between

class RescueUser(HttpUser):
    wait_time = between(1, 3)
    token = None  

    # --- 0. BƯỚC KHỞI TẠO: ĐĂNG NHẬP ---
    def on_start(self):
        login_payload = {
            "identifier": "0923456771",  # <--- USERNAME CỦA BẠN
            "password": "Pb2345678@"     # <--- PASSWORD CỦA BẠN
        }
        
        response = self.client.post("/api/auth/login", json=login_payload)
        
        if response.status_code == 200:
            data = response.json()
            # Logic lấy token (chỉnh lại key nếu cần)
            self.token = data.get('access') or data.get('access_token') or data.get('data', {}).get('access_token')
            print(f"✅ Login success. Token: {self.token[:10]}...")
        else:
            print(f"🔴 Login failed: {response.text}")
            self.token = None

    # --- KHO DỮ LIỆU GIẢ LẬP ---
    ho_list = ["Nguyễn", "Trần", "Lê", "Phạm", "Huỳnh", "Hoàng", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ"]
    dem_list = ["Văn", "Thị", "Minh", "Ngọc", "Thanh", "Đức", "Thuỳ", "Hoàng", "Hữu", "Xuân"]
    ten_list = ["Hùng", "Dũng", "Tuấn", "Nghĩa", "Phúc", "Linh", "Hương", "Bình", "Tâm", "Thảo"]
    
    # Thêm tỉnh thành để địa chỉ trông thật hơn
    tinh_thanh = ["Hà Nội", "Hồ Chí Minh", "Đà Nẵng", "Cần Thơ", "Hải Phòng", "Nghệ An", "Lâm Đồng", "Quảng Ninh"]
    duong_list = ["Quốc Lộ 1A", "Trần Hưng Đạo", "Nguyễn Trãi", "Lê Duẩn", "Hùng Vương", "Đường 3/2"]
    
    conditions_data = {
        'Cấp cứu y tế': ["Có người ngất xỉu", "Bị sốt cao", "Đau tim đột ngột"],
        'Tai nạn giao thông': ["Va chạm xe máy", "Tông xe liên hoàn", "Xe lao xuống ruộng"],
        'Hỏa hoạn': ["Chập điện cháy nhỏ", "Khói bốc lên nghi ngút", "Cháy kho hàng"],
        'Khác': ["Cần thực phẩm", "Hết pin điện thoại", "Mắc kẹt do lũ"]
    }
    available_condition_keys = list(conditions_data.keys())

    # --- HÀM TẠO TỌA ĐỘ VIỆT NAM ---
    def get_random_vietnam_coords(self):
        """
        Chia VN thành 3 vùng để random không bị rơi vào biển hoặc nước khác
        """
        region = random.choice(['north', 'central', 'south'])
        
        if region == 'north':
            # Khu vực Phía Bắc (Hà Nội, Hà Giang...)
            lat = random.uniform(20.0, 23.0)
            lon = random.uniform(103.5, 107.0)
        elif region == 'central':
            # Khu vực Miền Trung (Đà Nẵng, Nha Trang...)
            lat = random.uniform(12.0, 20.0)
            lon = random.uniform(107.5, 109.5)
        else:
            # Khu vực Phía Nam (HCM, Cần Thơ, Cà Mau...)
            lat = random.uniform(8.5, 12.0)
            lon = random.uniform(104.5, 107.5)
            
        return lat, lon

    @task
    def create_rescue(self):
        if not self.token:
            return

        # --- 1. TẠO TỌA ĐỘ TOÀN VIỆT NAM ---
        random_lat, random_lon = self.get_random_vietnam_coords()

        # --- 2. RANDOM DATA ---
        full_name = f"{random.choice(self.ho_list)} {random.choice(self.dem_list)} {random.choice(self.ten_list)}"
        random_phone = f"09{random.randint(10000000, 99999999)}"
        
        primary_condition = random.choice(self.available_condition_keys)
        final_conditions = [primary_condition]
        
        # Tạo mô tả random
        description = f"{random.choice(self.conditions_data[primary_condition])}. (Locust Full Map VN)"
        
        # Tạo địa chỉ ảo ngẫu nhiên
        fake_address = f"Số {random.randint(1,999)}, {random.choice(self.duong_list)}, {random.choice(self.tinh_thanh)}"

        payload = {
            "name": full_name,
            "code": "VN_TEST", # Đổi code để dễ nhận biết
            "contact_phone": random_phone,
            "adults": random.randint(1, 3),
            "children": random.randint(0, 2),
            "elderly": random.randint(0, 1),
            "address": fake_address,
            "latitude": random_lat,
            "longitude": random_lon,
            "conditions": final_conditions,
            "description": description
        }

        headers = {
            "Authorization": f"Bearer {self.token}"
        }
        
        self.client.post("/api/rescue", json=payload, headers=headers)