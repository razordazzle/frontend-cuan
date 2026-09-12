typedef WebMessageCallback = void Function(String type, dynamic payload);

void listenToWebMessages(WebMessageCallback callback) {
  // No-op on non-web platforms (Android & iOS use InAppWebView native handlers)
}
