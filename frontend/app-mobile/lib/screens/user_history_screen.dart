// screens/user_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/request_service.dart';
import '../services/auth_service.dart';
import '../models/rescue_request.dart'; // Import model

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  int _currentIndex = 1;
  late Future<List<RescueRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final user = AuthService.getCurrentUser();
    // Gọi hàm async và gán vào biến Future
    _requestsFuture = RequestService.getUserRequests();
  }

  // ... (Giữ nguyên các hàm helper màu sắc _getStatusColor, _getStatusText ...)
  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'resolved': return Colors.green.shade50;
      case 'in_progress': return Colors.orange.shade50;
      case 'cancelled': return Colors.red.shade50;
      default: return Colors.blue.shade50;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'resolved': return Colors.green.shade700;
      case 'in_progress': return Colors.orange.shade800;
      case 'cancelled': return Colors.red.shade700;
      default: return Colors.blue.shade700;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'resolved': return 'Hoàn thành';
      case 'in_progress': return 'Đang xử lý';
      case 'cancelled': return 'Đã hủy';
      default: return 'Chờ tiếp nhận';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lịch sử Cứu hộ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false, // Bỏ nút back mặc định vì có nav bar dưới
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadData();
              });
            },
          ),
        ],
      ),
      // DÙNG FUTURE BUILDER ĐỂ SỬA LỖI
      body: FutureBuilder<List<RescueRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadData();
              });
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildHistoryCard(request);
              },
            ),
          );
        },
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.red.withOpacity(0.1),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Lịch sử'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Chưa có lịch sử cứu hộ nào."));
  }
  Widget _buildHistoryCard(RescueRequest request) {
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

    // Cắt ngắn mã nếu quá dài để hiển thị đẹp hơn
    String displayCode = request.code;
    if (displayCode.length > 8) {
      displayCode = displayCode.substring(0, 8).toUpperCase();
    }

    String displayStatus = request.status.toUpperCase(); // Hiển thị nguyên văn status (Việt/Anh)

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/user-request-detail',
            arguments: request.toJson(),
          ).then((_) => setState(() => _loadData()));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // --- DÒNG 1: MÃ SỐ + TRẠNG THÁI (Sửa lỗi Overflow ở đây) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Dùng Expanded cho phần Text bên trái để nó tự co lại nếu thiếu chỗ
                  Expanded(
                    child: Text(
                      "MÃ: $displayCode",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis, // Thêm dấu ... nếu dài quá
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8), // Khoảng cách an toàn
                  // 2. Container trạng thái giữ nguyên kích thước
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(request.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                        color: _getStatusTextColor(request.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),

              // --- DÒNG 2: THỜI GIAN ---
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                      dateFormat.format(request.requestTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // --- DÒNG 3: ĐỊA CHỈ (Đã có Expanded là đúng) ---
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.address,
                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Cắt bớt nếu địa chỉ quá dài
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}