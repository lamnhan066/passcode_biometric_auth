/// This class represents the state of passcode checking.
/// It holds information about whether the user is authenticated
/// and whether biometric authentication is enabled.
class CheckPasscodeState {
  /// Indicates if the user is authenticated.
  final bool isAuthenticated;

  /// Indicates if biometric authentication is being used.
  final bool isUseBiometric;

  /// Creates a [CheckPasscodeState] instance with authentication
  /// and biometric options.
  const CheckPasscodeState({
    required this.isAuthenticated,
    required this.isUseBiometric,
  });
}
