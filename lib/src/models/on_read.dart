class OnRead {
  /// Read bool.
  final Future<bool?> Function(String key) readBool;

  /// Read String.
  final Future<String?> Function(String key) readString;

  /// Read int.
  final Future<int?> Function(String key) readInt;

  /// All configuration that needs to be read from the local database will
  /// be called through these methods.
  OnRead({
    required this.readBool,
    required this.readString,
    required this.readInt,
  });
}
