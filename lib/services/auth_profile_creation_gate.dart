import 'dart:async';

class AuthProfileCreationGate {
  static Completer<void>? _pending;

  static final StreamController<void> _profileCreatedController =
      StreamController<void>.broadcast();

  static Stream<void> get profileCreated => _profileCreatedController.stream;

  static void notifyProfileCreated() {
    _profileCreatedController.add(null);
  }

  static void begin() {
    _pending ??= Completer<void>();
  }

  static Future<void> waitForCompletion() async {
    final pending = _pending;
    if (pending != null) {
      await pending.future;
    }
  }

  static void complete() {
    final pending = _pending;
    _pending = null;

    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
  }
}
