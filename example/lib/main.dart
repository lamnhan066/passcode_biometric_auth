import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/passcode_biometric_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: App(),
    );
  }
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
    onForgotPasscode: _handleForgotPasscode,
  );

  static Future<bool> _handleForgotPasscode(
      BuildContext context, PasscodeBiometricAuthUI authUI) async {
    return await _showResetPasscodeDialog(context);
  }

  static Future<bool> _showResetPasscodeDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Passcode'),
        content: const Text(
          'Resetting your passcode will remove all of your local data. '
          'Would you like to continue?',
          textAlign: TextAlign.justify,
        ),
        actions: [
          OutlinedButton(
            child: const Text('No'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            child: const Text('Yes'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _authenticate() {
    authUI.authenticate(context).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: $error')),
        );
      }
      return false;
    });
  }

  void _changePasscode() {
    authUI.changePasscode(context).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Change passcode error: $error')),
        );
      }
      return false;
    });
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
              onPressed: _authenticate,
              child: const Text('Authenticate'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePasscode,
              child: const Text('Change Passcode'),
            ),
          ],
        ),
      ),
    );
  }
}
