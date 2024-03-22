class OnWrite {
  /// Write bool.
  final Future<void> Function(String key, bool value) writeBool;

  /// Write String.
  final Future<void> Function(String key, String value) writeString;

  /// Write int.
  final Future<void> Function(String key, int value) writeInt;

  /// All configuration that needs to be write to the local database will
  /// be called through these methods.
  OnWrite({
    required this.writeBool,
    required this.writeString,
    required this.writeInt,
  });
}
