import 'package:flutter/material.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import 'page_glass.dart';

enum WeddingProgressSize { thin, medium, large }

/// Reusable premium progress bar — gradient fill, animated, rounded caps
/// Used for checklist footer, couple profile header, home wedding progress
class WeddingProgressBar extends StatelessWidget {
  const WeddingProgressBar({
    super.key,
    required this.value,
    this.size = WeddingProgressSize.medium,
    this.showPercent = false,
    this.label,
    this.caption,
    this.animate = true,
    this.gradient,
  });

  final double value; // 0..1
  final WeddingProgressSize size;
  final bool showPercent;
  final String? label;
  final String? caption;
  final bool animate;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final isDark = AppTok.isDark(context);
    final track = AppTok.ringTrack(context);
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final accentSoft = AppTok.accentSoft(context);

    final height = switch (size) {
      WeddingProgressSize.thin => 6.0,
      WeddingProgressSize.medium => 10.0,
      WeddingProgressSize.large => 14.0,
    };

    final fillGradient = gradient ??
        LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            accentSoft,
            accent,
            accentDeep,
          ],
          stops: const [0.0, 0.55, 1.0],
        );

    const darkGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFEFC4A8),
        Color(0xFFD4AF8C),
        Color(0xFFE8C9A8),
      ],
    );

    final effectiveGradient = isDark ? darkGradient : fillGradient;

    Widget bar(double progress) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(height),
        ),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: effectiveGradient,
                  borderRadius: BorderRadius.circular(height),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // subtle inner highlight
            if (progress > 0.02)
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.12 : 0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercent || caption != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (label != null)
                  Expanded(
                    child: Text(
                      label!,
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontWeight: FontWeight.w700,
                        fontSize: size == WeddingProgressSize.large ? 14 : 12.5,
                      ),
                    ),
                  ),
                if (caption != null && label != null) const SizedBox(width: 8),
                if (caption != null)
                  Text(
                    caption!,
                    style: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 11.5,
                    ),
                  ),
                if (showPercent) ...[
                  const Spacer(),
                  _PercentBadge(value: v),
                ],
              ],
            ),
          ),
        if (animate)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: v),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) => bar(animatedValue),
          )
        else
          bar(v),
      ],
    );

    return content;
  }
}

class _PercentBadge extends StatelessWidget {
  const _PercentBadge({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round().clamp(0, 100);
    final accentDeep = AppTok.accentDeep(context);
    final accent = AppTok.accent(context);
    final display = AppLang.I.isFa
        ? _toFaDigits(pct.toString()) + AppLang.tr('percent_unit')
        : '$pct${AppLang.tr('percent_unit')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: accentDeep,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }

  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  static String _toFaDigits(String s) {
    return s.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _fa[i] : c;
    }).join();
  }
}

/// Premium checklist footer card — full-width glass, gradient track, animated fill,
/// large percentage + secondary line + status chip
class ChecklistProgressFooter extends StatelessWidget {
  const ChecklistProgressFooter({
    super.key,
    required this.doneCount,
    required this.total,
  });

