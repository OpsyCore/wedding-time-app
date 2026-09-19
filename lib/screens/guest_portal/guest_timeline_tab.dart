import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../models/invitation_model.dart';

/// تایم‌لاین فقط‌خواندنی مهمان —
/// محتوا دقیقاً مشابه صفحهٔ زوج (TimelineScreen) است:
/// همان کالکشن `timeline`، همان مرتب‌سازی (time سپس order)، همان قالب ساعت،
/// همان آیکون‌ها و همان ۱۰ رویداد پیش‌فرض وقتی لیست خالی است؛
/// تنها تفاوت: مهمان هیچ دکمهٔ افزودن/ویرایش/حذف/ریست نمی‌بیند.
class GuestTimelineTab extends StatelessWidget {
  const GuestTimelineTab({
    super.key,
    required this.weddingId,
    this.invitation,
  });

  final String weddingId;
  final InvitationModel? invitation;

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  // ── دقیقاً مشابه _iconOf در TimelineScreen زوج ──
  IconData _iconOf(String? key) {
    switch (key) {
      case 'ring':
        return Icons.diamond_outlined;
      case 'guests':
        return Icons.groups_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'party':
        return Icons.celebration_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'mic':
        return Icons.mic_none_rounded;
      case 'music':
        return Icons.music_note_outlined;
      case 'heart':
        return Icons.favorite_border;
      case 'cake':
        return Icons.cake_outlined;
      case 'car':
        return Icons.directions_car_outlined;
      case 'camera':
        return Icons.photo_camera_outlined;
      case 'place':
        return Icons.place_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  // ── همان ۱۰ رویداد پیش‌فرض صفحهٔ زوج (فقط نمایش، بدون نوشتن در دیتابیس) ──
  List<Map<String, dynamic>> get _defaultEvents => [
        {
          'time': '10:00',
          'title': AppLang.tr('tl_prep'),
          'icon': 'ring',
          'order': 1,
        },
        {
          'time': '11:00',
          'title': AppLang.tr('tl_guests_arrive'),
          'icon': 'guests',
          'order': 2,
        },
        {
          'time': '12:00',
          'title': AppLang.tr('tl_ceremony_start'),
          'icon': 'home',
          'order': 3,
        },
        {
          'time': '12:30',
          'title': AppLang.tr('tl_reception_start'),
          'icon': 'party',
          'order': 4,
        },
        {
          'time': '13:00',
          'title': AppLang.tr('tl_lunch_tables'),
          'icon': 'food',
          'order': 5,
        },
        {
          'time': '14:00',
          'title': AppLang.tr('tl_speeches'),
          'icon': 'mic',
          'order': 6,
        },
        {
          'time': '15:00',
          'title': AppLang.tr('tl_games'),
          'icon': 'music',
          'order': 7,
        },
        {
          'time': '16:00',
          'title': AppLang.tr('tl_first_dance'),
          'icon': 'heart',
          'order': 8,
        },
        {
          'time': '16:30',
          'title': AppLang.tr('tl_cake_group_photo'),
          'icon': 'cake',
          'order': 9,
        },
        {
          'time': '18:00',
          'title': AppLang.tr('tl_farewell'),
          'icon': 'car',
          'order': 10,
        },
      ];

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  // ── دقیقاً مشابه _displayTime در TimelineScreen زوج ──
  String _displayTime(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '--:--';
    if (t.toUpperCase().contains('AM') || t.toUpperCase().contains('PM')) {
      return t.toUpperCase();
    }
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final mm = m.toString().padLeft(2, '0');
    if (AppLang.I.isFa) {
      return '${parts[0].padLeft(2, '0')}:$mm';
    }
    final isAm = h < 12;
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:$mm ${isAm ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('weddings')
        .doc(weddingId)
        .collection('timeline');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _t(
                  'timeline_load_error',
                  'خطا در بارگذاری تایم‌لاین',
                  'Timeline load error',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTok.danger(context)),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppTok.accent(context)),
          );
        }

        // همان مرتب‌سازی صفحهٔ زوج: time سپس order
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final ta = _timeToMinutes(a.data()['time']?.toString() ?? '');
          final tb = _timeToMinutes(b.data()['time']?.toString() ?? '');
          if (ta != tb) return ta.compareTo(tb);
          final oa = (a.data()['order'] ?? 0) as num;
          final ob = (b.data()['order'] ?? 0) as num;
          return oa.compareTo(ob);
        });

        // اگر زوج هنوز رویدادی ثبت نکرده، همان ۱۰ رویداد پیش‌فصف صفحهٔ زوج
        // (فقط نمایش محلی — مهمان هرگز در دیتابیس نمی‌نویسد)
        final items = docs.isEmpty
            ? _defaultEvents
            : docs.map((d) => d.data()).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: _HeaderCard(count: items.length),
              );
            }

            final i = index - 1;
            final data = items[i];
            final isLast = i == items.length - 1;
            final onStart = i.isEven;

            return _TimelineNode(
              isLast: isLast,
              onStartSide: onStart,
              time: _displayTime(data['time']?.toString() ?? ''),
              title: data['title']?.toString() ?? '',
              note: data['note']?.toString() ?? '',
              icon: _iconOf(data['icon']?.toString()),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// هدر مشابه صفحهٔ زوج (بدون چیپ ویرایش)
// ═══════════════════════════════════════════

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final border = AppTok.border(context);
    final card = AppTok.card(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppTok.progressGradient(context),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: AppTok.shadow(context),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: card.withValues(alpha: 0.85),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(Icons.view_timeline_rounded, color: accent, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'WEDDING TIMELINE',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentDeep,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLang.tr('timeline_hero_body'),
            textAlign: TextAlign.center,
            style: TextStyle(color: textSoft, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: card.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available_outlined, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    color: text,
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
  }
}

// ═══════════════════════════════════════════
// نود تایم‌لاین مشابه صفحهٔ زوج (وسط + چپ/راست) — بدون onTap/onLongPress
// ═══════════════════════════════════════════

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.isLast,
    required this.onStartSide,
    required this.time,
    required this.title,
    required this.note,
    required this.icon,
  });

  final bool isLast;
  final bool onStartSide;
  final String time;
  final String title;
  final String note;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final border = AppTok.border(context);
    final card = AppTok.card(context);
    final cardSoft = AppTok.cardSoft(context);

    Widget eventCard({required bool alignEnd}) {
      final cross =
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
      final ta = alignEnd ? TextAlign.end : TextAlign.start;

      return Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: card.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: AppTok.shadow(context),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: cross,
          children: [
            Row(
              mainAxisAlignment:
                  alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!alignEnd) ...[
                  _iconBadge(icon, accent, cardSoft),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: cross,
                    children: [
                      Text(
                        time,
                        textDirection: TextDirection.ltr,
                        textAlign: ta,
                        style: TextStyle(
                          color: accentDeep,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title.trim().isEmpty ? '—' : title.trim(),
                        textAlign: ta,
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.2,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                if (alignEnd) ...[
                  const SizedBox(width: 10),
                  _iconBadge(icon, accent, cardSoft),
                ],
              ],
            ),
            if (note.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note,
                textAlign: ta,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textSoft,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: onStartSide
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: 10,
                      top: 4,
                      bottom: 4,
                    ),
                    child: eventCard(alignEnd: true),
                  )
                : const SizedBox.shrink(),
          ),

          // ستون وسط
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.15),
                          accent.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card,
                    border: Border.all(color: accent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2.2,
                    color: isLast
                        ? Colors.transparent
                        : accent.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: !onStartSide
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 10,
                      top: 4,
                      bottom: 4,
                    ),
                    child: eventCard(alignEnd: false),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge(IconData icon, Color accent, Color soft) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: accent, size: 20),
    );
  }
}
