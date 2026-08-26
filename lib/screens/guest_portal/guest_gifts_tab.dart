import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../models/gift_item_model.dart';
import '../../services/gift_registry_service.dart';

/// هدایا برای مهمان — فقط‌خواندنی (مطابق هنداف: مهمان read-only، نه claim).
/// فقط هدیه‌هایی با isPublic == true نمایش داده می‌شوند.
class GuestGiftsTab extends StatefulWidget {
  const GuestGiftsTab({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<GuestGiftsTab> createState() => _GuestGiftsTabState();
}

class _GuestGiftsTabState extends State<GuestGiftsTab> {
  late final GiftRegistryService _service;

  @override
  void initState() {
    super.initState();
    _service = GiftRegistryService(widget.weddingId);
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

  String _statusText(GiftItemModel g) {
    if (g.isReceived) {
      return _t('gift_status_received', 'دریافت شد', 'Received');
    }
    if (g.isClaimed) {
      final who = (g.claimedByName ?? '').trim();
      return who.isEmpty
          ? _t('gift_status_claimed', 'رزرو شده', 'Claimed')
          : '${_t('claimed_by', 'رزرو:', 'Claimed:')} $who';
    }
    return _t('gift_status_open', 'آزاد', 'Open');
  }

  @override
  Widget build(BuildContext context) {
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
                  final items = snap.data!.where((g) => g.isPublic).toList();
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
                              g.isClaimed
                                  ? Icons.redeem
                                  : Icons.card_giftcard,
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
                                  const SizedBox(height: 4),
                                  Text(
                                    _statusText(g),
                                    style: TextStyle(
                                      color: g.isOpen
                                          ? AppTok.accent(context)
                                          : AppTok.textSoft(context),
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
            ),
          ],
        );
      },
    );
  }
}
