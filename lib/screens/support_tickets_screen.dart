import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../services/plan_access.dart';

/// سیستم تیکت پشتیبانی — اولویت پاسخ‌گویی بر اساس پلن:
/// free → عادی | pro → اولویت‌دار | premium → VIP
class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key, this.weddingId});

  final String? weddingId;

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLang.I.direction,
      child: Scaffold(
        backgroundColor: AppTok.background(context),
        appBar: AppBar(
          backgroundColor: AppTok.background(context),
          elevation: 0,
          iconTheme: IconThemeData(color: AppTok.text(context)),
          title: Text(
            _t('support_tickets_title', 'پشتیبانی', 'Support'),
            style: TextStyle(
              color: AppTok.text(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'new_ticket_fab',
          backgroundColor: AppTok.accent(context),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            _t('new_ticket', 'تیکت جدید', 'New ticket'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: _openNewTicket,
        ),
        body: StreamBuilder<PlanLimits>(
          stream: PlanAccess.I.watchMyPlanId().map(PlanLimits.forPlanId),
          builder: (context, planSnap) {
            final tier = planSnap.data?.supportTier ?? 'normal';
            return Column(
              children: [
                _tierBanner(context, tier),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _db
                        .collection('support_tickets')
                        .where('uid', isEqualTo: _uid)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            _t('load_error', 'خطا در بارگذاری', 'Load error'),
                            style: TextStyle(color: AppTok.danger(context)),
                          ),
                        );
                      }
                      if (!snap.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTok.accent(context),
                          ),
                        );
                      }
                      final docs = snap.data!.docs.toList();
                      docs.sort((a, b) => ((b.data()['createdAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0)
                          .compareTo((a.data()['createdAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0));
                      if (docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                              _t(
                                'no_tickets',
                                'هنوز تیکتی ثبت نکرده‌اید. سوال یا مشکلی دارید؟ همین حالا بنویسید.',
                                'No tickets yet. Have a question or issue? Write us now.',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 13,
                                height: 1.7,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final d = docs[i].data();
                          return _ticketTile(context, docs[i].id, d);
                        },
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
  }

  Widget _tierBanner(BuildContext context, String tier) {
    final label = tier == 'vip'
        ? _t('tier_vip', 'پشتیبانی VIP — پاسخ فوری', 'VIP support — instant reply')
        : tier == 'priority'
            ? _t(
                'tier_priority',
                'پشتیبانی اولویت‌دار — پاسخ سریع',
                'Priority support — fast reply',
              )
            : _t('tier_normal', 'پشتیبانی عادی', 'Standard support');
    final icon = tier == 'vip'
        ? Icons.workspace_premium_rounded
        : tier == 'priority'
            ? Icons.bolt_rounded
            : Icons.support_agent_rounded;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTok.accent(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTok.accent(context).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTok.accent(context), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppTok.text(context),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketTile(
    BuildContext context,
    String id,
    Map<String, dynamic> d,
  ) {
    final subject = (d['subject'] ?? '').toString();
    final status = (d['status'] ?? 'open').toString();
    final messages = (d['messages'] as List?) ?? const [];
    final statusLabel = status == 'answered'
        ? _t('ticket_answered', 'پاسخ داده شده', 'Answered')
        : status == 'closed'
            ? _t('ticket_closed', 'بسته شده', 'Closed')
            : _t('ticket_open', 'باز', 'Open');
    final statusColor = status == 'answered'
        ? AppTok.accent(context)
        : status == 'closed'
            ? AppTok.textSoft(context)
            : AppTok.danger(context);

    return Material(
      color: AppTok.card(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openThread(id, d),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTok.border(context)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.forum_outlined,
                color: AppTok.accent(context),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _t('messages_count', 'پیام‌ها:', 'Messages:') +
                              ' ${messages.length}',
                          style: TextStyle(
                            color: AppTok.textSoft(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                AppLang.I.isRtl ? Icons.chevron_left : Icons.chevron_right,
                color: AppTok.textSoft(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNewTicket() async {
    final subjectC = TextEditingController();
    final bodyC = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _t('new_ticket', 'تیکت جدید', 'New ticket'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.text(ctx),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: subjectC,
                style: TextStyle(color: AppTok.text(ctx)),
                decoration: InputDecoration(
                  labelText: _t('ticket_subject', 'موضوع', 'Subject'),
                  labelStyle: TextStyle(color: AppTok.textSoft(ctx)),
                  filled: true,
                  fillColor: AppTok.cardSoft(ctx),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyC,
                maxLines: 4,
                style: TextStyle(color: AppTok.text(ctx)),
                decoration: InputDecoration(
                  labelText: _t('ticket_body', 'توضیح مشکل یا سوال', 'Describe your issue'),
                  labelStyle: TextStyle(color: AppTok.textSoft(ctx)),
                  filled: true,
                  fillColor: AppTok.cardSoft(ctx),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTok.accent(ctx),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (subjectC.text.trim().isEmpty ||
                      bodyC.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: Text(
                  _t('send', 'ارسال', 'Send'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;

    final limits = PlanLimits.forPlanId(await PlanAccess.I.myPlanId());
    try {
      await _db.collection('support_tickets').add({
        'uid': _uid,
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'weddingId': widget.weddingId ?? '',
        'subject': subjectC.text.trim(),
        'status': 'open',
        'tier': limits.supportTier,
        'messages': [
          {
            'from': 'user',
            'text': bodyC.text.trim(),
            'at': FieldValue.serverTimestamp(),
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('ticket_sent', 'تیکت ثبت شد', 'Ticket sent'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_t('save_error', 'خطا', 'Error')}: $e'),
          backgroundColor: AppTok.danger(context),
        ),
      );
    }
  }

  Future<void> _openThread(String id, Map<String, dynamic> d) async {
    final replyC = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (sheetCtx, scroll) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Text(
                  (d['subject'] ?? '').toString(),
                  style: TextStyle(
                    color: AppTok.text(sheetCtx),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream:
                        _db.collection('support_tickets').doc(id).snapshots(),
                    builder: (context, snap) {
                      final msgs =
                          ((snap.data?.data()?['messages']) as List?) ??
                              const [];
                      return ListView.builder(
                        controller: scroll,
                        itemCount: msgs.length,
                        itemBuilder: (context, i) {
                          final m = msgs[i] as Map;
                          final mine = m['from'] == 'user';
                          return Align(
                            alignment: mine && !AppLang.I.isRtl
                                ? Alignment.centerRight
                                : mine
                                    ? Alignment.centerLeft
                                    : AppLang.I.isRtl
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(sheetCtx).size.width * 0.8,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? AppTok.accent(sheetCtx)
                                        .withValues(alpha: 0.14)
                                    : AppTok.cardSoft(sheetCtx),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (m['text'] ?? '').toString(),
                                style: TextStyle(
                                  color: AppTok.text(sheetCtx),
                                  fontSize: 12.5,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyC,
                        style: TextStyle(color: AppTok.text(sheetCtx)),
                        decoration: InputDecoration(
                          hintText: _t('reply', 'پاسخ...', 'Reply...'),
                          filled: true,
                          fillColor: AppTok.cardSoft(sheetCtx),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final text = replyC.text.trim();
                        if (text.isEmpty) return;
                        replyC.clear();
                        await _db
                            .collection('support_tickets')
                            .doc(id)
                            .update({
                          'messages': FieldValue.arrayUnion([
                            {
                              'from': 'user',
                              'text': text,
                              'at': Timestamp.now(),
                            },
                          ]),
                          'status': 'open',
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                      },
                      icon: Icon(
                        AppLang.I.isRtl ? Icons.send_rounded : Icons.send_rounded,
                        color: AppTok.accent(sheetCtx),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
