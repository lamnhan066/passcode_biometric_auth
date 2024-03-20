import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../models/check_passcode_state.dart';
import '../models/on_read.dart';
import '../models/on_write.dart';
import '../passcode_biometric_auth_ui.dart';

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
    required this.onRead,
    required this.onWrite,
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
  final Future<void> Function(BuildContext context)? onForgetPasscode;
  final void Function(BuildContext context, int retriesNumber)?
      onMaxRetriesExceeded;
  final OnRead? onRead;
  final OnWrite? onWrite;

  @override
  State<CheckPasscode> createState() => _CheckPasscodeState();
}

class _CheckPasscodeState extends State<CheckPasscode> {
  final textController = TextEditingController();
  final focus = FocusNode();
  String? error;
  bool? isBiometricChecked;
  int _retryCounter = 0;

  void onCompleted(String code) async {
    final passcodeSHA256 =
        base64Encode(sha256.convert(utf8.encode(code)).bytes);
    if (passcodeSHA256 == widget.sha256Passcode && mounted) {
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
        FocusScope.of(context).requestFocus(focus);
      });
      if (_retryCounter >= widget.maxRetries) {
        int second = widget.retryInSecond * 1000;
        if (widget.onMaxRetriesExceeded != null) {
          widget.onMaxRetriesExceeded!(context, _retryCounter);
        }
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          second -= 100;
          if (second <= 0) {
            setState(() {
              _retryCounter = 0;
              error = null;
            });
            Future.delayed(const Duration(milliseconds: 100)).then((value) {
              FocusScope.of(context).requestFocus(focus);
            });
            timer.cancel();
            return;
          }
          setState(() {
            error = widget.maxRetriesExceededText
                .replaceAll('@{second}', (second / 1000).toStringAsFixed(2));
          });
        });
      } else {
        setState(() {
          error =
              widget.incorrectText.replaceAll('@{counter}', '$_retryCounter');
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
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
              enabled: _retryCounter < widget.maxRetries,
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
          if (widget.onForgetPasscode != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await widget.onForgetPasscode!(context);
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
    );
  }
}
