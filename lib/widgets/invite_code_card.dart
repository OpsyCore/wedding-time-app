import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_config.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';

/// کارت نمایش کد پیوستن + لینک دعوت عمومی.
/// FIX-02: کد پیوستن دیگر از سند عمومی مراسم خوانده نمی‌شود
/// (سند مراسم برای همه قابل‌خواندن است). کد در سند خصوصی
/// users/{uid} خود زوج نگهداری می‌شود.
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key, required this.weddingId});

  final String weddingId;

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLang.tr('copied'))),
    );
  }

  String _pickCode(Map<String, dynamic> data) {
    for (final k in ['inviteCode', 'joinCode', 'code']) {
      final v = (data[k] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final card = AppTok.card(context);
        final cardSoft = AppTok.cardSoft(context);
        final bg = AppTok.background(context);
        final text = AppTok.text(context);
        final textSoft = AppTok.textSoft(context);
        final accent = AppTok.accent(context);
        final accentDeep = AppTok.accentDeep(context);
        final border = AppTok.border(context);
        final shadow = AppTok.shadow(context);
        final dark = AppTok.isDark(context);
        final brandGreenSoft =
            dark ? AppDarkPalette.brandGreenSoft : AppPalette.brandGreenSoft;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          // کد پیوستن: سند خصوصی کاربر جاری
          stream: uid == null
              ? const Stream.empty()
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
          builder: (context, userSnap) {
            final code = _pickCode(userSnap.data?.data() ?? {});

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              // لینک دعوت عمومی: همچنان از سند مراسم (اسلاگ عمومی است)
              stream: FirebaseFirestore.instance
                  .collection('weddings')
                  .doc(weddingId)
                  .snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() ?? {};
                final slug = (data['slug'] ?? data['inviteSlug'] ?? weddingId)
                    .toString()
                    .trim();
                final link = AppConfig.inviteUrl(slug);

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: brandGreenSoft,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.vpn_key_outlined,
                              color: accentDeep,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLang.tr('invite_code'),
                                  style: TextStyle(
                                    color: text,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppLang.tr('invite_code_hint'),
                                  style: TextStyle(
                                    color: textSoft,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cardSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                code.isEmpty ? '—' : code,
                                style: TextStyle(
                                  color: accentDeep,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: AppLang.tr('copy'),
                              onPressed: code.isEmpty
                                  ? null
                                  : () => _copy(context, code),
                              icon: Icon(Icons.copy_rounded, color: accent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLang.tr('public_invite_link'),
                        style: TextStyle(
                          color: textSoft,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                link,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: text,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: AppLang.tr('copy'),
                              onPressed: () => _copy(context, link),
                              icon: Icon(Icons.link, color: accent, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
