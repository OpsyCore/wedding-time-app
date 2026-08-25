import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../models/invitation_model.dart';

/// تایم‌لاین فقط‌خواندنی مهمان — استایل عمودی چپ/راست مثل موکاپ زوج
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

  IconData _iconOf(String? key) {
    switch ((key ?? '').toLowerCase().trim()) {
      case 'ring':
      case 'diamond':
        return Icons.diamond_outlined;
      case 'guests':
      case 'guest':
        return Icons.groups_outlined;
      case 'home':
      case 'ceremony':
        return Icons.home_outlined;
      case 'party':
      case 'welcome':
        return Icons.celebration_outlined;
      case 'food':
      case 'dinner':
      case 'lunch':
        return Icons.restaurant_outlined;
      case 'mic':
      case 'speech':
        return Icons.mic_none_rounded;
      case 'music':
      case 'dance':
      case 'party_music':
        return Icons.music_note_outlined;
      case 'heart':
      case 'first_dance':
        return Icons.favorite_border;
      case 'cake':
        return Icons.cake_outlined;
      case 'car':
      case 'leave':
        return Icons.directions_car_outlined;
      case 'camera':
      case 'photo':
        return Icons.photo_camera_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  int _timeToMinutes(String time) {
    final cleaned = time.trim();
    final parts = cleaned.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  List<_TimelineItem> _fromInvitation() {
    final schedule = invitation?.schedule ?? const <ScheduleItem>[];
    return schedule
        .map(
          (e) => _TimelineItem(
            time: e.time,
            title: e.title,
            note: '',
            iconKey: e.icon,
          ),
        )
        .toList();
  }

  List<_TimelineItem> _fromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) {
      final d = doc.data();
      return _TimelineItem(
        time: (d['time'] ?? '').toString(),
        title: (d['title'] ?? d['name'] ?? '').toString(),
        note: (d['note'] ?? d['description'] ?? '').toString(),
        iconKey: (d['icon'] ?? d['iconKey'] ?? 'custom').toString(),
      );
    }).toList();
  }

  List<_TimelineItem> _sorted(List<_TimelineItem> items) {
    final list = List<_TimelineItem>.from(items);
    list.sort(
      (a, b) => _timeToMinutes(a.time).compareTo(_timeToMinutes(b.time)),
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('weddings')
        .doc(weddingId)
        .collection('timeline');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        List<_TimelineItem> items = const [];

        if (snap.hasError) {
          items = _sorted(_fromInvitation());
        } else if (!snap.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppTok.accent(context)),
          );
        } else {
          final docs = snap.data!.docs;
          items = docs.isEmpty
              ? _sorted(_fromInvitation())
              : _sorted(_fromDocs(docs));
        }

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _t(
                  'no_schedule_yet',
                  'هنوز برنامه‌ای ثبت نشده',
                  'No schedule yet',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTok.textSoft(context)),
              ),
            ),
          );
        }

        return _TimelineView(items: items, iconOf: _iconOf);
      },
    );
  }
}

class _TimelineItem {
  const _TimelineItem({
    required this.time,
    required this.title,
    required this.note,
    required this.iconKey,
  });

  final String time;
  final String title;
  final String note;
  final String iconKey;
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({
    required this.items,
    required this.iconOf,
  });

  final List<_TimelineItem> items;
  final IconData Function(String?) iconOf;

