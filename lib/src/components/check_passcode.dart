// This file defines the CheckPasscode widget which lets users verify their passcode
// and optionally authenticate using biometrics. It handles retry counters and displays
// feedback messages based on user inputs and configuration settings.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/src/models/dialog_configs.dart';
import 'package:pinput/pinput.dart';

import '../models/check_passcode_state.dart';
import '../models/on_read.dart';
import '../models/on_write.dart';
import '../passcode_biometric_auth_ui.dart';
import '../utils/pref_keys.dart';

/// A StatefulWidget that displays a passcode check UI with optional biometric
/// authentication support.
class CheckPasscode extends StatefulWidget {
  const CheckPasscode({
    super.key,
    required this.localAuth,
    required this.sha256Passcode,
    required this.title,
    required this.checkConfig,
    required this.onForgetPasscode,
    required this.onMaxRetriesExceeded,
    required this.onRead,
    required this.onWrite,
    required this.hapticFeedbackType,
    required this.dialogBuilder,
  });

  /// Instance of PasscodeBiometricAuthUI for managing authentication.
  final PasscodeBiometricAuthUI localAuth;

  /// The passcode stored in sha256 format.
  final String? sha256Passcode;

  /// Title to be shown in UI.
  final String title;

  /// Configuration settings for the passcode checking process.
  final CheckConfig checkConfig;

  /// Callback when the user taps on the "forget passcode" action.
  final Future<void> Function()? onForgetPasscode;

  /// Callback when maximum retries are exceeded.
  final void Function()? onMaxRetriesExceeded;

  /// Callback for reading data (e.g., retries remaining).
  final OnRead? onRead;

  /// Callback for writing data (e.g., updating retry counter).
  final OnWrite? onWrite;

  /// Haptic feedback type to use.
  final HapticFeedbackType hapticFeedbackType;

  /// Custom dialog builder for customizing the UI.
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? actions)? dialogBuilder;

  @override
  State<CheckPasscode> createState() => _CheckPasscodeState();
}

class _CheckPasscodeState extends State<CheckPasscode> {
  // Controller for managing passcode input.
  final textController = TextEditingController();
  // Focus node for the input field.
  final focusNode = FocusNode();
  // Variable holding current error message, if any.
  String? error;
  // Flag indicating whether biometric authentication is enabled.
  bool? isBiometricChecked;
  // Counter to track number of failed attempts.
  int _retryCounter = 0;
  // Timer to handle the waiting period when maximum retries are exceeded.
  Timer? timer;

  /// Called when the user completes entering the passcode.
  /// It validates the input and handles success or failure scenarios.
  void onCompleted(String code) async {
    if (await widget.localAuth.isPasscodeAuthenticated(code) && mounted) {
      // Successful authentication: remove focus and return success state.
      focusNode.unfocus();
      Navigator.pop(
        context,
        CheckPasscodeState(
          isAuthenticated: true,
          isUseBiometric: isBiometricChecked ?? false,
        ),
      );
    } else {
      // Increase the retry counter and clear input.
      _retryCounter++;
      textController.clear();
      Future.delayed(const Duration(milliseconds: 100)).then((value) {
        if (mounted) FocusScope.of(context).requestFocus(focusNode);
      });
      // If retries reached maximum, start the cooldown timer.
      if (_retryCounter >= widget.checkConfig.maxRetries) {
        maxRetriesExceededCounter(widget.checkConfig.retryInSecond * 1000);
      } else {
        // Update error message to notify the user about the incorrect passcode
        // and retry count.
        setState(() {
          error = widget.checkConfig.incorrectText
              .replaceAll('@{counter}', '$_retryCounter')
              .replaceAll('@{maxRetries}', '${widget.checkConfig.maxRetries}')
              .replaceAll(
                  '@{retryInSecond}', '${widget.checkConfig.retryInSecond}');
        });
      }
    }
  }

