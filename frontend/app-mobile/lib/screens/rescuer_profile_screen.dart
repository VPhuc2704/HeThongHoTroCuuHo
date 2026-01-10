import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/rescue_team_service.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../models/rescue_team.dart'; // Đổi tên file import cho đúng
import '../models/account_model.dart';     // Đổi tên file import cho đúng

class RescuerProfileScreen extends StatefulWidget {
  const RescuerProfileScreen({super.key});

  @override
  State<RescuerProfileScreen> createState() => _RescuerProfileScreenState();
}

class _RescuerProfileScreenState extends State<RescuerProfileScreen> {
  RescueTeamModel? _team;
  AccountModel? _account;

  bool _isLoading = true;
  final _primaryColor = const Color(0xFF1565C0);
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // 1. Tải dữ liệu
  Future<void> _fetchAllData() async {
    if (_team == null) setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        AccountService.getProfile(),
        RescueTeamService.getMyTeam(),
      ]);

      if (mounted) {
        setState(() {
          _account = results[0] as AccountModel?;
          _team = results[1] as RescueTeamModel?;
          _isLoading = false;
        });
        _checkMissingData();
      }
    } catch (e) {
      print("Lỗi tải dữ liệu: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Kiểm tra dữ liệu thiếu
  void _checkMissingData() {
    if (_team == null) return;
    bool isMissingLocation = (_team!.latitude == 0 && _team!.longitude == 0);
    bool isMissingInfo = _team!.hotline.isEmpty || _team!.address.isEmpty;

    if (isMissingLocation || isMissingInfo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Yêu cầu bổ sung thông tin"),
            content: const Text("Vui lòng cập nhật Hotline, Địa chỉ và Vị trí GPS để bắt đầu hoạt động."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showEditSheet(autoOpen: true);
                },
                child: const Text("CẬP NHẬT NGAY"),
              )
            ],
          ),
        );
      });
    }
  }

  // 3. Lấy GPS
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng bật GPS!")));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Lấy vị trí chính xác cao
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentPosition = position);
  }

  // 4. Form Chỉnh sửa
  void _showEditSheet({bool autoOpen = false}) {
    if (_team == null || _account == null) return;
    if (autoOpen) _getCurrentLocation();

    final fullNameController = TextEditingController(text: _account!.fullName);
    final emailController = TextEditingController(text: _account!.email);
    final passController = TextEditingController();

    final teamNameController = TextEditingController(text: _team!.name);
    final leaderController = TextEditingController(text: _team!.leaderName);
    final phoneController = TextEditingController(text: _team!.contactPhone);
    final hotlineController = TextEditingController(text: _team!.hotline);
    final addressController = TextEditingController(text: _team!.address);

    // Logic: Có email rồi thì ReadOnly
    bool isEmailHasData = _account!.email.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text("Cập nhật hồ sơ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor)),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("TÀI KHOẢN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 10),
                      _buildInputField(emailController, isEmailHasData ? "Email (Đã xác thực)" : "Nhập Email", Icons.email, isReadOnly: isEmailHasData),
                      const SizedBox(height: 10),
                      _buildInputField(fullNameController, "Họ tên quản lý", Icons.person),
                      const SizedBox(height: 10),
                      _buildInputField(passController, "Mật khẩu mới (Bỏ trống nếu không đổi)", Icons.lock, isPassword: true),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),

                      const Text("THÔNG TIN ĐỘI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 10),
                      _buildInputField(teamNameController, "Tên đội", Icons.security),
                      const SizedBox(height: 10),
                      _buildInputField(leaderController, "Đội trưởng", Icons.badge),
                      const SizedBox(height: 10),
                      _buildInputField(phoneController, "SĐT Liên hệ", Icons.phone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 10),
                      _buildInputField(hotlineController, "Hotline Khẩn cấp (*)", Icons.phone_in_talk, color: Colors.red, keyboardType: TextInputType.phone),
                      const SizedBox(height: 10),
                      _buildInputField(addressController, "Địa chỉ trụ sở (*)", Icons.location_on),

                      const SizedBox(height: 20),
                      InkWell(
                        onTap: () async {
                          await _getCurrentLocation();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lấy vị trí GPS mới!")));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location, color: Colors.blue),
                              const SizedBox(width: 10),
                              const Expanded(child: Text("Cập nhật vị trí GPS hiện tại", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                              if (_currentPosition != null) const Icon(Icons.check_circle, color: Colors.green)
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () {
                            if (hotlineController.text.isEmpty || addressController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thiếu Hotline hoặc Địa chỉ!"), backgroundColor: Colors.orange));
                              return;
                            }
                            Navigator.pop(context);
                            _handleUpdate(
                              fullName: fullNameController.text,
                              email: emailController.text,
                              password: passController.text,
                              teamName: teamNameController.text,
                              leader: leaderController.text,
                              phone: phoneController.text,
                              hotline: hotlineController.text,
                              address: addressController.text,
                            );
                          },
                          child: const Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // 5. Xử lý logic Update (SỬA LỖI LOGIC HIỂN THỊ)
  Future<void> _handleUpdate({
    required String fullName,
    required String email,
    required String password,
    required String teamName,
    required String leader,
    required String phone,
    required String hotline,
    required String address,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang lưu dữ liệu...")));

    bool hasError = false;

    // --- A. XỬ LÝ ACCOUNT (Chỉ gửi cái gì ĐÃ THAY ĐỔI) ---
    String? updateName;
    String? updateEmail;
    String? updatePass;
    bool needUpdateAccount = false;

    // 1. So sánh Tên
    if (fullName != _account!.fullName) {
      updateName = fullName;
      needUpdateAccount = true;
    }
    // 2. So sánh Email (nếu chưa có email thì mới so sánh)
    if (_account!.email.isEmpty && email.isNotEmpty) {
      updateEmail = email;
      needUpdateAccount = true;
    }
    // 3. So sánh Password (chỉ gửi nếu người dùng có nhập)
    if (password.isNotEmpty) {
      updatePass = password;
      needUpdateAccount = true;
    }

    // Chỉ gọi API Account nếu có ít nhất 1 trường thay đổi
    if (needUpdateAccount) {
      bool accSuccess = await AccountService.updateProfile(
          email: updateEmail,     // Cái nào không đổi sẽ là null -> Service sẽ không gửi
          fullName: updateName,
          password: updatePass
      );
      if (!accSuccess) hasError = true;
    }

    // --- B. XỬ LÝ TEAM (Tương tự, chỉ gửi cái có dữ liệu) ---
    Map<String, dynamic> teamPayload = {};

    // Logic của Team: Gửi đè cũng được, hoặc so sánh như trên.
    // Nhưng để an toàn ta chỉ gửi các trường không rỗng.
    if (teamName.isNotEmpty && teamName != _team!.name) teamPayload['name'] = teamName;
    if (leader.isNotEmpty && leader != _team!.leaderName) teamPayload['leader_name'] = leader;
    if (phone.isNotEmpty && phone != _team!.contactPhone) teamPayload['contact_phone'] = phone;
    if (hotline.isNotEmpty && hotline != _team!.hotline) teamPayload['hotline'] = hotline;
    if (address.isNotEmpty && address != _team!.address) teamPayload['address'] = address;

    // GPS: Chỉ gửi nếu có thay đổi
    if (_currentPosition != null) {
      teamPayload['latitude'] = _currentPosition!.latitude;
      teamPayload['longitude'] = _currentPosition!.longitude;
    }

    if (teamPayload.isNotEmpty) {
      bool teamSuccess = await RescueTeamService.updateTeam(_team!.id, teamPayload);
      if (!teamSuccess) hasError = true;
    }

    // --- C. KẾT QUẢ ---
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Có lỗi xảy ra (422) khi lưu!"), backgroundColor: Colors.red));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green));
      _fetchAllData(); // Load lại
    }
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon,
      {Color? color, TextInputType? keyboardType, bool isReadOnly = false, bool isPassword = false}) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      obscureText: isPassword,
      keyboardType: keyboardType ?? TextInputType.text,
      style: TextStyle(color: isReadOnly ? Colors.grey[600] : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isReadOnly ? Colors.grey : (color ?? _primaryColor)),
        suffixIcon: isReadOnly ? const Icon(Icons.lock, size: 16, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isReadOnly ? Colors.grey[200] : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _toggleStatus(bool isOnline) async {
    if (_team == null) return;
    final newStatus = isOnline ? 'active' : 'inactive';
    await RescueTeamService.updateTeam(_team!.id, {'status': newStatus});
    _fetchAllData();
  }

  void _logout() {
    AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    bool isOnline = _team?.status == 'active';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Hồ sơ Đội cứu hộ", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade600]))),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_team == null || _account == null)
          ? Center(child: ElevatedButton(onPressed: _fetchAllData, child: const Text("Tải lại")))
          : RefreshIndicator(
        onRefresh: _fetchAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // HEADER CARD
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(children: [
                  Row(children: [
                    CircleAvatar(radius: 30, backgroundColor: Colors.blue[100], child: Text(_account!.fullName.isNotEmpty ? _account!.fullName[0].toUpperCase() : "U", style: TextStyle(color: _primaryColor, fontSize: 24, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_account!.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_account!.email, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ])),
                    IconButton(onPressed: () => _showEditSheet(), icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: Icon(Icons.edit, color: _primaryColor, size: 20)))
                  ]),
                  const Divider(height: 30),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_team!.name, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(isOnline ? "● Đang trực tuyến" : "○ Đang nghỉ", style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 13)),
                    ]),
                    Switch(value: isOnline, activeColor: Colors.green, onChanged: _toggleStatus)
                  ])
                ]),
              ),
              // DETAIL INFO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("THÔNG TIN ĐỘI CỨU HỘ", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      _buildInfoRow(Icons.badge, "Đội trưởng", _team!.leaderName),
                      const Divider(),
                      _buildInfoRow(Icons.phone_in_talk, "Hotline", _team!.hotline, valueColor: Colors.red),
                      const Divider(),
                      _buildInfoRow(Icons.location_city, "Địa chỉ", _team!.address),
                      const Divider(),
                      _buildInfoRow(Icons.my_location, "Vị trí GPS", (_team!.latitude == 0) ? "Chưa cập nhật" : "${_team!.latitude}, ${_team!.longitude}"),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 40),
              TextButton.icon(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.red), label: const Text("Đăng xuất", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, {Color? valueColor}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.grey[400], size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 2),
        Text(value.isEmpty ? "---" : value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: valueColor ?? Colors.black87)),
      ]))
    ]));
  }
}