class Household {
  const Household({
    required this.id,
    required this.name,
    this.inviteCode,
    this.role,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? inviteCode;
  final String? role;
  final DateTime? createdAt;

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as int,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String?,
      role: json['role'] as String?,
      createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
    );
  }
}
