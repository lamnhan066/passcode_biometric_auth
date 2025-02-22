import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// A class for handling passcode and biometric authentication.
class PasscodeBiometricAuth {
  /// SHA256 hashed passcode stored in Base64 encoding.
  String get sha256Passcode => _sha256Passcode;

  /// The SHA256 hashed passcode in Base64.
  final String _sha256Passcode;

  /// Cache for whether biometric authentication is available.
  bool? _isBiometricAvailableCached;

  /// Constructor for initializing with a SHA256 hashed passcode.
  PasscodeBiometricAuth({
    required String sha256Passcode,
  }) : _sha256Passcode = sha256Passcode;

  /// Returns a copy of the current instance with updated values.
  PasscodeBiometricAuth copyWith({
    String? sha256Passcode,
    bool? isBiometricAvailableCached,
  }) {
    return PasscodeBiometricAuth(
      // Use the provided value or fallback to the current _sha256Passcode.
      sha256Passcode: sha256Passcode ?? _sha256Passcode,
    ).._isBiometricAvailableCached = isBiometricAvailableCached;
  }

  /// Checks if biometrics are available on the device.
  ///
  /// Returns true if biometrics are available, false otherwise.
  Future<bool> isBiometricAvailable() async {
    // Return previously cached result to prevent redundant checks.
    if (_isBiometricAvailableCached != null) {
      return _isBiometricAvailableCached!;
    }

    // Biometrics are not available on web platforms.
    if (kIsWeb) {
      _isBiometricAvailableCached = false;
      return false;
    }

    try {
      // Initialize the LocalAuthentication instance.
      var localAuth = LocalAuthentication();

      // Verify if the device supports biometric hardware.
      final isDeviceSupported = await localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        _isBiometricAvailableCached = false;
        return false;
      }

      // Check if biometrics can be enrolled and verified on the device.
      _isBiometricAvailableCached = await localAuth.canCheckBiometrics;

      // Return the (cached) result indicating biometric availability.
      return _isBiometricAvailableCached!;
    } catch (_) {
      // On error, default to biometrics being unavailable.
      _isBiometricAvailableCached = false;
      return false;
    }
  }

  /// Authenticates the user using biometric authentication.
  ///
  /// [biometricReason] is the message shown in the biometric prompt.
  /// Returns true if authentication is successful, false otherwise.
  Future<bool> isBiometricAuthenticated({
    String biometricReason = 'Please authenticate to use this feature',
  }) async {
    // If biometrics aren't available, return false.
    if (!await isBiometricAvailable()) {
      return false;
    }

    var localAuth = LocalAuthentication();
    // Attempt to authenticate using biometrics.
    return await localAuth.authenticate(
      localizedReason: biometricReason,
    );
  }

  /// Checks if the provided passcode matches the stored SHA256 passcode.
  ///
  /// The [code] provided is hashed and encoded in Base64 to compare with the stored value.
  /// Returns true if the passcode is valid.
  bool isPasscodeAuthenticated(String code) {
    // Generate SHA256 hash of the input code then encode it in Base64.
    final passcodeSHA256 =
        base64Encode(sha256.convert(utf8.encode(code)).bytes);
    // Compare with the stored hashed passcode.
    if (passcodeSHA256 == _sha256Passcode) {
      return true;
    }
    return false;
  }

  /// Checks if a passcode is available (non-empty hash).
  ///
  /// Returns true if there is a valid passcode set.
  bool isAvailablePasscode() {
    return _sha256Passcode != '';
  }
}
