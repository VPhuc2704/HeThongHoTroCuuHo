import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/assign_service.dart';

class RescueRequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;

  const RescueRequestDetailScreen({super.key, required this.request});

  @override
  State<RescueRequestDetailScreen> createState() => _RescueRequestDetailScreenState();
}

class _RescueRequestDetailScreenState extends State<RescueRequestDetailScreen> {
  late String _currentStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.request['status'] ?? 'assigned';
  }

  // --- LOGIC XỬ LÝ (GIỮ NGUYÊN) ---
  Future<void> _handleAction(String action) async {
    setState(() => _isLoading = true);
    final String assignmentId = widget.request['id'].toString();
    bool success = false;

    try {
      if (action == 'start') {
        success = await AssignService.confirmStart(assignmentId);
        if (success) setState(() => _currentStatus = 'in_progress');
      } else if (action == 'arrived') {
        success = await AssignService.confirmArrived(assignmentId);
        if (success) setState(() => _currentStatus = 'arrived');
      } else if (action == 'complete') {
        final note = await _showCompletionDialog();
        if (note != null) {
          success = await AssignService.completeTask(assignmentId, note);
          if (success) setState(() => _currentStatus = 'completed');
        } else {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (success && mounted) {
        if (action == 'complete') Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
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
        title: const Text("Kết quả nhiệm vụ"),
        content: TextField(
          autofocus: true,
          onChanged: (v) => note = v,
          decoration: InputDecoration(
            hintText: "Nhập ghi chú...",
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

  void _makePhoneCall() async {
    final phone = widget.request['contact_phone'] ?? widget.request['victimPhone'];
    if (phone != null) {
      final Uri launchUri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
    }
  }

  // --- GIAO DIỆN CHÍNH ---
  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    // Parse dữ liệu an toàn
    final double lat = (req['latitude'] is String) ? double.parse(req['latitude']) : (req['latitude'] as num).toDouble();
    final double lng = (req['longitude'] is String) ? double.parse(req['longitude']) : (req['longitude'] as num).toDouble();
    final String name = req['name'] ?? 'N/A';
    final String address = req['address'] ?? 'N/A';

    // Lấy thông tin nhân khẩu (Mặc định 0 nếu null)
    final int adults = req['adults'] ?? 0;
    final int children = req['children'] ?? 0;
    final int elderly = req['elderly'] ?? 0;

    final List conditions = req['conditions'] is List ? req['conditions'] : [];
    final String timeStr = req['created_at'] ?? req['assigned_at'] ?? DateTime.now().toIso8601String();
    final DateTime time = DateTime.parse(timeStr);
    final DateFormat formatter = DateFormat('HH:mm - dd/MM/yyyy');

    // Cấu hình màu sắc
    Color statusColor = Colors.grey;
    String statusText = "KHÔNG RÕ";
    String btnLabel = "";
    IconData btnIcon = Icons.check;
    String nextAction = "";

    if (_currentStatus == 'assigned') {
      statusColor = Colors.orange; statusText = "ĐÃ NHẬN LỆNH";
      btnLabel = "XUẤT PHÁT"; btnIcon = Icons.near_me; nextAction = 'start';
    } else if (_currentStatus == 'in_progress') {
      statusColor = Colors.blue; statusText = "ĐANG DI CHUYỂN";
      btnLabel = "ĐÃ ĐẾN NƠI"; btnIcon = Icons.place; nextAction = 'arrived';
    } else if (_currentStatus == 'arrived') {
      statusColor = Colors.purple; statusText = "TẠI HIỆN TRƯỜNG";
      btnLabel = "HOÀN THÀNH"; btnIcon = Icons.assignment_turned_in; nextAction = 'complete';
    } else if (_currentStatus == 'completed') {
      statusColor = Colors.green; statusText = "HOÀN THÀNH";
    } else if (_currentStatus == 'cancelled') {
      statusColor = Colors.red; statusText = "ĐÃ HỦY";
    }

    final bool isActionable = ['assigned', 'in_progress', 'arrived'].contains(_currentStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám nhạt hiện đại
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. HEADER BẢN ĐỒ
              SliverAppBar(
                expandedHeight: 240.0,
                pinned: true,
                backgroundColor: statusColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 15),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                          MarkerLayer(markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 60, height: 60,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                            ),
                          ]),
                        ],
                      ),
                      // Lớp phủ mờ để map không quá gắt
                      Container(color: Colors.black.withOpacity(0.1)),
                    ],
                  ),
                ),
              ),

              // 2. NỘI DUNG CHI TIẾT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CARD 1: THÔNG TIN TRẠNG THÁI & NẠN NHÂN ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Text(formatter.format(time), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                            const Divider(height: 30),
                            Row(
                              children: [
                                CircleAvatar(radius: 25, backgroundColor: Colors.blue.shade50, child: const Icon(Icons.person, color: Colors.blue)),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(req['contact_phone'] ?? "Không có SĐT", style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                                if (isActionable)
                                  IconButton(
                                    onPressed: _makePhoneCall,
                                    icon: const Icon(Icons.phone),
                                    style: IconButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  )
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- CARD 2: CHI TIẾT SỰ CỐ (QUAN TRỌNG) ---
                      const Text("CHI TIẾT SỰ CỐ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Thống kê người (Adults/Children/Elderly)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildPeopleCount(Icons.person, "Người lớn", adults, Colors.blue),
                                Container(width: 1, height: 30, color: Colors.grey[200]),
                                _buildPeopleCount(Icons.child_care, "Trẻ em", children, Colors.orange),
                                Container(width: 1, height: 30, color: Colors.grey[200]),
                                _buildPeopleCount(Icons.elderly, "Người già", elderly, Colors.purple),
                              ],
                            ),
                            const Divider(height: 30),

                            // 2. Tình trạng (Tags)
                            if (conditions.isNotEmpty) ...[
                              const Text("Tình trạng:", style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: conditions.map((c) => Chip(
                                  label: Text(c.toString(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                                  backgroundColor: Colors.redAccent,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                )).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 3. Mô tả & Địa chỉ
                            _buildInfoRow(Icons.description, "Mô tả", req['description'] ?? "Không có mô tả"),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.location_on, "Địa chỉ", address),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100), // Khoảng trống cho nút bấm
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. NÚT HÀNH ĐỘNG DƯỚI CÙNG
          if (isActionable)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                ),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _handleAction(nextAction),
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(btnIcon),
                    label: Text(btnLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET CON (HELPER) ---

  // Widget hiển thị số lượng người
  Widget _buildPeopleCount(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text("$count", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      ],
    );
  }

  // Widget hiển thị dòng thông tin
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}