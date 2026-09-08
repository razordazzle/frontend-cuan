class RegisterResponse {
  final String userId;
  final String email;

  RegisterResponse({required this.userId, required this.email});

  factory RegisterResponse.fromJson(Map<String, dynamic> j) => RegisterResponse(
    userId: j['user_id'] as String,
    email: j['email'] as String,
  );
}
