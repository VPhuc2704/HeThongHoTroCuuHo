class RescueTeamModel {
  final String id;
  final String name;
  final String leaderName;
  final String contactPhone;
  final String hotline;
  final String teamType;
  final String address;
  final String status;
  final double latitude;
  final double longitude;

  RescueTeamModel({
    required this.id,
    required this.name,
    required this.leaderName,
    required this.contactPhone,
    required this.hotline,
    required this.teamType,
    required this.address,
    required this.status,
    required this.latitude,
    required this.longitude,
  });

  factory RescueTeamModel.fromJson(Map<String, dynamic> json) {
    return RescueTeamModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Đội cứu hộ',
      leaderName: json['leader_name'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      hotline: json['hotline'] ?? '',
      teamType: json['team_type'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? 'inactive',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
}