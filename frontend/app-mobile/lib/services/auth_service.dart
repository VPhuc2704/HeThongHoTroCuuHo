// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 1. Import thêm cái này

class AuthService {
  // 2. TỰ ĐỘNG ĐỔI IP
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000'; // IP cho Emulator Android
    }
  }

  static Map<String, dynamic>? _currentUser;

  // Cấu hình Google Sign In
  // LƯU Ý: Nếu bạn cấu hình thủ công trên Google Cloud Console,
  // bạn có thể cần thêm tham số `serverClientId` vào đây để lấy được idToken hợp lệ.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '456997668692-6o22fr9o1gg6rhl3qrcn8i7f49te90b7.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // --- API ĐĂNG KÝ (Giữ nguyên) ---
  static Future<bool> register(String name, String phone, String password) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "full_name": name,
          "phone": phone,
          "password": password
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Lỗi đăng ký: $e");
      return false;
    }
  }

  // --- API ĐĂNG NHẬP THƯỜNG (Giữ nguyên logic) ---
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': email,
          'password': password,
        }),
      );

      print("Login Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await _saveUserData(response.body); // Gọi hàm lưu chung
      } else {
        print('Đăng nhập thất bại: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Lỗi kết nối Login: $e');
      return false;
    }
  }

  // --- API ĐĂNG NHẬP GOOGLE (MỚI) ---
  static Future<bool> loginWithGoogle() async {
    try {
      // 1. Trigger Popup đăng nhập
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("Người dùng hủy đăng nhập.");
        return false;
      }

      // 2. Lấy thông tin xác thực
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // --- LOGIC QUAN TRỌNG NHẤT: TỰ ĐỘNG CHỌN TOKEN ---
      // Nếu có idToken (Android) thì dùng. Nếu null (Web) thì dùng accessToken.
      final String? tokenToSend = googleAuth.idToken ?? googleAuth.accessToken;

      print("Token gửi đi Backend: $tokenToSend");

      if (tokenToSend == null) {
        print("Lỗi: Không lấy được bất kỳ token nào.");
        return false;
      }

      // 3. Gửi về Backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': tokenToSend,
        }),
      );

      print("Backend Status: ${response.statusCode}");

      // 4. Xử lý kết quả
      if (response.statusCode == 200 || response.statusCode == 201) {
        return await _saveUserData(response.body);
      } else {
        print("Lỗi từ Backend: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi Exception Google: $e");
      return false;
    }
  }

  // --- HÀM PHỤ: XỬ LÝ LƯU DỮ LIỆU (Dùng chung cho cả 2 cách đăng nhập) ---
  static Future<bool> _saveUserData(String responseBody) async {
    try {

      final Map<String, dynamic> data = jsonDecode(responseBody);

      final accessToken = data['token']['access_token'];

      if (accessToken == null) return false;

      // 1. Giải mã Token để lấy Role
      Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
      String role = decodedToken['role_account'] ?? 'USER';

      // 2. Lưu token vào máy
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', accessToken);

      // 3. Xử lý hiển thị tên
      String displayName = 'Người dùng';
      if (data['full_name'] != null && data['full_name'].toString().isNotEmpty) {
        displayName = data['full_name'];
      } else if (data['email'] != null) {
        displayName = data['email'].toString().split('@')[0];
      }

      // 4. Lưu thông tin user
      final userInfoToSave = {
        'id': data['id'],
        'full_name': displayName,
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'role': role
      };

      await prefs.setString('user_info', jsonEncode(userInfoToSave));
      _currentUser = userInfoToSave;

      print("Đăng nhập thành công! Role: $role");
      return true;
    } catch (e) {
      print("Lỗi khi lưu dữ liệu user: $e");
      return false;
    }
  }

  // --- HÀM ĐĂNG XUẤT ---
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _googleSignIn.signOut(); // Đăng xuất cả Google để lần sau nó hỏi lại tài khoản
    _currentUser = null;
  }

  // ... (Các hàm getter cũ giữ nguyên) ...
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
}