import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passcode_biometric_auth/src/models/check_passcode_state.dart';
import 'package:passcode_biometric_auth/src/models/dialog_configs.dart';
import 'package:passcode_biometric_auth/src/utils/animated_dialog.dart';
import 'package:pinput/pinput.dart';

import 'components/check_passcode.dart';
import 'components/create_passcode.dart';
import 'models/on_read.dart';
import 'models/on_write.dart';
import 'utils/pref_keys.dart';

/// UI handler for passcode and biometric authentication dialogs.
///
/// Provides methods to authenticate using biometrics, passcode or both,
/// and to create, change, or remove the passcode. It manages saving and
/// reading configuration using the provided [onRead] and [onWrite] callbacks.
class PasscodeBiometricAuthUI {
  /// Prefix used when saving to the local database via [OnRead] and [OnWrite] methods.
  final String prefix;

  /// Whether to force the creation of a passcode when it is not available.
  ///
  /// If `true`, the app will prompt the user to create a passcode even if the
  /// biometric authentication is available.
  final bool forceCreatePasscode;

  /// Title used for all dialogs.
  final String title;

  /// Configuration options for the passcode check dialog.
  final CheckConfig checkConfig;

  /// Configuration options for creating a passcode.
  final CreateConfig createConfig;

  /// Configuration options for the repeat passcode dialog.
  final RepeatConfig repeatConfig;

  /// Blur sigma value used for the background when showing dialogs.
  final double blurSigma;

  /// Callback triggered when the "forgot your passcode" option is selected.
  ///
  /// This callback usually prompts the user with cautions to confirm passcode reset.
  /// If it returns `true`, the passcode will be removed.
  late final Future<bool> Function(BuildContext context)? onForgotPasscode;

  /// Callback triggered when the maximum number of retries is exceeded.
  final void Function()? onMaxRetriesExceeded;

  /// Callback for reading configurations from the local storage.
  final OnRead? onRead;

  /// Callback for writing configurations to the local storage.
  final OnWrite? onWrite;

  /// Type of haptic feedback used when the user interacts with the UI.
  final HapticFeedbackType hapticFeedbackType;

  /// Builder for custom dialog widget.
  final Widget Function(BuildContext context, String title, Widget content,
      List<Widget>? actions)? dialogBuilder;

  bool? _isBiometricAvailableCached;
  late bool _isUseBiometric;

  /// Retrieves whether biometric authentication is enabled.
  Future<bool> get isUseBiometric async {
    return (await onRead?.readBool(PrefKeys.isUseBiometricKey)) ??
        _isUseBiometric;
  }

  late String _sha256Passcode;

  /// Retrieves the current passcode in SHA256 format.
  ///
  /// The raw passcode is not accessible; only its SHA256 hash.
  Future<String> get sha256Passcode async {
    return (await onRead?.readString(PrefKeys.sha256PasscodeKey)) ??
        _sha256Passcode;
  }

  /// Creates an instance of [PasscodeBiometricAuthUI].
  ///
  /// The [onForgotPasscode] callback is modified to remove the passcode if it returns `true`.
  PasscodeBiometricAuthUI({
    this.prefix = 'PasscodeBiometricAuth',
    String sha256Passcode = '',
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
  }) {
    _isUseBiometric = isUseBiometric;
    _sha256Passcode = sha256Passcode;
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

  /// Authenticates the user using both passcode and biometric methods.
  ///
  /// Depending on the configurations and availability, it will either authenticate
  /// with biometric first then fallback to passcode, or prompt to create a new passcode.
  /// Returns `true` if authentication is successful.
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

    // Attempt biometric authentication if applicable.
    if (!isNeedCreatePasscode && isUseBiometric) {
      authenticated = await authenticateWithBiometric();
    }

    if (authenticated == true) return true;

    // If passcode is not available, prompt to create one.
    if (!isPasscodeAvailable) {
      if (!context.mounted) return false;
      final code = await _createPasscode(context);
      return code != '';
    } else {
      // Use passcode authentication.
      if (!context.mounted) return false;
      final isAuthenticated = await authenticateWithPasscode(context);
      return isAuthenticated == true;
    }
  }

