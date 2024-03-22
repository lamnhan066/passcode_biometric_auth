abstract class DialogConfig {
  /// Content that showing at the above of the passcode area.
  final String content;

  /// Subconent that shown at the below of the passcode area.
  final String? subcontent;

  /// Error text that shown under the passcode field.
  final String incorrectText;

  /// A button that shown at the end of the dialog.
  final String? buttonText;

  /// Configurations for a dialog.
  const DialogConfig({
    required this.content,
    this.subcontent,
    required this.incorrectText,
    this.buttonText,
  });
}

class CheckConfig extends DialogConfig {
  /// Max times to retry when inputting the passcode.
  final int maxRetries;

  /// A delay in second when the max number of retries is reached. It's also cached in
  /// local database so the user have to wait even after the app is terminated.
  final int waitWhenMaxRetriesReached;

  /// `Forget your passcode?` button.
  final String forgotButtonText;

  /// An error text that shown when the maximum number of retries is reached.
  final String maxRetriesReachedText;

  /// A checkbox that allows users to use biometric authentication instead of a passcode.
  /// This checkbox only shows on the supported device using the `local_auth` package.
  final String useBiometricCheckboxText;

  /// A text to display when biometric authentication is requested with the `local_auth` package.
  final String biometricReason;

  /// Configuration for the check dialog.
  const CheckConfig({
    this.maxRetries = 5,
    this.waitWhenMaxRetriesReached = 300,
    super.content = 'Input Passcode',
    super.subcontent,
    super.incorrectText =
        'This passcode is incorrect (max: @{counter}/@{maxRetries} times)\n'
            'You\'ll be locked in @{retryInSecond}s when the max number of retries is reached',
    this.forgotButtonText = 'Forgot your passcode?',
    this.useBiometricCheckboxText = 'Use biometric authentication',
    this.maxRetriesReachedText =
        'The max number of retries is reached\nPlease try again in @{second}s',
    this.biometricReason = 'Please authenticate to use this feature',
    super.buttonText,
  });
}

class CreateConfig extends DialogConfig {
  /// Configuration for the create dialog.
  const CreateConfig({
    super.content = 'Create Passcode',
    super.subcontent,
    super.buttonText,
  }) : super(incorrectText: '');
}

class RepeatConfig extends DialogConfig {
  /// Configuration for the repeat dialog.
  const RepeatConfig({
    super.content = 'Repeat Passcode',
    super.subcontent,
    super.incorrectText = 'This passcode is incorrect (times: @{counter})',
    super.buttonText,
  });
}
