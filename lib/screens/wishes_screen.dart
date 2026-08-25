import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../services/notification_service.dart';

class WishesScreen extends StatefulWidget {
  const WishesScreen({
    super.key,
    required this.weddingId,
  });

  final String weddingId;

  @override
  State<WishesScreen> createState() => _WishesScreenState();
}

class _WishesScreenState extends State<WishesScreen> {
  final _ctrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _sending = false;
  bool _roleLoading = true;
  bool _isOwner = false;
  String _filter = 'all'; // all | pending | approved | rejected

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('wishes');

  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  /// مالک = عروس/داماد همین مراسم (users + سند wedding)
  Future<void> _resolveRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isOwner = false;
          _roleLoading = false;
        });
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final role = userData['role']?.toString();
      final userWeddingId = userData['weddingId']?.toString();

      final coupleRole = role == 'bride' || role == 'groom';
      final sameWedding = userWeddingId == widget.weddingId;

      var owner = coupleRole && sameWedding;

      // تأیید مضاعف روی سند مراسم
      final weddingDoc = await FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .get();
      final w = weddingDoc.data() ?? {};
      final brideUid = w['brideUid']?.toString();
      final groomUid = w['groomUid']?.toString();
      final onWeddingDoc = brideUid == user.uid || groomUid == user.uid;

      // اگر روی wedding ثبت شده، مالک است
      // اگر فقط users گفته bride/groom همین wedding، باز هم مالک
      owner = onWeddingDoc || owner;

      if (!mounted) return;
      setState(() {
        _isOwner = owner;
        _roleLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isOwner = false;
        _roleLoading = false;
      });
    }
  }

  Future<void> _addWish() async {
    final text = _ctrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (text.isEmpty) {
      _toast(AppLang.tr('wish_text_required'));
      return;
    }

    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      // آرزوی خود زوج مستقیم تأیید شود
      final status = _isOwner ? 'approved' : 'pending';
      final authorName = name.isEmpty
          ? (_isOwner
              ? AppLang.tr('couple_default_name')
              : AppLang.tr('guest'))
          : name;

      final doc = await _ref.add({
        'text': text,
        'authorName': authorName,
        'authorUid': user?.uid,
        'authorEmail': user?.email,
        'status': status, // pending | approved | rejected
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (_isOwner) 'reviewedBy': user?.uid,
      });

      // اعلان فقط وقتی مهمان آرزو می‌فرستد (نه خود عروس/داماد)
      if (!_isOwner) {
        await NotificationService(widget.weddingId).notifyWish(
          guestName: authorName,
          wishId: doc.id,
        );
      }

      _ctrl.clear();
      _toast(
        _isOwner
            ? AppLang.tr('wish_saved')
            : AppLang.tr('wish_sent_pending'),
      );
    } catch (e) {
      _toast('${AppLang.tr('error_with_details')}$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setStatus(String id, String status) async {
    if (!_isOwner) {
      _toast(AppLang.tr('only_couple_status'));
      return;
    }
    if (status != 'approved' && status != 'rejected' && status != 'pending') {
      return;
    }

    try {
      await _ref.doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      _toast(
        status == 'approved'
            ? AppLang.tr('approved_toast')
            : status == 'rejected'
                ? AppLang.tr('rejected_toast')
                : AppLang.tr('pending_toast'),
      );
    } catch (e) {
      _toast('${AppLang.tr('error_with_details')}$e');
    }
  }

  Future<void> _deleteWish(String id) async {
    if (!_isOwner) {
      _toast(AppLang.tr('only_couple_delete'));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTok.card(ctx),
        title: Text(
          AppLang.tr('delete_wish'),
          style: TextStyle(color: AppTok.text(ctx)),
        ),
        content: Text(
          AppLang.tr('delete_wish_confirm'),
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
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _ref.doc(id).delete();
      _toast(AppLang.tr('deleted'));
    } catch (e) {
      _toast('${AppLang.tr('delete_error')}$e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTok.card(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF6FCF97);
      case 'rejected':
        return const Color(0xFFE68585);
      default:
        return const Color(0xFFF2C94C);
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return AppLang.tr('status_approved');
      case 'rejected':
        return AppLang.tr('status_rejected');
      default:
        return AppLang.tr('status_pending');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
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
              iconTheme: IconThemeData(color: AppTok.text(context)),
              title: Text(
                AppLang.tr('wishes_title'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: _roleLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTok.accent(context),
                    ),
                  )
                : Column(
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
                              color: AppTok.accent(context)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            _isOwner
                                ? AppLang.tr('wishes_owner_hint')
                                : AppLang.tr('wishes_guest_hint'),
                            style: TextStyle(
                              color: AppTok.textSoft(context),
                              height: 1.6,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                      if (_isOwner)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            children: [
                              _filterChip(AppLang.tr('all'), 'all'),
                              const SizedBox(width: 8),
                              _filterChip(
                                AppLang.tr('filter_pending'),
                                'pending',
                              ),
                              const SizedBox(width: 8),
                              _filterChip(
                                AppLang.tr('filter_approved'),
                                'approved',
                              ),
                              const SizedBox(width: 8),
                              _filterChip(
                                AppLang.tr('filter_rejected'),
                                'rejected',
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameCtrl,
                              style: TextStyle(color: AppTok.text(context)),
                              decoration: _inputDec(
                                hint: AppLang.tr('your_name_optional'),
                                icon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _ctrl,
                                    minLines: 1,
                                    maxLines: 3,
                                    style: TextStyle(
                                      color: AppTok.text(context),
                                    ),
                                    decoration: _inputDec(
                                      hint: AppLang.tr('wish_hint'),
                                      icon: Icons.favorite_border,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton.filled(
                                  onPressed: _sending ? null : _addWish,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTok.accent(context),
                                    foregroundColor: onAccent,
                                    padding: const EdgeInsets.all(14),
                                  ),
                                  icon: _sending
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: onAccent,
                                          ),
                                        )
                                      : const Icon(Icons.send_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: _ref
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    '${AppLang.tr('wishes_load_error')}\n${snap.error}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),
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

                            var docs = snap.data!.docs;

                            // غیرمالک: فقط تأییدشده
                            if (!_isOwner) {
                              docs = docs
                                  .where(
                                    (d) =>
                                        (d.data()['status'] ?? 'pending') ==
                                        'approved',
                                  )
                                  .toList();
                            } else if (_filter != 'all') {
                              docs = docs
                                  .where(
                                    (d) =>
                                        (d.data()['status'] ?? 'pending') ==
                                        _filter,
                                  )
                                  .toList();
                            }

                            if (docs.isEmpty) {
                              return Center(
                                child: Text(
                                  _isOwner
                                      ? (_filter == 'pending'
                                          ? AppLang.tr('no_pending_wishes')
                                          : AppLang.tr('no_wishes_to_show'))
                                      : AppLang.tr('no_approved_wishes_yet'),
                                  style: TextStyle(
                                    color: AppTok.textSoft(context),
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: docs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data();
                                final status =
                                    (data['status'] ?? 'pending').toString();
                                final author = (data['authorName'] ??
                                        AppLang.tr('guest'))
                                    .toString();
                                final text = (data['text'] ?? '').toString();

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTok.card(context),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTok.border(context),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.format_quote_rounded,
                                            color: AppTok.accent(context),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              author,
                                              style: TextStyle(
                                                color: AppTok.text(context),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (_isOwner)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status)
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _statusText(status),
                                                style: TextStyle(
                                                  color:
                                                      _statusColor(status),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
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
                                        ),
                                      ),
                                      if (_isOwner) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            if (status != 'approved')
                                              TextButton.icon(
                                                onPressed: () => _setStatus(
                                                  doc.id,
                                                  'approved',
                                                ),
                                                icon: const Icon(
                                                  Icons.check_circle_outline,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  AppLang.tr('approve'),
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFF6FCF97),
                                                ),
                                              ),
                                            if (status != 'rejected')
                                              TextButton.icon(
                                                onPressed: () => _setStatus(
                                                  doc.id,
                                                  'rejected',
                                                ),
                                                icon: const Icon(
                                                  Icons.cancel_outlined,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  AppLang.tr('reject'),
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFFF2C94C),
                                                ),
                                              ),
                                            if (status != 'pending')
                                              TextButton.icon(
                                                onPressed: () => _setStatus(
                                                  doc.id,
                                                  'pending',
                                                ),
                                                icon: const Icon(
                                                  Icons.hourglass_empty,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  AppLang.tr('set_pending'),
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      AppTok.textSoft(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                            const Spacer(),
                                            IconButton(
                                              onPressed: () =>
                                                  _deleteWish(doc.id),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              color: Colors.redAccent,
                                              tooltip: AppLang.tr('delete'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            );
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

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppTok.accent(context),
      labelStyle: TextStyle(
        color: selected ? onAccent : AppTok.text(context),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppTok.card(context),
    );
  }

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTok.textSoft(context)),
      prefixIcon: Icon(icon, color: AppTok.accent(context)),
      filled: true,
      fillColor: AppTok.card(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}