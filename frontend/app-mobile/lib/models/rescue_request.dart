class RescueRequest {
  final String? id; // ID từ database (UUID)
  final String name;
  final String contactPhone;
  final String code;
  final int adults;
  final int children;
  final int elderly;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> conditions;
  final String description;
  final List<dynamic> media; // Dùng dynamic để linh hoạt (String url hoặc XFile)
  final DateTime requestTime;
  final String status;

  // --- HAI TRƯỜNG MỚI BỔ SUNG ---
  final List<String> mediaUrls; // Chứa link ảnh từ server
  final Map<String, dynamic>? activeAssignment; // Chứa thông tin đội cứu hộ

  RescueRequest({
    this.id,
    required this.name,
    required this.contactPhone,
    required this.code,
    required this.adults,
    required this.children,
    required this.elderly,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.conditions,
    required this.description,
    this.media = const [],
    required this.requestTime,
    this.status = 'pending',
    // Mặc định
    this.mediaUrls = const [],
    this.activeAssignment,
  });

  // Chuyển từ JSON (Server trả về) -> Object (Dùng trong App)
  factory RescueRequest.fromJson(Map<String, dynamic> json) {
    return RescueRequest(
      id: json['id'],
      name: json['name'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      // Nếu không có code thì lấy ID làm code tạm
      code: json['code'] ?? json['id'] ?? '',
      adults: json['adults'] ?? 0,
      children: json['children'] ?? 0,
      elderly: json['elderly'] ?? 0,
      address: json['address'] ?? '',
      // Xử lý Lat/Lng an toàn (vì server có thể trả về String hoặc Double)
      latitude: (json['latitude'] is String)
          ? double.parse(json['latitude'])
          : (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] is String)
          ? double.parse(json['longitude'])
          : (json['longitude'] as num?)?.toDouble() ?? 0.0,

      // Xử lý danh sách điều kiện
      conditions: json['conditions'] != null
          ? List<String>.from(json['conditions'])
          : [],

      // Lấy description hoặc description_short
      description: json['description'] ?? json['description_short'] ?? '',

      // Xử lý ngày giờ
      requestTime: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['request_time'] != null
          ? DateTime.parse(json['request_time'].toString())
          : DateTime.now()),

      status: json['status'] ?? 'pending',

      // --- MAP DỮ LIỆU MỚI ---
      // 1. Lấy danh sách link ảnh
      mediaUrls: json['media_urls'] != null
          ? List<String>.from(json['media_urls'])
          : [],

      // 2. Lấy thông tin đội cứu hộ
      activeAssignment: json['active_assignment'],
    );
  }

  // Chuyển từ Object -> JSON (Để gửi lên Server hoặc truyền giữa các màn hình)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_phone': contactPhone,
      'code': code,
      'adults': adults,
      'children': children,
      'elderly': elderly,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'conditions': conditions,
      'description': description,
      'request_time': requestTime.toIso8601String(),
      'status': status,

      // Truyền cả 2 trường này đi
      'media_urls': mediaUrls,
      'active_assignment': activeAssignment,
    };
  }
}