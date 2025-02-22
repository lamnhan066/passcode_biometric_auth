import 'package:shared_preferences/shared_preferences.dart';

import 'models/on_read.dart';
import 'models/on_write.dart';
import 'passcode_biometric_auth_ui.dart';

/// A variant of [PasscodeBiometricAuthUI] that automatically caches configuration
/// values using SharedPreferences.
///
/// This implementation provides built-in implementations for [onRead] and
/// [onWrite] to persist configuration data as booleans, strings, and integers.
/// For more secure storage, use [PasscodeBiometricAuthUI] without caching.
class PasscodeBiometricAuthUICached extends PasscodeBiometricAuthUI {
  /// Creates a [PasscodeBiometricAuthUICached] instance.
  ///
  /// The [prefix] parameter is used as a key prefix for all stored values.
  ///
  /// Other parameters configure the behavior and appearance of the UI and
  /// passcode configuration.
  PasscodeBiometricAuthUICached({
    super.prefix,
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

  /// Returns an [OnRead] instance that reads cached values from SharedPreferences.
  ///
  /// The [prefix] is prepended to every key to avoid collisions.
  static OnRead _onRead(String prefix) => OnRead(
        readBool: (String key) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          // Retrieve a boolean value associated with the combined key.
          return prefs.getBool('$prefix.$key') ?? false;
        },
        readString: (String key) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          // Retrieve a string value associated with the combined key.
          return prefs.getString('$prefix.$key');
        },
        readInt: (String key) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          // Retrieve an integer value associated with the combined key.
          return prefs.getInt('$prefix.$key');
        },
      );

  /// Returns an [OnWrite] instance that writes values to SharedPreferences.
  ///
  /// The [prefix] is prepended to every key to avoid collisions.
  static OnWrite _onWrite(String prefix) => OnWrite(
        writeBool: (String key, bool value) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          // Persist a boolean value using a combined key.
          await prefs.setBool('$prefix.$key', value);
        },
        writeString: (String key, String value) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          // Persist a string value using a combined key.
          await prefs.setString('$prefix.$key', value);
        },
        writeInt: (String key, int value) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          // Persist an integer value using a combined key.
          await prefs.setInt('$prefix.$key', value);
        },
      );
}
