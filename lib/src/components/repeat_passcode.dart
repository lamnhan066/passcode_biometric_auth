import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/src/models/dialog_configs.dart';
import 'package:pinput/pinput.dart';

class RepeatPasscode extends StatefulWidget {
  const RepeatPasscode({
    super.key,
    required this.passcode,
    required this.title,
    required this.repeatConfig,
    required this.hapticFeedbackType,
    required this.dialogBuilder,
  });

  final String passcode;
  final String title;
  final RepeatConfig repeatConfig;
  final HapticFeedbackType hapticFeedbackType;
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? buttons)? dialogBuilder;

  @override
  State<RepeatPasscode> createState() => _RepeatPasscodeState();
}

class _RepeatPasscodeState extends State<RepeatPasscode> {
  final textController = TextEditingController();
  final focusNode = FocusNode();
  String? error;
  int _retryCounter = 0;

  void onCompleted(code) {
    if (code == widget.passcode) {
      focusNode.unfocus();
      Navigator.pop(context, true);
    } else {
      _retryCounter++;
      textController.clear();
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        FocusScope.of(context).requestFocus(focusNode);
      });
      setState(() {
        error = widget.repeatConfig.incorrectText
            .replaceAll('@{counter}', '$_retryCounter')
            .replaceAll('@{maxRetries}', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;

    final content = AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.repeatConfig.content,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Pinput(
              controller: textController,
              focusNode: focusNode,
              autofocus: true,
              length: 6,
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              obscureText: true,
              closeKeyboardWhenCompleted: false,
              onCompleted: onCompleted,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );

    final buttons = widget.repeatConfig.buttonText == null
        ? null
        : [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(widget.repeatConfig.buttonText!),
            ),
          ];

    Widget child;
    if (widget.dialogBuilder != null) {
      child = widget.dialogBuilder!(context, title, content, buttons);
    } else {
      child = AlertDialog(
        title: Text(title),
        content: content,
        actions: buttons,
      );
    }

    return child;
  }
}