  /// Starts a timer that counts down during the cooldown period after maximum
  /// retries have been exceeded.
  /// [retryInSecond] is provided in milliseconds.
  void maxRetriesExceededCounter(int retryInSecond) {
    timer?.cancel();
    _retryCounter = widget.checkConfig.maxRetries;
    int second = retryInSecond;
    // Trigger callback if maximum retries exceeded.
    if (widget.onMaxRetriesExceeded != null) {
      widget.onMaxRetriesExceeded!();
    }
    // Periodically update the UI to reflect the remaining cooldown time.
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      second -= 100;
      if (second <= 0) {
        timer.cancel();
        setState(() {
          _retryCounter = 0;
          error = null;
        });
        Future.delayed(const Duration(milliseconds: 500)).then((value) {
          if (mounted) FocusScope.of(context).requestFocus(focusNode);
        });
        widget.onWrite?.writeInt(
          PrefKeys.createKey(
            widget.localAuth.prefix,
            PrefKeys.lastRetriesExceededRemainingSecond,
          ),
          0,
        );
        return;
      }
      // Update persistent storage every one second.
      if (second % 1000 == 0) {
        widget.onWrite?.writeInt(
          PrefKeys.createKey(
            widget.localAuth.prefix,
            PrefKeys.lastRetriesExceededRemainingSecond,
          ),
          second,
        );
      }
      setState(() {
        error = widget.checkConfig.maxRetriesExceededText
            .replaceAll('@{second}', (second / 1000).toStringAsFixed(2));
      });
    });
  }

  /// Initialize the widget:
  /// If there's a cooldown value stored (e.g., from a previous session),
  /// it starts the cooldown timer; otherwise, set focus to input.
  void init() async {
    final second = await widget.onRead?.readInt(
      PrefKeys.createKey(
        widget.localAuth.prefix,
        PrefKeys.lastRetriesExceededRemainingSecond,
      ),
    );
    if (second != null && second > 0) {
      maxRetriesExceededCounter(second);
    } else {
      focusNode.requestFocus();
    }
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    // Cancel timers and dispose controllers to avoid memory leaks.
    timer?.cancel();
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;

    // Layout content with animation for smoother error message display.
    final content = AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Display instructional text.
          Text(widget.checkConfig.content,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          // Pinput widget is used for passcode entry.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Pinput(
              controller: textController,
              focusNode: focusNode,
              enabled: _retryCounter < widget.checkConfig.maxRetries,
              length: 6,
              hapticFeedbackType: widget.hapticFeedbackType,
              obscureText: true,
              closeKeyboardWhenCompleted: false,
              onCompleted: onCompleted,
            ),
          ),
          // Display error message if exists.
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          // "Forgot Passcode" button.
          if (widget.onForgetPasscode != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  widget.onForgetPasscode!();
                },
                child: Text(
                  widget.checkConfig.forgotButtonText,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          // Check for biometric availability and show checkbox if available.
          FutureBuilder(
            future: widget.localAuth.isBiometricAvailable(),
            builder: (ctx, snapshot) {
              if (!snapshot.hasData || snapshot.data != true) {
                return const SizedBox.shrink();
              }
              return FutureBuilder<bool>(
                  future: Future.value(widget.localAuth.isUseBiometric),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    // Set initial biometric checkbox state if not set.
                    if (snapshot.hasData && isBiometricChecked == null) {
                      isBiometricChecked = snapshot.data!;
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: isBiometricChecked,
                          onChanged: (value) async {
                            if (value == null) return;

                            if (value == true) {
                              // Authenticate user with biometric when checkbox is checked.
                              final authenticated = await widget.localAuth
                                  .authenticateWithBiometric();
                              if (authenticated == true) {
                                setState(() {
                                  isBiometricChecked = true;
                                });
                              }
                            } else {
                              setState(() {
                                isBiometricChecked = false;
                              });
                            }
                          },
                        ),
                        Text(widget.checkConfig.useBiometricCheckboxText),
                      ],
                    );
                  });
            },
          ),
        ],
      ),
    );

    // Define actions (buttons) for the dialog based on configuration.
    final actions = widget.checkConfig.buttonText == null
        ? null
        : [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(widget.checkConfig.buttonText!),
            ),
          ];

    Widget child;
    // Use a custom dialog builder if provided, otherwise default to AlertDialog.
    if (widget.dialogBuilder != null) {
      child = widget.dialogBuilder!(context, title, content, actions);
    } else {
      child = AlertDialog(
        title: Text(widget.title),
        content: content,
        actions: actions,
      );
    }

    return child;
  }
}
