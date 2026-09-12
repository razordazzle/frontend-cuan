import 'dart:convert';
import 'dart:js_interop';
import 'web_message_listener_stub.dart';

@JS('window.addEventListener')
external void _addEventListener(String type, JSFunction listener);

@JS()
extension type _MessageEvent(JSObject _) implements JSObject {
  external JSAny? get data;
}

void listenToWebMessages(WebMessageCallback callback) {
  _addEventListener(
    'message',
    ((_MessageEvent event) {
      try {
        final JSAny? rawJSAny = event.data;
        if (rawJSAny == null) return;
        final Object? rawData = rawJSAny.dartify();
        if (rawData == null) return;
        final Map<String, dynamic> data = rawData is String
            ? (jsonDecode(rawData) as Map<String, dynamic>)
            : (rawData is Map
                ? Map<String, dynamic>.from(rawData)
                : <String, dynamic>{});
        final String? type = data['type'] as String?;
        if (type != null) {
          callback(type, data['payload']);
        }
      } catch (_) {}
    }).toJS,
  );
}
