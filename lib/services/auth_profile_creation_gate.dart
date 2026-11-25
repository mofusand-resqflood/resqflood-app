import 'dart:async';

class AuthProfileCreationGate {
  static Completer<void>? _pending;

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
