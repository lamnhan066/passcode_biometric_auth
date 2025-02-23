/// A stateless widget that requests passcode creation and confirmation, then
/// returns the passcode hashed with SHA-256 and a provided salt.
library;

import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/src/models/dialog_configs.dart';
import 'package:passcode_biometric_auth/src/passcode_biometric_auth.dart';
import 'package:pinput/pinput.dart';

class CreatePasscode extends StatelessWidget {
  /// Constructs a widget to create and confirm a passcode.
  ///
  /// The [salt] is used when hashing the passcode.
  /// [title] is displayed at the top of the dialog.
  /// [createConfig] manages text/content for passcode creation.
  /// [repeatConfig] manages content for the confirmation dialog.
  /// [hapticFeedbackType] configures vibration feedback on passcode input.
  /// If [dialogBuilder] is provided, it replaces the default dialog UI.
  const CreatePasscode({
    super.key,
    required this.salt,
    required this.title,
    required this.createConfig,
    required this.repeatConfig,
    required this.hapticFeedbackType,
    required this.dialogBuilder,
  });

  /// Salt appended to the passcode before hashing.
  final String salt;

  /// Dialog title displayed during passcode creation.
  final String title;

  /// Configuration for the passcode creation dialog text.
  final CreateConfig createConfig;

  /// Configuration for the dialog used when repeating the passcode.
  final RepeatConfig repeatConfig;

  /// Sets the type of haptic feedback for the passcode input.
  final HapticFeedbackType hapticFeedbackType;

  /// Overrides the default dialog design if provided.
  final Widget Function(
    BuildContext context,
    String title,
    Widget content,
    List<Widget>? buttons,
  )? dialogBuilder;

  @override
  Widget build(BuildContext context) {
    // Handles user completion of passcode input:
    // 1. Passcode is hashed with the salt.
    // 2. The result is returned to the calling navigator.
    void onCompleted(String code) async {
      final passcodeSHA256 = PasscodeBiometricAuth.sha256FromPasscode(
        code,
        salt,
      );
      Navigator.pop(context, passcodeSHA256);
    }

    // Main content of the create passcode dialog, including instructions,
    // passcode entry, and optional subcontent.
    final widgetContent = AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Primary instruction text
          Text(createConfig.content, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          // Passcode input field
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
          // Displays additional instructions if provided
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

    // Optional action buttons for the dialog
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

    // Builds the dialog using a custom dialog builder if provided,
    // otherwise defaults to AlertDialog.
    return dialogBuilder?.call(context, title, widgetContent, buttons) ??
        AlertDialog(
          title: Text(title),
          content: widgetContent,
          actions: buttons,
        );
  }
}
