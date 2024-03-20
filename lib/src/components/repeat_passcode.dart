import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class RepeatPasscode extends StatefulWidget {
  const RepeatPasscode({
    super.key,
    required this.passcode,
    required this.title,
    required this.content,
    required this.incorrectText,
    required this.hapticFeedbackType,
  });

  final String passcode;
  final String title;
  final String content;
  final String incorrectText;
  final HapticFeedbackType hapticFeedbackType;

  @override
  State<RepeatPasscode> createState() => _RepeatPasscodeState();
}

class _RepeatPasscodeState extends State<RepeatPasscode> {
  final textController = TextEditingController();
  final focus = FocusNode();
  String? error;
  int _retryCounter = 0;

  void onCompleted(code) {
    if (code == widget.passcode) {
      Navigator.pop(context, true);
    } else {
      _retryCounter++;
      textController.clear();
      Future.delayed(const Duration(milliseconds: 100)).then((value) {
        FocusScope.of(context).requestFocus(focus);
      });
      setState(() {
        error = widget.incorrectText
            .replaceAll('@{counter}', '$_retryCounter')
            .replaceAll('@{maxRetries}', '');
      });
    }
  }

  void onChanged(code) {
    if (error != null && code.length < 6) {
      setState(() {
        error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: AnimatedSize(
        duration: const Duration(milliseconds: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.content, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Pinput(
                controller: textController,
                focusNode: focus,
                length: 6,
                autofocus: true,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                obscureText: true,
                onCompleted: onCompleted,
                onChanged: onChanged,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
