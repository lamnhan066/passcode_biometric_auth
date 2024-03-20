class OnRead {
  final Future<bool?> Function(String key) readBool;
  final Future<String?> Function(String key) readString;
  final Future<int?> Function(String key) readInt;
  OnRead({
    required this.readBool,
    required this.readString,
    required this.readInt,
  });
}
