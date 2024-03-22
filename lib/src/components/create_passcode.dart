import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/src/utils/animated_dialog.dart';
import 'package:pinput/pinput.dart';

import 'repeat_passcode.dart';

class CreatePasscode extends StatelessWidget {
  const CreatePasscode({
    super.key,
    required this.title,
    required this.content,
    required this.subContent,
    required this.repeatContent,
    required this.incorrectText,
    required this.hapticFeedbackType,
    required this.cancelButtonText,
    required this.repeatBackButtonText,
    required this.dialogBuilder,
  });

  final String title;
  final String content;
  final String? subContent;
  final String repeatContent;
  final String incorrectText;
  final String? cancelButtonText;
  final String? repeatBackButtonText;
  final HapticFeedbackType hapticFeedbackType;
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? buttons)? dialogBuilder;

  @override
  Widget build(BuildContext context) {
    final widgetContent = AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(content, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Pinput(
              length: 6,
              autofocus: true,
              hapticFeedbackType: hapticFeedbackType,
              obscureText: true,
              closeKeyboardWhenCompleted: false,
              onCompleted: (code) async {
                final c = await animatedDialog<bool>(
                  context: context,
                  blurSigma: 0,
                  builder: (_) => RepeatPasscode(
                    passcode: code,
                    title: title,
                    content: repeatContent,
                    incorrectText: incorrectText,
                    hapticFeedbackType: hapticFeedbackType,
                    backButtonText: repeatBackButtonText,
                    dialogBuilder: dialogBuilder,
                  ),
                );

                if (c == true && context.mounted) {
                  final passcodeSHA256 =
                      base64Encode(sha256.convert(utf8.encode(code)).bytes);
                  Navigator.pop(context, passcodeSHA256);
                }
              },
            ),
          ),
          if (subContent != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                subContent!,
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.justify,
              ),
            ),
        ],
      ),
    );
    final buttons = cancelButtonText == null
        ? null
        : [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(cancelButtonText!),
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
