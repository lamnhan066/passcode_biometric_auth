# passcode_biometric_auth

A new Flutter plugin project.

## Getting Started

```dart

final localAuth = PasscodeBiometricAuthAuto(
  isUseBiometricKey: 'IsUseBiometric',
  sha256PasscodeKey: 'Sha256Passcode',
  forceCreatePasscode: true,
  title: 'Passcode',
  inputContent: 'Input your passcode',
  createContent: 'Create your passcode',
  createSubContent: 'Please remember your passcode. '
      'When you forget your passcode, you can reset it but '
      'all your cards will be removed from your local storage '
      'and your Google account will be signed out.',
  forgetText: 'Forgot your passcode?',
  incorrectText: 'This passcode is not correct',
  repeatContent: 'Repeat your passcode',
  useBiometricChecboxText: 'Use biometric authentication',
  onForgetPasscode: (context, localAuth) async {
    final isForget = await _forgetPassword(context,
        title: 'Reset your Passcode',
        content: 'Do you want to reset your passcode?');

    if (isForget) {
      return true;
    }

    return false;
  },
);

Future<bool> _forgetPassword(
  BuildContext context, {
  String title = 'Reset your Passcode',
  required String content,
  String yesText = 'Yes',
  String noText = 'No',
}) async {
  final result = await boxWDialog<bool>(
    context: context,
    title: title,
    content: Text(
      content,
      textAlign: TextAlign.justify,
    ),
    buttons: (ctx) => [
      Buttons(
        axis: Axis.horizontal,
        buttons: [
          BoxWButton(
            child: Text(noText),
            onPressed: () {
              Navigator.pop(ctx, false);
            },
          ),
          BoxWOutlinedButton(
            child: Text(yesText),
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
