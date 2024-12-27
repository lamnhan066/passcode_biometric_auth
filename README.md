# Passcode Biometric Auth

A Flutter package that combines both passcode and biometric authentications effectively.

## Passcode Demo

[https://pub.lamnhan.dev/passcode-biometric-auth/](https://pub.lamnhan.dev/passcode-biometric-auth/)

## Usage

```dart
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final auth = PasscodeBiometricAuthUICached(
    forceCreatePasscode: true,
    title: 'Passcode',
    checkConfig: const CheckConfig(
      maxRetries: 5,
      retryInSecond: 30,
      content: 'Input Passcode',
      incorrectText:
          'This passcode is incorrect (max: @{counter}/@{maxRetries} times)\n'
          'You have to wait for @{retryInSecond}s to try again when the max number of retries is exceeded',
      forgotButtonText: 'Forgot your passcode?',
      useBiometricCheckboxText: 'Use biometric authentication',
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
    onForgotPasscode: (context, authUI) async {
      if (await _forgotPasscode(context)) {
        return true;
      }

      return false;
    },
  );

  static Future<bool> _forgotPasscode(BuildContext context) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Forget Passcode'),
            content: const Text(
              'All of your local data will be removed when reset the passcode. Would you like to continue?',
              textAlign: TextAlign.justify,
            ),
            actions: [
              OutlinedButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.pop(ctx, false);
                },
              ),
              ElevatedButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.pop(ctx, true);
                },
              ),
            ],
          );
        });

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passcode Biometric Auth'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                auth.authenticate(context);
              },
              child: const Text('Authenticate'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                auth.changePasscode(context);
              },
              child: const Text('Change Passcode'),
            ),
          ],
        ),
      ),
    );
  }
}
```

Basic methods:

```dart
// Basic authentication
authUI.authenticate(context);

// Change the passcode
authUI.changePasscode(context);
```

Beside that, there're classes that you can use to create your own custom UI:

```dart
/// Base biometric auth
class PasscodeBiometricAuth {
  /// Check whether biometric authentication is available on the current device.
  Future<bool> isBiometricAvailable();

  /// `true`: authenticated
  /// `false`: not authenticated or not available
  Future<bool> isBiometricAuthenticated({
    String biometricReason = 'Please authenticate to use this feature',
  });

  /// Check whether the passcode `code` is correct.
  bool isPasscodeAuthenticated(String code);

  /// Check if there is a passcode.
  bool isAvailablePasscode();
}
```

```dart
/// Base UI
class PasscodeBiometricAuthUI {
  /// This method will automatically handles both passcode and biometric authentications.
  ///
  /// If the `forceCreatePasscode` is set to `true`, the app requests to create a passcode if it's
  /// unavailable. If `false`, the app only requests to create a passcode if
  /// the biometric authentication is unavailable in the device. Default is set to
  /// the global config.
  ///
  /// If the `isUseBiometric` is set to `true`, the app will try to use biometric
  /// authentication if available. Default is set to the global config.
  Future<bool> authenticate(
    BuildContext context, {
    bool? forceCreatePasscode,
    bool? isUseBiometric,
  });

  /// Check whether biometric authentication is available on the current device.
  Future<bool> isBiometricAvailable();

  /// Manually authenticate via biometric authentication.
  Future<bool> authenticateWithBiometric();

  /// Manually authenticate via passcode authentication.
  Future<bool> authenticateWithPasscode(BuildContext context);

  /// Change the passcode.
  Future<bool> changePasscode(BuildContext context);

  /// Check whether the passcode `code` is correct.
  Future<bool> isPasscodeAuthenticated(String code);

  /// Set the `isUseBiometric` value.
  Future<void> useBiometric(bool isUse);

  /// Remove the current passcode.
  Future<void> removePasscode();

  /// Check whether the passcode is available.
  FutureOr<bool> isAvailablePasscode();
}
```

And the `PasscodeBiometricAuthUICached` is just a `PasscodeBiometricAuthUI` with built-in `onRead` and `onWrite` using `SharedPreferences`. If you want to use a more secure way to cache the data then you need to use the `PasscodeBiometricAuthUI`.
