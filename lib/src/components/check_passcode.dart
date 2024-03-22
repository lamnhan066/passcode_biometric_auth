import 'dart:async';

import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/src/models/dialog_configs.dart';
import 'package:pinput/pinput.dart';

import '../models/check_passcode_state.dart';
import '../models/on_read.dart';
import '../models/on_write.dart';
import '../passcode_biometric_auth_ui.dart';
import '../utils/pref_keys.dart';

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

  final PasscodeBiometricAuthUI localAuth;
  final String? sha256Passcode;
  final String title;
  final CheckConfig checkConfig;
  final Future<void> Function()? onForgetPasscode;
  final void Function()? onMaxRetriesExceeded;
  final OnRead? onRead;
  final OnWrite? onWrite;
  final HapticFeedbackType hapticFeedbackType;
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? actions)? dialogBuilder;

  @override
  State<CheckPasscode> createState() => _CheckPasscodeState();
}

class _CheckPasscodeState extends State<CheckPasscode> {
  final textController = TextEditingController();
  final focusNode = FocusNode();
  String? error;
  bool? isBiometricChecked;
  int _retryCounter = 0;
  Timer? timer;

  void onCompleted(String code) async {
    if (await widget.localAuth.isPasscodeAuthenticated(code) && mounted) {
      focusNode.unfocus();
      Navigator.pop(
        context,
        CheckPasscodeState(
          isAuthenticated: true,
          isUseBiometric: isBiometricChecked ?? false,
        ),
      );
    } else {
      _retryCounter++;
      textController.clear();
      Future.delayed(const Duration(milliseconds: 100)).then((value) {
        FocusScope.of(context).requestFocus(focusNode);
      });
      if (_retryCounter >= widget.checkConfig.maxRetries) {
        maxRetriesExceededCounter(
            widget.checkConfig.waitWhenMaxRetriesExceeded * 1000);
      } else {
        setState(() {
          error = widget.checkConfig.incorrectText
              .replaceAll('@{counter}', '$_retryCounter')
              .replaceAll('@{maxRetries}', '${widget.checkConfig.maxRetries}')
              .replaceAll('@{retryInSecond}',
                  '${widget.checkConfig.waitWhenMaxRetriesExceeded}');
        });
      }
    }
  }

  void maxRetriesExceededCounter(int retryInSecond) {
    timer?.cancel();
    _retryCounter = widget.checkConfig.maxRetries;
    int second = retryInSecond;
    if (widget.onMaxRetriesExceeded != null) {
      widget.onMaxRetriesExceeded!();
    }
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      second -= 100;
      if (second <= 0) {
        setState(() {
          _retryCounter = 0;
          error = null;
        });
        Future.delayed(const Duration(milliseconds: 500)).then((value) {
          FocusScope.of(context).requestFocus(focusNode);
        });
        timer.cancel();
        widget.onWrite
            ?.writeInt(PrefKeys.lastRetriesExceededRemainingSecond, 0);
        return;
      }
      if (second % 1000 == 0) {
        widget.onWrite
            ?.writeInt(PrefKeys.lastRetriesExceededRemainingSecond, second);
      }
      setState(() {
        error = widget.checkConfig.maxRetriesExceededText
            .replaceAll('@{second}', (second / 1000).toStringAsFixed(2));
      });
    });
  }

  void init() async {
    final second = await widget.onRead
        ?.readInt(PrefKeys.lastRetriesExceededRemainingSecond);
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
    timer?.cancel();
    textController.dispose();
    focusNode.dispose();
    super.dispose();
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
          Text(widget.checkConfig.content,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
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
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
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

                    if (snapshot.hasData && isBiometricChecked == null) {
                      isBiometricChecked = snapshot.data!;
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: isBiometricChecked,
                          onChanged: (value) async {
                            if (value != null) {
                              if (value == true) {
                                if (await widget.localAuth
                                        .authenticateWithBiometric() ==
                                    true) {
                                  setState(() {
                                    isBiometricChecked = true;
                                  });
                                }
                              } else {
                                setState(() {
                                  isBiometricChecked = false;
                                });
                              }
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
