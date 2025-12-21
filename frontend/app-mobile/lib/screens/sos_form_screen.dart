import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Import để check kIsWeb
import '../models/rescue_request.dart';
import '../services/province_service.dart';
import '../services/request_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class SOSFormScreen extends StatefulWidget {
  const SOSFormScreen({super.key});

  @override
  State<SOSFormScreen> createState() => _SOSFormScreenState();
}

class _SOSFormScreenState extends State<SOSFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Style Constants
  final Color _primaryColor = const Color(0xFFD32F2F); // Đỏ đậm hơn chút cho SOS
  final Color _backgroundColor = const Color(0xFFF2F4F8);
  final double _sectionSpacing = 24.0;

  // Data Variables
  int _adults = 1;
  int _children = 0;
  int _elderly = 0;

  String? _selectedProvince;
  double? _latitude;
  double? _longitude;
  String? _address;

  final List<String> _selectedConditions = [];
  final List<XFile> _selectedImages = []; // Dùng XFile cho cả Web & Mobile

  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  final List<String> _availableConditions = [
    'Cấp cứu y tế', 'Đau ngực', 'Té ngã', 'Không di chuyển được',
    'Tai nạn giao thông', 'Chấn thương nặng', 'Hỏa hoạn', 'Mắc kẹt',
    'Khó thở', 'Bất tỉnh', 'Chảy máu', 'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadUserInfo() {
    final user = AuthService.getCurrentUser();
    if (user != null) {
      _nameController.text = user['name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
    }
  }

  // --- LOCATION LOGIC ---
  // --- LOCATION LOGIC (ĐÃ SỬA LỖI) ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final location = await LocationService.getCurrentLocation();

      // SỬA: Thêm dấu chấm than (!) hoặc ép kiểu để đảm bảo không null
      final double lat = location['latitude'] ?? 0.0;
      final double lng = location['longitude'] ?? 0.0;

      final addressText = "Toạ độ: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";

      if (mounted) {
        setState(() {
          _latitude = lat;
          _longitude = lng;
          _address = addressText;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Không lấy được vị trí: $e'),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  // --- IMAGE LOGIC ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70); // Giảm chất lượng chút cho nhẹ
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeMedia(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Widget _displayImage(XFile file) {
    if (kIsWeb) {
      return Image.network(file.path, fit: BoxFit.cover);
    } else {
      return Image.file(File(file.path), fit: BoxFit.cover);
    }
  }

  // --- SUBMIT LOGIC ---
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      // Scroll lên đầu hoặc báo lỗi
      return;
    }

    if (_selectedConditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một tình trạng khẩn cấp!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String codeToSend = _selectedProvince ?? 'VN';

      final newRequest = RescueRequest(
        name: _nameController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        code: codeToSend,
        adults: _adults,
        children: _children,
        elderly: _elderly,
        address: _address ?? 'Chưa xác định',
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        conditions: _selectedConditions,
        description: _descriptionController.text.trim(),
        media: [], // Gửi mảng rỗng trước
        requestTime: DateTime.now(),
        status: 'pending',
      );

      // 1. Tạo Request
      final newRequestId = await RequestService.createRequest(newRequest);

      if (newRequestId != null) {
        // 2. Upload Ảnh (Nếu có)
        if (_selectedImages.isNotEmpty) {
          await RequestService.uploadMedia(newRequestId, _selectedImages);
        }

        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSuccessDialog(codeToSend);
        }
      } else {
        throw Exception("Lỗi server: Không tạo được yêu cầu");
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gửi thất bại: $e')));
      }
    }
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Đã gửi thành công!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Đội cứu hộ đang xem xét yêu cầu của bạn.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300)
              ),
              child: Column(
                children: [
                  const Text('MÃ YÊU CẦU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(code, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryColor, letterSpacing: 2)),
                ],
              ),
            )
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Đóng Dialog
                Navigator.of(context).pop(); // Quay về màn hình trước
              },
              child: const Text('HOÀN TẤT'),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Gửi Yêu Cầu Cứu Hộ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWarningBanner(),
              SizedBox(height: _sectionSpacing),

              _buildSectionTitle('1. Thông tin liên hệ & Vị trí'),
              _buildContactCard(),

              SizedBox(height: _sectionSpacing),
              _buildSectionTitle('2. Tình trạng khẩn cấp'),
              _buildConditionCard(),

              SizedBox(height: _sectionSpacing),
              _buildSectionTitle('3. Chi tiết nạn nhân'),
              _buildVictimCard(),

              SizedBox(height: _sectionSpacing),
              _buildSectionTitle('4. Hình ảnh hiện trường'),
              _buildImageCard(),

              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: Colors.white),
      ),
      child: child,
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hãy giữ bình tĩnh! Cung cấp thông tin chính xác giúp chúng tôi tiếp cận bạn nhanh hơn.',
              style: TextStyle(color: Colors.orange[900], fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return _buildCard(
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration('Họ và tên', Icons.person_outline),
            validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Số điện thoại', Icons.phone_outlined),
            validator: (v) => v!.isEmpty ? 'Vui lòng nhập SĐT' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedProvince,
            decoration: _inputDecoration('Tỉnh/Thành phố', Icons.location_city),
            dropdownColor: Colors.white,
            items: ProvinceService.PROVINCE_MAP.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.value,
                child: Text(entry.key),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedProvince = val),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

          // Location Picker
          InkWell(
            onTap: _getCurrentLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: _isLoadingLocation
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vị trí hiện tại', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 4),
                        Text(
                          _address ?? 'Chưa xác định vị trí',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildConditionCard() {
    return _buildCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: _availableConditions.map((condition) {
          final isSelected = _selectedConditions.contains(condition);
          return FilterChip(
            label: Text(condition),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                selected ? _selectedConditions.add(condition) : _selectedConditions.remove(condition);
              });
            },
            selectedColor: _primaryColor.withOpacity(0.1),
            checkmarkColor: _primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? _primaryColor : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: isSelected ? _primaryColor : Colors.transparent),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVictimCard() {
    return _buildCard(
      child: Column(
        children: [
          _buildCounterRow('Người lớn', _adults, (v) => setState(() => _adults = v)),
          const Divider(height: 24),
          _buildCounterRow('Trẻ em', _children, (v) => setState(() => _children = v)),
          const Divider(height: 24),
          _buildCounterRow('Người già', _elderly, (v) => setState(() => _elderly = v)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: _inputDecoration('Mô tả thêm (Tình trạng, vết thương...)', Icons.note_add_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                icon: Icon(Icons.remove, color: value > 0 ? Colors.black87 : Colors.grey),
                iconSize: 20,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(
                onPressed: () => onChanged(value + 1),
                icon: const Icon(Icons.add, color: Colors.black87),
                iconSize: 20,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildImageCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedImages.isNotEmpty)
            Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, index) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _displayImage(_selectedImages[index]),
                        ),
                      ),
                      Positioned(
                        top: -8, right: -8,
                        child: GestureDetector(
                          onTap: () => _removeMedia(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Thêm ảnh / Chụp ảnh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(color: _primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: _primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSubmitting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded),
            SizedBox(width: 10),
            Text('GỬI YÊU CẦU CỨU HỘ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[500]),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}