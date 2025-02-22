/// Represents the state of passcode validation, including authentication
/// and biometric options.
///
/// This class is used to store the result of passcode checking and related
/// biometric authentication status.
class CheckPasscodeState {
  /// True if the user has been successfully authenticated.
  final bool isAuthenticated;

  /// True if biometric authentication is enabled and being used.
  final bool isUseBiometric;

  /// Creates an instance of [CheckPasscodeState] with the specified authentication
  /// and biometric settings.
  ///
  /// The [isAuthenticated] parameter indicates whether the user has passed the
  /// passcode check. The [isUseBiometric] parameter indicates whether biometric
  /// authentication is enabled.
  const CheckPasscodeState({
    required this.isAuthenticated,
    required this.isUseBiometric,
  });
}
