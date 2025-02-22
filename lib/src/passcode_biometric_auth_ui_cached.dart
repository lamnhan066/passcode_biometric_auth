import 'package:shared_preferences/shared_preferences.dart';

import 'models/on_read.dart';
import 'models/on_write.dart';
import 'passcode_biometric_auth_ui.dart';

/// A variant of [PasscodeBiometricAuthUI] that automatically caches configuration
/// values using SharedPreferences.
///
/// This implementation provides default [onRead] and [onWrite] methods that persist
/// configuration data (booleans, strings, and integers) using SharedPreferences. For
/// scenarios requiring more secure storage, consider using [PasscodeBiometricAuthUI]
/// without caching.
class PasscodeBiometricAuthUICached extends PasscodeBiometricAuthUI {
  /// Creates a [PasscodeBiometricAuthUICached] instance.
  ///
  /// The [prefix] parameter is used to namespace all stored keys.
  /// Other parameters customize the UI behavior and passcode configuration.
  PasscodeBiometricAuthUICached({
    super.prefix,
    super.salt,
    super.forceCreatePasscode,
    super.title,
    super.checkConfig,
    super.createConfig,
    super.repeatConfig,
    super.blurSigma,
    super.onMaxRetriesExceeded,
    super.onForgotPasscode,
    super.hapticFeedbackType,
    super.dialogBuilder,
  }) : super(
          sha256Passcode: '',
          onRead: _onRead(prefix),
          onWrite: _onWrite(prefix),
        );

  /// Creates an [OnRead] instance with methods to retrieve stored values.
  ///
  /// Each read method uses a combined key of the provided [prefix] and the [key]
  /// to prevent collisions in the shared preferences.
  static OnRead _onRead(String prefix) => OnRead(
        readBool: (String key) async {
          // Retrieves a boolean value associated with the namespaced key.
          SharedPreferences prefs = await SharedPreferences.getInstance();
          return prefs.getBool(key) ?? false;
        },
        readString: (String key) async {
          // Retrieves a string value associated with the namespaced key.
          SharedPreferences prefs = await SharedPreferences.getInstance();
          return prefs.getString(key);
        },
        readInt: (String key) async {
          // Retrieves an integer value associated with the namespaced key.
          SharedPreferences prefs = await SharedPreferences.getInstance();
          return prefs.getInt(key);
        },
      );

  /// Creates an [OnWrite] instance with methods to persist values.
  ///
  /// Each write method uses a combined key of the provided [prefix] and the [key]
  /// to ensure uniqueness and avoid key collisions.
  static OnWrite _onWrite(String prefix) => OnWrite(
        writeBool: (String key, bool value) async {
          // Persists a boolean value using the namespaced key.
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool(key, value);
        },
        writeString: (String key, String value) async {
          // Persists a string value using the namespaced key.
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(key, value);
        },
        writeInt: (String key, int value) async {
          // Persists an integer value using the namespaced key.
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt(key, value);
        },
      );
}
