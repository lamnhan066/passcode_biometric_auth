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
  final auth = PasscodeBiometricAuthUICached(retryInSecond: 5);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              auth.authenticate(context);
            },
            child: const Text('Lock'),
          ),
        ],
      ),
    );
  }
}
