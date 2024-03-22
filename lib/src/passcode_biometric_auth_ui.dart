import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passcode_biometric_auth/src/models/check_passcode_state.dart';
import 'package:passcode_biometric_auth/src/models/dialog_configs.dart';
import 'package:passcode_biometric_auth/src/utils/animated_dialog.dart';
import 'package:pinput/pinput.dart';

import 'components/check_passcode.dart';
import 'components/create_passcode.dart';
import 'models/on_read.dart';
import 'models/on_write.dart';
import 'utils/pref_keys.dart';

class PasscodeBiometricAuthUI {
  /// Prefix for saving to local database in `OnRead` and `OnWrite`.
  final String prefix;

  /// If this value is `true`, the app requests to create a passcode if it's
  /// unavailable. If `false`, the app only requests to create a passcode if
  /// the biometric authentication is unavailable in the device.
  final bool forceCreatePasscode;

  /// Main title of all dialogs.
  final String title;

  /// Config for the check dialog.
  final CheckConfig checkConfig;

  /// Config for the create dialog.
  final CreateConfig createConfig;

  /// Config for the repeat dialog.
  final RepeatConfig repeatConfig;

  /// Blur sigma for the background.
  final double blurSigma;

  /// This method is called when users tap the `forgot your passcode` button.
  /// We usually use a dialog to show the cautions when users want to reset their passcode.
  /// The passcode will be removed if this method returns `true`.
  late final Future<bool> Function(BuildContext context)? onForgetPasscode;

  /// This callback will be triggered when users reach the maximum number of retries.
  final void Function()? onMaxRetriesReached;

  /// All configuration that needs to be read from the local database will
  /// be called through these methods.
  final OnRead? onRead;

  /// All configuration that needs to be write to the local database will
  /// be called through these methods.
  final OnWrite? onWrite;

  /// The vibration type when user types.
  final HapticFeedbackType hapticFeedbackType;

