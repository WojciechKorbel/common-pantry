class HouseholdMember {
  const HouseholdMember({
    required this.userId,
    required this.username,
    required this.role,
    this.joinedAt,
    required this.isMe,
  });

  final int userId;
  final String username;
  final String role;
  final DateTime? joinedAt;
  final bool isMe;

  bool get isOwner => role == 'owner';

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      isMe: json['is_me'] as bool? ?? false,
      role: json['role'] as String,
      joinedAt: json['joined_at'] == null ? null : DateTime.tryParse(json['joined_at'] as String),
    );
  }
}

class HouseholdDetails {
  const HouseholdDetails({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.role,
    required this.members,
    this.createdAt,
  });

  final int id;
  final String name;
  final String inviteCode;
  final String role;
  final List<HouseholdMember> members;
  final DateTime? createdAt;

  bool get isOwner => role == 'owner';

  factory HouseholdDetails.fromJson(Map<String, dynamic> json) {
    return HouseholdDetails(
      id: json['id'] as int,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
      members: (json['members'] as List<dynamic>? ?? [])
          .map(
            (item) => HouseholdMember.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
