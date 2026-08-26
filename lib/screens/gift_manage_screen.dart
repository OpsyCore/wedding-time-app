import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/gift_item_model.dart';
import '../services/gift_registry_service.dart';

class GiftManageScreen extends StatefulWidget {
  const GiftManageScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<GiftManageScreen> createState() => _GiftManageScreenState();
}

class _GiftManageScreenState extends State<GiftManageScreen> {
  late final GiftRegistryService _service;
  final _titleC = TextEditingController();
  final _noteC = TextEditingController();
  final _cardHolderC = TextEditingController();
  final _bankC = TextEditingController();
  final _cardNumC = TextEditingController();
  bool _cardEnabled = false;
  bool _showRegistry = true;

  @override
  void initState() {
    super.initState();
    _service = GiftRegistryService(widget.weddingId);
  }

  @override
  void dispose() {
    _titleC.dispose();
    _noteC.dispose();
    _cardHolderC.dispose();
    _bankC.dispose();
    _cardNumC.dispose();
    super.dispose();
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  Future<void> _add() async {
    final t = _titleC.text.trim();
    if (t.isEmpty) return;
    await _service.addGift(title: t, note: _noteC.text.trim());
    _titleC.clear();
    _noteC.clear();
  }

  Future<void> _saveSettings() async {
    final cards = <GiftCardInfo>[];
    if (_cardNumC.text.trim().isNotEmpty) {
      cards.add(GiftCardInfo(
        holderName: _cardHolderC.text.trim(),
        bankName: _bankC.text.trim(),
        cardNumber: _cardNumC.text.trim(),
        enabled: true,
      ));
    }
    await _service.saveSettings(GiftSettingsModel(
      showRegistry: _showRegistry,
      cardEnabled: _cardEnabled,
      cards: cards,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t('saved', 'ذخیره شد', 'Saved'))),
    );
  }

