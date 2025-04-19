import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/passcode_biometric_auth.dart';
import 'package:pinput/pinput.dart';

/// A widget that repeats the entered passcode and verifies if it matches the original.
/// Displays an error and lets the user retry if the passcode does not match.
class RepeatPasscode extends StatefulWidget {
  const RepeatPasscode({
    super.key,
    required this.sha256Passcode,
    required this.salt,
    required this.title,
    required this.repeatConfig,
    required this.hapticFeedbackType,
    required this.dialogBuilder,
  });

  /// The initial passcode that the user needs to re-enter.
  final String sha256Passcode;

  /// A salt string used for additional security when hashing the passcode.
  final String salt;

  /// The title of the dialog or screen.
  final String title;

  /// Configuration for repeat passcode including error messages and related settings.
  final RepeatConfig repeatConfig;

  /// The type of haptic feedback to provide.
  final HapticFeedbackType hapticFeedbackType;

  /// Optional builder for customizing the dialog UI.
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? buttons)? dialogBuilder;

  @override
  State<RepeatPasscode> createState() => _RepeatPasscodeState();
}

/// State class for RepeatPasscode widget.
class _RepeatPasscodeState extends State<RepeatPasscode> {
  // Controller to manage the text input of the passcode.
  final textController = TextEditingController();

  // FocusNode to manage the input focus.
  final focusNode = FocusNode();

  // Holds the error message when the entered passcode is incorrect.
  String? error;

  // Number of retry attempts for entering the correct passcode.
  int _retryCounter = 0;

  /// Callback when the user completes entering the passcode.
  /// It verifies if the entered passcode matches the original.
  void onCompleted(String code) {
    final sha256Passcode = PasscodeBiometricAuth.sha256FromPasscode(
      code,
      widget.salt,
    );
    if (sha256Passcode == widget.sha256Passcode) {
      // If passcode matches, unfocus the input and close dialog with success.
      focusNode.unfocus();
      Navigator.pop(context, true);
    } else {
      // Increase retry counter on mismatches.
      _retryCounter++;
      // Clear the input field.
      textController.clear();

      // Delay refocusing to give subtle feedback to the user.
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        if (mounted) FocusScope.of(context).requestFocus(focusNode);
      });

      // Set error message with retry counter info.
      setState(() {
        error = widget.repeatConfig.incorrectText
            .replaceAll('@{counter}', '$_retryCounter')
            .replaceAll('@{maxRetries}',
                ''); // You can update this if max retry info is available.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;

    // Build the content of the dialog including instructions, input field, and error message.
    final content = AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Display the instruction or content text from repeatConfig.
          Text(
            widget.repeatConfig.content,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          // Container for the passcode input field.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Pinput(
              controller: textController,
              focusNode: focusNode,
              autofocus: true,
              length: 6, // Expected length of the passcode.
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              obscureText: true,
              closeKeyboardWhenCompleted: false,
              // Callback once input is completed.
              onCompleted: onCompleted,
            ),
          ),
          // Display error message if passcode entry is incorrect.
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

    // Build the optional cancel button if defined in repeatConfig.
    final buttons = widget.repeatConfig.buttonText == null
        ? null
        : [
            ElevatedButton(
              onPressed: () {
                // Pop the current context without a success result.
                Navigator.pop(context);
              },
              child: Text(widget.repeatConfig.buttonText!),
            ),
          ];

    // Use custom dialog builder if provided, otherwise fallback to AlertDialog.
    return widget.dialogBuilder?.call(context, title, content, buttons) ??
        AlertDialog(
          title: Text(title),
          content: content,
          actions: buttons,
        );
  }
}
