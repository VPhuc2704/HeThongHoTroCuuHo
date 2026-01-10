class AccountModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String roleName;

  AccountModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.roleName,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'Chưa cập nhật',
      phone: json['phone'] ?? '',
      roleName: json['role'] != null ? json['role']['name'] : 'User',
    );
  }
}