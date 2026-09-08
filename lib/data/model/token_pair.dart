class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    // backend kamu kirim "Access_token", "Refresh_token", "expires_in"
    // tapi untuk jaga-jaga, fallback ke lowercase juga.
    final access = (json['Access_token'] ?? json['access_token']) as String? ?? '';
    final refresh = (json['Refresh_token'] ?? json['refresh_token']) as String? ?? '';

    final raw = json['expires_in'];
    final expires = raw is int
        ? raw
        : raw is num
            ? raw.toInt()
            : raw is String
                ? int.tryParse(raw) ?? 0
                : 0;

    return TokenPair(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: expires,
    );
  }

  Map<String, dynamic> toJson() => {
        'Access_token': accessToken,
        'Refresh_token': refreshToken,
        'expires_in': expiresIn,
      };
}