  final int doneCount;
  final int total;

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  String _fa(String input) {
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _faDigits[i] : c;
    }).join();
  }

  String _d(Object n) {
    final s = n.toString();
    return AppLang.I.isFa ? _fa(s) : s;
  }

  String _statusKey(double p) {
    if (p <= 0) return 'progress_status_not_started';
    if (p < 0.4) return 'progress_status_in_progress';
    if (p < 0.85) return 'progress_status_almost_done';
    return 'progress_status_completed';
  }

  Color _statusColor(BuildContext context, double p) {
    if (p <= 0) return AppTok.textSoft(context);
    if (p < 0.4) return const Color(0xFF8E9C6B);
    if (p < 0.85) return AppTok.accent(context);
    return const Color(0xFF5F7F62);
  }

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : doneCount / total;
    final pct = total == 0 ? 0 : ((doneCount / total) * 100).round();
    final pctClamped = pct.clamp(0, 100);
    final title = AppLang.tr('checklist_progress');
    final doneLabel = AppLang.tr('checklist_progress_done');
    final ofLabel = AppLang.tr('checklist_progress_of');
    final subtitle = AppLang.I.isFa
        ? '${_d(doneCount)} $ofLabel ${_d(total)} $doneLabel'
        : '${_d(doneCount)} $ofLabel ${_d(total)} $doneLabel';

    final statusKey = _statusKey(progress);
    final statusLabel = AppLang.tr(statusKey);
    final statusColor = _statusColor(context, progress);

    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accentDeep = AppTok.accentDeep(context);
    final isDark = AppTok.isDark(context);

    return PageGlass(
      opacity: isDark ? 0.86 : 0.90,
      blurSigma: 14,
      borderRadius: 20,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTok.accentSoft(context).withValues(alpha: 0.35),
                      AppTok.accent(context).withValues(alpha: 0.22),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTok.accent(context).withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  color: AppTok.accent(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSoft,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // large percent
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: pctClamped.toDouble()),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedPct, _) {
                      final disp = AppLang.I.isFa
                          ? '${_d(animatedPct.round())}${AppLang.tr('percent_unit')}'
                          : '${_d(animatedPct.round())}${AppLang.tr('percent_unit')}';
                      return Text(
                        disp,
                        style: TextStyle(
                          color: accentDeep,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLang.I.isFa ? 'تکمیل شده' : 'completed',
                    style: TextStyle(
                      color: textSoft.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          WeddingProgressBar(
            value: progress,
            size: WeddingProgressSize.medium,
            animate: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _DotLegend(
                color: AppTok.accent(context),
                label: AppLang.I.isFa ? 'انجام شده' : 'Done',
                value: _d(doneCount),
              ),
              const SizedBox(width: 12),
              _DotLegend(
                color: AppTok.ringTrack(context),
                label: AppLang.I.isFa ? 'باقی‌مانده' : 'Left',
                value: _d((total - doneCount).clamp(0, total)),
              ),
              const Spacer(),
              Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: AppTok.accentSoft(context).withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                AppLang.I.isFa
                    ? 'به‌روزرسانی زنده'
                    : 'Live updating',
                style: TextStyle(
                  color: textSoft.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotLegend extends StatelessWidget {
  const _DotLegend({
    required this.color,
    required this.label,
    required this.value,
  });
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Premium dual-profile progress header (couple profile top)
class CoupleProgressHeader extends StatelessWidget {
  const CoupleProgressHeader({
    super.key,
    required this.progress, // 0..1
    this.showCircular = true,
  });

  final double progress;
  final bool showCircular;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round().clamp(0, 100);
    final isDark = AppTok.isDark(context);
    final label = pct == 0
        ? AppLang.tr('progress_start')
        : pct < 40
            ? AppLang.tr('progress_good_start')
            : pct < 70
                ? AppLang.tr('progress_taking_shape')
                : pct < 100
                    ? AppLang.tr('progress_almost')
                    : AppLang.tr('progress_ready');

    final statusKey = pct <= 0
        ? 'progress_status_not_started'
        : pct < 40
            ? 'progress_status_in_progress'
            : pct < 85
                ? 'progress_status_almost_done'
                : 'progress_status_completed';

    return PageGlass(
      opacity: isDark ? 0.86 : 0.90,
      blurSigma: 14,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showCircular)
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 5,
                          color: AppTok.ringTrack(context),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, anim, _) => SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: anim,
                            strokeWidth: 5,
                            strokeCap: StrokeCap.round,
                            color: AppTok.accent(context),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                      Text(
                        AppLang.I.isFa
                            ? '${_faDigits(pct)}${AppLang.tr('percent_unit')}'
                            : '$pct${AppLang.tr('percent_unit')}',
                        style: TextStyle(
                          color: AppTok.text(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              if (showCircular) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLang.tr('wedding_progress'),
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTok.accent(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppLang.tr(statusKey),
                            style: TextStyle(
                              color: AppTok.accentDeep(context),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    WeddingProgressBar(
                      value: progress,
                      size: WeddingProgressSize.thin,
                      animate: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  static String _faDigits(int n) {
    final s = n.toString();
    if (!AppLang.I.isFa) return s;
    return s.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _fa[i] : c;
    }).join();
  }
}
