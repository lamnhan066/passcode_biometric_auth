/// Base class representing the configuration for passcode dialogs.
abstract class DialogConfig {
  /// The main text content shown above the passcode entry area.
  final String content;

  /// Optional supplementary content displayed below the main text.
  final String? subcontent;

  /// Error message displayed below the passcode field when the passcode is incorrect.
  final String incorrectText;

  /// Optional button text displayed at the bottom of the dialog.
  final String? buttonText;

  /// Creates a dialog configuration.
  const DialogConfig({
    required this.content,
    this.subcontent,
    required this.incorrectText,
    this.buttonText,
  });
}

/// Configuration for the dialog used when checking an existing passcode.
class CheckConfig extends DialogConfig {
  /// Maximum allowed number of passcode entry attempts.
  final int maxRetries;

  /// Delay (in seconds) before allowing retry after maximum attempts have been exceeded.
  /// This delay is cached in local storage, enforcing the wait even if the app is restarted.
  final int retryInSecond;

  /// Text for the "Forgot your passcode?" button.
  final String forgotButtonText;

  /// Error message displayed when the maximum number of retries is exceeded.
  final String maxRetriesExceededText;

  /// Text for a checkbox that offers the option to use biometric authentication.
  final String useBiometricCheckboxText;

  /// Message displayed when requesting biometric authentication.
  final String biometricReason;

  /// Creates a check dialog configuration with optional customizations.
  const CheckConfig({
    this.maxRetries = 5,
    this.retryInSecond = 300,
    super.content = 'Input Passcode',
    super.subcontent,
    super.incorrectText =
        'This passcode is incorrect (max: @{counter}/@{maxRetries} times).\n'
            'Please wait for @{retryInSecond}s before trying again after reaching the maximum retries.',
    this.forgotButtonText = 'Forgot your passcode?',
    this.useBiometricCheckboxText = 'Use biometric authentication',
    this.maxRetriesExceededText =
        'Maximum retries exceeded.\nTry again in @{second}s.',
    this.biometricReason = 'Please authenticate to use this feature',
    super.buttonText,
  });
}

/// Configuration for the dialog used when creating a new passcode.
class CreateConfig extends DialogConfig {
  /// Creates a dialog configuration for creating a new passcode.
  const CreateConfig({
    super.content = 'Create Passcode',
    super.subcontent,
    super.buttonText,
  }) : super(incorrectText: '');
}

/// Configuration for the dialog used when repeating an existing passcode.
class RepeatConfig extends DialogConfig {
  /// Creates a dialog configuration for repeating the passcode entry.
  const RepeatConfig({
    super.content = 'Repeat Passcode',
    super.subcontent,
    super.incorrectText = 'This passcode is incorrect (times: @{counter})',
    super.buttonText,
  });
}
