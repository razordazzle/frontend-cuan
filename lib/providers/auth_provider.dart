import 'package:cuan_app/data/request/register_request.dart';
import 'package:cuan_app/data/request/update_me_request.dart';
import 'package:cuan_app/data/response/me_response.dart';
import 'package:cuan_app/data/services/users_service.dart';
import 'package:cuan_app/pages/launch/otp_insert_page.dart';
import 'package:cuan_app/utils/phone_format.dart';
import 'package:flutter/foundation.dart';
import 'package:cuan_app/data/core/token_storage.dart';
import 'package:cuan_app/data/services/auth_service.dart';

enum AccountExistence { none, email, phone, both }

class AuthProvider extends ChangeNotifier {
  final TokenStorage _storage;
  late final AuthService _auth;
  late final UsersService _users;

  MeResponse? _me;
  bool _loading = false;

  MeResponse? get me => _me;
  bool get loading => _loading;

  AuthProvider(this._storage) {
    _auth = AuthService(_storage);
    _users = UsersService.fromStorage(_storage);
  }

  Future<bool> bootstrap() async {
    try {
      final access = await _storage.getAccess();
      if (access == null) return false;
      _me = await _auth.me();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      await _auth.login(email: email, password: password);
      _me = await _users.me();
      return null; // sukses
    } catch (e) {
      print('LOGIN ERROR >>> $e');
      return 'Login gagal. Cek kredensial / jaringan.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    _me = null;
    notifyListeners();
  }

  // return (challengeId, expiresIn) kalau sukses; null kalau gagal
  // Future<(String, int)?> requestOtp(OtpVerificationType type) async {
  //   try {
  //     final res = await _auth.requestOtp(
  //       type == OtpVerificationType.whatsapp ? 'whatsapp' : 'email',
  //     );
  //     // misal service balikin {challengeId, expiresIn}
  //     return (res.challengeId, res.expiresIn);
  //   } catch (_) {
  //     return null;
  //   }
  // }

  Future<(String, int, String?)?> requestOtp(OtpVerificationType type) async {
    try {
      final kind = (type == OtpVerificationType.whatsapp)
          ? 'whatsapp'
          : 'email';
      final c = await _auth.requestOtp(kind);
      return (c.challengeId, c.expiresIn, c.codeDev);
    } catch (_) {
      return null;
    }
  }

  /// Verifikasi OTP → simpan token via service; refresh profil biar state terisi.
  Future<bool> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    final ok = await _auth.verifyOtp(challengeId: challengeId, code: code);
    if (ok) {
      try {
        _me = await _auth.me(); // optional: tarik profil terbaru
        notifyListeners();
      } catch (_) {
        // abaikan bila /users/me belum siap
      }
    }
    return ok;
  }

  // ====== STATE REGISTER (multi-step) ======
  String? _regName;
  String? _regEmail;
  String? _regPhoneE164;

  void saveRegisterStep1({
    required String name,
    required String email,
    required String phoneRaw,
  }) {
    _regName = name.trim();
    _regEmail = email.trim();
    _regPhoneE164 = toE164ID(phoneRaw);
  }

  void resetRegisterDraft() {
    _regName = _regEmail = _regPhoneE164 = null;
    notifyListeners();
  }

  /// Kembalikan null jika sukses; string pesan jika gagal.
  Future<String?> submitRegister({
    required String password,
    String? username,
    String? birthPlace,
    String? birthDate, // "YYYY-MM-DD"
    String? domicile,
    bool autoLogin = false, // optional: auto-login setelah register
  }) async {
    if (_regName == null || _regEmail == null || _regPhoneE164 == null) {
      return 'Data pendaftaran belum lengkap.';
    }

    _loading = true;
    notifyListeners();
    try {
      final req = RegisterRequest(
        name: _regName!,
        email: _regEmail!,
        phone: _regPhoneE164!,
        password: password,
        username: username,
        birthPlace: birthPlace,
        birthDate: birthDate,
        domicile: domicile,
      );
      await _auth.register(req);

      // OPTIONAL: auto login setelah register
      if (autoLogin) {
        await _auth.login(email: _regEmail!, password: password);
        _me = await _auth.me();
      }

      resetRegisterDraft(); // bereskan draft
      return null; // sukses
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> refreshMe() async {
    try {
      _me = await _users.me();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Gagal memuat profil';
    }
  }

  Future<String?> updateProfile(UpdateMeRequest req) async {
    _loading = true;
    notifyListeners();
    try {
      await _users.updateMe(
        name: req.name,
        username: req.username,
        birthPlace: req.birthPlace,
        birthDate: req.birthDate,
        domicile: req.domicile,
        phone: req.phone,
      );
      _me = await _users.me(); // <-- refresh setelah update
      return null;
    } catch (e) {
      return 'Gagal menyimpan profil';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AccountExistence> checkAccountExistence({
    required String email,
    required String phoneRaw,
  }) async {
    final phoneE164 = toE164ID(phoneRaw);
    final res = await _auth.checkAccount(
      email: email.trim(),
      phoneE164: phoneE164,
    );
    final e = res.emailExists;
    final p = res.phoneExists;
    if (e && p) return AccountExistence.both;
    if (e) return AccountExistence.email;
    if (p) return AccountExistence.phone;
    return AccountExistence.none;
  }

  String get displayName {
    final n = _me?.name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final u = _me?.username?.trim();
    if (u != null && u.isNotEmpty) return u;
    final e = _me?.email?.trim();
    if (e != null && e.isNotEmpty) return e.split('@').first;
    return 'User';
  }

  // String? get avatarUrl => _me?.avatarUrl;
}
