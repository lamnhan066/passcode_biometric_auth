# Passcode Biometric Auth

A Flutter package that combines both passcode and biometric authentications effectively.

## Passcode Demo

[https://pub.lamnhan.dev/passcode-biometric-auth/](https://pub.lamnhan.dev/passcode-biometric-auth/)

## Usage

Create an instance:

```dart
final authUI = PasscodeBiometricAuthUICached(
  forceCreatePasscode: true,
  title: 'Passcode',
  checkConfig: const CheckConfig(
    content: 'Input Passcode',
    incorrectText:
        'This passcode is incorrect (max: @{counter}/@{maxRetries} times)\n'
        'The app will be locked in @{retryInSecond}s when the max number of retries is exceeded',
    forgotButtonText: 'Forgot your passcode?',
    useBiometricCheckboxText: 'Use biometric authentication',
    maxRetries: 5,
    maxRetriesExceededText:
        'Maximum number of retries is exceeded\nPlease try again in @{second}s',
    biometricReason: 'Please authenticate to use this feature',
  ),
  createConfig: const CreateConfig(
    content: 'Create Passcode',
    subcontent: 'Please remember your passcode. '
        'When you forget your passcode, you can reset it but '
        'all your cards will be removed from your local storage '
        'and your Google account will be signed out.',
  ),
  repeatConfig: const RepeatConfig(
    content: 'Repeat Passcode',
    incorrectText: 'This passcode is not correct',
  ),
  onForgotPasscode: (context, authUI) async {
    final isAllowed = await _forgotPassword(context);

    if (isAllowed) {
      await Future.wait([
        googleSignInController.googleSignOut(),
        pageHomeController.removeAllCards(),
        authUI.useBiometric(false),
      ]);
      return true;
    }

    return false;
  },
  dialogBuilder: (context, title, content, actions) {
    return BoxWDialog(
      showCloseButton: true,
      backgroundColor: generalController.backgroundColor,
      title: title,
      content: content,
    );
  },
);

Future<bool> _forgotPassword(BuildContext context) async {
  final result = await boxWDialog<bool>(
    backgroundColor: generalController.backgroundColor,
    context: context,
    title: 'Reset Passcode',
    content: const Text(
      'When your passcode is reset, all your cards will be '
      'removed from your local storage and your Google account '
      'will be signed out.\n\n'
      'Do you want to continue?',
      textAlign: TextAlign.justify,
    ),
    buttons: (ctx) => [
      Buttons(
        axis: Axis.horizontal,
        buttons: [
          BoxWButton(
            backgroundColor: generalController.appBarColor,
            child: const Text('No'),
            onPressed: () {
              Navigator.pop(ctx, false);
            },
          ),
          BoxWButton(
            backgroundColor: generalController.buttonRiskyColor,
            child: const Text('Yes'),
            onPressed: () {
              Navigator.pop(ctx, true);
            },
          ),
        ],
      )
    ],
  );

  return result == true;
}
```

Basic methods:

```dart
// Basic authentication
authUI.authenticate(context);

// Change the passcode
authUI.changePasscode(context);
```
