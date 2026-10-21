/// Respons POST /auth/login: password benar, tapi token akses baru ada setelah OTP terverifikasi.
class OtpLoginResponse {
  /// Hanya diterima /auth/otp/request; ditolak semua endpoint lain.
  final String otpToken;

  /// Batas waktu (detik) menyelesaikan OTP.
  final int expiresIn;

  /// Sudah disamarkan server, mis. "+62****890"; null kalau akun tak punya nomor.
  final String? phone;

  const OtpLoginResponse({
    required this.otpToken,
    required this.expiresIn,
    this.phone,
  });

  factory OtpLoginResponse.fromJson(Map<String, dynamic> json) =>
      OtpLoginResponse(
        otpToken: json['otp_token'] as String,
        expiresIn: (json['expires_in'] as num).toInt(),
        phone: json['phone'] as String?,
      );
}
