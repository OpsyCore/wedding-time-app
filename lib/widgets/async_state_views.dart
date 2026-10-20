import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// ویجت استاندارد نمایش خطای بارگذاری در StreamBuilder / FutureBuilder
/// تا در صورت خطای شبکه یا دسترسی، صفحه در چرخندهٔ بی‌نهایت گیر نکند.
class AsyncErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;
  final String? titleKey;
  final bool compact;

  const AsyncErrorView({
    super.key,
    this.error,
    this.onRetry,
    this.titleKey,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final danger = AppTok.danger(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final accent = AppTok.accent(context);
    final title = AppLang.tr(titleKey ?? 'async_load_error');

    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, size: 16, color: accent),
                label: Text(
                  AppLang.tr('retry'),
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: danger,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLang.tr('async_network_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSoft,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh_rounded, size: 18, color: accent),
                  label: Text(
                    AppLang.tr('retry'),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ویجت استاندارد نمایش حالت در حال بارگذاری
class AsyncLoadingView extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const AsyncLoadingView({
    super.key,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: CircularProgressIndicator(
          color: AppTok.accent(context),
        ),
      ),
    );
  }
}
