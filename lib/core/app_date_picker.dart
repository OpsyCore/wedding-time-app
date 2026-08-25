import 'package:flutter/material.dart';

import 'app_theme.dart';

Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  Locale? locale,
}) {
  final now = DateTime.now();
  final initial = initialDate ?? now;
  final first = firstDate ?? DateTime(now.year - 1);
  final last = lastDate ?? DateTime(now.year + 6);

  return showDatePicker(
    context: context,
    initialDate: initial.isBefore(first)
        ? first
        : (initial.isAfter(last) ? last : initial),
    firstDate: first,
    lastDate: last,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    locale: locale,
    builder: (context, child) {
      return Theme(
        data: AppTheme.datePickerOverlay(Theme.of(context)),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}