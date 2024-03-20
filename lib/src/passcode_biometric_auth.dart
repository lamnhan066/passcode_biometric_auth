import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class PasscodeBiometricAuth {
  String get sha256Passcode => _sha256Passcode;
  final String _sha256Passcode;
  bool? _isBiometricAvailableCached;

  PasscodeBiometricAuth({
    required String sha256Passcode,
  }) : _sha256Passcode = sha256Passcode;

  PasscodeBiometricAuth copyWith({
    String? sha256Passcode,
    bool? isBiometricAvailableCached,
  }) {
    return PasscodeBiometricAuth(
      sha256Passcode: sha256Passcode ?? _sha256Passcode,
    ).._isBiometricAvailableCached = isBiometricAvailableCached;
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

  bool isPasscodeAuthenticated(String code) {
    final passcodeSHA256 =
        base64Encode(sha256.convert(utf8.encode(code)).bytes);
    if (passcodeSHA256 == _sha256Passcode) {
      return true;
    }
    return false;
  }

  bool isAvailablePasscode() {
    return _sha256Passcode != '';
  }
}
