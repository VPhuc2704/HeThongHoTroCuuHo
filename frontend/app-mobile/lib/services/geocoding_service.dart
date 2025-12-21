// services/geocoding_service.dart
class GeocodingService {
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    // Mock reverse geocoding
    await Future.delayed(const Duration(milliseconds: 500));

    // Simple mock based on coordinates
    if (latitude > 10.7 &&
        latitude < 10.9 &&
        longitude > 106.6 &&
        longitude < 106.8) {
      return '123 Main St, District 1, Ho Chi Minh City';
    } else if (latitude > 21.0 &&
        latitude < 21.1 &&
        longitude > 105.8 &&
        longitude < 105.9) {
      return '456 Oak Ave, Ba Dinh, Hanoi';
    }

    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}
