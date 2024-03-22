import 'dart:ui';

import 'package:flutter/material.dart';

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
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.fastEaseInToSlowEaseOut,
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
  );
}
