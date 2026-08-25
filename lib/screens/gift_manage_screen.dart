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
                          ListTile(
                            tileColor: AppTok.card(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(g.title, style: TextStyle(color: AppTok.text(context))),
                            subtitle: Text(
                              g.isOpen
                                  ? _t('open', 'آزاد', 'Open')
                                  : '${g.claimedByName ?? ''} · ${g.status}',
                              style: TextStyle(color: AppTok.textSoft(context)),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: AppTok.danger(context)),
                              onPressed: () => _service.deleteGift(g.id),
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