import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_config.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';

/// کارت نمایش کد/لینک دعوت مراسم — برای پروفایل
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({
    super.key,
    required this.weddingId,
  });

  final String weddingId;

  String _pickCode(Map<String, dynamic> data) {
    for (final k in [
      'inviteCode',
      'joinCode',
      'weddingCode',
      'code',
      'shareCode',
    ]) {
      final v = (data[k] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    // fallback: بخشی از id
    if (weddingId.length >= 6) {
      return weddingId.substring(0, 6).toUpperCase();
    }
    return weddingId;
  }

  String _pickSlug(Map<String, dynamic> data) {
    for (final k in ['inviteSlug', 'slug', 'publicSlug']) {
      final v = (data[k] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _inviteUrl(String slug) {
    if (slug.isEmpty) return '';
    return AppConfig.inviteUrl(slug);
  }

  Future<void> _copy(BuildContext context, String value, String okMsg) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(okMsg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        const t = AppLang.tr;

        final dark = AppTok.isDark(context);
        final brandGreenSoft =
            dark ? AppDarkPalette.brandGreenSoft : AppPalette.brandGreenSoft;

        return Directionality(
          textDirection: AppLang.I.direction,
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('weddings')
                .doc(weddingId)
                .snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() ?? {};
              final code = _pickCode(data);
              final slug = _pickSlug(data);
              final url = _inviteUrl(slug);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTok.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTok.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTok.shadow(context),
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
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: brandGreenSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.vpn_key_rounded,
                            color: AppTok.accentDeep(context),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('invite_code_title'),
                                style: TextStyle(
                                  color: AppTok.text(context),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t('invite_code_hint'),
                                style: TextStyle(
                                  color: AppTok.textSoft(context),
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
                        color: AppTok.cardSoft(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTok.border(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              code,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTok.accentDeep(context),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.2,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: t('copy'),
                            onPressed: () => _copy(
                              context,
                              code,
                              t('invite_code_copied'),
                            ),
                            icon: Icon(
                              Icons.copy_rounded,
                              color: AppTok.accent(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (url.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        t('invite_link_label'),
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                          color: AppTok.background(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTok.border(context)),
                        ),
                        child: Text(
                          url,
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copy(
                              context,
                              url.isNotEmpty ? url : code,
                              t('invite_code_copied'),
                            ),
                            icon: const Icon(Icons.copy_all_outlined, size: 18),
                            label: Text(t('copy')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final text = url.isNotEmpty
                                  ? '${t('invite_share_text')}\n$url'
                                  : '${t('invite_share_text')}\n${t('invite_code_title')}: $code';
                              Share.share(text);
                            },
                            icon: const Icon(Icons.share_outlined, size: 18),
                            label: Text(t('share')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}