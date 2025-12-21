// services/request_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rescue_request.dart';
import 'auth_service.dart';

class RequestService {
  // Nhớ đổi IP nếu chạy máy thật (VD: 192.168.1.x)
  static const String baseUrl = 'http://10.0.2.2:8000';

  // --- API 1: TẠO REQUEST ---
  static Future<String?> createRequest(RescueRequest request) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/rescue'); // Endpoint tạo mới

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
        return data['id'];
      } else {
        print('Lỗi tạo request: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      throw Exception('Không thể kết nối đến máy chủ');
    }
  }

  // --- API 2: UPLOAD ẢNH ---
  static Future<void> uploadMedia(String rescueId, List<String> filePaths) async {
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/rescue/$rescueId/media');

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      for (String path in filePaths) {
        request.files.add(await http.MultipartFile.fromPath('files', path));
      }

      var streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        print("Upload ảnh thành công!");
      }
    } catch (e) {
      print("Lỗi upload media: $e");
    }
  }

  // --- API 3: LẤY LỊCH SỬ ---
  static Future<List<RescueRequest>> getUserRequests(String userName) async {
    final token = await AuthService.getToken();
    // Endpoint lấy lịch sử (Backend cần hỗ trợ route này)
    final url = Uri.parse('$baseUrl/rescue/history');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RescueRequest.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Lỗi lấy lịch sử: $e');
      return [];
    }
  }

  // --- API 4: HỦY YÊU CẦU (Mới thêm) ---
  static Future<bool> cancelRequest(String code) async {
    final token = await AuthService.getToken();
    // Giả định backend có route: PATCH /rescue/{code}/cancel
    // Hoặc PUT /rescue/{code} body: {"status": "cancelled"}
    final url = Uri.parse('$baseUrl/rescue/$code/status');

    try {
      final response = await http.patch( // Hoặc PUT tùy backend
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': 'cancelled'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi hủy yêu cầu: $e');
      return false;
    }
  }
}