import random
from locust import HttpUser, task, between

class RescueUser(HttpUser):
    wait_time = between(1, 3) 

    # --- KHO DỮ LIỆU GIẢ LẬP ---
    
    # 1. Tên người Việt
    ho_list = ["Nguyễn", "Trần", "Lê", "Phạm", "Huỳnh", "Hoàng", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Lý"]
    dem_list = ["Văn", "Thị", "Minh", "Ngọc", "Thanh", "Đức", "Thuỳ", "Hoàng", "Hữu", "Xuân", "Gia", "Khánh"]
    ten_list = ["Hùng", "Dũng", "Tuấn", "Nghĩa", "Phúc", "Linh", "Hương", "Bình", "Tâm", "Thảo", "Trang", "Hiếu", "Nam", "Khải", "Việt"]

    # 2. Tên đường phố phổ biến ở TP.HCM (để ghép vào địa chỉ)
    duong_list = [
        "Nguyễn Huệ", "Lê Lợi", "Pasteur", "Nam Kỳ Khởi Nghĩa", "Hai Bà Trưng", "Điện Biên Phủ",
        "Cách Mạng Tháng 8", "Nguyễn Thị Minh Khai", "Võ Văn Kiệt", "Phạm Văn Đồng", "Lê Văn Sỹ",
        "Huỳnh Tấn Phát", "Nguyễn Văn Linh", "Trần Hưng Đạo", "Nguyễn Trãi"
    ]

    # 3. Tình trạng và Lời nhắn tương ứng (cho khớp ngữ cảnh)
    conditions_data = {
        'Cấp cứu y tế': ["Có người ngất xỉu cần oxy gấp", "Bị sốt cao co giật", "Đau ruột thừa dữ dội"],
        'Đau ngực': ["Khó thở, đau thắt ngực trái", "Tim đập nhanh, hồi hộp"],
        'Té ngã': ["Người già bị trượt chân trong nhà vệ sinh", "Trẻ em té cầu thang chảy máu đầu"],
        'Không di chuyển được': ["Nước ngập quá cao không thể ra ngoài", "Xe hư giữa dòng nước lũ", "Nhà bị cô lập hoàn toàn"],
        'Tai nạn giao thông': ["Va chạm xe máy, nạn nhân bất tỉnh", "Tông xe liên hoàn cần cảnh sát"],
        'Chấn thương nặng': ["Gãy chân do vật nặng đè", "Vết thương hở chảy máu nhiều"],
        'Hỏa hoạn': ["Chập điện cháy nhỏ trong nhà", "Khói bốc lên từ tầng hầm"],
        'Mắc kẹt': ["Kẹt trong thang máy", "Kẹt trong nhà do cửa cuốn hỏng"],
        'Khác': ["Cần thực phẩm và nước sạch gấp", "Hết pin điện thoại cần sạc nhờ", "Cần xuồng cứu hộ di tản"]
    }
    
    # Danh sách Keys tình trạng để random
    available_condition_keys = list(conditions_data.keys())

    @task
    def create_rescue(self):
        # --- 1. RANDOM TỌA ĐỘ TP.HCM ---
        min_lat, max_lat = 10.3500, 11.1600
        min_lon, max_lon = 106.3300, 107.0200
        random_lat = random.uniform(min_lat, max_lat)
        random_lon = random.uniform(min_lon, max_lon)

        # --- 2. RANDOM THÔNG TIN CÁ NHÂN ---
        # Sinh tên: Họ + Đệm + Tên
        full_name = f"{random.choice(self.ho_list)} {random.choice(self.dem_list)} {random.choice(self.ten_list)}"
        
        # Sinh số điện thoại: Đầu số ngẫu nhiên + 7 số cuối
        dau_so = random.choice(['03', '05', '07', '08', '09'])
        duoi_so = random.randint(1000000, 9999999) # 7 chữ số
        random_phone = f"{dau_so}{duoi_so}"

        # --- 3. RANDOM TÌNH TRẠNG & MÔ TẢ ---
        # Chọn 1 tình trạng chính để làm mô tả
        primary_condition = random.choice(self.available_condition_keys)
        
        # Chọn thêm 0-2 tình trạng phụ nữa cho list
        other_conditions = random.sample([c for c in self.available_condition_keys if c != primary_condition], k=random.randint(0, 2))
        final_conditions = [primary_condition] + other_conditions

        # Lấy mô tả chi tiết tương ứng với tình trạng chính
        description_template = random.choice(self.conditions_data[primary_condition])
        description = f"{description_template}. (Toạ độ: {random_lat:.3f}, {random_lon:.3f})"

        # --- 4. RANDOM ĐỊA CHỈ GIẢ LẬP ---
        so_nha = random.randint(1, 999)
        duong = random.choice(self.duong_list)
        quan = random.choice(["1", "3", "4", "5", "7", "8", "10", "12", "Bình Thạnh", "Gò Vấp", "Tân Bình"])
        fake_address = f"Số {so_nha} đường {duong}, Quận {quan}, TP.HCM"

        # --- 5. TẠO PAYLOAD ---
        # Random Mã tỉnh (Ưu tiên SG 90%)
        selected_code = random.choices(['SG', 'VN'], weights=[90, 10], k=1)[0]

        payload = {
            "name": full_name,
            "code": selected_code,
            "contact_phone": random_phone,
            "adults": random.randint(1, 4),
            "children": random.randint(0, 3),
            "elderly": random.randint(0, 2),
            
            # Địa chỉ hiển thị text (cho nhìn thật)
            "address": fake_address,
            
            # Tọa độ dùng để map (quan trọng nhất)
            "latitude": random_lat,
            "longitude": random_lon,
            
            "conditions": final_conditions,
            "description": description
        }

        # Gửi request
        self.client.post("/api/rescue", json=payload)