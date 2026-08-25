import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../core/app_theme_controller.dart';

/// داستان عشق مهمان — فقط مشاهده
/// همان دادهٔ زوج از: weddings/{id}/loveStories
/// فیلدها: title, dateText, content, photoUrl, order
class GuestLoveStoryTab extends StatelessWidget {
  const GuestLoveStoryTab({super.key, required this.weddingId});

  final String weddingId;

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(weddingId)
          .collection('loveStories');

  bool _isEmptyStory(Map<String, dynamic> d) {
    final title = (d['title'] ?? '').toString().trim();
    final dateText = (d['dateText'] ?? '').toString().trim();
    final content = (d['content'] ?? '').toString().trim();
    final photoUrl = (d['photoUrl'] ?? '').toString().trim();
    return title.isEmpty &&
        dateText.isEmpty &&
        content.isEmpty &&
        photoUrl.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: AppTok.background(context),
            appBar: AppBar(
              backgroundColor: AppTok.background(context),
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: AppTok.text(context)),
              title: Text(
                _t('love_story', 'داستان عشق ما', 'Our love story'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ref.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _t(
                          'stories_load_error',
                          'بارگذاری داستان ممکن نیست',
                          'Could not load the story',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTok.accent(context),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((d) {
                  return !_isEmptyStory(d.data());
                }).toList()
                  ..sort((a, b) {
                    final oa = (a.data()['order'] is num)
                        ? (a.data()['order'] as num)
                        : 0;
                    final ob = (b.data()['order'] is num)
                        ? (b.data()['order'] as num)
                        : 0;
                    return oa.compareTo(ob);
                  });

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 42,
                            color: AppTok.accent(context)
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _t(
                              'no_love_story',
                              'هنوز داستانی ثبت نشده',
                              'No story yet',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTok.textSoft(context),
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  itemCount: docs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _HeaderCard(count: docs.length, t: _t),
                      );
                    }

                    final doc = docs[index - 1];
                    final data = doc.data();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _GuestStoryCard(
                        index: index,
                        title: (data['title'] ?? '').toString().trim(),
                        dateText: (data['dateText'] ?? '').toString().trim(),
                        content: (data['content'] ?? '').toString().trim(),
                        photoUrl: (data['photoUrl'] ?? '').toString().trim(),
                        t: _t,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.count, required this.t});

  final int count;
  final String Function(String key, String fa, String en) t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTok.accent(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTok.accent(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: AppTok.accent(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('love_story', 'داستان عشق ما', 'Our love story'),
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t(
                    'love_story_guest_hint',
                    'همان روایتی که عروس و داماد نوشته‌اند',
                    'Exactly as the couple shared it',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTok.cardSoft(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTok.accent(context).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: AppTok.text(context),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestStoryCard extends StatelessWidget {
  const _GuestStoryCard({
    required this.index,
    required this.title,
    required this.dateText,
    required this.content,
    required this.photoUrl,
    required this.t,
  });

  final int index;
  final String title;
  final String dateText;
  final String content;
  final String photoUrl;
  final String Function(String key, String fa, String en) t;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.startsWith('http');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTok.accent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: AppTok.accent(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.isNotEmpty
                      ? title
                      : '${t('story_n', 'خاطره', 'Story')} $index',
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (dateText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 15,
                  color: AppTok.accent(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateText,
                    style: TextStyle(
                      color: AppTok.accent(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (hasPhoto) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTok.cardSoft(context),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppTok.textSoft(context),
                    ),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppTok.cardSoft(context),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppTok.accent(context),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (content.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              content,
              style: TextStyle(
                color: AppTok.text(context),
                fontSize: 14.5,
                height: 1.75,
              ),
            ),
          ],
        ],
      ),
    );
  }
}