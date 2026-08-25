import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';

class RsvpInboxScreen extends StatefulWidget {
  const RsvpInboxScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<RsvpInboxScreen> createState() => _RsvpInboxScreenState();
}

class _RsvpInboxScreenState extends State<RsvpInboxScreen> {
  String _filter = 'all'; // all | yes | no

  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  String fa(String s) {
    if (!AppLang.I.isFa) return s;
    return s.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _fa[i] : c;
    }).join();
  }

  CollectionReference<Map<String, dynamic>> get _rsvpRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('rsvps');

  CollectionReference<Map<String, dynamic>> get _guestsRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('guests');

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return AppLang.tr('just_now');
    if (diff.inMinutes < 60) {
      return '${fa('${diff.inMinutes}')} ${AppLang.tr('minutes_ago')}';
    }
    if (diff.inHours < 24) {
      return '${fa('${diff.inHours}')} ${AppLang.tr('hours_ago')}';
    }
    if (diff.inDays < 7) {
      return '${fa('${diff.inDays}')} ${AppLang.tr('days_ago')}';
    }
    final t =
        '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    return fa(t);
  }

  Future<void> _deleteRsvp(String id, {String? guestId}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTok.card(ctx),
        title: Text(
          AppLang.tr('delete_response'),
          style: TextStyle(color: AppTok.text(ctx)),
        ),
        content: Text(
          AppLang.tr('delete_rsvp_confirm'),
          style: TextStyle(color: AppTok.textSoft(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLang.tr('cancel'),
              style: TextStyle(color: AppTok.textSoft(ctx)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLang.tr('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_rsvpRef.doc(id));

    if (guestId != null && guestId.isNotEmpty) {
      batch.set(
        _guestsRef.doc(guestId),
        {
          'status': 'invited',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
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
              iconTheme: IconThemeData(color: AppTok.text(context)),
              title: Text(
                AppLang.tr('rsvp_responses'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  _rsvpRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTok.accent(context),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];
                final yesCount = docs
                    .where((d) => (d.data()['status'] ?? '') == 'yes')
                    .length;
                final noCount = docs
                    .where((d) => (d.data()['status'] ?? '') == 'no')
                    .length;

                final filtered = docs.where((d) {
                  final s = (d.data()['status'] ?? '').toString();
                  if (_filter == 'yes') return s == 'yes';
                  if (_filter == 'no') return s == 'no';
                  return true;
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _statChip(
                              label: AppLang.tr('total'),
                              value: docs.length,
                              selected: _filter == 'all',
                              color: AppTok.accent(context),
                              onTap: () => setState(() => _filter = 'all'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statChip(
                              label: AppLang.tr('attending'),
                              value: yesCount,
                              selected: _filter == 'yes',
                              color: const Color(0xFF4CD37B),
                              onTap: () => setState(() => _filter = 'yes'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statChip(
                              label: AppLang.tr('not_attending'),
                              value: noCount,
                              selected: _filter == 'no',
                              color: const Color(0xFFEF5A7D),
                              onTap: () => setState(() => _filter = 'no'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _InfoBanner(),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                AppLang.tr('no_rsvp_yet'),
                                style: TextStyle(
                                  color: AppTok.textSoft(context),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final doc = filtered[index];
                                final data = doc.data();
                                final name = (data['name'] ??
                                        AppLang.tr('guest'))
                                    .toString();
                                final phone =
                                    (data['phone'] ?? '').toString();
                                final status =
                                    (data['status'] ?? '').toString();
                                final guestId =
                                    (data['guestId'] ?? '').toString();
                                final createdAt =
                                    (data['createdAt'] as Timestamp?)
                                        ?.toDate();
                                final isYes = status == 'yes';

                                return Dismissible(
                                  key: ValueKey(doc.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) async {
                                    await _deleteRsvp(
                                      doc.id,
                                      guestId: guestId,
                                    );
                                    return false;
                                  },
                                  background: Container(
                                    alignment: AppLang.I.isFa
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    padding: EdgeInsets.only(
                                      left: AppLang.I.isFa ? 20 : 0,
                                      right: AppLang.I.isFa ? 0 : 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.red.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTok.card(context),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: (isYes
                                                ? const Color(0xFF4CD37B)
                                                : const Color(0xFFEF5A7D))
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: (isYes
                                                    ? const Color(0xFF4CD37B)
                                                    : const Color(0xFFEF5A7D))
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            isYes
                                                ? Icons.check_circle_outline
                                                : Icons.cancel_outlined,
                                            color: isYes
                                                ? const Color(0xFF4CD37B)
                                                : const Color(0xFFEF5A7D),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  color: AppTok.text(context),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (phone.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  phone,
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  style: TextStyle(
                                                    color: AppTok.textSoft(
                                                      context,
                                                    ),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 4),
                                              Text(
                                                _timeLabel(createdAt),
                                                style: TextStyle(
                                                  color: AppTok.textSoft(
                                                    context,
                                                  ),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: (isYes
                                                        ? const Color(
                                                            0xFF4CD37B)
                                                        : const Color(
                                                            0xFFEF5A7D))
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isYes
                                                    ? AppLang.tr('attending')
                                                    : AppLang.tr(
                                                        'not_attending'),
                                                style: TextStyle(
                                                  color: isYes
                                                      ? const Color(
                                                          0xFF4CD37B)
                                                      : const Color(
                                                          0xFFEF5A7D),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (guestId.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                AppLang.tr('in_guests_list'),
                                                style: TextStyle(
                                                  color: AppTok.textSoft(
                                                    context,
                                                  ).withValues(alpha: 0.8),
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _statChip({
    required String label,
    required int value,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? color.withValues(alpha: 0.15)
          : AppTok.card(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Text(
                fa('$value'),
                style: TextStyle(
                  color: selected ? color : AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppTok.textSoft(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppLang.tr('rsvp_inbox_info'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTok.textSoft(context),
          fontSize: 11.5,
          height: 1.45,
        ),
      ),
    );
  }
}