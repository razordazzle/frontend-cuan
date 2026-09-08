import 'dart:async';

import 'dart:convert';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class LivePricesWS {
  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  bool _disposed = false;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void connect(Uri uri) {
    if (_disposed) return;

    _ch = WebSocketChannel.connect(uri);

    _sub = _ch!.stream.listen(
      (event) {
        try {
          final msg = jsonDecode(event as String);
          if (msg is Map<String, dynamic>) {
            _controller.add(msg);
          }
        } catch (_) {
          // ignore parsing errors
        }
      },
      onError: (_) {},
      onDone: () {},
      cancelOnError: false,
    );
  }

  void close() {
    _disposed = true;
    _sub?.cancel();
    _sub = null;
    _ch?.sink.close(status.normalClosure);
    _ch = null;
    _controller.close();
  }
}