  /// The `AlertDialog` will be used by default. If you want to modify the dialog,
  /// you can use this builder.
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? actions)? dialogBuilder;

  bool? _isBiometricAvailableCached;
  late bool _isUseBiometric;

  /// Check whether the app is using biometric.
  Future<bool> get isUseBiometric async {
    return (await onRead?.readBool(PrefKeys.isUseBiometricKey)) ??
        _isUseBiometric;
  }

  late String _sha256Passcode;

  /// Get the current passcode in SHA256. There is no way to get the raw passcode.
  Future<String> get sha256Passcode async {
    return (await onRead?.readString(PrefKeys.sha256PasscodeKey)) ??
        _sha256Passcode;
  }

  /// An UI to show the passcode and biometric authentication dialogs.
  PasscodeBiometricAuthUI({
    this.prefix = 'PasscodeBiometricAuth',
    String sha256Passcode = '',
    bool isUseBiometric = false,
    this.forceCreatePasscode = true,
    this.title = 'Passcode',
    this.checkConfig = const CheckConfig(),
    this.createConfig = const CreateConfig(),
    this.repeatConfig = const RepeatConfig(),
    this.blurSigma = 15,
    this.onMaxRetriesReached,
    Future<bool> Function(BuildContext context, PasscodeBiometricAuthUI authUI)?
        onForgetPasscode,
    this.onRead,
    this.onWrite,
    this.hapticFeedbackType = HapticFeedbackType.lightImpact,
    this.dialogBuilder,
  }) {
    _isUseBiometric = isUseBiometric;
    _sha256Passcode = sha256Passcode;
    this.onForgetPasscode = onForgetPasscode == null
        ? null
        : (context) async {
            if (await onForgetPasscode(context, this)) {
              await removePasscode();
              return true;
            }
            return false;
          };
  }

  /// This method will automatically handles both passcode and biometric authentications.
  ///
  /// If the `forceCreatePasscode` is set to `true`, the app requests to create a passcode if it's
  /// unavailable. If `false`, the app only requests to create a passcode if
  /// the biometric authentication is unavailable in the device. Default is set to
  /// the global config.
  ///
  /// If the `isUseBiometric` is set to `true`, the app will try to use biometric
  /// authentication if available. Default is set to the global config.
  Future<bool> authenticate(
    BuildContext context, {
    bool? forceCreatePasscode,
    bool? isUseBiometric,
  }) async {
    bool? authenticated;
    forceCreatePasscode ??= this.forceCreatePasscode;
    isUseBiometric ??= await this.isUseBiometric;

    final isPasscodeAvailable = await isAvailablePasscode();
    final isNeedCreatePasscode = forceCreatePasscode && !isPasscodeAvailable;

    if (!isNeedCreatePasscode && isUseBiometric) {
      authenticated = await authenticateWithBiometric();
    }

    if (authenticated == true) return true;

    if (!isPasscodeAvailable) {
      if (!context.mounted) return false;
      final code = await _createPasscode(context);
      return code != '';
    } else {
      if (!context.mounted) return false;
      final isAuthenticated = await authenticateWithPasscode(context);
      return isAuthenticated == true;
    }
  }

  /// Change the passcode.
  Future<bool> changePasscode(BuildContext context) async {
    final isPasscodeAvailable = await isAvailablePasscode();
    if (!isPasscodeAvailable) {
      if (!context.mounted) return false;
      final code = await _createPasscode(context);
      return code != '';
    } else {
      if (!context.mounted) return false;
      final isAuthenticated = await authenticateWithPasscode(context);
      if (!isAuthenticated || !context.mounted) return false;
      return (await _createPasscode(context)) != '';
    }
  }

  /// Check whether biometric authentication is available on the current device.
  Future<bool> isBiometricAvailable() async {
    if (_isBiometricAvailableCached != null) {
      return _isBiometricAvailableCached!;
    }

    if (kIsWeb) {
      _isBiometricAvailableCached = false;
      return false;
    }

    var localAuth = LocalAuthentication();
    final isDeviceSupported = await localAuth.isDeviceSupported();
    if (!isDeviceSupported) {
      _isBiometricAvailableCached = false;
      return false;
    }

    _isBiometricAvailableCached = await localAuth.canCheckBiometrics;
    return _isBiometricAvailableCached!;
  }

  /// Manually authenticate via biometric authentication.
  Future<bool> authenticateWithBiometric() async {
    if (!await isBiometricAvailable()) {
      return false;
    }

    var localAuth = LocalAuthentication();
    return await localAuth.authenticate(
      localizedReason: checkConfig.biometricReason,
    );
  }

  /// Manually authenticate via passcode authentication.
  Future<bool> authenticateWithPasscode(BuildContext context) async {
    final code = await sha256Passcode;
    if (!context.mounted) return false;

    final state = await animatedDialog<CheckPasscodeState>(
      context: context,
      blurSigma: blurSigma,
      builder: (ctx) {
        return CheckPasscode(
          localAuth: this,
          sha256Passcode: code,
          title: title,
          checkConfig: checkConfig,
          onForgetPasscode: onForgetPasscode == null
              ? null
              : () async {
                  Navigator.pop(ctx);
                  onForgetPasscode!(context);
                },
          onMaxRetriesReached: onMaxRetriesReached,
          onRead: onRead,
          onWrite: onWrite,
          hapticFeedbackType: hapticFeedbackType,
          dialogBuilder: dialogBuilder,
        );
      },
    );

    if (state == null) return false;

    useBiometric(state.isUseBiometric);
    return state.isAuthenticated == true;
  }

  /// Check whether the passcode `code` is correct.
  Future<bool> isPasscodeAuthenticated(String code) async {
    final passcodeSHA256 =
        base64Encode(sha256.convert(utf8.encode(code)).bytes);
    if (passcodeSHA256 == await sha256Passcode) {
      return true;
    }
    return false;
  }

  /// Set the `isUseBiometric` value.
  @mustCallSuper
  Future<void> useBiometric(bool isUse) async {
    await onWrite?.writeBool(PrefKeys.isUseBiometricKey, isUse);
    _isUseBiometric = isUse;
  }

  /// Remove the current passcode.
  @mustCallSuper
  Future<void> removePasscode() async {
    await onWrite?.writeString(PrefKeys.sha256PasscodeKey, '');
    await onWrite?.writeBool(PrefKeys.isUseBiometricKey, false);
    await onWrite?.writeInt(PrefKeys.lastRetriesReachedRemainingSecond, 0);
    _sha256Passcode = '';
  }

  /// Check whether the passcode is available.
  FutureOr<bool> isAvailablePasscode() async {
    return await sha256Passcode != '';
  }

  Future<String> _createPasscode(BuildContext context) async {
    if (!context.mounted) return '';

    final recievedCode = await animatedDialog(
      context: context,
      blurSigma: blurSigma,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: CreatePasscode(
          title: title,
          createConfig: createConfig,
          repeatConfig: repeatConfig,
          hapticFeedbackType: hapticFeedbackType,
          dialogBuilder: dialogBuilder,
        ),
      ),
    );

    if (recievedCode != null) {
      _sha256Passcode = recievedCode;
      await onWrite?.writeString(PrefKeys.sha256PasscodeKey, recievedCode);
      return recievedCode;
    } else {
      return '';
    }
  }
}
