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
    salt: 'This is a salt value',
    forceCreatePasscode: true,
    title: 'Passcode',
    checkConfig: const CheckConfig(
      maxRetries: 5,
      retryInSecond: 30,
      content: 'Enter Passcode',
      incorrectText:
          'Incorrect passcode (attempt: @{counter} of @{maxRetries}).\n'
          'You must wait @{retryInSecond} seconds before trying again once the maximum number of retries has been exceeded.',
      forgotButtonText: 'Forgot your passcode?',
      useBiometricCheckboxText: 'Use biometric authentication',
      maxRetriesExceededText:
          'Maximum number of retries exceeded.\nPlease try again in @{second} seconds.',
      biometricReason: 'Please authenticate to access this feature',
    ),
    createConfig: const CreateConfig(
      content: 'Create Passcode',
      subcontent:
          'Please remember your passcode. If you forget it, you can reset it, but doing so will remove all your local data and sign you out of your Google account.',
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
          title: const Text('Reset Passcode'),
          content: const Text(
            'Resetting your passcode will remove all of your local data. Would you like to continue?',
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
      },
    );

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
