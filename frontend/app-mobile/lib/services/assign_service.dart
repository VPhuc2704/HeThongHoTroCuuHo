import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/assignment.dart';

class AssignService {
  // Tự động đổi IP
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.2.2:8000';
  }

  // Helper để lấy Header
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. LẤY DANH SÁCH NHIỆM VỤ
  static Future<List<Assignment>> getMyAssignments() async {
    final url = Uri.parse('$baseUrl/api/rescue-teams/assignments');
    try {
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Assignment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi lấy nhiệm vụ: $e");
      return [];
    }
  }

  // 2. XÁC NHẬN XUẤT PHÁT
  static Future<bool> confirmStart(String assignmentId) async {
    final url = Uri.parse('$baseUrl/api/rescue-teams/task/start');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({'assignment_id': assignmentId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 3. XÁC NHẬN ĐẾN NƠI
  static Future<bool> confirmArrived(String assignmentId) async {
    final url = Uri.parse('$baseUrl/api/rescue-teams/task/arrived');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({'assignment_id': assignmentId}), // Body dùng chung schema ConfirmStartIn
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. HOÀN THÀNH NHIỆM VỤ
  static Future<bool> completeTask(String assignmentId, String note) async {
    final url = Uri.parse('$baseUrl/api/rescue-teams/task/complete');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'assignment_id': assignmentId,
          'outcome_note': note,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}