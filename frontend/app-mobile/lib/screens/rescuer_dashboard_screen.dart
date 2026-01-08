import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/assign_service.dart';
import '../models/assignment.dart';
import '../services/auth_service.dart';

class RescuerDashboardScreen extends StatefulWidget {
  const RescuerDashboardScreen({super.key});

  @override
  State<RescuerDashboardScreen> createState() => _RescuerDashboardScreenState();
}

class _RescuerDashboardScreenState extends State<RescuerDashboardScreen> {
  bool _isLoading = false;
  List<Assignment> _assignments = [];
  List<Assignment> _historyList = [];
  Assignment? _currentTask;

  // Thống kê
  int _totalCompleted = 0;
  int _totalCancelled = 0;

  // Giả lập số thông báo (Sau này bạn bind data thật vào đây)
  int _unreadNotifications = 2;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    try {
      final data = await AssignService.getMyAssignments();
      if (mounted) {
        setState(() {
          data.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
          _assignments = data;

          try {
            _currentTask = data.firstWhere(
                  (t) => ['assigned', 'in_progress', 'arrived'].contains(t.status),
            );
          } catch (e) {
            _currentTask = null;
          }

          _historyList = data
              .where((t) => ['completed', 'cancelled'].contains(t.status))
              .toList();
          _totalCompleted =
              _historyList.where((t) => t.status == 'completed').length;
          _totalCancelled =
              _historyList.where((t) => t.status == 'cancelled').length;
        });
      }
    } catch (e) {
      print("Lỗi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logic gọi API update nhanh ngay tại Dashboard
  Future<void> _quickUpdateStatus(String action) async {
    if (_currentTask == null) return;
    setState(() => _isLoading = true);

    try {
      bool success = false;
      if (action == 'start') {
        success = await AssignService.confirmStart(_currentTask!.id);
      } else if (action == 'arrived') {
        success = await AssignService.confirmArrived(_currentTask!.id);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Đã cập nhật trạng thái!"),
            backgroundColor: Colors.green));
        _loadAssignments();
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDetail(Assignment task) async {
    final requestMap = {
      'id': task.id,
      'status': task.status,
      'name': task.victimName,
      'contact_phone': task.victimPhone,
      'address': task.address,
      'adults': task.adults,
      'children': task.children,
      'elderly': task.elderly,
      'latitude': task.latitude,
      'longitude': task.longitude,
      'conditions': task.conditions,
      'description': task.description,
      'created_at': task.assignedAt.toIso8601String(),
    };

    final result = await Navigator.pushNamed(context, '/rescue-request-detail',
        arguments: requestMap);

    if (result == true) {
      _loadAssignments();
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  void _openMap(double lat, double lng) async {
    // Sử dụng đường dẫn chuẩn của Google Maps:
    // api=1: Phiên bản API
    // query: Tọa độ điểm đến
    final Uri googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    // Nếu muốn mở thẳng chế độ CHỈ ĐƯỜNG (Navigation) thì dùng link này:
    // final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving");

    try {
      // Thêm mode: LaunchMode.externalApplication để buộc mở bằng App Google Maps (nếu có) thay vì mở trong Webview của app
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Nếu không mở được app, thử mở bằng trình duyệt mặc định
        await launchUrl(googleMapsUrl);
      }
    } catch (e) {
      print("Lỗi mở bản đồ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể mở bản đồ.")));
    }
  }

  void _logout() {
    AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Bỏ AppBar mặc định, dùng Body full màn hình để vẽ Header Custom
      body: Column(
        children: [
          // 1. HEADER MỚI (Gradient + Avatar + Thông báo)
          _buildCustomHeader(),

          // 2. PHẦN NỘI DUNG CUỘN BÊN DƯỚI
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAssignments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Đẩy nội dung xuống một chút để Stats Box đè lên Header (hiệu ứng 3D)
                    const SizedBox(height: 20),

                    // Thống kê (Floating Box)
                    _buildSummaryStats(),
                    const SizedBox(height: 30),

                    // NHIỆM VỤ ĐANG CHẠY
                    if (_currentTask != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.radar, color: Colors.blueAccent, size: 24),
                          const SizedBox(width: 8),
                          Text("NHIỆM VỤ ĐANG THỰC HIỆN",
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, letterSpacing: 1.1)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildActiveTaskCard(_currentTask!),
                      const SizedBox(height: 30),
                    ],

                    // LỊCH SỬ
                    Row(
                      children: [
                        const Icon(Icons.history, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text("LỊCH SỬ HOẠT ĐỘNG",
                            style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_historyList.isEmpty)
                      _buildEmptyHistory()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _historyList.length,
                        itemBuilder: (ctx, i) => _buildHistoryCard(_historyList[i]),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW HEADER WIDGET ---
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // AVATAR & INFO (Update Info)
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tính năng cập nhật thông tin đang phát triển")));
            },
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.verified_user, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Xin chào,", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Row(
                      children: [
                        const Text("Đội Cứu Hộ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, color: Colors.white.withOpacity(0.5), size: 14)
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ACTIONS (Noti & Logout)
          Row(
            children: [
              // Thông báo
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: 12, top: 12,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    )
                ],
              ),
              // Đăng xuất
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70),
                onPressed: _logout,
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- STATS WIDGET (Modified Style) ---
  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Hoàn thành", "$_totalCompleted", Colors.green),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _buildStatItem("Đã hủy", "$_totalCancelled", Colors.red),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _buildStatItem("Tổng cộng", "${_historyList.length}", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // --- TASK CARD (Keep user logic, slightly refined UI) ---
  Widget _buildActiveTaskCard(Assignment task) {
    String btnText = "XUẤT PHÁT";
    Color themeColor = Colors.orange;
    String nextAction = 'start';
    double progress = 0.3;

    if (task.status == 'in_progress') {
      btnText = "ĐÃ ĐẾN NƠI";
      themeColor = Colors.blue;
      nextAction = 'arrived';
      progress = 0.6;
    } else if (task.status == 'arrived') {
      btnText = "HOÀN TẤT >>";
      themeColor = Colors.green;
      nextAction = 'detail';
      progress = 0.9;
    }

    return GestureDetector(
      onTap: () => _navigateToDetail(task),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: themeColor.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
          border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: themeColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text("TRẠNG THÁI: ${task.status.toUpperCase()}",
                      style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: themeColor),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[100],
                        child: Icon(Icons.person,
                            color: Colors.grey[400], size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.victimName,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(task.address,
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[100],
                      color: themeColor,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Nút Gọi
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _makePhoneCall(task.victimPhone),
                            icon: const Icon(Icons.phone),
                            label: const Text("GỌI"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: BorderSide(color: Colors.green.shade200),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút Map
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: OutlinedButton(
                          onPressed: () =>
                              _openMap(task.latitude, task.longitude),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: BorderSide(color: Colors.blue.shade200),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Icon(Icons.map, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút Hành động chính
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: nextAction == 'detail'
                                ? () => _navigateToDetail(task)
                                : () => _quickUpdateStatus(nextAction),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(btnText,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Assignment task) {
    final bool isSuccess = task.status == 'completed';
    final Color statusColor = isSuccess ? Colors.green : Colors.red;
    final DateFormat formatter = DateFormat('dd/MM HH:mm');

    return GestureDetector(
      onTap: () => _navigateToDetail(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(isSuccess ? Icons.check : Icons.close,
                  color: statusColor, size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.address,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(formatter.format(task.assignedAt),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.history, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text("Chưa có lịch sử", style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }
}