class Assignment {
  final String id;
  final String status; // assigned, in_progress, arrived, completed, cancelled
  final String victimName;
  final String victimPhone;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> conditions;
  final String description;
  final DateTime assignedAt;

  // --- CÁC TRƯỜNG MỚI (Để sửa lỗi) ---
  final int adults;
  final int children;
  final int elderly;

  Assignment({
    required this.id,
    required this.status,
    required this.victimName,
    required this.victimPhone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.conditions,
    required this.description,
    required this.assignedAt,
    // Thêm vào constructor
    required this.adults,
    required this.children,
    required this.elderly,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    // 1. LẤY DỮ LIỆU CỐT LÕI
    // API của bạn lồng thông tin nạn nhân trong 'rescue_request'
    final requestData = json['rescue_request'] ?? json;

    // 2. XỬ LÝ TRẠNG THÁI (Map Tiếng Việt -> Tiếng Anh)
    String rawStatus = (json['status'] ?? 'assigned').toString().toLowerCase();
    String normalizedStatus = 'assigned';

    if (rawStatus.contains('điều động') || rawStatus.contains('phân công') || rawStatus == 'assigned') {
      normalizedStatus = 'assigned';
    } else if (rawStatus.contains('thực hiện') || rawStatus.contains('di chuyển') || rawStatus == 'in_progress') {
      normalizedStatus = 'in_progress';
    } else if (rawStatus.contains('đến') || rawStatus.contains('hiện trường') || rawStatus == 'arrived') {
      normalizedStatus = 'arrived';
    } else if (rawStatus.contains('hoàn thành') || rawStatus == 'completed' || rawStatus == 'resolved') {
      normalizedStatus = 'completed';
    } else if (rawStatus.contains('hủy') || rawStatus == 'cancelled') {
      normalizedStatus = 'cancelled';
    }

    return Assignment(
      id: json['id']?.toString() ?? '',
      status: normalizedStatus,

      // Map thông tin nạn nhân
      victimName: requestData['name'] ?? 'Không tên',
      victimPhone: requestData['contact_phone'] ?? requestData['victim_phone'] ?? '',
      address: requestData['address'] ?? '',

      // Xử lý tọa độ an toàn
      latitude: (requestData['latitude'] is String)
          ? double.parse(requestData['latitude'])
          : (requestData['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (requestData['longitude'] is String)
          ? double.parse(requestData['longitude'])
          : (requestData['longitude'] as num?)?.toDouble() ?? 0.0,

      conditions: requestData['conditions'] != null
          ? List<String>.from(requestData['conditions'])
          : [],

      description: requestData['description'] ?? '',

      // Xử lý thời gian (ưu tiên assigned_at, nếu không có lấy created_at)
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),

      // --- MAP CÁC TRƯỜNG MỚI ---
      adults: (requestData['adults'] as num?)?.toInt() ?? 0,
      children: (requestData['children'] as num?)?.toInt() ?? 0,
      elderly: (requestData['elderly'] as num?)?.toInt() ?? 0,
    );
  }
}