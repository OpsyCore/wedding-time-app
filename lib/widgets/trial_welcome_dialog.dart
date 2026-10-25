import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_plans.dart';
import '../core/app_theme.dart';
import '../screens/plans_screen.dart';

/// پاپ‌آپ خوش‌آمدگویی تریال — فقط بار اول برای هر کاربر (hasSeenTrialWelcome)
class TrialWelcomeDialog {
  static Future<void> showIfNeeded(BuildContext context, String weddingId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await userRef.get();
    final data = snap.data() ?? {};
    final planId = (data['planId'] ?? data['plan'] ?? '').toString();
    final isPaid = planId == AppPlans.proId ||
        planId == 'pro_monthly' ||
        planId == AppPlans.premiumId;
    if (!isPaid && data['trialEndsAt'] == null) {
      try {
        final endsTs = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        );
        await userRef.set({
          'plan': AppPlans.trialId,
          'planId': AppPlans.trialId,
          'trialStartedAt': FieldValue.serverTimestamp(),
          'trialEndsAt': endsTs,
        }, SetOptions(merge: true));
        if (weddingId.trim().isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('weddings')
              .doc(weddingId.trim())
              .set({
            'planId': AppPlans.trialId,
            'trialStartedAt': FieldValue.serverTimestamp(),
            'trialEndsAt': endsTs,
          }, SetOptions(merge: true));
        }
      } catch (_) {}
    }
    if (data['hasSeenTrialWelcome'] == true) return;
    // فقط اگر تریال یا کاربر جدید (بدون پلن) — نمایش بده
    final isTrial = planId == AppPlans.trialId || planId.isEmpty || planId == 'trial';
    // اگر کاربر قبلا پرمیوم خریده، نیازی نیست
    if (!isTrial && planId == AppPlans.premiumId) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TrialWelcomeContent(weddingId: weddingId),
    );
    // علامت بزن دیده شده
    try {
      await userRef.set({'hasSeenTrialWelcome': true}, SetOptions(merge: true));
    } catch (_) {}
  }
}

class _TrialWelcomeContent extends StatelessWidget {
  final String weddingId;
  const _TrialWelcomeContent({required this.weddingId});

  @override
  Widget build(BuildContext context) {
    final isFa = AppLang.I.isFa;
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    return Directionality(
      textDirection: AppLang.I.direction,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // هدر گرادینت
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [accent.withValues(alpha: 0.18), accentDeep.withValues(alpha: 0.10), AppTok.card(context)],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), shape: BoxShape.circle),
                        child: Icon(Icons.card_giftcard_rounded, color: accent, size: 32),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isFa ? '🎉 ۱ ماه کامل رایگان هدیه شماست!' : '🎉 1 Month Full — Free Gift!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTok.text(context), fontSize: 18, fontWeight: FontWeight.w900, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isFa
                            ? 'از همین الان ۳۰ روز به تمام امکانات پرمیوم دسترسی دارید — بدون کارت بانکی.'
                            : 'You have 30 days of full Premium access — no card required.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTok.textSoft(context), fontSize: 12.5, height: 1.6),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseAuth.instance.currentUser == null
                                  ? null
                                  : FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
                              builder: (ctx, snap) {
                                final d = snap.hasError ? null : snap.data?.data();
                                final ts = d?['trialEndsAt'];
                                String txt = isFa ? '۳۰ روز باقی' : '30 days left';
                                if (ts is Timestamp) {
                                  final diff = ts.toDate().difference(DateTime.now());
                                  final days = diff.inDays.clamp(0, 30);
                                  txt = isFa ? '$days روز باقی‌مانده' : '$days days left';
                                }
                                return Text(txt, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    children: [
                      // لیست امکانات تریال
                      _featureRow(context, Icons.people_alt_rounded, isFa ? 'مهمان نامحدود + RSVP' : 'Unlimited guests + RSVP'),
                      _featureRow(context, Icons.collections_rounded, isFa ? 'رسانه نامحدود + گالری' : 'Unlimited media + gallery'),
                      _featureRow(context, Icons.auto_stories_rounded, isFa ? 'داستان عشق نامحدود' : 'Unlimited love story'),
                      _featureRow(context, Icons.account_balance_wallet_rounded, isFa ? 'بودجه، تامین‌کننده و اقساط' : 'Budget, vendors & payments'),
                      _featureRow(context, Icons.event_seat_rounded, isFa ? 'چیدمان سالن' : 'Seating chart'),
                      _featureRow(context, Icons.camera_alt_rounded, isFa ? 'دوربین مهمان (نامحدود شات)' : 'Guest camera (unlimited shots)'),
                      _featureRow(context, Icons.qr_code_2_rounded, isFa ? 'دعوت‌نامه + QR' : 'Invite + QR'),
                      _featureRow(context, Icons.picture_as_pdf_rounded, isFa ? 'خروجی PDF/اکسل' : 'PDF/Excel export'),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTok.cardSoft(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTok.border(context).withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isFa ? 'بعد از ۳۰ روز چی میشه؟' : 'What after 30 days?',
                              style: TextStyle(color: AppTok.text(context), fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isFa
                                  ? 'حساب شما اتومات به «هدیه محدود» (۴۰ مهمان، ۱۰ رسانه) برمی‌گردد. هر وقت خواستید با پرو یا پرمیوم ادامه دهید — اطلاعات شما پاک نمی‌شود.'
                                  : 'Your account auto-switches to Free Limited (40 guests, 10 media). Upgrade anytime to Pro or Premium — nothing is deleted.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTok.textSoft(context), fontSize: 11.5, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // کارت‌های پلن مینی
                      Row(
                        children: [
                          _miniPlan(context, isFa ? 'هدیه' : 'Free', '0', isFa ? '۴۰ نفر' : '40', false),
                          const SizedBox(width: 8),
                          _miniPlan(context, 'Pro', '298k', isFa ? 'نامحدود' : 'Unlim', true),
                          const SizedBox(width: 8),
                          _miniPlan(context, 'Premium', '3.98M', isFa ? 'مادام' : 'Life', false),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PlansScreen(weddingId: weddingId)));
                          },
                          child: Text(isFa ? 'مشاهده پلن‌ها' : 'View plans', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(isFa ? 'بعداً — برو به برنامه' : 'Later — go to app', style: TextStyle(color: AppTok.textSoft(context), fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppTok.accent(context).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: AppTok.accent(context)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: AppTok.text(context), fontSize: 12.5, fontWeight: FontWeight.w600))),
          Icon(Icons.check_circle_rounded, size: 16, color: AppTok.accent(context)),
        ],
      ),
    );
  }

  Widget _miniPlan(BuildContext context, String title, String price, String sub, bool popular) {
    final accent = AppTok.accent(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: popular ? accent.withValues(alpha: 0.12) : AppTok.cardSoft(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: popular ? accent : AppTok.border(context).withValues(alpha: 0.6), width: popular ? 1.6 : 1),
        ),
        child: Column(
          children: [
            if (popular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
                child: Text(AppLang.I.isFa ? 'محبوب' : 'Popular', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            if (popular) const SizedBox(height: 4),
            Text(title, style: TextStyle(color: AppTok.text(context), fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(price, style: TextStyle(color: popular ? accent : AppTok.textSoft(context), fontSize: 11, fontWeight: FontWeight.w800)),
            Text(sub, style: TextStyle(color: AppTok.textSoft(context), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
