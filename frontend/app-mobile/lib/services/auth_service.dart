// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart'; // 1. Import cái này

class AuthService {
  // 2. TỰ ĐỘNG ĐỔI IP
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  static Map<String, dynamic>? _currentUser;

  static Future<bool> register(String name, String phone, String password) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/register');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // Gửi dữ liệu theo format JSON bạn yêu cầu
          "full_name": name, // Vẫn nên gửi tên để lưu DB
          "phone": phone,    // <--- Dùng key là "phone"
          "password": password
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return false;
    }
  }

  // --- API ĐĂNG NHẬP ---
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'), // Đã dùng baseUrl động
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];

        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        String role = decodedToken['role_account'] ?? 'USER';

        final userObj = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', accessToken);

        final userInfoToSave = {
          'id': userObj['id'],
          'name': userObj['email'].toString().split('@')[0],
          'email': userObj['email'],
          'phone': userObj['phone'] ?? '',
          'role': role
        };

        await prefs.setString('user_info', jsonEncode(userInfoToSave));
        _currentUser = userInfoToSave;

        print("Đăng nhập thành công! Role: $role");
        return true;
      } else {
        print('Đăng nhập thất bại: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Lỗi kết nối Login: $e');
      return false;
    }
  }

  // ... (Các hàm getToken, loadUserFromStorage, logout giữ nguyên như cũ) ...
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, dynamic>? getCurrentUser() {
    return _currentUser;
  }

  static Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfo = prefs.getString('user_info');
    final token = prefs.getString('auth_token');

    if (token != null && userInfo != null) {
      if (JwtDecoder.isExpired(token)) {
        await logout();
      } else {
        _currentUser = jsonDecode(userInfo);
      }
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;
  }
}