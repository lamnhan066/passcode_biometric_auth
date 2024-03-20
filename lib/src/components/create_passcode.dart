import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
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
  });

  final String title;
  final String content;
  final String? subContent;
  final String repeatContent;
  final String incorrectText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(content, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 50,
              child: Pinput(
                length: 6,
                autofocus: true,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                obscureText: true,
                onCompleted: (code) async {
                  final c = await showDialog<bool>(
                    context: context,
                    builder: (_) => RepeatPasscode(
                      passcode: code,
                      title: title,
                      content: repeatContent,
                      incorrectText: incorrectText,
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
          ),
          if (subContent != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                subContent!,
                textAlign: TextAlign.justify,
              ),
            ),
        ],
      ),
    );
  }
}
