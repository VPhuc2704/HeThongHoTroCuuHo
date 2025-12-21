// services/location_service.dart
class LocationService {
  // Mock location service - In production, use geolocator package
  static Future<Map<String, double>> getCurrentLocation() async {
    // Simulate GPS delay
    await Future.delayed(const Duration(seconds: 2));

    // Return mock location (Ho Chi Minh City center)
    return {
      'latitude': 10.7769 + (DateTime.now().millisecond / 100000),
      'longitude': 106.7009 + (DateTime.now().millisecond / 100000),
    };
  }

  static Future<bool> isLocationServiceEnabled() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  static Future<bool> requestPermission() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
