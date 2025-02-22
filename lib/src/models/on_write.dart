/// Provides asynchronous write operations for various data types to a local database.
///
/// This class defines the callbacks used to persist configuration and settings
/// by writing boolean, string, and integer values associated with a unique key.
class OnWrite {
  /// Asynchronously writes a boolean [value] with the associated [key].
  final Future<void> Function(String key, bool value) writeBool;

  /// Asynchronously writes a string [value] with the associated [key].
  final Future<void> Function(String key, String value) writeString;

  /// Asynchronously writes an integer [value] with the associated [key].
  final Future<void> Function(String key, int value) writeInt;

  /// Creates an instance of [OnWrite] with required callbacks for writing data.
  ///
  /// Each callback is responsible for persisting a specific type of data:
  /// - [writeBool] for boolean values,
  /// - [writeString] for string values,
  /// - [writeInt] for integer values.
  OnWrite({
    required this.writeBool,
    required this.writeString,
    required this.writeInt,
  });
}
