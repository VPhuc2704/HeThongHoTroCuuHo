// services/request_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/rescue_request.dart';
import 'auth_service.dart';

class RequestService {
  // 2. TỰ ĐỘNG ĐỔI IP: Web dùng localhost, Android dùng 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  // --- API 1: TẠO REQUEST ---
  static Future<String?> createRequest(RescueRequest request) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/api/requests/rescue');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': request.name,
          'contact_phone': request.contactPhone,
          'code': request.code,
          'adults': request.adults,
          'children': request.children,
          'elderly': request.elderly,
          'address': request.address,
          'latitude': request.latitude,
          'longitude': request.longitude,
          'conditions': request.conditions,
          'description': request.description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Trả về ID để dùng cho bước Upload ảnh tiếp theo
        return data['id'] ?? data['_id'];
      } else {
        print('Lỗi tạo request: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối Create: $e');
      return null;
    }
  }

  // --- API 2: UPLOAD ẢNH (ĐÃ SỬA CHO WEB) ---
  // ⚠️ Thay List<String> bằng List<XFile>
  static Future<void> uploadMedia(String rescueId, List<XFile> files) async {
    if (files.isEmpty) return;

    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/api/requests/rescue/$rescueId/media');

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      for (var file in files) {
        if (kIsWeb) {
          // --- WEB: Đọc Bytes (Không dùng path) ---
          final bytes = await file.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'files',
              bytes,
              filename: file.name,
            ),
          );
        } else {
          // --- MOBILE: Dùng Path ---
          request.files.add(
            await http.MultipartFile.fromPath('files', file.path),
          );
        }
      }

      print("Đang upload ${files.length} ảnh...");
      var response = await request.send();

      if (response.statusCode == 200) {
        print("Upload ảnh thành công!");
      } else {
        print("Lỗi upload: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi kết nối upload: $e");
    }
  }

  // --- API 3: LẤY LỊCH SỬ (Đã sửa logic parse JSON) ---
  static Future<List<RescueRequest>> getUserRequests() async {
    final token = await AuthService.getToken();
    // Đảm bảo URL này đúng với BE của bạn
    final url = Uri.parse('$baseUrl/api/requests/my-requests/history');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Decode UTF8 để không lỗi font tiếng Việt
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        List<dynamic> listData = [];

        // --- SỬA LOGIC Ở ĐÂY ---
        if (decodedData is Map) {
          // JSON của bạn trả về: { "items": [...], "total": ... }
          if (decodedData['items'] != null) {
            listData = decodedData['items'];
          } else if (decodedData['data'] != null) {
            listData = decodedData['data'];
          }
        } else if (decodedData is List) {
          listData = decodedData;
        }

        // Map dữ liệu từ JSON sang Model
        // Lưu ý: Nếu Model của bạn tên trường khác JSON (ví dụ JSON là created_at, Model là requestTime)
        // thì cần sửa trong Model.fromJson.
        // Ở đây mình giả định Model.fromJson đã map đúng hoặc mình map tay tạm thời:
        return listData.map((json) {
          // Vá lỗi thiếu 'code' bằng cách lấy 'id'
          if (json['code'] == null) {
            json['code'] = json['id']; // Dùng ID làm code tạm
          }
          return RescueRequest.fromJson(json);
        }).toList();

      } else {
        return [];
      }
    } catch (e) {
      print('Lỗi lấy lịch sử: $e');
      return [];
    }
  }

  // --- API 4: HỦY YÊU CẦU ---
  static Future<bool> cancelRequest(String code) async {
    final token = await AuthService.getToken();
    // Thêm /api vào đường dẫn
    final url = Uri.parse('$baseUrl/api/rescue/$code/status');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': 'cancelled'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- API 5: LẤY TẤT CẢ ---
  static Future<List<RescueRequest>> getAllRequests() async {
    final token = await AuthService.getToken();
    // Thêm /api vào đường dẫn
    final url = Uri.parse('$baseUrl/api/rescue');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData is List) {
          return decodedData.map((json) => RescueRequest.fromJson(json)).toList();
        } else if (decodedData is Map && decodedData['data'] != null) {
          return (decodedData['data'] as List).map((json) => RescueRequest.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print("Lỗi lấy tất cả request: $e");
      return [];
    }
  }

  // --- API 6: LẤY THỐNG KÊ ---
  static Future<Map<String, int>> getStatistics() async {
    try {
      final requests = await getAllRequests();
      return {
        'total': requests.length,
        'pending': requests.where((r) => r.status == 'pending').length,
        'in_progress': requests.where((r) => r.status == 'in_progress').length,
        'resolved': requests.where((r) => r.status == 'resolved').length,
        'cancelled': requests.where((r) => r.status == 'cancelled').length,
      };
    } catch (e) {
      return {'total': 0, 'pending': 0, 'in_progress': 0, 'resolved': 0, 'cancelled': 0};
    }
  }
}