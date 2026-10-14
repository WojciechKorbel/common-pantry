class AuthTokens {
  const AuthTokens({
    required this.access,
    required this.refresh,
  });

  final String access;
  final String refresh;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final access = json['access'];
    final refresh = json['refresh'];

    if (access is! String || access.isEmpty || refresh is! String || refresh.isEmpty) {
      throw const FormatException(
        'Invalid authentication response',
      );
    }

    return AuthTokens(
      access: access,
      refresh: refresh,
    );
  }
}
