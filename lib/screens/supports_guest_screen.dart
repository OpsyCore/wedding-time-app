import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    final thanks = settings.thanks(isFa);
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTok.cardSoft(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Text(
                              intro,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: text,
                                height: 1.6,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
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
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _GuestItemTile(
                                    svc: _svc,
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
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _GuestItemTile(
                                  svc: _svc,
                                  item: item,
                                  settings: settings,
                                  onSupport: () => _support(item, settings),
                                ),
                              ),
                            ),
                          ],
                        ],
                        if (thanks.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  color: accent,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    thanks,
                                    style: TextStyle(
                                      color: text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    if (!settings.guestClaimEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('supports_guest_claim_disabled'))),
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
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset + MediaQuery.of(ctx).padding.bottom),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${t('supports_claim_title')} — ${item.title}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTok.text(ctx),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
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
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteC,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: t('supports_claim_note'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (item.hasTarget && item.allowPartial) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: fullClaim,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppTok.accent(ctx),
                        title: Text(
                          t('supports_full_claim'),
                          style: TextStyle(
                            color: AppTok.text(ctx),
                            fontSize: 13.5,
                          ),
                        ),
                        onChanged: (v) => setLocal(() => fullClaim = v ?? false),
                      ),
                      if (!fullClaim) ...[
                        const SizedBox(height: 8),
                        if (settings.currencyMode == 'both' ||
                            settings.currencyMode == 'toman') ...[
                          TextField(
                            controller: amountTomanC,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: t('supports_amount_toman'),
                              hintText: item.remainingToman > 0
                                  ? '${t('supports_left')}: ${item.remainingToman}'
                                  : null,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (settings.currencyMode == 'both' ||
                            settings.currencyMode == 'usd') ...[
                          TextField(
                            controller: amountUsdC,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: t('supports_amount_usd'),
                              hintText: item.remainingUsd > 0
                                  ? '${t('supports_left')}: \$${item.remainingUsd.toStringAsFixed(0)}'
                                  : null,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ],
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
          backgroundColor: AppTok.accent(context),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('already_claimed')
          ? t('supports_already_claimed')
          : (e.toString().contains('empty_amount')
              ? t('supports_enter_amount')
              : '${t('error')}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTok.danger(context),
        ),
      );
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
    required this.svc,
    required this.item,
    required this.settings,
    required this.onSupport,
  });

  final SupportService svc;
  final SupportItem item;
  final SupportSettings settings;
  final VoidCallback onSupport;

  Future<void> _openPurchaseLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLang.tr('could_not_open'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final open = item.isOpen;
    final hasImage = item.imageUrl.trim().isNotEmpty;
    final hasPurchaseUrl = item.purchaseUrl.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTok.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product Image (if provided) ──
          if (hasImage) ...[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                width: double.infinity,
                height: 170,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl.trim(),
                  fit: BoxFit.cover,
                  placeholder: (c, _) => Container(
                    color: AppTok.cardSoft(context),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (c, _, __) => Container(
                    color: AppTok.cardSoft(context),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: textSoft,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(14),
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
                          fontSize: 15.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (open ? accent : textSoft)
                            .withValues(alpha: 0.12),
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
                  Text(
                    item.note,
                    style: TextStyle(color: textSoft, height: 1.4, fontSize: 13),
                  ),
                ],

                // ── Progress Bar ──
                if (item.hasTarget && settings.showProgress) ...[
                  const SizedBox(height: 12),
                  SupportProgressBar(
                    item: item,
                    showRemaining: settings.showRemaining,
                    currencyMode: settings.currencyMode,
                  ),
                ],

                // ── Purchase link button (if provided) ──
                if (hasPurchaseUrl) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openPurchaseLink(context, item.purchaseUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTok.cardSoft(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 16, color: accent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              t('supports_buy_online'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new_rounded,
                              size: 14, color: accent),
                        ],
                      ),
                    ),
                  ),
                ],

                // ── Primary Claimed By (Single Claim) ──
                if (!open && item.claimedByName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.volunteer_activism_rounded,
                          size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        '${t('supports_claimed_by')}: ${item.claimedByName}',
                        style: TextStyle(
                          color: textSoft,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Contributors List (Multiple Supporters) ──
                StreamBuilder<List<SupportContribution>>(
                  stream: svc.watchContributions(item.id),
                  builder: (context, cSnap) {
                    final contribs = cSnap.data ?? const <SupportContribution>[];
                    if (contribs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Divider(
                          height: 1,
                          color: AppTok.border(context).withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.favorite_border_rounded,
                                size: 14, color: accent),
                            const SizedBox(width: 6),
                            Text(
                              '${t('supports_contributors_title')} (${contribs.length})',
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final c in contribs)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTok.cardSoft(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTok.border(context)
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  c.name +
                                      (c.amountToman > 0
                                          ? ' (${c.amountToman} ${t('currency_toman')})'
                                          : (c.amountUsd > 0
                                              ? ' (\$${c.amountUsd.toStringAsFixed(0)})'
                                              : '')),
                                  style: TextStyle(
                                    color: text,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                // ── Claim / Contribute Button ──
                if (open) ...[
                  const SizedBox(height: 14),
                  if (settings.guestClaimEnabled)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onSupport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          item.hasTarget && item.allowPartial
                              ? t('supports_contribute_cta')
                              : t('supports_claim_cta'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTok.cardSoft(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        t('supports_guest_claim_disabled_hint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          fontSize: 12,
                          height: 1.4,
                        ),
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
