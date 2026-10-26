import 'dart:convert';
import 'dart:typed_data';

import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/core/token_refresher.dart';
import 'package:cuan_app/data/core/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage extends TokenStorage {
  _FakeStorage({this.access, this.refresh});
  String? access;
  String? refresh;

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<String?> getAccess() async => access;

  @override
  Future<String?> getRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

typedef _Reply = ({int status, Object? body});

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final _Reply Function(RequestOptions) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // jeda kecil supaya request bersamaan benar-benar tumpang tindih
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final r = handler(options);
    return ResponseBody.fromString(
      jsonEncode(r.body),
      r.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _ok = (status: 200, body: {'ok': true});
const _unauthorized = (status: 401, body: {'detail': 'x'});

/// Dio utama (dengan interceptor) + Dio khusus refresh, keduanya ke "server" palsu yang sama.
({Dio dio, _FakeStorage storage, List<RequestOptions> refreshCalls}) _setup({
  String? access = 'old',
  String? refresh = 'r1',
  _Reply Function(RequestOptions)? onRefreshCall,
}) {
  final storage = _FakeStorage(access: access, refresh: refresh);
  final refreshCalls = <RequestOptions>[];

  _Reply server(RequestOptions o) {
    if (o.path == '/auth/refresh') {
      refreshCalls.add(o);
      return onRefreshCall != null
          ? onRefreshCall(o)
          : (status: 200, body: {'Access_token': 'new', 'expires_in': 3600});
    }
    if (o.path == '/auth/login') return _unauthorized;
    return o.headers['Authorization'] == 'Bearer new' ? _ok : _unauthorized;
  }

  final refreshDio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = _Adapter(server);
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = _Adapter(server);
  final interceptor = AuthInterceptor(
    storage: storage,
    onRefresh: (_) => TokenRefresher.refresh(storage, client: refreshDio),
  );
  dio.interceptors.add(interceptor);
  interceptor.attach(dio);
  return (dio: dio, storage: storage, refreshCalls: refreshCalls);
}

void main() {
  test('401 -> refresh dengan field Refresh_token -> request diulang dengan token baru', () async {
    final t = _setup();
    final res = await t.dio.get('/users/me');

    expect(res.statusCode, 200);
    expect(t.refreshCalls, hasLength(1));
    // backend meminta "Refresh_token" (R besar); "refresh_token" dulu bikin 422 dan user ter-logout
    expect(t.refreshCalls.single.data, {'Refresh_token': 'r1'});
    expect(t.storage.access, 'new');
    expect(t.storage.refresh, 'r1');
  });

  test('tiga request 401 bersamaan hanya memanggil refresh sekali', () async {
    final t = _setup();
    final results = await Future.wait([
      t.dio.get('/a'),
      t.dio.get('/b'),
      t.dio.get('/c'),
    ]);

    expect(results.map((r) => r.statusCode), [200, 200, 200]);
    expect(t.refreshCalls, hasLength(1));
  });

  test('refresh token ditolak server (401): token dihapus, error 401 diteruskan', () async {
    final t = _setup(onRefreshCall: (_) => _unauthorized);

    await expectLater(
      t.dio.get('/users/me'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );
    expect(t.storage.access, isNull);
    expect(t.storage.refresh, isNull);
  });

  test('refresh gagal karena server error (500) atau 422: token TIDAK dihapus', () async {
    for (final status in [500, 422]) {
      final t = _setup(onRefreshCall: (_) => (status: status, body: {'detail': 'x'}));
      await expectLater(t.dio.get('/users/me'), throwsA(isA<DioException>()));
      expect(t.storage.refresh, 'r1', reason: 'status $status');
      expect(t.storage.access, 'old', reason: 'status $status');
    }
  });

  test('login yang 401 (password salah) tidak memicu refresh dan tidak menghapus token', () async {
    final t = _setup(access: 'otp-ticket', refresh: 'r1');

    await expectLater(t.dio.post('/auth/login'), throwsA(isA<DioException>()));
    expect(t.refreshCalls, isEmpty);
    expect(t.storage.access, 'otp-ticket');
  });

  test('tanpa refresh token (mis. sesudah login, sebelum OTP) tidak memanggil refresh', () async {
    final t = _setup(refresh: '');

    await expectLater(t.dio.get('/users/me'), throwsA(isA<DioException>()));
    expect(t.refreshCalls, isEmpty);
    expect(t.storage.access, 'old');
  });

  test('request yang tetap 401 sesudah refresh tidak masuk lingkaran refresh', () async {
    // server menolak token baru juga
    final storage = _FakeStorage(access: 'old', refresh: 'r1');
    var refreshCount = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = _Adapter((o) {
        if (o.path == '/auth/refresh') {
          refreshCount++;
          return (status: 200, body: {'Access_token': 'new', 'expires_in': 3600});
        }
        return _unauthorized; // selalu 401
      });
    final interceptor = AuthInterceptor(
      storage: storage,
      onRefresh: (_) => TokenRefresher.refresh(storage, client: dio),
    );
    dio.interceptors.add(interceptor);
    interceptor.attach(dio);

    await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));
    expect(refreshCount, 1);
  });
}
