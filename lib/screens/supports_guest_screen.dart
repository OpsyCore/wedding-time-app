import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/support_item_model.dart';
import '../services/support_service.dart';
import '../widgets/support_progress_bar.dart';
import 'login_screen.dart';

class SupportsGuestScreen extends StatefulWidget {
  const SupportsGuestScreen({
    super.key,
    required this.weddingId,
    this.previewMode = false,
    this.requireLogin = false,
  });

  final String weddingId;
  final bool previewMode;
  final bool requireLogin;

  @override
  State<SupportsGuestScreen> createState() => _SupportsGuestScreenState();
}

class _SupportsGuestScreenState extends State<SupportsGuestScreen> {
  late final SupportService _svc;

  @override
  void initState() {
    super.initState();
    _svc = SupportService(widget.weddingId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requireLogin &&
        !widget.previewMode &&
        FirebaseAuth.instance.currentUser == null) {
      return Directionality(
        textDirection: AppLang.I.direction,
        child: Scaffold(
          backgroundColor: AppTok.background(context),
          appBar: AppBar(title: Text(AppLang.tr('supports_title'))),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLang.tr('supports_login_required'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTok.text(context), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(AppLang.tr('login')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        const t = AppLang.tr;
        final bg = AppTok.background(context);
        final text = AppTok.text(context);
        final textSoft = AppTok.textSoft(context);
        final accent = AppTok.accent(context);
        final isFa = AppLang.I.isFa;

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              title: Text(t('supports_title')),
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
            ),
            body: StreamBuilder<SupportSettings>(
              stream: _svc.watchSettings(),
              builder: (context, setSnap) {
                final settings = setSnap.data ?? const SupportSettings();
                if (!settings.enabled && !widget.previewMode) {
                  return Center(
                    child: Text(t('supports_disabled'),
                        style: TextStyle(color: textSoft)),
                  );
                }

                return StreamBuilder<List<SupportItem>>(
                  stream: _svc.watchItemsSimple(),
                  builder: (context, itemSnap) {
                    final items = itemSnap.data ?? const <SupportItem>[];
                    final intro = settings.intro(isFa);
                    final cats = settings.enabledCategories.isEmpty
                        ? SupportSettings.defaultCategories()
                        : settings.enabledCategories;

                    // group
                    final byCat = <String, List<SupportItem>>{};
                    for (final it in items) {
                      byCat.putIfAbsent(it.categoryId, () => []).add(it);
                    }
                    final uncategorized = <SupportItem>[];
                    for (final e in byCat.entries) {
                      if (!cats.any((c) => c.id == e.key)) {
                        uncategorized.addAll(e.value);
                      }
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
                        if (widget.previewMode)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t('supports_preview_banner'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTok.accentDeep(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        if (intro.isNotEmpty) ...[
                          Text(
                            intro,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSoft,
                              height: 1.6,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (settings.cardSectionEnabled &&
                            settings.enabledCards.isNotEmpty) ...[
                          Text(
                            t('supports_transfer_title'),
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...settings.enabledCards
                              .map((c) => _CardTile(card: c)),
                          const SizedBox(height: 18),
                        ],
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              t('supports_empty_guest'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textSoft),
                            ),
                          )
                        else ...[
                          for (final cat in cats) ...[
                            if ((byCat[cat.id] ?? const []).isNotEmpty) ...[
                              _CategoryHeader(cat: cat, isFa: isFa),
                              const SizedBox(height: 10),
                              ...(byCat[cat.id] ?? const <SupportItem>[]).map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _GuestItemTile(
                                    item: item,
                                    settings: settings,
                                    onSupport: () => _support(item, settings),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                          if (uncategorized.isNotEmpty) ...[
                            Text(
                              t('supports_list_title'),
                              style: TextStyle(
                                color: text,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...uncategorized.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _GuestItemTile(
                                  item: item,
                                  settings: settings,
                                  onSupport: () => _support(item, settings),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _support(SupportItem item, SupportSettings settings) async {
    const t = AppLang.tr;

    if (widget.previewMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('supports_preview_no_claim'))),
      );
      return;
    }
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('supports_login_required'))),
      );
      return;
    }

    final nameC = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? '',
    );
    final phoneC = TextEditingController();
    final noteC = TextEditingController();
    final amountTomanC = TextEditingController();
    final amountUsdC = TextEditingController();
    var fullClaim = !item.allowPartial || !item.hasTarget;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final inset = MediaQuery.viewInsetsOf(ctx).bottom;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t('supports_claim_title'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTok.text(ctx),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTok.textSoft(ctx)),
                    ),
                    if (item.hasTarget && settings.showProgress) ...[
                      const SizedBox(height: 12),
                      SupportProgressBar(
                        item: item,
                        showRemaining: settings.showRemaining,
                        currencyMode: settings.currencyMode,
                        compact: true,
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameC,
                      decoration: InputDecoration(
                        labelText: t('supports_claim_name'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneC,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: t('supports_claim_phone'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (item.hasTarget && item.allowPartial) ...[
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: fullClaim,
                        activeThumbColor: AppTok.accent(ctx),
                        title: Text(
                          t('supports_full_claim'),
                          style: TextStyle(
                            color: AppTok.text(ctx),
                            fontSize: 13.5,
                          ),
                        ),
                        onChanged: (v) => setLocal(() => fullClaim = v),
                      ),
                      if (!fullClaim) ...[
                        if (settings.currencyMode != 'usd' &&
                            item.targetToman > 0)
                          TextField(
                            controller: amountTomanC,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: t('supports_amount_toman'),
                              helperText:
                                  '${t('supports_left')}: ${SupportProgressBar.fmtToman(item.remainingToman)}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        if (settings.currencyMode != 'toman' &&
                            item.targetUsd > 0) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: amountUsdC,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: t('supports_amount_usd'),
                              helperText:
                                  '${t('supports_left')}: \$${SupportProgressBar.fmtUsd(item.remainingUsd)}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteC,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: t('supports_claim_note'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          fullClaim || !item.hasTarget
                              ? t('supports_claim_cta')
                              : t('supports_contribute_cta'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (ok != true) return;

    try {
      await _svc.contribute(
        itemId: item.id,
        name: nameC.text,
        phone: phoneC.text,
        note: noteC.text,
        amountToman: int.tryParse(amountTomanC.text.trim()) ?? 0,
        amountUsd: double.tryParse(amountUsdC.text.trim()) ?? 0,
        fullClaim: fullClaim || !item.hasTarget || !item.allowPartial,
      );
      if (!mounted) return;
      final thanks = settings.thanks(AppLang.I.isFa);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thanks.isEmpty ? t('supports_claim_thanks') : thanks,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('already_claimed')
          ? t('supports_already_claimed')
          : (e.toString().contains('empty_amount')
              ? t('supports_enter_amount')
              : '${t('error')}: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.cat, required this.isFa});
  final SupportCategory cat;
  final bool isFa;

  @override
  Widget build(BuildContext context) {
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final desc = cat.desc(isFa);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTok.cardSoft(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(cat.icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.title(isFa),
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(color: textSoft, height: 1.45, fontSize: 13),
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

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});
  final SupportBankCard card;

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final number = card.cardNumber.replaceAll(' ', '');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.credit_card, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.holderName.trim().isNotEmpty)
                  Text(card.holderName,
                      style:
                          TextStyle(color: text, fontWeight: FontWeight.w800)),
                if (card.bankName.trim().isNotEmpty)
                  Text(card.bankName,
                      style: TextStyle(color: textSoft, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _prettyCard(number),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: t('copy_short'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: number));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t('supports_card_copied'))),
              );
            },
            icon: Icon(Icons.copy, color: AppTok.textSoft(context)),
          ),
        ],
      ),
    );
  }

  String _prettyCard(String n) {
    final b = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(n[i]);
    }
    return b.toString();
  }
}

class _GuestItemTile extends StatelessWidget {
  const _GuestItemTile({
    required this.item,
    required this.settings,
    required this.onSupport,
  });

  final SupportItem item;
  final SupportSettings settings;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final open = item.isOpen;

    return Container(
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
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (open ? accent : textSoft).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.isFullyFunded && item.hasTarget
                      ? t('supports_goal_reached')
                      : (open
                          ? t('supports_status_open')
                          : (item.status == SupportStatus.received
                              ? t('supports_status_received')
                              : t('supports_status_claimed'))),
                  style: TextStyle(
                    color: open ? accent : textSoft,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (item.note.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.note, style: TextStyle(color: textSoft, height: 1.4)),
          ],
          if (item.hasTarget && settings.showProgress) ...[
            const SizedBox(height: 12),
            SupportProgressBar(
              item: item,
              showRemaining: settings.showRemaining,
              currencyMode: settings.currencyMode,
            ),
          ],
          if (!open && item.claimedByName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${t('supports_claimed_by')}: ${item.claimedByName}',
              style: TextStyle(color: textSoft, fontSize: 12.5),
            ),
          ],
          if (open) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onSupport,
                child: Text(
                  item.hasTarget && item.allowPartial
                      ? t('supports_contribute_cta')
                      : t('supports_claim_cta'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}