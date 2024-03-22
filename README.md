# Passcode Biometric Authe

A Flutter package that combines both passcode and biometric effectively.

## Usage

```dart
final passcodeBiometric = PasscodeBiometricAuthUICached(
  forceCreatePasscode: true,
  title: 'Passcode'.tr,
  checkContent: 'Input Passcode'.tr,
  checkIncorrectText:ß
      'This passcode is incorrect (max: @{counter}/@{maxRetries} times)'.tr,
  checkCancelButtonText: 'Cancel'.tr,
  createContent: 'Create Passcode'.tr,
  createSubContent: 'Please remember your passcode. '
          'When you forgot your passcode, you can reset it but '
          'all your cards will be removed from your local storage '
          'and your Google account will be signed out.'
      .tr,
  forgotText: 'Forgot your passcode?'.tr,
  repeatIncorrectText: 'This passcode is not correct'.tr,
  repeatContent: 'Repeat Passcode'.tr,
  useBiometricChecboxText: 'Use biometric authentication'.tr,
  maxRetriesExceeededText:
      'Maximum retries are exceeded\nPlease try again in @{second}s'.tr,
  onForgetPasscode: (context, localAuth) async {
    final isAllowed = await _forgotPassword(context);

    if (isAllowed) {
      await Future.wait([
        googleSignInController.googleSignOut(),
        pageHomeController.removeAllCards(),
        localAuth.useBiometric(false),
      ]);
      return true;
    }

    return false;
  },
  // Optional, default is `AlertDialog`.
  dialogBuilder: (context, title, content, actions) {
    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
    );
  },
);

Future<bool> _forgotPassword(BuildContext context) async {
  final result = await boxWDialog<bool>(
    backgroundColor: generalController.backgroundColor,
    context: context,
    title: 'Reset Passcode'.tr,
    content: Text(
      'When your passcode is reset, all your cards will be '
              'removed from your local storage and your Google account '
              'will be signed out.\n\n'
              'Do you want to continue?'
          .tr,
      textAlign: TextAlign.justify,
    ),
    buttons: (ctx) => [
      Buttons(
        axis: Axis.horizontal,
        buttons: [
          BoxWButton(
            backgroundColor: generalController.appBarColor,
            child: Text('No'.tr),
            onPressed: () {
              Navigator.pop(ctx, false);
            },
          ),
          BoxWButton(
            backgroundColor: generalController.buttonRiskyColor,
            child: Text('Yes'.tr),
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
