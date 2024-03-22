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
  final auth = PasscodeBiometricAuthUICached(
    checkConfig: const CheckConfig(
      maxRetries: 5,
      waitWhenMaxRetriesReached: 30,
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
