import 'package:shared_preferences/shared_preferences.dart';

import 'models/on_read.dart';
import 'models/on_write.dart';
import 'passcode_biometric_auth_ui.dart';

class PasscodeBiometricAuthUICached extends PasscodeBiometricAuthUI {
  /// This is the same as [PasscodeBiometricAuthUI] but with built-in [onRead]
  /// and [onWrite] using `SharedPreferences`.
  ///
  /// If you want to use a more secure way to cache the data then you need to
  /// use [PasscodeBiometricAuthUI].
  PasscodeBiometricAuthUICached({
    super.prefix,
    super.forceCreatePasscode,
    super.title,
    super.checkConfig,
    super.createConfig,
    super.repeatConfig,
    super.blurSigma,
    super.onMaxRetriesReached,
    super.onForgotPasscode,
    super.hapticFeedbackType,
    super.dialogBuilder,
  }) : super(
          sha256Passcode: '',
          onRead: _onRead(prefix),
          onWrite: _onWrite(prefix),
        );

  static OnRead _onRead(String prefix) => OnRead(readBool: (String key) async {
        SharedPreferences pref = await SharedPreferences.getInstance();
        return pref.getBool('$prefix.$key') ?? false;
      }, readString: (String key) async {
        SharedPreferences pref = await SharedPreferences.getInstance();
        return pref.getString('$prefix.$key');
      }, readInt: (String key) async {
        SharedPreferences pref = await SharedPreferences.getInstance();
        return pref.getInt('$prefix.$key');
      });

  static OnWrite _onWrite(String prefix) => OnWrite(
        writeBool: (String key, bool value) async {
          SharedPreferences pref = await SharedPreferences.getInstance();
          await pref.setBool('$prefix.$key', value);
        },
        writeString: (String key, String value) async {
          SharedPreferences pref = await SharedPreferences.getInstance();
          await pref.setString('$prefix.$key', value);
        },
        writeInt: (String key, int value) async {
          SharedPreferences pref = await SharedPreferences.getInstance();
          await pref.setInt('$prefix.$key', value);
        },
      );
}
