import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Handles both passcode and biometric authentication.
class PasscodeBiometricAuth {
  /// Generates a secure random salt encoded in Base64 URL format.
  ///
  /// Uses a cryptographically secure random number generator when available,
  /// otherwise falls back to a less secure generator.
  /// Returns a 16-byte salt as a Base64 URL-safe string.
  static String generateSalt() {
    Random random;
    try {
      random = Random.secure();
    } on UnsupportedError {
      random = Random();
    }

    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Combines a passcode and salt, hashes them with SHA256, and encodes in Base64 URL format.
  ///
  /// Using a salt defends against attacks by ensuring the hash is unique even for common passcodes.
  /// Parameters:
  /// - [code]: The user-provided passcode.
  /// - [salt]: A string used to augment security.
  /// Returns a new instance with the hashed passcode and salt.
  static String sha256FromPasscode(String code, String salt) {
    final combined = code + salt;
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);

    return base64Encode(hash.bytes);
  }

  /// Returns the stored SHA256 hashed passcode (in Base64 encoding).
  String get sha256Passcode => _sha256Passcode;

  /// The SHA256 hashed passcode as a Base64 encoded string.
  final String _sha256Passcode;

  /// The salt used to enhance the passcode security. (Defaults to an empty string.)
  final String salt;

  /// Caches the result of the biometric availability check.
  bool? _isBiometricAvailableCached;

  /// Instance for handling local biometric authentication.
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Creates an instance with a given SHA256 hashed passcode and salt.
  PasscodeBiometricAuth({
    required String sha256Passcode,
    this.salt = '',
  }) : _sha256Passcode = sha256Passcode;

  /// Returns a modified copy of this instance.
  ///
  /// Updated fields if provided, otherwise retains previous values.
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

  /// Checks if biometric authentication is available on the device.
  ///
  /// On web platforms or unsupported devices, it returns false.
  /// Caches the result to avoid redundant checks.
  Future<bool> isBiometricAvailable() async {
    if (_isBiometricAvailableCached != null) {
      return _isBiometricAvailableCached!;
    }

    if (kIsWeb) {
      _isBiometricAvailableCached = false;
      return false;
    }

    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        _isBiometricAvailableCached = false;
        return false;
      }
      _isBiometricAvailableCached = await _localAuth.canCheckBiometrics;
      return _isBiometricAvailableCached!;
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');
      _isBiometricAvailableCached = false;
      return false;
    }
  }

  /// Authenticates the user using biometrics.
  ///
  /// [biometricReason] is the prompt message for the biometric request.
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

  /// Verifies if the provided passcode matches the stored hash.
  ///
  /// Combines [code] with the stored salt, hashes them,
  /// and compares the result with the stored hash.
  /// Returns true if they match.
  bool isPasscodeAuthenticated(String code) {
    final sha256 = sha256FromPasscode(code, salt);
    return sha256 == sha256Passcode;
  }

  /// Checks if a passcode is set.
  ///
  /// Returns true if the stored passcode hash is not empty.
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
