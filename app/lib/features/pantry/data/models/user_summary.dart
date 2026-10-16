class UserSummary {
  const UserSummary({
    required this.id,
    required this.username,
  });

  final int id;
  final String username;

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    if (json case {'id': final int id, 'username': final String username}) {
      return UserSummary(id: id, username: username);
    }
    throw const FormatException('Invalid user');
  }
}
