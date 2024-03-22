import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passcode_biometric_auth/src/models/check_passcode_state.dart';
import 'package:passcode_biometric_auth/src/utils/animated_dialog.dart';
import 'package:pinput/pinput.dart';

import 'components/check_passcode.dart';
import 'components/create_passcode.dart';
import 'models/on_read.dart';
import 'models/on_write.dart';
import 'utils/pref_keys.dart';

class PasscodeBiometricAuthUI {
  final String prefix;
  final int maxRetries;
  final int retryInSecond;
  final bool forceCreatePasscode;
  final String title;
  final String checkContent;
  final String checkIncorrectText;
  final String? checkCancelButtonText;
  final String createContent;
  final String? createSubContent;
  final String? createCancelButtonText;
  final String forgetText;
  final String maxRetriesExceeededText;
  final String repeatContent;
  final String repeatIncorrectText;
  final String? repeatBackButtonText;
  final String? useBiometricChecboxText;
  final String biometricReason;
  final double blurSigma;
  late final Future<bool> Function(BuildContext context)? onForgetPasscode;
  final void Function()? onMaxRetriesExceeded;
  final OnRead? onRead;
  final OnWrite? onWrite;
  final HapticFeedbackType hapticFeedbackType;
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? actions)? dialogBuilder;

  bool? _isBiometricAvailableCached;
  late bool _isUseBiometric;
  Future<bool> get isUseBiometric async {
    return (await onRead?.readBool(PrefKeys.isUseBiometricKey)) ??
        _isUseBiometric;
  }

  late String _sha256Passcode;
  Future<String> get sha256Passcode async {
    return (await onRead?.readString(PrefKeys.sha256PasscodeKey)) ??
        _sha256Passcode;
  }

  /// An UI to show the passcode and biometric authentication dialogs
  PasscodeBiometricAuthUI({
    this.prefix = 'PasscodeBiometricAuth',
    this.maxRetries = 5,
    this.retryInSecond = 300,
    String sha256Passcode = '',
    bool isUseBiometric = false,
    this.forceCreatePasscode = true,
    this.title = 'Passcode',
    this.checkContent = 'Input Passcode',
    this.checkIncorrectText =
        'This passcode is incorrect (max: @{counter}/@{maxRetries} times)\n'
            'You\'ll be locked in @{retryInSecond}s when the max retries are reached',
    this.checkCancelButtonText,
    this.createContent = 'Create Passcode',
    this.createSubContent,
    this.createCancelButtonText,
    this.forgetText = 'Forgot your passcode?',
    this.repeatContent = 'Repeat Passcode',
    this.repeatIncorrectText = 'This passcode is incorrect (times: @{counter})',
    this.repeatBackButtonText,
    this.useBiometricChecboxText = 'Use biometric authentication',
    this.maxRetriesExceeededText =
        'The max retries are reached\nPlease try again in @{second}s',
    this.biometricReason = 'Please authenticate to use this feature',
    this.blurSigma = 15,
    this.onMaxRetriesExceeded,
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
      authenticated = await isBiometricAuthenticated();
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

  /// `true`: authenticated
  /// `false`: not authenticated or not available
  Future<bool> isBiometricAuthenticated() async {
    if (!await isBiometricAvailable()) {
      return false;
    }

    var localAuth = LocalAuthentication();
    return await localAuth.authenticate(
      localizedReason: biometricReason,
    );
  }

  Future<bool> authenticateWithPasscode(BuildContext context) async {
    final code = await sha256Passcode;
    if (!context.mounted) return false;

    final state = await animatedDialog<CheckPasscodeState>(
      context: context,
      blurSigma: blurSigma,
      builder: (ctx) {
        return CheckPasscode(
          localAuth: this,
          maxRetries: maxRetries,
          retryInSecond: retryInSecond,
          sha256Passcode: code,
          title: title,
          content: checkContent,
          forgetText: forgetText,
          incorrectText: checkIncorrectText,
          cancelButtonText: checkCancelButtonText,
          useBiometricChecboxText: useBiometricChecboxText,
          maxRetriesExceededText: maxRetriesExceeededText,
          onForgetPasscode: onForgetPasscode == null
              ? null
              : () async {
                  Navigator.pop(ctx);
                  onForgetPasscode!(context);
                },
          onMaxRetriesExceeded: onMaxRetriesExceeded,
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

  Future<bool> isPasscodeAuthenticated(String code) async {
    final passcodeSHA256 =
        base64Encode(sha256.convert(utf8.encode(code)).bytes);
    if (passcodeSHA256 == await sha256Passcode) {
      return true;
    }
    return false;
  }

  @mustCallSuper
  Future<void> useBiometric(bool isUse) async {
    await onWrite?.writeBool(PrefKeys.isUseBiometricKey, isUse);
    _isUseBiometric = isUse;
  }

  @mustCallSuper
  Future<void> removePasscode() async {
    await onWrite?.writeString(PrefKeys.sha256PasscodeKey, '');
    await onWrite?.writeBool(PrefKeys.isUseBiometricKey, false);
    await onWrite?.writeInt(PrefKeys.lastRetriesExceededRemainingSecond, 0);
    _sha256Passcode = '';
  }

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
          content: createContent,
          subContent: createSubContent,
          cancelButtonText: createCancelButtonText,
          repeatContent: repeatContent,
          repeatBackButtonText: repeatBackButtonText,
          incorrectText: repeatIncorrectText,
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
