import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passcode_biometric_auth/src/models/check_passcode_state.dart';

import 'components/check_passcode.dart';
import 'components/create_passcode.dart';
import 'models/on_read.dart';
import 'models/on_write.dart';

class PasscodeBiometricAuthUI {
  final String prefix;
  static const _isUseBiometricKey = 'IsUseBiometric';
  static const _sha256PasscodeKey = 'Sha256Passcode';
  int maxRetries;
  int retryInSecond;
  bool forceCreatePasscode;
  String title;
  String inputContent;
  String createContent;
  String createSubContent;
  String forgetText;
  String maxRetriesExceeededText;
  String incorrectText;
  String repeatContent;
  String? useBiometricChecboxText;
  Future<bool> Function(BuildContext context)? onForgetPasscode;
  Future<void> Function(String sha256Passcode)? onCreatePasscode;
  void Function(BuildContext context, int retriesNumber)? onMaxRetriesExceeded;
  OnRead? onRead;
  OnWrite? onWrite;

  bool? _isBiometricAvailableCached;
  late bool _isUseBiometric;
  Future<bool> get isUseBiometric async {
    return (await onRead?.readBool(_isUseBiometricKey)) ?? _isUseBiometric;
  }

  late String _sha256Passcode;
  Future<String> get sha256Passcode async {
    return (await onRead?.readString(_sha256PasscodeKey)) ?? _sha256Passcode;
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
    this.createSubContent = '',
    this.forgetText = 'Forgot your passcode?',
    this.incorrectText = 'This passcode is not correct (counter: @{counter})',
    this.repeatContent = 'Repeat your passcode',
    this.useBiometricChecboxText = 'Use biometric authentication',
    this.maxRetriesExceeededText =
        'Maximum retries are exceeded, please try again in @{second}s',
    this.onMaxRetriesExceeded,
    Future<void> Function(String sha256Code, PasscodeBiometricAuthUI localAuth)?
        onCreatePasscode,
    Future<bool> Function(
            BuildContext context, PasscodeBiometricAuthUI localAuth)?
        onForgetPasscode,
    this.onRead,
    this.onWrite,
  }) {
    _isUseBiometric = isUseBiometric;
    _sha256Passcode = sha256Passcode;
    this.onCreatePasscode = (sha256Passcode) async {
      if (onCreatePasscode != null) {
        await onCreatePasscode(sha256Passcode, this);
      }
      await onWrite?.writeString(_sha256PasscodeKey, sha256Passcode);
    };
    this.onForgetPasscode = onForgetPasscode == null
        ? null
        : (context) async {
            if (await onForgetPasscode(context, this)) {
              await removePasscode();
              if (context.mounted) {
                Navigator.pop(context);
              }
              return true;
            }
            return false;
          };
  }

  @mustCallSuper
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
  @mustCallSuper
  Future<bool?> isBiometricAuthenticated() async {
    if (!await isBiometricAvailable()) {
      return false;
    }

    var localAuth = LocalAuthentication();
    return await localAuth.authenticate(
      localizedReason: 'Please authenticate to use this feature',
    );
  }

  @mustCallSuper
  Future<bool> authenticateWithPasscode(BuildContext context) async {
    final code = await sha256Passcode;
    if (!context.mounted) return false;

    final state = await showDialog<CheckPasscodeState>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
          onForgetPasscode: (ctx) async {
            if (onForgetPasscode != null) {
              await onForgetPasscode!(ctx);
            }
          },
          onMaxRetriesExceeded: onMaxRetriesExceeded,
          onRead: onRead,
          onWrite: onWrite,
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
    await onWrite?.writeBool(_isUseBiometricKey, isUse);
    _isUseBiometric = isUse;
  }

  @mustCallSuper
  Future<void> removePasscode() async {
    await onWrite?.writeString(_sha256PasscodeKey, '');
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: CreatePasscode(
          title: title,
          content: createContent,
          subContent: createSubContent,
          repeatContent: repeatContent,
          incorrectText: incorrectText,
        ),
      ),
    );

    if (recievedCode != null) {
      _sha256Passcode = recievedCode;
      onWrite?.writeString(_sha256PasscodeKey, recievedCode);
      if (onCreatePasscode != null) {
        await onCreatePasscode!(recievedCode);
      }

      return recievedCode;
    } else {
      return '';
    }
  }
}
