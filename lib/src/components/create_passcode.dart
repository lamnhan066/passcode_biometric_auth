/// A stateless widget that creates a passcode by allowing the user to input a numeric code.
/// After input is complete, it prompts the user to repeat the passcode for confirmation.
/// If confirmed, it returns the passcode hashed using SHA-256.
library;

import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/src/models/dialog_configs.dart';
import 'package:passcode_biometric_auth/src/passcode_biometric_auth.dart';
import 'package:passcode_biometric_auth/src/utils/animated_dialog.dart';
import 'package:pinput/pinput.dart';

import 'repeat_passcode.dart';

class CreatePasscode extends StatelessWidget {
  /// Constructs a CreatePasscode widget.
  ///
  /// [title] is the dialog title.
  ///
  /// [createConfig] holds configuration for the passcode creation properties such as content,
  /// optional subcontent, and button text.
  ///
  /// [repeatConfig] holds configuration for the dialog used to repeat the passcode.
  ///
  /// [hapticFeedbackType] specifies the type of haptic feedback that should be used.
  ///
  /// [dialogBuilder] is an optional function to customize dialog appearance.
  const CreatePasscode({
    super.key,
    required this.salt,
    required this.title,
    required this.createConfig,
    required this.repeatConfig,
    required this.hapticFeedbackType,
    required this.dialogBuilder,
  });

  final String salt;
  final String title;
  final CreateConfig createConfig;
  final RepeatConfig repeatConfig;
  final HapticFeedbackType hapticFeedbackType;
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? buttons)? dialogBuilder;

  @override
  Widget build(BuildContext context) {
    // Callback executed when the passcode input is completed.
    // It prompts the user to repeat the passcode for confirmation.
    // If the confirmation is successful, it hashes the passcode using SHA-256 and returns it.
    void onCompleted(String code) async {
      final confirmed = await animatedDialog<bool>(
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

      // If passcode confirmation succeeded and the widget is still in the widget tree,
      // calculate SHA-256 hash and close the current dialog passing the hash.
      if (confirmed == true && context.mounted) {
        final passcodeSHA256 =
            PasscodeBiometricAuth.sha256FromPasscode(code, salt);
        Navigator.pop(context, passcodeSHA256);
      }
    }

    // Widget containing the content of the passcode creation dialog.
    final widgetContent = AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Display the main instruction for creating the passcode.
          Text(createConfig.content, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8),
            // Pinput widget for entering the passcode. Haptic feedback and secure text
            // (obscured) are enabled.
            child: Pinput(
              length: 6,
              autofocus: true,
              hapticFeedbackType: hapticFeedbackType,
              obscureText: true,
              closeKeyboardWhenCompleted: false,
              onCompleted: onCompleted,
            ),
          ),
          // Optionally display additional instructions if provided.
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

    // Define optional actions (buttons) for the dialog.
    final buttons = createConfig.buttonText == null
        ? null
        : [
            ElevatedButton(
              onPressed: () {
                // Close the dialog without passing any passcode.
                Navigator.pop(context);
              },
              child: Text(createConfig.buttonText!),
            ),
          ];

    // Build the dialog using a custom dialog builder if provided, or default to an AlertDialog.
    return dialogBuilder?.call(context, title, widgetContent, buttons) ??
        AlertDialog(
          title: Text(title),
          content: widgetContent,
          actions: buttons,
        );
  }
}
