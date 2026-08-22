import 'dart:async';

class SessionManager {
  static final _controller = StreamController<String>.broadcast();
  static Stream<String> get logoutStream => _controller.stream;

  static void triggerLogout(String message) {
    _controller.add(message);
  }
}
