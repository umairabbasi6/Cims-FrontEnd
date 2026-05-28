import 'package:flutter/material.dart';
import 'package:cims/core/utils/responsive.dart';

/// Shows a modal that adapts based on screen size.
///
/// - On mobile: Uses [showModalBottomSheet] with [isScrollControlled: true]
/// - On desktop: Uses [showDialog]
///
/// Returns the result of the modal (or null if dismissed).
Future<T?> showResponsiveModal<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  if (Responsive.isMobile(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      barrierColor: barrierColor,
      isDismissible: barrierDismissible,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
  } else {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: (_) => child,
    );
  }
}
