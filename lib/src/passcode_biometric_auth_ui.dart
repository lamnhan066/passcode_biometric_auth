import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:passcode_biometric_auth/passcode_biometric_auth.dart';
import 'package:passcode_biometric_auth/src/components/repeat_passcode.dart';
import 'package:passcode_biometric_auth/src/models/check_passcode_state.dart';
import 'package:passcode_biometric_auth/src/utils/animated_dialog.dart';
import 'package:pinput/pinput.dart';

import 'components/check_passcode.dart';
import 'components/create_passcode.dart';
import 'utils/pref_keys.dart';

/// UI handler for passcode and biometric authentication dialogs.
///
/// Manages displaying dialogs for passcode and biometric authentication,
/// and handles configuration persistence via provided [onRead] and [onWrite]
/// callbacks. It supports operations such as authenticating, creating a new
/// passcode, changing an existing passcode, and removing a passcode.
class PasscodeBiometricAuthUI {
  /// Prefix used when storing configuration data.
  final String prefix;

  /// The salt used to enhance the passcode security. (Defaults to an empty string.)
  final String salt;

  /// Determines if the app must force the creation of a passcode when it is missing.
  ///
  /// When true, the app will prompt the user to create a passcode even if biometric
  /// authentication is available.
  final bool forceCreatePasscode;

  /// Title displayed across all dialogs.
  final String title;

  /// Configuration options for the passcode validation dialog.
  final CheckConfig checkConfig;

  /// Configuration options for creating a new passcode.
  final CreateConfig createConfig;

  /// Configuration options for confirming the newly created passcode.
  final RepeatConfig repeatConfig;

  /// Blur intensity for the background when dialogs are shown.
  final double blurSigma;

  /// Callback invoked when "forgot your passcode" is selected.
  ///
  /// Should prompt the user to confirm passcode reset. If the callback returns true,
  /// the passcode is removed.
  late final Future<bool> Function(BuildContext context)? onForgotPasscode;

  /// Callback executed when the maximum retry attempt threshold is exceeded.
  final void Function()? onMaxRetriesExceeded;

  /// Callback to read saved configuration from local storage.
  final OnRead? onRead;

  /// Callback to write configuration to local storage.
  final OnWrite? onWrite;

  /// Type of haptic feedback for UI interactions.
  final HapticFeedbackType hapticFeedbackType;

