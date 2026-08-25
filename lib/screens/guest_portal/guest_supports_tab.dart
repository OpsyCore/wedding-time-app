import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';

/// حمایت‌ها — نمایش برای مهمان (claim اگر rules اجازه دهد)
class GuestSupportsTab extends StatelessWidget {
  const GuestSupportsTab({super.key, required this.weddingId});

  final String weddingId;

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('weddings')
        .doc(weddingId)
        .collection('supports');

    return Scaffold(
      backgroundColor: AppTok.background(context),
      appBar: AppBar(
        backgroundColor: AppTok.background(context),
        elevation: 0,
        title: Text(
          _t('supports_title', 'حمایت‌ها', 'Supports'),
          style: TextStyle(color: AppTok.text(context), fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: AppTok.text(context)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                _t('supports_unavailable', 'حمایت‌ها در دسترس نیست', 'Supports unavailable'),
                style: TextStyle(color: AppTok.textSoft(context)),
              ),
            );
          }
          if (!snap.hasData) {
            return Center(
              child: CircularProgressIndicator(color: AppTok.accent(context)),
            );
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                _t('no_supports', 'مورد حمایتی ثبت نشده', 'No support items'),
                style: TextStyle(color: AppTok.textSoft(context)),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final title = (d['title'] ?? d['name'] ?? '').toString();
              final note = (d['note'] ?? d['description'] ?? '').toString();
              final status = (d['status'] ?? 'open').toString();
              final claimed = status == 'claimed' || status == 'done';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTok.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTok.border(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      color: claimed
                          ? AppTok.textSoft(context)
                          : AppTok.accent(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              note,
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            claimed
                                ? _t('support_claimed', 'رزرو شده', 'Claimed')
                                : _t('support_open', 'باز', 'Open'),
                            style: TextStyle(
                              color: AppTok.accentDeep(context),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }
}