  @override
  Widget build(BuildContext context) {
    final dark = AppTok.isDark(context);

    final bg = dark ? const Color(0xFF14121C) : AppTok.background(context);
    final line = dark
        ? const Color(0xFFC6A75E).withValues(alpha: 0.55)
        : AppTok.accent(context).withValues(alpha: 0.35);
    final dotFill = dark ? const Color(0xFF1A1724) : AppTok.card(context);
    final dotBorder = dark ? const Color(0xFFD4B56A) : AppTok.accent(context);
    final cardBg = dark
        ? const Color(0xFF1E1A2A).withValues(alpha: 0.92)
        : AppTok.card(context);
    final cardBorder = dark
        ? const Color(0xFFD4B56A).withValues(alpha: 0.28)
        : AppTok.border(context);
    final titleColor = dark ? const Color(0xFFF3EFE6) : AppTok.text(context);
    final timeColor =
        dark ? const Color(0xFFE8D5A3) : AppTok.accentDeep(context);
    final soft = dark
        ? const Color(0xFFB8B0C4).withValues(alpha: 0.85)
        : AppTok.textSoft(context);
    final iconBg = dark
        ? const Color(0xFFD4B56A).withValues(alpha: 0.12)
        : AppTok.accent(context).withValues(alpha: 0.12);
    final iconColor = dark ? const Color(0xFFE6C97A) : AppTok.accent(context);

    return ColoredBox(
      color: bg,
      child: Stack(
        children: [
          if (dark)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _SoftSparkPainter()),
              ),
            ),
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 28),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isRight = index.isEven;
              final rtl = Directionality.of(context) == TextDirection.rtl;
              final cardOnStart = rtl ? !isRight : isRight;

              return _TimelineRow(
                item: item,
                isLast: index == items.length - 1,
                cardOnStart: cardOnStart,
                icon: iconOf(item.iconKey),
                line: line,
                dotFill: dotFill,
                dotBorder: dotBorder,
                cardBg: cardBg,
                cardBorder: cardBorder,
                titleColor: titleColor,
                timeColor: timeColor,
                soft: soft,
                iconBg: iconBg,
                iconColor: iconColor,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.isLast,
    required this.cardOnStart,
    required this.icon,
    required this.line,
    required this.dotFill,
    required this.dotBorder,
    required this.cardBg,
    required this.cardBorder,
    required this.titleColor,
    required this.timeColor,
    required this.soft,
    required this.iconBg,
    required this.iconColor,
  });

  final _TimelineItem item;
  final bool isLast;
  final bool cardOnStart;
  final IconData icon;
  final Color line;
  final Color dotFill;
  final Color dotBorder;
  final Color cardBg;
  final Color cardBorder;
  final Color titleColor;
  final Color timeColor;
  final Color soft;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    const rowMinHeight = 88.0;

    final card = _EventCard(
      item: item,
      icon: icon,
      cardBg: cardBg,
      cardBorder: cardBorder,
      titleColor: titleColor,
      timeColor: timeColor,
      soft: soft,
      iconBg: iconBg,
      iconColor: iconColor,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: rowMinHeight),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: cardOnStart
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 10, 16),
                      child: card,
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotFill,
                      border: Border.all(color: dotBorder, width: 2.2),
                      boxShadow: [
                        BoxShadow(
                          color: dotBorder.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              line,
                              line.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: !cardOnStart
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 4, 16),
                      child: card,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.item,
    required this.icon,
    required this.cardBg,
    required this.cardBorder,
    required this.titleColor,
    required this.timeColor,
    required this.soft,
    required this.iconBg,
    required this.iconColor,
  });

  final _TimelineItem item;
  final IconData icon;
  final Color cardBg;
  final Color cardBorder;
  final Color titleColor;
  final Color timeColor;
  final Color soft;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.time.trim().isNotEmpty)
                  Text(
                    item.time.trim(),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: timeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  item.title.trim().isEmpty ? '—' : item.title.trim(),
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    height: 1.25,
                  ),
                ),
                if (item.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note.trim(),
                    style: TextStyle(
                      color: soft,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftSparkPainter extends CustomPainter {
  const _SoftSparkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4B56A).withValues(alpha: 0.10);
    final points = <Offset>[
      Offset(size.width * 0.12, size.height * 0.08),
      Offset(size.width * 0.82, size.height * 0.14),
      Offset(size.width * 0.20, size.height * 0.42),
      Offset(size.width * 0.88, size.height * 0.48),
      Offset(size.width * 0.15, size.height * 0.72),
      Offset(size.width * 0.78, size.height * 0.80),
      Offset(size.width * 0.50, size.height * 0.30),
      Offset(size.width * 0.60, size.height * 0.62),
    ];
    for (final p in points) {
      canvas.drawCircle(p, 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}