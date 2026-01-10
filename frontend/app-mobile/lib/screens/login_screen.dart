// screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final Color _primaryColor = const Color(0xFFE53935);

  // --- HÀM ĐĂNG NHẬP GIỮ NGUYÊN ---
  void _login() async {
    final identifier = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập SDT và Mật khẩu'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    bool success = await AuthService.login(identifier, password);
    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      final user = AuthService.getCurrentUser();
      final role = (user?['role'] ?? '').toString().toUpperCase();

      if (role == 'RESCUER' || role == 'RESCUER') {
        Navigator.pushReplacementNamed(context, '/rescue-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/user-home');
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Đăng nhập thất bại!'), backgroundColor: _primaryColor),
      );
    }
  }

  // --- HÀM XỬ LÝ ĐĂNG NHẬP GOOGLE ---
  void _handleGoogleLogin() async {
    // 1. Hiển thị loading
    setState(() => _isLoading = true);

    // 2. Gọi hàm đăng nhập Google từ AuthService (đã viết ở bước trước)
    // Lưu ý: Hàm này sẽ mở popup Google, lấy token và gửi về backend xác thực
    bool success = await AuthService.loginWithGoogle();

    // 3. Tắt loading
    setState(() => _isLoading = false);

    // 4. Xử lý kết quả
    if (success) {
      if (!mounted) return;

      // Lấy thông tin user vừa đăng nhập để kiểm tra Role
      final user = AuthService.getCurrentUser();

      // Chuyển hướng (Thường Google Login là user thường)
      // Nhưng nếu backend bạn trả về role khác thì vẫn check được
      final role = (user?['role'] ?? '').toString().toUpperCase();

      if (role == 'RESCUER') {
        Navigator.pushReplacementNamed(context, '/rescue-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/user-home');
      }

    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập Google thất bại hoặc đã hủy'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO ---
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
                      border: Border.all(color: _primaryColor.withOpacity(0.1), width: 1),
                    ),
                    child: Icon(Icons.medical_services_outlined, size: 50, color: _primaryColor),
                  ),
                  const SizedBox(height: 24),
                  Text('CỨU HỘ KHẨN CẤP', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.grey[900])),
                  const SizedBox(height: 8),
                  Text('Đăng nhập hệ thống phản ứng nhanh', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 40),

                  // --- INPUT FIELDS ---
                  _buildTextField(controller: _usernameController, label: 'SĐT / Tài khoản', icon: Icons.person_outline, hint: '0999999999'),
                  const SizedBox(height: 20),
                  _buildTextField(controller: _passwordController, label: 'Mật khẩu', icon: Icons.lock_outline, hint: 'Nhập mật khẩu', isPassword: true),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text('Quên mật khẩu?', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- LOGIN BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor, foregroundColor: Colors.white,
                        elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- GOOGLE LOGIN (MỚI) ---
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("Hoặc đăng nhập với", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _handleGoogleLogin,
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                        height: 24,
                      ),
                      label: const Text("Tiếp tục bằng Google", style: TextStyle(fontSize: 16, color: Colors.black87)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- REGISTER & RESCUER NOTE (MỚI) ---
                  // 1. Link đăng ký cho người dân
                  _buildRegisterLink(),

                  const SizedBox(height: 16),

                  // 2. Thông báo cho Đội cứu hộ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                              children: const [
                                TextSpan(text: "Bạn là Đội Cứu Hộ? ", style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: "Vui lòng liên hệ Admin để được cấp tài khoản chuyên dụng."),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... (Giữ nguyên các hàm _buildTextField và _buildRegisterLink cũ)

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, String? hint, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint, prefixIcon: Icon(icon, color: Colors.grey[500]),
            filled: true, fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Người dân chưa có tài khoản? ', style: TextStyle(color: Colors.grey[600])),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/register'),
          child: Text('Đăng ký miễn phí', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}