import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/account_model.dart';

class AccountService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  static Future<AccountModel?> getProfile() async {
    // ... (Giữ nguyên hàm getProfile cũ) ...
    final token = await AuthService.getToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/me'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success'] == true) return AccountModel.fromJson(body['data']);
      }
    } catch (e) {
      print("Error getProfile: $e");
    }
    return null;
  }

  // --- SỬA HÀM NÀY ---
  // Bỏ 'required', cho phép truyền null
  static Future<bool> updateProfile({
    String? email,
    String? fullName,
    String? password,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    // 1. Chỉ đưa vào payload những trường CÓ GIÁ TRỊ (không null)
    Map<String, dynamic> payload = {};

    if (email != null) {
      payload["email"] = email;
    }
    if (fullName != null) {
      payload["full_name"] = fullName;
    }
    if (password != null && password.isNotEmpty) {
      payload["password"] = password;
    }

    // Nếu không có gì thay đổi thì trả về true luôn, đỡ gọi API
    if (payload.isEmpty) return true;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/profile/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      // 200 OK
      if (response.statusCode == 200) {
        return true;
      } else {
        // In lỗi ra để debug nếu còn bị 422
        print("Update Account Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error updateProfile: $e");
    }
    return false;
  }
}