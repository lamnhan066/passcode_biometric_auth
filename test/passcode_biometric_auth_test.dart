import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passcode_biometric_auth/src/passcode_biometric_auth.dart';

void main() {
  // Test constants with salt implementation
  const correctCode = '1234';
  const wrongCode = '0000';
  const salt = 'mysalt';

  // Compute the salted hash: passcode + salt
  final correctHash =
      PasscodeBiometricAuth.createFromPasscode(correctCode, salt)
          .sha256Passcode;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Passcode Authentication with Salt', () {
    test('Passcode availability returns true when salted hash provided', () {
      final auth = PasscodeBiometricAuth(
        sha256Passcode: correctHash,
        salt: salt,
      );
      expect(auth.isAvailablePasscode(), isTrue);
    });

    test('Passcode availability returns false when hash is empty', () {
      final auth = PasscodeBiometricAuth(
        sha256Passcode: '',
        salt: salt,
      );
      expect(auth.isAvailablePasscode(), isFalse);
    });

    test('Authentication succeeds with correct passcode and salt', () {
      final auth = PasscodeBiometricAuth(
        sha256Passcode: correctHash,
        salt: salt,
      );
      expect(auth.isPasscodeAuthenticated(correctCode), isTrue);
    });

    test('Authentication fails with incorrect passcode even with salt', () {
      final auth = PasscodeBiometricAuth(
        sha256Passcode: correctHash,
        salt: salt,
      );
      expect(auth.isPasscodeAuthenticated(wrongCode), isFalse);
    });

    test('Authentication fails when no hash exists irrespective of salt', () {
      final auth = PasscodeBiometricAuth(
        sha256Passcode: '',
        salt: salt,
      );
      expect(auth.isPasscodeAuthenticated(correctCode), isFalse);
    });

    test(
        'copyWith updates passcode hash and salt, without altering the original',
        () {
      const newCode = '5678';
      const newSalt = 'newsalt';
      final newHash = PasscodeBiometricAuth.createFromPasscode(newCode, newSalt)
          .sha256Passcode;
      final original = PasscodeBiometricAuth(
        sha256Passcode: correctHash,
        salt: salt,
      );
      final updated = original.copyWith(
        sha256Passcode: newHash,
        salt: newSalt,
      );

      expect(updated.sha256Passcode, equals(newHash));
      expect(updated.salt, equals(newSalt));
      // Original instance remains unchanged.
      expect(original.sha256Passcode, equals(correctHash));
      expect(original.salt, equals(salt));
    });
  });

  group('Biometric Authentication', () {
    test('Biometric availability: false on web and a bool otherwise', () async {
      final auth = PasscodeBiometricAuth(
        sha256Passcode: correctHash,
        salt: salt,
      );
      if (kIsWeb) {
        expect(await auth.isBiometricAvailable(), isFalse);
      } else {
        expect(await auth.isBiometricAvailable(), isA<bool>());
      }
    });

    test('Biometric authentication returns false when biometrics unavailable',
        () async {
      final auth = PasscodeBiometricAuth(
        sha256Passcode: correctHash,
        salt: salt,
      );
      final available = await auth.isBiometricAvailable();
      if (!available) {
        expect(await auth.isBiometricAuthenticated(), isFalse);
      } else {
        expect(await auth.isBiometricAuthenticated(), isA<bool>());
      }
    });
  });
}
