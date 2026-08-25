import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../models/support_item_model.dart';

class SupportProgressBar extends StatelessWidget {
  const SupportProgressBar({
    super.key,
    required this.item,
    required this.showRemaining,
    required this.currencyMode,
    this.compact = false,
  });

  final SupportItem item;
  final bool showRemaining;
  final String currencyMode; // toman | usd | both
  final bool compact;

  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  static String dig(String s) {
    if (!AppLang.I.isFa) return s;
    final b = StringBuffer();
    for (final c in s.codeUnits) {
      if (c >= 48 && c <= 57) {
        b.write(_fa[c - 48]);
      } else {
        b.writeCharCode(c);
      }
    }
    return b.toString();
  }

  static String fmtToman(int n) {
    final raw = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final rev = raw.length - i;
      b.write(raw[i]);
      if (rev > 1 && rev % 3 == 1) b.write(',');
    }
    return dig(b.toString());
  }

  static String fmtUsd(double n) {
    final s =
        n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
    return dig(s);
  }

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    if (!item.hasTarget) return const SizedBox.shrink();

    final accent = AppTok.accent(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final track = AppTok.ringTrack(context);

    final pct = item.percentFilled;
    final rem = item.percentRemaining;
    final progress = pct / 100.0;

    final filledColor = pct >= 100
        ? const Color(0xFF5FA777)
        : (pct >= 60 ? accent : AppTok.accentSoft(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${dig('$pct')}%',
              style: TextStyle(
                color: filledColor,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 13 : 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                showRemaining
                    ? '${t('supports_remaining_pct')} ${dig('$rem')}%'
                    : t('supports_funded_pct'),
                style: TextStyle(
                  color: textSoft,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (pct >= 100)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: filledColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t('supports_goal_reached'),
                  style: TextStyle(
                    color: filledColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // نوار استریم‌مانند
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: compact ? 10 : 14,
            child: Stack(
              children: [
                Container(color: track),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          filledColor.withValues(alpha: 0.85),
                          filledColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (currencyMode != 'usd' && item.targetToman > 0)
          Text(
            '${t('supports_raised')}: ${fmtToman(item.raisedToman)} / ${fmtToman(item.targetToman)} ${t('toman')}'
            '${showRemaining ? '  ·  ${t('supports_left')}: ${fmtToman(item.remainingToman)}' : ''}',
            style: TextStyle(color: text, fontSize: compact ? 11 : 12.5, height: 1.35),
          ),
        if (currencyMode != 'toman' && item.targetUsd > 0) ...[
          const SizedBox(height: 2),
          Text(
            '${t('supports_raised')}: \$${fmtUsd(item.raisedUsd)} / \$${fmtUsd(item.targetUsd)}'
            '${showRemaining ? '  ·  ${t('supports_left')}: \$${fmtUsd(item.remainingUsd)}' : ''}',
            style: TextStyle(color: textSoft, fontSize: compact ? 11 : 12, height: 1.35),
          ),
        ],
      ],
    );
  }
}