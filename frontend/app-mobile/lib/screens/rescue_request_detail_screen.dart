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
  State<RescueRequestDetailScreen> createState() =>
      _RescueRequestDetailScreenState();
}

class _RescueRequestDetailScreenState extends State<RescueRequestDetailScreen> {
  late String _currentStatus;
  bool _isLoading = false;

  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.request['status'] ?? 'assigned';
  }

  // --- LOGIC XỬ LÝ (GIỮ NGUYÊN KHÔNG ĐỔI) ---
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
        _hasChanged = true;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cập nhật thành công!")));

        if (action == 'complete') Navigator.pop(context, true);

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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, note),
              child: const Text("HOÀN TẤT")),
        ],
      ),
    );
  }

  void _makePhoneCall() async {
    final phone =
        widget.request['contact_phone'] ?? widget.request['victimPhone'];
    if (phone != null) {
      final Uri launchUri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
    }
  }

  // --- UI ĐƯỢC LÀM MỚI ---
  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    // Parse data
    final double lat = (req['latitude'] is String)
        ? double.parse(req['latitude'])
        : (req['latitude'] as num).toDouble();
    final double lng = (req['longitude'] is String)
        ? double.parse(req['longitude'])
        : (req['longitude'] as num).toDouble();

    // Status Logic
    Color themeColor = Colors.grey;
    String statusText = "KHÔNG RÕ";
    String btnLabel = "";
    IconData btnIcon = Icons.check;
    String nextAction = "";
    IconData statusIcon = Icons.info;

    if (_currentStatus == 'assigned') {
      themeColor = Colors.orange.shade700;
      statusText = "ĐÃ NHẬN LỆNH";
      btnLabel = "BẮT ĐẦU XUẤT PHÁT";
      btnIcon = Icons.near_me;
      nextAction = 'start';
      statusIcon = Icons.assignment_turned_in;
    } else if (_currentStatus == 'in_progress') {
      themeColor = Colors.blue.shade700;
      statusText = "ĐANG DI CHUYỂN";
      btnLabel = "XÁC NHẬN ĐÃ ĐẾN";
      btnIcon = Icons.location_on;
      nextAction = 'arrived';
      statusIcon = Icons.directions_car;
    } else if (_currentStatus == 'arrived') {
      themeColor = Colors.green.shade700;
      statusText = "TẠI HIỆN TRƯỜNG";
      btnLabel = "HOÀN THÀNH NHIỆM VỤ";
      btnIcon = Icons.check_circle;
      nextAction = 'complete';
      statusIcon = Icons.medical_services;
    } else if (_currentStatus == 'completed') {
      themeColor = Colors.teal;
      statusText = "ĐÃ HOÀN THÀNH";
      statusIcon = Icons.flag;
    } else if (_currentStatus == 'cancelled') {
      themeColor = Colors.red;
      statusText = "ĐÃ HỦY";
      statusIcon = Icons.cancel;
    }

    final bool isActionable =
    ['assigned', 'in_progress', 'arrived'].contains(_currentStatus);

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND MAP (Full Screen)
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.4, // Map chiếm phần trên
            child: FlutterMap(
              options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all)
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Icon(Icons.location_on, color: themeColor, size: 50),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)]
                          ),
                          child: const Text("Vị trí cứu hộ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // 2. BACK BUTTON (Floating Top Left)
          Positioned(
            top: 50,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.pop(context, _hasChanged),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
          ),

          // 3. DRAGGABLE SHEET / CONTENT AREA
          // Dùng DraggableScrollableSheet để có hiệu ứng kéo lên kéo xuống mượt mà
          DraggableScrollableSheet(
            initialChildSize: 0.6, // Mặc định che 60% màn hình
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh kéo (Handle bar)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      // --- Header Trạng thái ---
                      Row(
                        children: [
                          Icon(statusIcon, color: themeColor, size: 28),
                          const SizedBox(width: 10),
                          Text(statusText,
                              style: TextStyle(
                                  color: themeColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- Card Thông tin Nạn nhân ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue[50],
                              child: Icon(Icons.person, size: 32, color: Colors.blue[800]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(req['name'] ?? 'Chưa rõ tên',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(req['contact_phone'] ?? 'Không có SĐT',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            if (isActionable)
                              ElevatedButton(
                                onPressed: _makePhoneCall,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(14),
                                  elevation: 4,
                                ),
                                child: const Icon(Icons.phone, color: Colors.white),
                              )
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text("CHI TIẾT SỰ CỐ",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 10),

                      // --- Grid Thống kê người ---
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(Icons.person, "Người lớn", req['adults'], Colors.blue)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildStatCard(Icons.child_care, "Trẻ em", req['children'], Colors.orange)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildStatCard(Icons.elderly, "Người già", req['elderly'], Colors.purple)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // --- Thông tin chi tiết (Địa chỉ & Mô tả) ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Column(
                          children: [
                            // Địa chỉ
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Địa chỉ sự cố", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                      const SizedBox(height: 2),
                                      Text(req['address'] ?? "Chưa xác định",
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

                            // Tình trạng & Mô tả
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.description_outlined, color: Colors.amber),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Tình trạng & Mô tả", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                      const SizedBox(height: 8),
                                      // Tags
                                      if (req['conditions'] != null && (req['conditions'] as List).isNotEmpty)
                                        Wrap(
                                          spacing: 6, runSpacing: 6,
                                          children: (req['conditions'] as List).map((c) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.red.withOpacity(0.2))
                                            ),
                                            child: Text(c.toString(), style: TextStyle(color: Colors.red[800], fontSize: 12, fontWeight: FontWeight.bold)),
                                          )).toList(),
                                        ),
                                      const SizedBox(height: 8),
                                      Text(req['description'] ?? "Không có mô tả thêm",
                                          style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Khoảng trống để không bị nút che mất nội dung cuối
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              );
            },
          ),

          // 4. ACTION BUTTON (Sticky Bottom)
          if (isActionable)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _handleAction(nextAction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: themeColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(btnIcon),
                  label: Text(btnLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget Helper nhỏ gọn
  Widget _buildStatCard(IconData icon, String label, dynamic count, Color color) {
    final int val = count ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(val.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }
}