import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passcode_biometric_auth/src/models/check_passcode_state.dart';
import 'package:pinput/pinput.dart';

import 'components/check_passcode.dart';
import 'components/create_passcode.dart';
import 'models/on_read.dart';
import 'models/on_write.dart';
import 'pref_keys.dart';

class PasscodeBiometricAuthUI {
  final String prefix;
  int maxRetries;
  int retryInSecond;
  bool forceCreatePasscode;
  String title;
  String inputContent;
  String createContent;
  String? createSubContent;
  String forgetText;
  String maxRetriesExceeededText;
  String incorrectText;
  String repeatContent;
  String repeatIncorrectText;
  String? useBiometricChecboxText;
  double blurSigma;
  Future<bool> Function(BuildContext context)? onForgetPasscode;
  void Function()? onMaxRetriesExceeded;
  OnRead? onRead;
  OnWrite? onWrite;
  HapticFeedbackType hapticFeedbackType;

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

  PasscodeBiometricAuthUI({
    this.prefix = 'PasscodeBiometricAuth',
    this.maxRetries = 5,
    this.retryInSecond = 300,
    String sha256Passcode = '',
    bool isUseBiometric = false,
    this.forceCreatePasscode = false,
    this.title = 'Passcode',
    this.inputContent = 'Input your passcode',
    this.createContent = 'Create your passcode',
    this.createSubContent,
    this.forgetText = 'Forgot your passcode?',
    this.incorrectText =
        'This passcode is not correct (max: @{counter}/@{maxRetries} times)',
    this.repeatContent = 'Repeat your passcode',
    this.repeatIncorrectText =
        'This passcode is not correct (number: @{counter})',
    this.useBiometricChecboxText = 'Use biometric authentication',
    this.maxRetriesExceeededText =
        'Maximum retries are exceeded, please try again in @{second}s',
    this.blurSigma = 10,
    this.onMaxRetriesExceeded,
    Future<bool> Function(BuildContext context, PasscodeBiometricAuthUI authUI)?
        onForgetPasscode,
    this.onRead,
    this.onWrite,
    this.hapticFeedbackType = HapticFeedbackType.lightImpact,
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

  Future<bool> authenticate(BuildContext context) async {
    bool? authenticated;

    final isPasscodeAvailable = await isAvailablePasscode();
    final isNeedCreatePasscode = forceCreatePasscode && !isPasscodeAvailable;

    if (!isNeedCreatePasscode && await isUseBiometric) {
      authenticated = await isBiometricAuthenticated();
    }

    if (authenticated == true) return true;

    String code = await sha256Passcode;
    if (code == '') {
      if (!context.mounted) return false;
      final code = await _createPasscode(context);
      return code != '';
    } else {
      if (!context.mounted) return false;
      final isAuthenticated = await authenticateWithPasscode(context);
      return isAuthenticated == true;
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
      localizedReason: 'Please authenticate to use this feature',
    );
  }

  Future<bool> authenticateWithPasscode(BuildContext context) async {
    final code = await sha256Passcode;
    if (!context.mounted) return false;

    final state = await showDialog<CheckPasscodeState>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: CheckPasscode(
          localAuth: this,
          maxRetries: maxRetries,
          retryInSecond: retryInSecond,
          sha256Passcode: code,
          title: title,
          content: inputContent,
          forgetText: forgetText,
          incorrectText: incorrectText,
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
        ),
      ),
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
    print('OK');
    await onWrite?.writeString(PrefKeys.sha256PasscodeKey, '');
    await onWrite?.writeBool(PrefKeys.isUseBiometricKey, false);
    await onWrite?.writeInt(PrefKeys.lastRetriesExceededSecond, 0);
    _sha256Passcode = '';
  }

  FutureOr<bool> isAvailablePasscode() async {
    return await sha256Passcode != '';
  }

  Future<String> _createPasscode(BuildContext context) async {
    if (!context.mounted) return '';

    final recievedCode = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: CreatePasscode(
          title: title,
          content: createContent,
          subContent: createSubContent,
          repeatContent: repeatContent,
          incorrectText: repeatIncorrectText,
          hapticFeedbackType: hapticFeedbackType,
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