  /// Custom builder for dialog widgets.
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? actions)? dialogBuilder;

  bool _isUseBiometric;
  late String _sha256Passcode;

  Future<PasscodeBiometricAuth> get _auth async => PasscodeBiometricAuth(
        sha256Passcode: await sha256Passcode,
        salt: salt,
      );

  /// Indicates if biometric authentication is enabled.
  Future<bool> get isUseBiometric async {
    return (await onRead?.readBool(_createKey(PrefKeys.isUseBiometricKey))) ??
        _isUseBiometric;
  }

  /// Retrieves the current passcode in SHA256 hash format.
  ///
  /// The raw passcode is kept secure and only its SHA256 hash is exposed.
  Future<String> get sha256Passcode async {
    return (await onRead?.readString(_createKey(PrefKeys.sha256PasscodeKey))) ??
        _sha256Passcode;
  }

  /// Creates a new instance of [PasscodeBiometricAuthUI].
  ///
  /// If [onForgotPasscode] is supplied, it is wrapped to remove the passcode upon
  /// confirmation of a reset.
  PasscodeBiometricAuthUI({
    this.prefix = 'PasscodeBiometricAuth',
    String sha256Passcode = '',
    this.salt = '',
    bool isUseBiometric = false,
    this.forceCreatePasscode = true,
    this.title = 'Passcode',
    this.checkConfig = const CheckConfig(),
    this.createConfig = const CreateConfig(),
    this.repeatConfig = const RepeatConfig(),
    this.blurSigma = 15,
    this.onMaxRetriesExceeded,
    Future<bool> Function(BuildContext context, PasscodeBiometricAuthUI authUI)?
        onForgotPasscode,
    this.onRead,
    this.onWrite,
    this.hapticFeedbackType = HapticFeedbackType.lightImpact,
    this.dialogBuilder,
  })  : _isUseBiometric = isUseBiometric,
        _sha256Passcode = sha256Passcode {
    this.onForgotPasscode = onForgotPasscode == null
        ? null
        : (context) async {
            if (await onForgotPasscode(context, this)) {
              await removePasscode();
              return true;
            }
            return false;
          };
  }

  /// Authenticates the user with biometric and/or passcode verification.
  ///
  /// Depending on [forceCreatePasscode] and the availability of a passcode,
  /// it will either prompt for biometric authentication, request passcode input,
  /// or trigger creation of a new passcode.
  /// Returns true if the user is successfully authenticated.
  Future<bool> authenticate(
    BuildContext context, {
    bool? forceCreatePasscode,
    bool? isUseBiometric,
  }) async {
    bool? authenticated;
    forceCreatePasscode ??= this.forceCreatePasscode;
    isUseBiometric ??= await this.isUseBiometric;

    final isPasscodeAvailable = await isAvailablePasscode();
    final isNeedCreatePasscode = forceCreatePasscode && !isPasscodeAvailable;

    // Attempt biometric authentication if passcode exists and biometric is enabled.
    if (!isNeedCreatePasscode && isUseBiometric) {
      authenticated = await authenticateWithBiometric();
    }

    if (authenticated == true) return true;

    // Prompt user to create a new passcode if none exists.
    if (!isPasscodeAvailable) {
      if (!context.mounted) return false;
      return await _isPasscodeCreated(context);
    } else {
      // Fallback to passcode authentication.
      if (!context.mounted) return false;
      final isAuthenticated = await authenticateWithPasscode(context);
      return isAuthenticated == true;
    }
  }

  /// Allows the user to change the current passcode.
  ///
  /// If no passcode exists, it will trigger passcode creation.
  /// Otherwise, it first validates the current passcode before prompting
  /// for a new passcode.
  Future<bool> changePasscode(BuildContext context) async {
    final isPasscodeAvailable = await isAvailablePasscode();

    if (!context.mounted) return false;

    if (isPasscodeAvailable) {
      final isAuthenticated = await authenticateWithPasscode(context);

      if (!isAuthenticated || !context.mounted) return false;

      return await _isPasscodeCreated(context);
    } else {
      return await _isPasscodeCreated(context);
    }
  }

  /// Checks if biometric authentication is available on this device.
  ///
  /// Note: Biometric support may not be available on all platforms (e.g., web).
  Future<bool> isBiometricAvailable() async {
    return PasscodeBiometricAuth(
      sha256Passcode: await sha256Passcode,
      salt: salt,
    ).isBiometricAvailable();
  }

  /// Initiates biometric authentication using available device sensors.
  ///
  /// Returns true if the biometric check is successful.
  Future<bool> authenticateWithBiometric() async {
    return (await _auth)
        .isBiometricAuthenticated(biometricReason: checkConfig.biometricReason);
  }

  /// Displays the passcode input dialog for authentication.
  ///
  /// It retrieves the stored SHA256 passcode and validates the user input. After
  /// successful validation, it updates the biometric preference setting.
  /// Returns true if the passcode is correctly authenticated.
  Future<bool> authenticateWithPasscode(BuildContext context) async {
    final code = await sha256Passcode;
    if (!context.mounted) return false;

    final state = await animatedDialog<CheckPasscodeState>(
      context: context,
      blurSigma: blurSigma,
      builder: (ctx) {
        return CheckPasscode(
          localAuth: this,
          sha256Passcode: code,
          title: title,
          checkConfig: checkConfig,
          onForgetPasscode: onForgotPasscode == null
              ? null
              : () async {
                  Navigator.pop(ctx);
                  onForgotPasscode!(context);
                },
          onMaxRetriesExceeded: onMaxRetriesExceeded,
          onRead: onRead,
          onWrite: onWrite,
          hapticFeedbackType: hapticFeedbackType,
          dialogBuilder: dialogBuilder,
        );
      },
    );

    if (state == null) return false;

    // Persist the new biometric usage preference after authentication.
    await useBiometric(state.isUseBiometric);
    return state.isAuthenticated == true;
  }

  /// Validates the provided passcode by comparing its SHA256 hash.
  ///
  /// Returns true if the computed hash matches the stored passcode hash.
  Future<bool> isPasscodeAuthenticated(String code) async {
    return (await _auth).isPasscodeAuthenticated(code);
  }

  /// Updates the user's preference for biometric authentication.
  ///
  /// The new setting is saved using the [onWrite] callback and updates the local state.
  @mustCallSuper
  Future<void> useBiometric(bool isUse) async {
    await onWrite?.writeBool(_createKey(PrefKeys.isUseBiometricKey), isUse);
    _isUseBiometric = isUse;
  }

  /// Removes the stored passcode and related authentication configurations.
  ///
  /// This method clears the passcode hash, resets biometric usage preference,
  /// and clears any retry attempt counters.
  @mustCallSuper
  Future<void> removePasscode() async {
    await onWrite?.writeString(_createKey(PrefKeys.sha256PasscodeKey), '');
    await onWrite?.writeBool(_createKey(PrefKeys.isUseBiometricKey), false);
    await onWrite?.writeInt(
      _createKey(PrefKeys.lastRetriesExceededRemainingSecond),
      0,
    );
    _sha256Passcode = '';
  }

  /// Determines if a passcode has already been set.
  ///
  /// Returns true if the stored SHA256 passcode is non-empty.
  FutureOr<bool> isAvailablePasscode() async {
    return (await _auth).isAvailablePasscode();
  }

  /// Prompts the user to create a new passcode via a dialog.
  ///
  /// Displays a blurred background and the passcode creation dialog. After the user
  /// successfully creates a passcode, it stores the passcode's SHA256 hash.
  /// Returns the SHA256 hash of the created passcode, or an empty string on failure.
  Future<bool> _isPasscodeCreated(BuildContext context) async {
    if (!context.mounted) return false;

    final recievedSha256Code = await animatedDialog(
      context: context,
      blurSigma: blurSigma,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: CreatePasscode(
          salt: salt,
          title: title,
          createConfig: createConfig,
          repeatConfig: repeatConfig,
          hapticFeedbackType: hapticFeedbackType,
          dialogBuilder: dialogBuilder,
        ),
      ),
    );

    if (recievedSha256Code == null || !context.mounted) return false;

    final confirmed = await animatedDialog<bool>(
      context: context,
      blurSigma: 0,
      builder: (_) => RepeatPasscode(
        sha256Passcode: recievedSha256Code,
        salt: salt,
        title: title,
        repeatConfig: repeatConfig,
        hapticFeedbackType: hapticFeedbackType,
        dialogBuilder: dialogBuilder,
      ),
    );

    // Upon successful confirmation of the newly created passcode and if the widget is still active,
    // update the local SHA-256 passcode, persist it using the onWrite callback,
    // and then close the dialog by returning true.
    if (confirmed == true) {
      _sha256Passcode = recievedSha256Code;
      await onWrite?.writeString(
        _createKey(PrefKeys.sha256PasscodeKey),
        recievedSha256Code,
      );

      return true;
    }

    return false;
  }

  String _createKey(String subKey) {
    return PrefKeys.createKey(prefix, subKey);
  }
}
