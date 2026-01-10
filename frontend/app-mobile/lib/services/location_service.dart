// services/location_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart'; // Để dùng biến kIsWeb
import 'package:geolocator/geolocator.dart';

class LocationService {

  static Future<Position> getRescueLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Kiểm tra GPS có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('GPS đang bị tắt. Vui lòng bật GPS.');
    }

    // 2. Kiểm tra quyền truy cập
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Quyền truy cập vị trí bị từ chối.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Quyền vị trí bị chặn vĩnh viễn. Hãy vào Cài đặt để cấp quyền thủ công.');
    }

    // 3. Cấu hình độ chính xác dựa trên nền tảng
    // - Mobile: Cần High để cứu hộ chính xác từng mét.
    // - Web: Cần Medium/Low vì PC không có chip GPS, để High sẽ rất chậm hoặc lỗi.
    LocationSettings locationSettings;

    if (kIsWeb) {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        timeLimit: Duration(seconds: 20), // Mobile chỉ chờ 5s, lâu quá thì báo lỗi để user biết
      );
    }

    // 4. Lấy vị trí
    try {
      return await Geolocator.getCurrentPosition(
          locationSettings: locationSettings
      );
    } catch (e) {
      // Xử lý lỗi Timeout đặc biệt
      if (e.toString().contains("TimeLimitReached")) {
        return Future.error("Không tìm thấy tín hiệu GPS. Hãy ra chỗ thoáng hơn.");
      }
      return Future.error("Lỗi lấy vị trí: $e");
    }
  }
}
