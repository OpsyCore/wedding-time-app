import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../models/gift_item_model.dart';
import '../../services/gift_registry_service.dart';
import '../../services/guest_local_store.dart';

/// هدایا برای مهمان — با یا بدون لاگین.
/// FIX-01: رزرو/لغو رزرو فقط با نام (مطابق rules) انجام می‌شود؛
/// «رزرو شما» از روی نام ذخیره‌شده محلی تشخیص داده می‌شود.
class GuestGiftsTab extends StatefulWidget {
  const GuestGiftsTab({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<GuestGiftsTab> createState() => _GuestGiftsTabState();
}

class _GuestGiftsTabState extends State<GuestGiftsTab> {
  late final GiftRegistryService _service;
  final _nameC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = GiftRegistryService(widget.weddingId);
    final u = FirebaseAuth.instance.currentUser;
    final fallback = u?.displayName?.trim().isNotEmpty == true
        ? u!.displayName!.trim()
        : (u?.email?.split('@').first ?? '');
    if (fallback.isNotEmpty) {
      _nameC.text = fallback;
    }
    _loadSavedName();
  }

  /// نامی که مهمان قبلاً (RSVP / میز من / رزرو هدیه) وارد کرده
  Future<void> _loadSavedName() async {
    final n = await GuestLocalStore.loadDisplayName(widget.weddingId);
    if (!mounted) return;
    if ((n ?? '').trim().isNotEmpty) {
      _nameC.text = n!.trim();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  void _toast(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? AppTok.danger(context) : AppTok.accentDeep(context),
      ),
    );
  }

  /// آیا این رزرو مالِ همین دستگاه/مهمان است؟
  /// - با uid اگر لاگین کرده باشد
  /// - وگرنه با تطبیق نام رزرو با نام واردشده (نرمال‌شده)
  bool _isMine(GiftItemModel g, String? uid) {
    if (!g.isClaimed) return false;
    if (uid != null &&
        g.claimedByUid != null &&
        g.claimedByUid!.isNotEmpty &&
        g.claimedByUid == uid) {
      return true;
    }
    final mine = GuestLocalStore.normalizeName(_nameC.text);
    final theirs = GuestLocalStore.normalizeName(g.claimedByByName ?? '');
    return mine.isNotEmpty && theirs.isNotEmpty && mine == theirs;
  }

  Future<void> _claim(GiftItemModel g) async {
    final name = _nameC.text.trim();
    if (name.isEmpty) {
      _toast(_t('enter_your_name', 'نام خود را وارد کنید', 'Enter your name'), error: true);
      return;
    }
    if (name.length > 80) {
      _toast(_t('wish_name_long', 'نام خیلی بلند است', 'Name is too long'), error: true);
      return;
    }
    try {
      await _service.claimGift(giftId: g.id, guestName: name);
      await GuestLocalStore.saveDisplayName(
        weddingId: widget.weddingId,
        name: name,
      );
      _toast(_t('gift_claimed', 'هدیه رزرو شد', 'Gift reserved'));
    } catch (e) {
      _toast('${_t('error', 'خطا', 'Error')}: $e', error: true);
    }
  }

  Future<void> _unclaim(GiftItemModel g) async {
    try {
      await _service.unclaimGift(g.id);
      _toast(_t('gift_unclaimed', 'رزرو لغو شد', 'Reservation cancelled'));
    } catch (e) {
      _toast('${_t('error', 'خطا', 'Error')}: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<GiftSettingsModel>(
      stream: _service.watchSettings(),
      builder: (context, setSnap) {
        final settings = setSnap.data ?? GiftSettingsModel.defaults();
        if (!settings.showRegistry) {
          return Center(
            child: Text(
              _t('gifts_hidden', 'لیست هدایا فعال نیست', 'Gift registry is hidden'),
              style: TextStyle(color: AppTok.textSoft(context)),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                controller: _nameC,
                style: TextStyle(color: AppTok.text(context)),
                decoration: InputDecoration(
                  labelText: _t('your_name_for_gift', 'نام شما (برای رزرو هدیه)', 'Your name (for gift claim)'),
                  filled: true,
                  fillColor: AppTok.card(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (settings.cardEnabled && settings.cards.any((c) => c.enabled)) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final c in settings.cards.where((e) => e.enabled))
                      Container(
                        width: 260,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTok.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTok.accent(context).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.bankName.isEmpty ? _t('card', 'کارت', 'Card') : c.bankName,
                              style: TextStyle(
                                color: AppTok.accent(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.holderName,
                              style: TextStyle(color: AppTok.text(context), fontSize: 12.5),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.cardNumber,
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      color: AppTok.text(context),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: _t('copy', 'کپی', 'Copy'),
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: c.cardNumber));
                                    _toast(_t('copied', 'کپی شد', 'Copied'));
                                  },
                                  icon: Icon(Icons.copy, size: 18, color: AppTok.accent(context)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<GiftItemModel>>(
                stream: _service.watchGifts(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        _t('gifts_load_error', 'خطا در بارگذاری هدایا', 'Failed to load gifts'),
                        style: TextStyle(color: AppTok.danger(context)),
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: AppTok.accent(context)),
                    );
                  }
                  final items = snap.data!;
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        _t('no_gifts_yet', 'هنوز هدیه‌ای ثبت نشده', 'No gifts yet'),
                        style: TextStyle(color: AppTok.textSoft(context)),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final g = items[i];
                      final mine = _isMine(g, uid);
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
                              Icons.card_giftcard,
                              color: g.isOpen
                                  ? AppTok.accent(context)
                                  : AppTok.textSoft(context),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.title,
                                    style: TextStyle(
                                      color: AppTok.text(context),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (g.note.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      g.note,
                                      style: TextStyle(
                                        color: AppTok.textSoft(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if (g.isClaimed) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      mine
                                          ? _t('claimed_by_you', 'رزرو شما', 'Reserved by you')
                                          : '${_t('claimed_by', 'رزرو:', 'Reserved:')} ${g.claimedByByName ?? '—'}',
                                      style: TextStyle(
                                        color: AppTok.accentDeep(context),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (g.isOpen)
                              TextButton(
                                onPressed: () => _claim(g),
                                child: Text(
                                  _t('claim', 'رزرو', 'Claim'),
                                  style: TextStyle(color: AppTok.accent(context)),
                                ),
                              )
                            else if (mine)
                              TextButton(
                                onPressed: () => _unclaim(g),
                                child: Text(
                                  _t('unclaim', 'لغو', 'Undo'),
                                  style: TextStyle(color: AppTok.danger(context)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
