// screens/user_home_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'sos_form_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isPressed = false;
  double _pressProgress = 0.0; // 0.0 đến 1.0

  // Animation cho hiệu ứng lan tỏa (Pulse)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Hiệu ứng nhịp tim/lan tỏa nhẹ nhàng
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onSOSPressed() {
    // Reset trạng thái
    setState(() {
      _isPressed = false;
      _pressProgress = 0.0;
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SOSFormScreen()),
    );
  }

  // Xử lý khi bắt đầu nhấn giữ
  void _startHolding() async {
    setState(() => _isPressed = true);

    // Giả lập vòng lặp 30 lần (3 giây), mỗi lần 100ms
    for (int i = 0; i <= 30; i++) {
      if (!_isPressed) return; // Nếu thả tay ra thì dừng lại

      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        setState(() => _pressProgress = i / 30);
      }

      if (i == 30 && _isPressed) {
        _onSOSPressed(); // Hoàn thành 3 giây -> Gọi SOS
      }
    }
  }

  // Xử lý khi thả tay ra
  void _stopHolding() {
    if (_pressProgress < 1.0) {
      setState(() {
        _isPressed = false;
        _pressProgress = 0.0;
      });
    }
  }

  void _logout() {
    AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    final primaryRed = const Color(0xFFE53935);

    return Scaffold(
      backgroundColor: Colors.white, // Nền sáng sạch sẽ
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. HEADER & LOCATION ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${user?['name'] ?? 'Bạn'}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: primaryRed),
                              const SizedBox(width: 4),
                              Text(
                                'Vị trí: Đang cập nhật...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.grey),
                        tooltip: 'Đăng xuất',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // --- 2. BIG SOS BUTTON ---
            Column(
              children: [
                GestureDetector(
                  onLongPressStart: (_) => _startHolding(),
                  onLongPressEnd: (_) => _stopHolding(),
                  onLongPressCancel: () => _stopHolding(), // Trường hợp trượt tay ra ngoài
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Vòng lan tỏa (Pulse Effect)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 200 * _pulseAnimation.value,
                            height: 200 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryRed.withOpacity(0.1 * (1.3 - _pulseAnimation.value)),
                            ),
                          );
                        },
                      ),

                      // Vòng tròn Progress (chạy khi giữ)
                      SizedBox(
                        width: 230,
                        height: 230,
                        child: CircularProgressIndicator(
                          value: _pressProgress,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                        ),
                      ),

                      // Nút chính
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: _isPressed ? primaryRed.withOpacity(0.9) : primaryRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryRed.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sos_rounded, size: 60, color: Colors.white),
                            const SizedBox(height: 5),
                            Text(
                              _isPressed ? 'GIỮ TAY...' : 'NHẤN GIỮ\n3 GIÂY',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  height: 1.2
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _isPressed
                      ? 'Đang gửi tín hiệu khẩn cấp...'
                      : 'Giữ nút đỏ để gửi tín hiệu SOS khẩn cấp',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // --- 3. QUICK ACTION BUTTONS ---
            // Các nút tắt cho tình huống cụ thể
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HỖ TRỢ NHANH',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(Icons.medical_services, 'Cấp cứu', Colors.blue),
                      _buildQuickAction(Icons.local_fire_department, 'Cứu hỏa', Colors.orange),
                      _buildQuickAction(Icons.local_police, 'Cảnh sát', Colors.indigo),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // --- 4. BOTTOM NAVIGATION ---
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/user-history');
          } else {
            setState(() => _currentIndex = index);
          }
        },
        backgroundColor: Colors.white,
        elevation: 1,
        indicatorColor: primaryRed.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFFE53935)),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFFE53935)),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFE53935)),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  // Widget con cho nút thao tác nhanh
  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        // Logic xử lý nhanh (ví dụ: tự động điền loại sự cố)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SOSFormScreen()), // Có thể truyền tham số loại sự cố vào đây
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}