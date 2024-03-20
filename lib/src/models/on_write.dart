class OnWrite {
  final Future<void> Function(String key, bool value) writeBool;
  final Future<void> Function(String key, String value) writeString;
  final Future<void> Function(String key, int value) writeInt;
  OnWrite({
    required this.writeBool,
    required this.writeString,
    required this.writeInt,
  });
}
