import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/passcode_biometric_auth.dart';

void main(List<String> args) {
  runApp(const MaterialApp(home: App()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final authUI = PasscodeBiometricAuthUICached(
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
                authUI.authenticate(context);
              },
              child: const Text('Authenticate'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                authUI.changePasscode(context);
              },
              child: const Text('Change Passcode'),
            ),
          ],
        ),
      ),
    );
  }
}
