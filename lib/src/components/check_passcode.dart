import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../models/check_passcode_state.dart';
import '../models/on_read.dart';
import '../models/on_write.dart';
import '../passcode_biometric_auth_ui.dart';
import '../pref_keys.dart';

class CheckPasscode extends StatefulWidget {
  const CheckPasscode({
    super.key,
    required this.maxRetries,
    required this.retryInSecond,
    required this.localAuth,
    required this.sha256Passcode,
    required this.title,
    required this.content,
    required this.forgetText,
    required this.incorrectText,
    required this.useBiometricChecboxText,
    required this.maxRetriesExceededText,
    required this.onForgetPasscode,
    required this.onMaxRetriesExceeded,
    required this.cancelButtonText,
    required this.onRead,
    required this.onWrite,
    required this.hapticFeedbackType,
  });

  final int maxRetries;
  final int retryInSecond;
  final PasscodeBiometricAuthUI localAuth;
  final String? sha256Passcode;
  final String title;
  final String content;
  final String forgetText;
  final String incorrectText;
  final String maxRetriesExceededText;
  final String? useBiometricChecboxText;
  final String? cancelButtonText;
  final Future<void> Function()? onForgetPasscode;
  final void Function()? onMaxRetriesExceeded;
  final OnRead? onRead;
  final OnWrite? onWrite;
  final HapticFeedbackType hapticFeedbackType;

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
      if (_retryCounter >= widget.maxRetries) {
        maxRetriesExceededCounter(widget.retryInSecond * 1000);
      } else {
        setState(() {
          error = widget.incorrectText
              .replaceAll('@{counter}', '$_retryCounter')
              .replaceAll('@{maxRetries}', '${widget.maxRetries}');
        });
      }
    }
  }

  void onChanged(String code) {
    if (error != null && code.length < 6) {
      setState(() {
        error = null;
      });
    }
  }

  void maxRetriesExceededCounter(int retryInSecond) {
    timer?.cancel();
    _retryCounter = widget.maxRetries;
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
        Future.delayed(const Duration(milliseconds: 100)).then((value) {
          FocusScope.of(context).requestFocus(focusNode);
        });
        timer.cancel();
        widget.onWrite?.writeInt(PrefKeys.lastRetriesExceededSecond, 0);
        return;
      }
      if (second % 1000 == 0) {
        widget.onWrite?.writeInt(PrefKeys.lastRetriesExceededSecond, second);
      }
      setState(() {
        error = widget.maxRetriesExceededText
            .replaceAll('@{second}', (second / 1000).toStringAsFixed(2));
      });
    });
  }

  void init() async {
    final second =
        await widget.onRead?.readInt(PrefKeys.lastRetriesExceededSecond);
    if (second != null && second > 0) {
      maxRetriesExceededCounter(second);
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
    return AlertDialog(
      title: Text(widget.title),
      content: AnimatedSize(
        alignment: Alignment.topCenter,
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
                focusNode: focusNode,
                enabled: _retryCounter < widget.maxRetries,
                length: 6,
                autofocus: true,
                hapticFeedbackType: widget.hapticFeedbackType,
                obscureText: true,
                onCompleted: onCompleted,
                onChanged: onChanged,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
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
                    widget.forgetText,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            if (widget.useBiometricChecboxText != null)
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
                                            .isBiometricAuthenticated() ==
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
                            Text(widget.useBiometricChecboxText!),
                          ],
                        );
                      });
                },
              ),
          ],
        ),
      ),
      actions: widget.cancelButtonText == null
          ? null
          : [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(widget.cancelButtonText!),
              ),
            ],
    );
  }
}