  /// Changes the current passcode.
  ///
  /// If a passcode is not present, it prompts the user to create one instead.
  /// If it is available, it will ask the user to authenticate with the current passcode
  /// before setting a new one.
  Future<bool> changePasscode(BuildContext context) async {
    final isPasscodeAvailable = await isAvailablePasscode();
    if (!isPasscodeAvailable) {
      if (!context.mounted) return false;
      final code = await _createPasscode(context);
      return code != '';
    } else {
      if (!context.mounted) return false;
      final isAuthenticated = await authenticateWithPasscode(context);
      if (!isAuthenticated || !context.mounted) return false;
      return (await _createPasscode(context)) != '';
    }
  }

  /// Checks if biometric authentication is available on the device.
  ///
  /// Results are cached for faster subsequent checks. Note: Biometric support
  /// is not available on web.
  Future<bool> isBiometricAvailable() async {
    if (_isBiometricAvailableCached != null) {
      return _isBiometricAvailableCached!;
    }

    if (kIsWeb) {
      _isBiometricAvailableCached = false;
      return false;
    }

    var localAuth = LocalAuthentication();
    final isDeviceSupported = await localAuth.isDeviceSupported();
    if (!isDeviceSupported) {
      _isBiometricAvailableCached = false;
      return false;
    }

    _isBiometricAvailableCached = await localAuth.canCheckBiometrics;
    return _isBiometricAvailableCached!;
  }

  /// Initiates biometric authentication.
  ///
  /// Returns `true` if the user is successfully authenticated with biometrics.
  Future<bool> authenticateWithBiometric() async {
    if (!await isBiometricAvailable()) {
      return false;
    }

    var localAuth = LocalAuthentication();
    return await localAuth.authenticate(
      localizedReason: checkConfig.biometricReason,
    );
  }

  /// Initiates passcode authentication by displaying the passcode check dialog.
  ///
  /// Reads the stored SHA256-computed passcode and uses it to validate the user input.
  /// Returns `true` if the user is authenticated.
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

    // Update biometric usage preference after authentication.
    useBiometric(state.isUseBiometric);
    return state.isAuthenticated == true;
  }

  /// Validates whether the provided [code] is correct.
  ///
  /// The passcode is compared using a SHA256 hash. Returns `true` if the
  /// computed hash matches the stored one.
  Future<bool> isPasscodeAuthenticated(String code) async {
    final passcodeSHA256 =
        base64Encode(sha256.convert(utf8.encode(code)).bytes);
    if (passcodeSHA256 == await sha256Passcode) {
      return true;
    }
    return false;
  }

  /// Updates the preference to use biometric authentication.
  ///
  /// Persists the new value using [onWrite] and updates the local variable.
  @mustCallSuper
  Future<void> useBiometric(bool isUse) async {
    await onWrite?.writeBool(PrefKeys.isUseBiometricKey, isUse);
    _isUseBiometric = isUse;
  }

  /// Removes the stored passcode and resets related authentication configurations.
  ///
  /// This includes clearing biometric preference and any record of retry attempts.
  @mustCallSuper
  Future<void> removePasscode() async {
    await onWrite?.writeString(PrefKeys.sha256PasscodeKey, '');
    await onWrite?.writeBool(PrefKeys.isUseBiometricKey, false);
    await onWrite?.writeInt(PrefKeys.lastRetriesExceededRemainingSecond, 0);
    _sha256Passcode = '';
  }

  /// Checks if a passcode is already set.
  ///
  /// Returns `true` if the stored SHA256 passcode is non-empty.
  FutureOr<bool> isAvailablePasscode() async {
    return await sha256Passcode != '';
  }

  /// Prompts the user to create a new passcode.
  ///
  /// Displays the create passcode dialog with a blurred background. Upon successful
  /// creation, stores the SHA256 hash of the passcode.
  Future<String> _createPasscode(BuildContext context) async {
    if (!context.mounted) return '';

    final recievedCode = await animatedDialog(
      context: context,
      blurSigma: blurSigma,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: CreatePasscode(
          title: title,
          createConfig: createConfig,
          repeatConfig: repeatConfig,
          hapticFeedbackType: hapticFeedbackType,
          dialogBuilder: dialogBuilder,
        ),
      ),
    );

    if (recievedCode == null) return '';

    _sha256Passcode = recievedCode;
    await onWrite?.writeString(PrefKeys.sha256PasscodeKey, recievedCode);
    return recievedCode;
  }
}
