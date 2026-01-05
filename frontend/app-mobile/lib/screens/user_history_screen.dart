// screens/user_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/request_service.dart';
import '../services/auth_service.dart';
import '../models/rescue_request.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  int _currentIndex = 1;
  late Future<List<RescueRequest>> _requestsFuture;

  // 1. BIẾN LƯU TRẠNG THÁI FILTER ĐANG CHỌN
  String _selectedStatus = 'all';

  // Danh sách các tùy chọn lọc
  final List<Map<String, String>> _filterOptions = [
    {'key': 'all', 'label': 'Tất cả'},
    {'key': 'Chờ xử lý', 'label': 'Chờ xử lý'},
    {'key': 'Đang thực hiện', 'label': 'Đang xử lý'},
    {'key': 'Hoàn thành', 'label': 'Hoàn thành'},
    {'key': 'Đã hủy', 'label': 'Đã hủy'},
  ];


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Gọi hàm async và gán vào biến Future
    _requestsFuture = RequestService.getUserRequests();
  }

  // ... (Giữ nguyên các hàm helper màu sắc _getStatusBgColor, _getStatusTextColor ...)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lịch sử Cứu hộ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loadData());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 2. THANH FILTER (Filter Bar)
          _buildFilterBar(),

          // 3. DANH SÁCH DỮ LIỆU
          Expanded(
            child: FutureBuilder<List<RescueRequest>>(
              future: _requestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final allRequests = snapshot.data ?? [];

                // --- LOGIC LỌC DỮ LIỆU TẠI CLIENT ---
                // Nếu chọn 'all' thì lấy hết, ngược lại lọc theo status
                final filteredRequests = _selectedStatus == 'all'
                    ? allRequests
                    : allRequests.where((req) => req.status == _selectedStatus).toList();

                if (filteredRequests.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loadData());
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRequests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final request = filteredRequests[index];
                      return _buildHistoryCard(request);
                    },
                  ),
                );
              },
            ),
          ),
        ],
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

  // --- WIDGET THANH FILTER ---
  Widget _buildFilterBar() {
    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _filterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedStatus == option['key'];

          return ChoiceChip(
            label: Text(option['label']!),
            selected: isSelected,
            onSelected: (bool selected) {
              if (selected) {
                setState(() {
                  _selectedStatus = option['key']!;
                });
              }
            },
            // Style cho chip
            selectedColor: const Color(0xFFE53935).withOpacity(0.1),
            backgroundColor: Colors.grey[100],
            labelStyle: TextStyle(
              color: isSelected ? const Color(0xFFE53935) : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? const Color(0xFFE53935) : Colors.transparent,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            showCheckmark: false, // Bỏ dấu tick mặc định cho gọn
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Không có đơn nào ${_selectedStatus != 'all' ? 'ở trạng thái này' : ''}",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(RescueRequest request) {
    // ... (Giữ nguyên code phần Card của bạn ở đây) ...
    // Để code gọn mình không paste lại phần _buildHistoryCard cũ,
    // bạn giữ nguyên logic hiển thị card như code cũ nhé.
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
    String displayCode = request.code.length > 8 ? request.code.substring(0, 8).toUpperCase() : request.code;
    String displayStatus = request.status.toUpperCase();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/user-request-detail', arguments: request.toJson())
              .then((_) => setState(() => _loadData()));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text("MÃ: $displayCode", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _getStatusBgColor(request.status), borderRadius: BorderRadius.circular(8)),
                    child: Text(displayStatus, style: TextStyle(color: _getStatusTextColor(request.status), fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [Icon(Icons.access_time, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Text(dateFormat.format(request.requestTime), style: TextStyle(color: Colors.grey[600], fontSize: 13))]),
              const SizedBox(height: 4),
              Row(children: [Icon(Icons.location_on, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Expanded(child: Text(request.address, style: TextStyle(color: Colors.grey[800], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis))]),
            ],
          ),
        ),
      ),
    );
  }
}