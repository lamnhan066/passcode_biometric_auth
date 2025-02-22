/// A collection of keys used for storing user preferences.
class PrefKeys {
  /// Key for saving the remaining seconds when a countdown is in progress,
  /// such as during a retry delay after exceeded attempts.
  static const lastRetriesExceededRemainingSecond =
      'LastRetriesExceededRemainingSecond';

  /// Key for saving the user's preference on whether to use biometric authentication.
  static const isUseBiometricKey = 'IsUseBiometric';

  /// Key for saving the hashed version (SHA256) of the user's passcode.
  static const sha256PasscodeKey = 'Sha256Passcode';
}
