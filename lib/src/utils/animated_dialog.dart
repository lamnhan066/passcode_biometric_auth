import 'dart:ui';

import 'package:flutter/material.dart';

/// Presents an animated general dialog with a blur and fade transition.
///
/// This function wraps the dialog content in a [BackdropFilter] that applies a dynamic blur effect,
/// coupled with a [FadeTransition] to smoothly fade in the dialog. The blur intensity is determined
/// by the [blurSigma] multiplied by the current animation progress. It uses [showGeneralDialog] to create
/// a modal dialog with a transparent barrier, ensuring that the background is not interactable while
/// the dialog is visible.
///
/// The transition lasts 400 milliseconds, during which the dialog's opacity and blur effect are
/// animated according to the current [AnimationStatus]. When the animation is in the forward direction,
/// the blur effect remains at its maximum intensity.
///
/// Parameters:
///   - [context]: The [BuildContext] in which to display the dialog.
///   - [blurSigma]: The maximum blur intensity (standard deviation) to apply when the animation is complete.
///   - [builder]: A builder function that returns the widget displayed as the dialog's content.
///
/// Returns:
///   A [Future] of type [T] that resolves when the dialog is dismissed.
Future<T?> animatedDialog<T>({
  required BuildContext context,
  required double blurSigma,
  required Widget Function(BuildContext context) builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      double value = animation.value;
      if (animation.status == AnimationStatus.forward) {
        value = 1;
      }
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma * value,
          sigmaY: blurSigma * value,
        ),
        child: FadeTransition(
          opacity: AlwaysStoppedAnimation(value),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
  );
}
