import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../services/plan_access.dart';

/// دروازهٔ پلن: اگر پلنِ مراسم اجازه دهد [child] وگرنه صفحهٔ قفل + دکمهٔ ارتقا.
class PlanGate extends StatelessWidget {
  const PlanGate({
    super.key,
    required this.weddingId,
    required this.allow,
    required this.featureFa,
    required this.featureEn,
    required this.child,
  });

  final String weddingId;
  final bool Function(PlanLimits limits) allow;
  final String featureFa;
  final String featureEn;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlanLimits>(
      stream: PlanAccess.I.watchWeddingLimits(weddingId),
      builder: (context, snap) {
        final limits = snap.data;
        if (limits == null) return child;
        if (allow(limits)) return child;
        return _Locked(
          weddingId: weddingId,
          featureFa: featureFa,
          featureEn: featureEn,
        );
      },
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({
    required this.weddingId,
    required this.featureFa,
    required this.featureEn,
  });

  final String weddingId;
  final String featureFa;
  final String featureEn;

  @override
  Widget build(BuildContext context) {
    final accent = AppTok.accent(context);
    return Scaffold(
      backgroundColor: AppTok.background(context),
      appBar: AppBar(
        backgroundColor: AppTok.background(context),
        elevation: 0,
        automaticallyImplyLeading: Navigator.canPop(context),
        iconTheme: IconThemeData(color: AppTok.text(context)),
        title: Text(
          AppLang.I.isFa ? featureFa : featureEn,
          style: TextStyle(
            color: AppTok.text(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.lock_outline_rounded, color: accent, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              AppLang.I.isFa ? featureFa : featureEn,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTok.text(context),
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLang.I.isFa
                  ? 'این بخش در پلن رایگان فعال نیست. با ارتقا به پرو یا پرمیوم همین حالا بازش کنید.'
                  : 'This section is not available on the free plan. Upgrade to Pro or Premium to unlock it now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTok.textSoft(context),
                fontSize: 12.5,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => PlanAccess.I.showUpgradeDialog(
                context,
                weddingId: weddingId,
                featureFa: featureFa,
                featureEn: featureEn,
              ),
              icon: const Icon(Icons.diamond_rounded, size: 18),
              label: Text(
                AppLang.I.isFa ? 'ارتقا به پلن پولی' : 'Upgrade',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
        ),
    );
  }
}
