import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../core/app_theme_controller.dart';
import '../../services/guest_local_store.dart';

/// آرزوهای مهمان
/// - ارسال بدون لاگین → status: pending
/// - لیست عمومی فقط approved
/// فیلدها هم‌خوان با WishesScreen + firestore.rules:
///   name, message, createdAt  (rules)
///   text, authorName, status  (پنل زوج)
class GuestWishesTab extends StatefulWidget {
  const GuestWishesTab({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<GuestWishesTab> createState() => _GuestWishesTabState();
}

class _GuestWishesTabState extends State<GuestWishesTab> {
  final _nameC = TextEditingController();
  final _msgC = TextEditingController();
  bool _sending = false;

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('wishes');

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _msgC.dispose();
    super.dispose();
  }

  Future<void> _loadSavedName() async {
    final n = await GuestLocalStore.loadDisplayName(widget.weddingId);
    if (!mounted) return;
    if ((n ?? '').trim().isNotEmpty && _nameC.text.trim().isEmpty) {
      _nameC.text = n!.trim();
    }
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  Future<void> _send() async {
    final name = _nameC.text.trim();
    final msg = _msgC.text.trim();

    if (name.isEmpty || msg.isEmpty) {
      _toast(
        _t(
          'wish_fill_all',
          'نام و پیام را وارد کنید',
          'Enter name and message',
        ),
      );
      return;
    }
    if (name.length > 80) {
      _toast(
        _t('wish_name_long', 'نام خیلی بلند است', 'Name is too long'),
      );
      return;
    }
    if (msg.length > 1000) {
      _toast(
        _t('wish_msg_long', 'پیام خیلی بلند است', 'Message is too long'),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await GuestLocalStore.saveDisplayName(
        weddingId: widget.weddingId,
        name: name,
      );

      // create عمومی: name + message + createdAt (rules)
      // + text/authorName/status برای پنل زوج
      await _ref.add({
        'name': name,
        'message': msg,
        'text': msg,
        'authorName': name,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'guest_portal',
      });

      _msgC.clear();
      if (!mounted) return;
      _toast(
        _t(
          'wish_sent_pending',
          'آرزو ارسال شد و منتظر تأیید زوج است',
          'Wish sent and waiting for approval',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _toast(
        '${_t('error', 'خطا', 'Error')}: $e',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? AppTok.danger(context) : AppTok.card(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _authorOf(Map<String, dynamic> d) {
    final a = (d['authorName'] ?? d['name'] ?? '').toString().trim();
    if (a.isNotEmpty) return a;
    return _t('guest', 'مهمان', 'Guest');
  }

  String _textOf(Map<String, dynamic> d) {
    return (d['text'] ?? d['message'] ?? d['body'] ?? '').toString().trim();
  }

  bool _isApproved(Map<String, dynamic> d) {
    return (d['status'] ?? '').toString().trim().toLowerCase() == 'approved';
  }

  @override
  Widget build(BuildContext context) {
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;

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
                _t('wishes', 'آرزوها', 'Wishes'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTok.card(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTok.accent(context).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      _t(
                        'wishes_guest_hint',
                        'آرزوی خود را بنویسید. بعد از تأیید عروس و داماد برای همه نمایش داده می‌شود.',
                        'Send your wish. After the couple approves it, everyone can see it.',
                      ),
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        height: 1.55,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: BoxDecoration(
                      color: AppTok.card(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTok.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _t(
                            'send_wish',
                            'ارسال آرزو',
                            'Send a wish',
                          ),
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameC,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: AppTok.text(context)),
                          decoration: _dec(
                            context,
                            _t('your_name', 'نام شما', 'Your name'),
                            Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _msgC,
                          minLines: 3,
                          maxLines: 5,
                          style: TextStyle(
                            color: AppTok.text(context),
                            height: 1.5,
                          ),
                          decoration: _dec(
                            context,
                            _t(
                              'your_wish',
                              'آرزوی شما برای زوج',
                              'Your wish for the couple',
                            ),
                            Icons.favorite_border,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _sending ? null : _send,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTok.accent(context),
                              foregroundColor: onAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: _sending
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: onAccent,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: Text(
                              _sending
                                  ? _t('sending', 'در حال ارسال…', 'Sending…')
                                  : _t('send_wish', 'ارسال آرزو', 'Send wish'),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _t(
                        'approved_wishes',
                        'آرزوهای تأییدشده',
                        'Approved wishes',
                      ),
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _ref
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        // fallback بدون orderBy (اگر ایندکس/permission)
                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: _ref.snapshots(),
                          builder: (context, s2) {
                            if (s2.hasError) {
                              return _centerMsg(
                                context,
                                _t(
                                  'wishes_load_error',
                                  'بارگذاری آرزوها ممکن نیست',
                                  'Could not load wishes',
                                ),
                              );
                            }
                            if (!s2.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppTok.accent(context),
                                ),
                              );
                            }
                            final docs = s2.data!.docs.toList()
                              ..sort((a, b) {
                                final ta = a.data()['createdAt'];
                                final tb = b.data()['createdAt'];
                                if (ta is Timestamp && tb is Timestamp) {
                                  return tb.compareTo(ta);
                                }
                                return 0;
                              });
                            return _list(context, docs);
                          },
                        );
                      }

                      if (!snap.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTok.accent(context),
                          ),
                        );
                      }

                      return _list(context, snap.data!.docs);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _list(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> raw,
  ) {
    final docs = raw.where((d) => _isApproved(d.data())).toList();

    if (docs.isEmpty) {
      return _centerMsg(
        context,
        _t(
          'no_approved_wishes_yet',
          'هنوز آرزوی تأییدشده‌ای نیست — شما اولی باشید',
          'No approved wishes yet — be the first',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final d = docs[i].data();
        final author = _authorOf(d);
        final text = _textOf(d);
        if (text.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTok.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: AppTok.accent(context),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      author,
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                text,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  height: 1.7,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _centerMsg(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTok.textSoft(context),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTok.textSoft(context)),
      prefixIcon: Icon(icon, color: AppTok.accent(context)),
      filled: true,
      fillColor: AppTok.cardSoft(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.accent(context)),
      ),
    );
  }
}