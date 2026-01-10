import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../models/account_model.dart'; // Import đúng file model

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  AccountModel? _user;
  bool _isLoading = true;
  final _primaryColor = const Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    // Chỉ hiện loading lần đầu
    if (_user == null) setState(() => _isLoading = true);

    final data = await AccountService.getProfile();
    if (mounted) {
      setState(() {
        _user = data;
        _isLoading = false;
      });
    }
  }

  // --- LOGIC UPDATE THÔNG MINH (Partial Update) ---
  Future<void> _handleUpdate({
    required String fullName,
    required String email,
    required String password,
  }) async {
    // 1. Kiểm tra xem có gì thay đổi không?
    bool nameChanged = fullName != _user!.fullName;
    bool emailChanged = email != _user!.email && _user!.email.isEmpty; // Chỉ cho đổi nếu email cũ rỗng
    bool passChanged = password.isNotEmpty; // Chỉ đổi nếu có nhập pass

    if (!nameChanged && !emailChanged && !passChanged) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không có thông tin nào thay đổi.")));
      return;
    }

    Navigator.pop(context); // Đóng form trước
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang cập nhật hồ sơ...")));

    // 2. Gọi Service (Chỉ truyền tham số nếu có thay đổi)
    final success = await AccountService.updateProfile(
      // Nếu tên đổi thì gửi tên mới, không thì gửi null
      fullName: nameChanged ? fullName : null,
      // Nếu email đổi thì gửi email mới, không thì gửi null
      email: emailChanged ? email : null,
      // Nếu có nhập pass thì gửi, không thì gửi null
      password: passChanged ? password : null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật hồ sơ thành công!"), backgroundColor: Colors.green));
        _fetchProfile(); // Load lại data mới
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi cập nhật! Có thể email đã tồn tại."), backgroundColor: Colors.red));
      }
    }
  }

  // --- UI: EDIT BOTTOM SHEET ---
  void _showEditSheet() {
    if (_user == null) return;

    final nameController = TextEditingController(text: _user!.fullName);
    final emailController = TextEditingController(text: _user!.email);
    final passController = TextEditingController();

    // Logic: Nếu đã có email thì khóa (ReadOnly)
    bool isEmailHasData = _user!.email.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Ẩn phím khi bấm ra ngoài
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20
          ),
          child: Column(
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text("Cập nhật thông tin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Email Field
                      _buildModernTextField(
                          emailController,
                          isEmailHasData ? "Email (Đã xác thực)" : "Nhập Email",
                          Icons.email,
                          isReadOnly: isEmailHasData // Khóa nếu đã có
                      ),
                      const SizedBox(height: 15),

                      // Name Field
                      _buildModernTextField(nameController, "Họ và tên", Icons.person),
                      const SizedBox(height: 15),

                      // Password Field
                      _buildModernTextField(passController, "Mật khẩu mới", Icons.lock, isPassword: true, hint: "Để trống nếu không đổi"),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 5,
                          ),
                          onPressed: () {
                            _handleUpdate(
                              fullName: nameController.text,
                              email: emailController.text,
                              password: passController.text,
                            );
                          },
                          child: const Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET INPUT FIELD ---
  Widget _buildModernTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, String? hint, bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isReadOnly ? Colors.grey[200] : Colors.grey[50], // Màu nền tối hơn nếu ReadOnly
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            readOnly: isReadOnly,
            style: TextStyle(color: isReadOnly ? Colors.grey[600] : Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: Icon(icon, color: isReadOnly ? Colors.grey : _primaryColor.withOpacity(0.7)),
              suffixIcon: isReadOnly ? const Icon(Icons.lock, size: 16, color: Colors.grey) : null, // Icon khóa
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? Center(child: ElevatedButton(onPressed: _fetchProfile, child: const Text("Tải lại")))
          : Stack(
        children: [
          // 1. BACKGROUND HEADER
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade900, _primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. NÚT BACK VÀ TITLE
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Hồ sơ cá nhân",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // 3. MAIN CONTENT
          Container(
            margin: const EdgeInsets.only(top: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: RefreshIndicator( // Thêm kéo xuống để reload
              onRefresh: _fetchProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Tên và Role
                    Text(_user!.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(_user!.roleName.toUpperCase(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),

                    const SizedBox(height: 30),

                    // INFO CARD
                    _buildInfoSection(),

                    const SizedBox(height: 30),

                    // NÚT SỬA
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _showEditSheet,
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                        label: const Text("CHỈNH SỬA HỒ SƠ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          elevation: 4,
                          shadowColor: _primaryColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),

          // 4. AVATAR
          Positioned(
            top: 130,
            left: 0, right: 0,
            child: Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)]),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.person, size: 60, color: Colors.grey[400]),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildInfoRow(Icons.email_outlined, "Email", _user!.email),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
        _buildInfoRow(Icons.phone_outlined, "Số điện thoại", _user!.phone.isNotEmpty ? _user!.phone : "Chưa cập nhật"),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
        _buildInfoRow(Icons.calendar_today_outlined, "Ngày tham gia", "2026-01-10"),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _primaryColor, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}