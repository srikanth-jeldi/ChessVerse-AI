/// A lease covers intro, display and native disposal across all full-screen ads.
class FullScreenAdGate {
  static Object? _owner;
  static Object? acquire() {
    if (_owner != null) return null;
    return _owner = Object();
  }

  static void release(Object? lease) {
    if (lease != null && identical(_owner, lease)) _owner = null;
  }
}
