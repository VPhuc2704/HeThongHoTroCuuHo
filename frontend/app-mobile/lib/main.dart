// File: lib/main.dart
import 'package:flutter/material.dart';
import 'screens/user_home_screen.dart';
import 'screens/user_history_screen.dart';
import 'screens/user_request_detail_screen.dart';
import 'screens/rescuer_dashboard_screen.dart'; // Import đúng file vừa tạo
import 'screens/rescue_request_detail_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/register_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency SOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.light,
          primary: const Color(0xFFE53935),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE53935),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        // ĐÃ XÓA PHẦN cardTheme GÂY LỖI
        // Flutter sẽ tự dùng giao diện mặc định (vẫn đẹp)

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/user-home': (context) => const UserHomeScreen(),
        '/user-history': (context) => const UserHistoryScreen(),
        '/rescue-dashboard': (context) => RescuerDashboardScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/user-request-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => UserRequestDetailScreen(request: args),
          );
        }
        if (settings.name == '/rescue-request-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => RescueRequestDetailScreen(request: args),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.getCurrentUser();

    // 1. IN LOG RA ĐỂ SOI LỖI
    print("----------- AUTH WRAPPER CHECK -----------");
    print("User Data: $currentUser");

    if (currentUser == null) {
      print("=> Chưa đăng nhập -> Về Login");
      return const LoginScreen();
    }

    // 2. CHUẨN HÓA ROLE (In hoa hết + Xóa khoảng trắng thừa)
    final String role = (currentUser['role'] ?? '').toString().toUpperCase().trim();
    print("=> Role sau khi chuẩn hóa: '$role'");

    // 3. SO SÁNH (Chấp nhận cả RESCUE và RESCUER)
    if (role == 'RESCUE' || role == 'RESCUER') {
      print("=> Role hợp lệ -> Vào màn hình Cứu Hộ");
      return RescuerDashboardScreen();
    }

    print("=> Role khác -> Vào màn hình User thường");
    return const UserHomeScreen();
  }
}