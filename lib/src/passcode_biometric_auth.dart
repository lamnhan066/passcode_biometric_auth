import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Manages passcode and biometric authentication operations.
class PasscodeBiometricAuth {
  /// Generates a secure random salt.
  ///
  /// The salt is generated using a cryptographically secure random number generator,
  /// if available; otherwise, a fallback generator is used. The result is a 16-byte
  /// salt encoded in Base64 URL-safe format.
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

  /// Computes a SHA256 hash for a combination of the passcode and a salt.
  ///
  /// The passcode ([passcode]) is concatenated with the provided [salt] and then hashed
  /// using the SHA256 algorithm. The resulting hash is encoded as a Base64 URL-safe string.
  static String sha256FromPasscode(String passcode, String salt) {
    final combined = passcode + salt;
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);

    return base64Encode(hash.bytes);
  }

  /// The SHA256-hashed passcode, stored as a Base64-encoded string.
  final String sha256Passcode;

  /// The salt used to enhance the passcode security.
  ///
  /// When not provided, defaults to an empty string.
  final String salt;

  /// Creates a PasscodeBiometricAuth instance with the hashed passcode and salt.
  const PasscodeBiometricAuth({
    required this.sha256Passcode,
    this.salt = '',
  });

  /// Returns a new instance with updated values.
  ///
  /// If a new [sha256Passcode] or [salt] is provided, they replace the current values;
  /// otherwise, the existing values are retained.
  PasscodeBiometricAuth copyWith({
    String? sha256Passcode,
    String? salt,
  }) {
    return PasscodeBiometricAuth(
      sha256Passcode: sha256Passcode ?? this.sha256Passcode,
      salt: salt ?? this.salt,
    );
  }

  /// Determines whether biometric authentication is available.
  ///
  /// On web platforms or devices that do not support biometric checks, returns false.
  /// Checks both if the device is supported and if biometric features can be used.
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final auth = LocalAuthentication();
      final isDeviceSupported = await auth.isDeviceSupported();
      if (!isDeviceSupported) {
        return false;
      }
      return await auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Prompts biometric authentication.
  ///
  /// Uses the provided [biometricReason] as the prompt message. If biometric
  /// authentication is not available or fails, returns false.
  Future<bool> isBiometricAuthenticated({
    String biometricReason = 'Please authenticate to use this feature',
  }) async {
    if (!await isBiometricAvailable()) {
      return false;
    }

    try {
      final auth = LocalAuthentication();
      return await auth.authenticate(localizedReason: biometricReason);
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
    }
  }

  /// Validates the provided passcode.
  ///
  /// Recomputes the SHA256 hash (with the stored salt) of the given [code] and compares
  /// it to the stored hashed passcode. Returns true if they match, otherwise false.
  bool isPasscodeAuthenticated(String code) {
    final computedHash = sha256FromPasscode(code, salt);
    return computedHash == sha256Passcode;
  }

  /// Checks whether a passcode has been set.
  ///
  /// Returns true if the stored hashed passcode is not empty.
  bool isAvailablePasscode() {
    return sha256Passcode.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PasscodeBiometricAuth &&
        other.sha256Passcode == sha256Passcode &&
        other.salt == salt;
  }

  @override
  int get hashCode => Object.hash(sha256Passcode, salt);
}
