import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/request_service.dart';

class UserRequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;

  const UserRequestDetailScreen({super.key, required this.request});

  @override
  State<UserRequestDetailScreen> createState() => _UserRequestDetailScreenState();
}

class _UserRequestDetailScreenState extends State<UserRequestDetailScreen> {
  final Color _primaryColor = const Color(0xFFE53935);
  bool _isCancelling = false;

  // --- HÀM XỬ LÝ URL ẢNH (QUAN TRỌNG: FIX LỖI KHÔNG HIỆN ẢNH) ---
  String _getValidImageUrl(String path) {
    if (path.startsWith('http') || path.startsWith('https')) {
      return path;
    }

    String baseUrl = RequestService.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.replaceAll('/api', '');
    }

    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    String cleanPath = path;

    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    if (!cleanPath.startsWith('media/')) {
      cleanPath = 'media/$cleanPath';
    }
    return '$baseUrl/$cleanPath';
  }

  // --- HELPER STATUS ---
  String _normalizeStatus(String? rawStatus) {
    if (rawStatus == null) return 'pending';
    String s = rawStatus.toLowerCase();
    if (s.contains('chờ') || s == 'pending') return 'pending';
    if (s.contains('phân công') || s.contains('điều động') || s == 'in_progress') return 'in_progress';
    if (s.contains('hoàn thành') || s == 'resolved') return 'resolved';
    if (s.contains('hủy') || s == 'cancelled') return 'cancelled';
    return 'pending';
  }

  Color _getStatusBgColor(String? status) {
    switch (_normalizeStatus(status)) {
      case 'resolved': return Colors.green.shade50;
      case 'in_progress': return Colors.orange.shade50;
      case 'cancelled': return Colors.red.shade50;
      default: return Colors.blue.shade50;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (_normalizeStatus(status)) {
      case 'resolved': return Colors.green.shade700;
      case 'in_progress': return Colors.orange.shade800;
      case 'cancelled': return Colors.red.shade700;
      default: return Colors.blue.shade700;
    }
  }

  // --- XỬ LÝ HỦY ---
  Future<void> _handleCancelRequest() async {
    final idToCancel = widget.request['code'] ?? widget.request['id'];
    if (idToCancel == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hủy', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    final success = await RequestService.cancelRequest(idToCancel.toString());
    setState(() => _isCancelling = false);

    if (mounted && success) Navigator.pop(context, true);
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    String displayCode = req['code'] ?? req['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A';
    String rawStatusText = req['status'] ?? 'Chờ xử lý';
    String normalizedStatus = _normalizeStatus(rawStatusText);

    DateTime requestTime = DateTime.now();
    try {
      if (req['created_at'] != null) requestTime = DateTime.parse(req['created_at']);
      else if (req['request_time'] != null) requestTime = DateTime.parse(req['request_time']);
    } catch (_) {}
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

    final double lat = (req['latitude'] is String) ? double.parse(req['latitude']) : (req['latitude'] as num).toDouble();
    final double lng = (req['longitude'] is String) ? double.parse(req['longitude']) : (req['longitude'] as num).toDouble();

    String description = req['description'] ?? req['description_short'] ?? 'Không có mô tả thêm.';
    if (description.isEmpty) description = 'Không có mô tả thêm.';

    List<dynamic> mediaUrls = req['media_urls'] ?? [];
    Map<String, dynamic>? assignment = req['active_assignment'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Chi tiết yêu cầu'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _buildCardDecoration(),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(rawStatusText),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      rawStatusText.toUpperCase(),
                      style: TextStyle(color: _getStatusTextColor(rawStatusText), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('MÃ SỐ: $displayCode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey[800])),
                  const SizedBox(height: 5),
                  Text(dateFormat.format(requestTime), style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (assignment != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: _buildCardDecoration().copyWith(
                    border: Border.all(color: Colors.green.shade200, width: 2),
                    color: Colors.green.shade50
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Colors.green[800]),
                        const SizedBox(width: 8),
                        Text("ĐỘI CỨU HỘ ĐANG ĐẾN!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800], fontSize: 16)),
                      ],
                    ),
                    const Divider(color: Colors.green),
                    _buildInfoRow('Đội', assignment['team_name'] ?? 'Chưa cập nhật'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SĐT Liên hệ', style: TextStyle(color: Colors.grey[600])),
                        InkWell(
                          onTap: () => _makePhoneCall(assignment['team_phone'] ?? ''),
                          child: Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.green[800]),
                              const SizedBox(width: 4),
                              Text(assignment['team_phone'] ?? 'N/A', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800], fontSize: 16)),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),

            // --- VỊ TRÍ & BẢN ĐỒ (ĐÃ SỬA DÙNG CARTODB ĐỂ KHÔNG BỊ CHẶN) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.location_on, 'Vị trí sự cố'),
                  const SizedBox(height: 8),
                  Text(req['address'] ?? 'Không xác định', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 15),
                        children: [
                          TileLayer(
                            // SỬA LẠI MAP: Dùng CartoDB Voyager (Đẹp & Không bị chặn)
                            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.vanphuc.rescuevn',
                          ),
                          MarkerLayer(markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              child: Icon(Icons.location_on, color: _primaryColor, size: 40),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- CHI TIẾT NẠN NHÂN ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildCardDecoration(),
              child: Column(
                children: [
                  _buildSectionHeader(Icons.person, 'Chi tiết nạn nhân'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Người báo tin', req['name'] ?? 'N/A'),
                  const Divider(),
                  _buildInfoRow('SĐT Liên hệ', req['contact_phone'] ?? 'N/A'),
                  const Divider(),
                  _buildInfoRow('Số lượng', '${req['adults']} Lớn · ${req['children']} Trẻ · ${req['elderly']} Già'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- TÌNH TRẠNG & GHI CHÚ ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.medical_services, 'Tình trạng & Ghi chú'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (req['conditions'] != null ? (req['conditions'] as List) : [])
                        .map<Widget>((c) => Chip(
                      label: Text(c, style: TextStyle(color: Colors.red[900], fontSize: 12)),
                      backgroundColor: Colors.red[50],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Mô tả chi tiết:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Text(description, style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- HÌNH ẢNH (ĐÃ SỬA LOGIC URL) ---
            if (mediaUrls.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _buildCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(Icons.image, 'Hình ảnh hiện trường'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: mediaUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          // Dùng hàm _getValidImageUrl mới để fix lỗi đường dẫn
                          String fullUrl = _getValidImageUrl(mediaUrls[index]);

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              fullUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              // Thêm headers này để ép load lại nếu cần (dù cache 304 vẫn hiện)
                              headers: const {'Cache-Control': 'no-cache'},
                              errorBuilder: (ctx, error, stackTrace) {
                                print("Lỗi load ảnh: $fullUrl - $error");
                                return Container(
                                  width: 120, height: 120, color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.broken_image, color: Colors.grey),
                                      const SizedBox(height: 4),
                                      Text("Lỗi ảnh", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            if (normalizedStatus == 'pending')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isCancelling ? null : _handleCancelRequest,
                  icon: _isCancelling
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                      : const Icon(Icons.cancel),
                  label: const Text('HỦY YÊU CẦU'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    elevation: 0,
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primaryColor),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}