  String _giftStatus(GiftItemModel g) {
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

  String _fmtDate(DateTime d) {
    const monthsFa = [
      'ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن',
      'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر',
    ];
    return AppLang.I.isFa
        ? '${monthsFa[d.month - 1]} ${d.day} ${d.year}'
        : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _markReceived(GiftItemModel g) async {
    final nameC = TextEditingController();
    final noteC = TextEditingController();
    var date = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(_t('gift_mark_received', 'ثبت دریافت', 'Mark received')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  g.title,
                  style: TextStyle(color: AppTok.textSoft(ctx), fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameC,
                  decoration: InputDecoration(
                    labelText: _t('received_gift_name', 'از طرف / نام (اختیاری)', 'From / name (optional)'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteC,
                  decoration: InputDecoration(
                    labelText: _t('received_gift_note', 'یادداشت (اختیاری)', 'Note (optional)'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _t('received_gift_date', 'تاریخ دریافت', 'Received date'),
                    style: TextStyle(color: AppTok.text(ctx), fontSize: 13),
                  ),
                  subtitle: Text(_fmtDate(date), style: TextStyle(color: AppTok.textSoft(ctx))),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(2015),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setLocal(() => date = picked);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t('cancel', 'انصراف', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t('save', 'ثبت', 'Save')),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    try {
      await _service.markReceived(
        giftId: g.id,
        giftTitle: g.title,
        name: nameC.text,
        note: noteC.text,
        receivedAt: date,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('gift_received_saved', 'دریافت ثبت شد', 'Marked as received'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t('error', 'خطا', 'Error')}: $e')),
      );
    }
  }

  Future<void> _unmarkReceived(ReceivedGiftModel r) async {
    try {
      await _service.unmarkReceived(r.id, r.giftId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('gift_received_removed', 'دریافت لغو شد', 'Removed from received'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t('error', 'خطا', 'Error')}: $e')),
      );
    }
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
              title: Text(
                _t('gift_manage_title', 'مدیریت هدایا', 'Gift registry'),
                style: TextStyle(color: AppTok.text(context), fontWeight: FontWeight.bold),
              ),
              iconTheme: IconThemeData(color: AppTok.text(context)),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  value: _showRegistry,
                  onChanged: (v) => setState(() => _showRegistry = v),
                  title: Text(
                    _t('show_gift_registry', 'نمایش لیست هدایا به مهمان', 'Show registry to guests'),
                    style: TextStyle(color: AppTok.text(context)),
                  ),
                ),
                SwitchListTile(
                  value: _cardEnabled,
                  onChanged: (v) => setState(() => _cardEnabled = v),
                  title: Text(
                    _t('show_card_numbers', 'نمایش شماره کارت', 'Show card numbers'),
                    style: TextStyle(color: AppTok.text(context)),
                  ),
                ),
                TextField(
                  controller: _cardHolderC,
                  style: TextStyle(color: AppTok.text(context)),
                  decoration: _dec(_t('card_holder', 'صاحب کارت', 'Card holder')),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bankC,
                  style: TextStyle(color: AppTok.text(context)),
                  decoration: _dec(_t('bank_name', 'بانک', 'Bank')),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cardNumC,
                  style: TextStyle(color: AppTok.text(context)),
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: _dec(_t('card_number', 'شماره کارت', 'Card number')),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTok.accent(context),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_t('save_settings', 'ذخیره تنظیمات', 'Save settings')),
                ),
                const Divider(height: 32),
                Text(
                  _t('add_gift', 'افزودن هدیه', 'Add gift'),
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleC,
                  style: TextStyle(color: AppTok.text(context)),
                  decoration: _dec(_t('gift_title', 'عنوان هدیه', 'Gift title')),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteC,
                  style: TextStyle(color: AppTok.text(context)),
                  decoration: _dec(_t('note_optional', 'یادداشت', 'Note')),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: Text(_t('add', 'افزودن', 'Add')),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<GiftItemModel>>(
                  stream: _service.watchGifts(),
                  builder: (context, snap) {
                    final items = snap.data ?? [];
                    return Column(
                      children: [
                        for (final g in items)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTok.card(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTok.border(context)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        g.title,
                                        style: TextStyle(
                                          color: AppTok.text(context),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _giftStatus(g),
                                        style: TextStyle(
                                          color: g.isOpen
                                              ? AppTok.accent(context)
                                              : AppTok.textSoft(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Tooltip(
                                  message: _t('gift_is_public', 'نمایش عمومی', 'Public'),
                                  child: Switch(
                                    value: g.isPublic,
                                    activeThumbColor: AppTok.accent(context),
                                    onChanged: (v) => _service.setPublic(g.id, v),
                                  ),
                                ),
                                if (!g.isReceived)
                                  IconButton(
                                    tooltip: _t('gift_mark_received', 'دریافت شد', 'Mark received'),
                                    icon: Icon(Icons.check_circle_outline,
                                        color: AppTok.accent(context)),
                                    onPressed: () => _markReceived(g),
                                  ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: AppTok.danger(context)),
                                  onPressed: () => _service.deleteGift(g.id),
                                ),
                              ],
                            ),
                          ),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _t('no_gifts_yet', 'هنوز هدیه‌ای ثبت نشده', 'No gifts yet'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTok.textSoft(context)),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const Divider(height: 32),
                Text(
                  _t('received_gifts_title', 'هدایای دریافت‌شده', 'Received gifts'),
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<ReceivedGiftModel>>(
                  stream: _service.watchReceivedGifts(),
                  builder: (context, snap) {
                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _t('received_gifts_empty', 'هنوز موردی ثبت نشده', 'Nothing yet'),
                          style: TextStyle(color: AppTok.textSoft(context)),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final r in list)
                          ListTile(
                            tileColor: AppTok.card(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(r.giftTitle,
                                style: TextStyle(color: AppTok.text(context))),
                            subtitle: Text(
                              [
                                if (r.name.trim().isNotEmpty) r.name,
                                if (r.receivedAt != null) _fmtDate(r.receivedAt!),
                              ].join(' · '),
                              style: TextStyle(color: AppTok.textSoft(context)),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.undo, color: AppTok.danger(context)),
                              tooltip: _t('gift_received_remove', 'لغو دریافت', 'Undo'),
                              onPressed: () => _unmarkReceived(r),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTok.card(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}