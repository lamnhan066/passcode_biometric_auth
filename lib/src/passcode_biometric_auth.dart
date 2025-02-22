import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// A class for handling passcode and biometric authentication.
class PasscodeBiometricAuth {
  /// Securely hashes a raw passcode by combining it with a salt and then applying SHA256.
  ///
  /// This static method concatenates the provided [code] with the [salt],
  /// converts the result into UTF-8 bytes, computes its SHA256 hash,
  /// and then encodes the hash bytes using Base64 URL-safe encoding.
  ///
  /// Using a salt helps defend against common attacks such as rainbow tables and
  /// dictionary attacks by increasing the complexity of the hash.
  ///
  /// Parameters:
  /// - [code]: The raw passcode input from the user.
  /// - [salt]: A string used to add extra security to the passcode.
  ///
  /// Returns:
  /// A new instance of PasscodeBiometricAuth containing the Base64 URL-safe SHA256 hash
  /// of the combined passcode and salt, along with the salt itself.
  static PasscodeBiometricAuth encode(String code, String salt) {
    // Combine the raw passcode with the salt.
    final combined = code + salt;

    // Convert the combined string into UTF-8 encoded bytes.
    final bytes = utf8.encode(combined);

    // Generate the SHA256 hash from the byte sequence.
    final hash = sha256.convert(bytes);

    // Encode the resulting hash bytes using Base64 URL-safe encoding.
    return PasscodeBiometricAuth(
      sha256Passcode: base64UrlEncode(hash.bytes),
      salt: salt,
    );
  }

  /// SHA256 hashed passcode stored in Base64 encoding.
  String get sha256Passcode => _sha256Passcode;

  /// The SHA256 hashed passcode in Base64.
  final String _sha256Passcode;

  /// A salt used for additional passcode encoding. Defaults to ''.
  final String salt;

  /// Cache for whether biometric authentication is available.
  bool? _isBiometricAvailableCached;

  /// Local Authentication instance (lazy initialization).
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Constructor for initializing with a SHA256 hashed passcode.
  PasscodeBiometricAuth({
    required String sha256Passcode,
    this.salt = '',
  }) : _sha256Passcode = sha256Passcode;

  /// Returns a copy of the current instance with updated values.
  PasscodeBiometricAuth copyWith({
    String? sha256Passcode,
    String? salt,
    bool? isBiometricAvailableCached,
  }) {
    var copy = PasscodeBiometricAuth(
      sha256Passcode: sha256Passcode ?? _sha256Passcode,
      salt: salt ?? this.salt,
    );
    copy._isBiometricAvailableCached =
        isBiometricAvailableCached ?? _isBiometricAvailableCached;
    return copy;
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
      // Verify if the device supports biometric hardware.
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        _isBiometricAvailableCached = false;
        return false;
      }

      // Check if biometrics can be enrolled and verified on the device.
      _isBiometricAvailableCached = await _localAuth.canCheckBiometrics;
      return _isBiometricAvailableCached!;
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');

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
    if (!await isBiometricAvailable()) {
      return false;
    }

    try {
      return await _localAuth.authenticate(localizedReason: biometricReason);
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
    }
  }

  /// Checks if the provided passcode matches the stored SHA256 passcode.
  ///
  /// The [code] provided is concatenated with [salt], hashed and encoded in Base64
  /// to compare with the stored value.
  ///
  /// Returns true if the passcode is valid.
  bool isPasscodeAuthenticated(String code) {
    final passcodeSHA256 = encode(code, salt);
    return passcodeSHA256 == this;
  }

  /// Checks if a passcode is available (non-empty hash).
  ///
  /// Returns true if there is a valid passcode set.
  bool isAvailablePasscode() {
    return _sha256Passcode.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PasscodeBiometricAuth &&
        other._sha256Passcode == _sha256Passcode;
  }

  @override
  int get hashCode => _sha256Passcode.hashCode;
}
