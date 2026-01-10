import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/rescue_team.dart';

class RescueTeamService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  // 1. Lấy thông tin đội (/me)
  static Future<RescueTeamModel?> getMyTeam() async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rescue_team/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success'] == true) {
          return RescueTeamModel.fromJson(body['data']);
        }
      }
    } catch (e) {
      print("Error getMyTeam: $e");
    }
    return null;
  }

  // 2. Cập nhật thông tin đội
  static Future<bool> updateTeam(String teamId, Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/rescue_team/$teamId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Update Team failed: ${response.body}");
      }
    } catch (e) {
      print("Error updateTeam: $e");
    }
    return false;
  }
}