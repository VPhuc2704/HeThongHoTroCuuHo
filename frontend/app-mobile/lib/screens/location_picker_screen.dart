import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Map miễn phí
import 'package:latlong2/latlong.dart'; // Xử lý tọa độ

class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerScreen({super.key, required this.initialLat, required this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _currentPosition;

  @override
  void initState() {
    super.initState();
    _currentPosition = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chọn vị trí")),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _currentPosition = position.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.vanphuc.rescuevn',
              ),
            ],
          ),
          const Center(child: Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.location_on, size: 50, color: Colors.red))),
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(15)),
              onPressed: () => Navigator.pop(context, _currentPosition),
              child: const Text("XÁC NHẬN VỊ TRÍ", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}