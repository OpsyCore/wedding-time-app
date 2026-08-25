import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';

/// فقط عکس‌های approved
class GuestGalleryTab extends StatelessWidget {
  const GuestGalleryTab({super.key, required this.weddingId});

  final String weddingId;

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('weddings')
        .doc(weddingId)
        .collection('guestMedia')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          // اگر ایندکس نباشد، بدون orderBy
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('weddings')
                .doc(weddingId)
                .collection('guestMedia')
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, snap2) {
              if (snap2.hasError) {
                return Center(
                  child: Text(
                    _t('gallery_load_error', 'خطا در بارگذاری گالری', 'Gallery load error'),
                    style: TextStyle(color: AppTok.danger(context)),
                  ),
                );
              }
              if (!snap2.hasData) {
                return Center(
                  child: CircularProgressIndicator(color: AppTok.accent(context)),
                );
              }
              return _grid(context, snap2.data!.docs);
            },
          );
        }
        if (!snap.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppTok.accent(context)),
          );
        }
        return _grid(context, snap.data!.docs);
      },
    );
  }

  Widget _grid(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          _t('no_approved_photos', 'هنوز عکسی تأیید نشده', 'No approved photos yet'),
          style: TextStyle(color: AppTok.textSoft(context)),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, i) {
        final d = docs[i].data();
        final url = (d['url'] ?? '').toString();
        final name = (d['uploaderName'] ?? '').toString();
        return Container(
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTok.border(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: url.isEmpty
                    ? Icon(Icons.broken_image, color: AppTok.textSoft(context))
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.broken_image, color: AppTok.textSoft(context)),
                      ),
              ),
              if (name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 11.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}