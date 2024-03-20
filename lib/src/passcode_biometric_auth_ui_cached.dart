import 'package:shared_preferences/shared_preferences.dart';

import 'models/on_read.dart';
import 'models/on_write.dart';
import 'passcode_biometric_auth_ui.dart';

class PasscodeBiometricAuthUICached extends PasscodeBiometricAuthUI {
  PasscodeBiometricAuthUICached({
    super.prefix,
    super.maxRetries,
    super.retryInSecond = 300,
    super.forceCreatePasscode,
    super.title,
    super.checkContent,
    super.checkIncorrectText,
    super.createContent,
    super.createSubContent,
    super.forgetText,
    super.repeatContent,
    super.useBiometricChecboxText,
    super.maxRetriesExceeededText,
    super.onMaxRetriesExceeded,
    super.onForgetPasscode,
    OnRead? onRead,
    OnWrite? onWrite,
  }) : super(sha256Passcode: '') {
    this.onRead = onRead ??
        OnRead(readBool: (String key) async {
          SharedPreferences pref = await SharedPreferences.getInstance();
          return pref.getBool('$prefix.$key') ?? false;
        }, readString: (String key) async {
          SharedPreferences pref = await SharedPreferences.getInstance();
          return pref.getString('$prefix.$key');
        }, readInt: (String key) async {
          SharedPreferences pref = await SharedPreferences.getInstance();
          return pref.getInt('$prefix.$key');
        });
    this.onWrite = onWrite ??
        OnWrite(
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
}
