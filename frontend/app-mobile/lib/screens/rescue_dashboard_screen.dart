// lib/screens/rescuer_dashboard_screen.dart
import 'package:flutter/material.dart';
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
  Assignment? _currentTask;

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
          _assignments = data;
          try {
            _currentTask = data.firstWhere(
                  (t) => ['assigned', 'in_progress', 'arrived'].contains(t.status),
            );
          } catch (e) {
            _currentTask = null;
          }
        });
      }
    } catch (e) {
      print("Lỗi tải nhiệm vụ: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String action) async {
    if (_currentTask == null) return;

    setState(() => _isLoading = true);
    bool success = false;

    try {
      if (action == 'start') {
        success = await AssignService.confirmStart(_currentTask!.id);
      } else if (action == 'arrived') {
        success = await AssignService.confirmArrived(_currentTask!.id);
      } else if (action == 'complete') {
        final note = await _showCompletionDialog();
        if (note != null) {
          success = await AssignService.completeTask(_currentTask!.id, note);
        } else {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
        _loadAssignments();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Có lỗi xảy ra, vui lòng thử lại.")));
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showCompletionDialog() async {
    String note = "";
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Báo cáo kết quả"),
        content: TextField(
          onChanged: (v) => note = v,
          decoration: const InputDecoration(
            hintText: "Nhập ghi chú (VD: Đã đưa nạn nhân đến BV...)",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, note), child: const Text("HOÀN TẤT")),
        ],
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _openMap(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    }
  }

  void _logout() {
    AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("ĐỘI CỨU HỘ", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssignments),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentTask != null
          ? _buildActiveTaskView()
          : _buildEmptyState(),
    );
  }

  Widget _buildActiveTaskView() {
    final task = _currentTask!;

    String btnText = "";
    Color btnColor = Colors.grey;
    String action = "";
    String statusText = "";

    switch (task.status) {
      case 'assigned':
        btnText = "BẮT ĐẦU XUẤT PHÁT";
        btnColor = Colors.orange.shade700;
        action = 'start';
        statusText = "Đã nhận lệnh";
        break;
      case 'in_progress':
        btnText = "ĐÃ ĐẾN HIỆN TRƯỜNG";
        btnColor = Colors.blue.shade700;
        action = 'arrived';
        statusText = "Đang di chuyển";
        break;
      case 'arrived':
        btnText = "HOÀN THÀNH NHIỆM VỤ";
        btnColor = Colors.green.shade700;
        action = 'complete';
        statusText = "Tại hiện trường";
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: btnColor.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: btnColor.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Text("TRẠNG THÁI HIỆN TẠI", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(statusText.toUpperCase(), style: TextStyle(color: btnColor, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[900]),
                      const SizedBox(width: 10),
                      const Text("THÔNG TIN NẠN NHÂN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 30),
                  _buildRow("Họ tên:", task.victimName),
                  const SizedBox(height: 12),
                  _buildPhoneRow(task.victimPhone),
                  const SizedBox(height: 12),
                  _buildRow("Địa chỉ:", task.address),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Tình trạng:", style: TextStyle(color: Colors.red[900], fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          task.conditions.join(', '),
                          style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: () => _updateStatus(action),
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              child: Text(btnText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () => _openMap(task.latitude, task.longitude),
            icon: const Icon(Icons.map),
            label: const Text("Mở bản đồ chỉ đường"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 100, color: Colors.green[200]),
          const SizedBox(height: 20),
          const Text("Không có nhiệm vụ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text("Đội đang ở trạng thái sẵn sàng (Standby)", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _loadAssignments,
            icon: const Icon(Icons.refresh),
            label: const Text("Kiểm tra lại"),
          )
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildPhoneRow(String phone) {
    return Row(
      children: [
        const SizedBox(width: 80, child: Text("SĐT:", style: TextStyle(color: Colors.grey))),
        InkWell(
          onTap: () => _makePhoneCall(phone),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(phone, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}