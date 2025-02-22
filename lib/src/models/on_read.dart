class OnRead {
  /// Callback to asynchronously read a boolean value from a local data source.
  ///
  /// Given a [key], returns a [Future] that completes with the corresponding
  /// boolean value, or `null` if the key does not exist.
  final Future<bool?> Function(String key) readBool;

  /// Callback to asynchronously read a string value from a local data source.
  ///
  /// Given a [key], returns a [Future] that completes with the corresponding
  /// string value, or `null` if the key does not exist.
  final Future<String?> Function(String key) readString;

  /// Callback to asynchronously read an integer value from a local data source.
  ///
  /// Given a [key], returns a [Future] that completes with the corresponding
  /// integer value, or `null` if the key does not exist.
  final Future<int?> Function(String key) readInt;

  /// Constructs an [OnRead] instance with the provided asynchronous read operations.
  ///
  /// Each callback ([readBool], [readString], and [readInt]) is required and
  /// is responsible for fetching data from a local data source based on a key.
  OnRead({
    required this.readBool,
    required this.readString,
    required this.readInt,
  });
}
