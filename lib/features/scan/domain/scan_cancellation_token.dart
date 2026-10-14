typedef ScanCancelCallback = void Function();

class ScanCancellationToken {
  bool _isCancelled = false;
  final Set<ScanCancelCallback> _callbacks = {};

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    final callbacks = List<ScanCancelCallback>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }

  ScanCancelCallback addCancelListener(ScanCancelCallback callback) {
    if (_isCancelled) {
      callback();
      return () {};
    }
    _callbacks.add(callback);
    return () => _callbacks.remove(callback);
  }
}
