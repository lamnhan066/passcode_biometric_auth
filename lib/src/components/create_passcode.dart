import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/src/models/dialog_configs.dart';
import 'package:passcode_biometric_auth/src/utils/animated_dialog.dart';
import 'package:pinput/pinput.dart';

import 'repeat_passcode.dart';

class CreatePasscode extends StatelessWidget {
  const CreatePasscode({
    super.key,
    required this.title,
    required this.createConfig,
    required this.repeatConfig,
    required this.hapticFeedbackType,
    required this.dialogBuilder,
  });

  final String title;
  final CreateConfig createConfig;
  final RepeatConfig repeatConfig;
  final HapticFeedbackType hapticFeedbackType;
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? buttons)? dialogBuilder;

  @override
  Widget build(BuildContext context) {
    void onCompleted(code) async {
      final c = await animatedDialog<bool>(
        context: context,
        blurSigma: 0,
        builder: (_) => RepeatPasscode(
          passcode: code,
          title: title,
          repeatConfig: repeatConfig,
          hapticFeedbackType: hapticFeedbackType,
          dialogBuilder: dialogBuilder,
        ),
      );

      if (c == true && context.mounted) {
        final passcodeSHA256 =
            base64Encode(sha256.convert(utf8.encode(code)).bytes);
        Navigator.pop(context, passcodeSHA256);
      }
    }

    final widgetContent = AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(createConfig.content, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Pinput(
              length: 6,
              autofocus: true,
              hapticFeedbackType: hapticFeedbackType,
              obscureText: true,
              closeKeyboardWhenCompleted: false,
              onCompleted: onCompleted,
            ),
          ),
          if (createConfig.subcontent != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                createConfig.subcontent!,
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.justify,
              ),
            ),
        ],
      ),
    );

    final buttons = createConfig.buttonText == null
        ? null
        : [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(createConfig.buttonText!),
            ),
          ];

    Widget child;
    if (dialogBuilder != null) {
      child = dialogBuilder!(context, title, widgetContent, buttons);
    } else {
      child = AlertDialog(
        title: Text(title),
        content: widgetContent,
        actions: buttons,
      );
    }

    return child;
  }
}
