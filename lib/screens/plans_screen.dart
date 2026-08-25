import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/subscription_plan.dart';
import '../services/plans_service.dart';
import 'plans_admin_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({
    super.key,
    this.weddingId,
    this.currentPlanId,
  });

  final String? weddingId;
  final String? currentPlanId;

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool _compare = false;
  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  static String dig(String input) {
    if (!AppLang.I.isFa) return input;
    final b = StringBuffer();
    for (final c in input.codeUnits) {
      if (c >= 48 && c <= 57) {
        b.write(_fa[c - 48]);
      } else {
        b.writeCharCode(c);
      }
    }
    return b.toString();
  }

  static String fmtToman(int n) {
    final raw = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final rev = raw.length - i;
      b.write(raw[i]);
      if (rev > 1 && rev % 3 == 1) b.write(',');
    }
    return dig(b.toString());
  }

  static String fmtUsd(double n) {
    final s =
        n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
    return dig(s);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        const t = AppLang.tr;
        final isFa = AppLang.I.isFa;
        final bg = AppTok.background(context);
        final text = AppTok.text(context);
        final textSoft = AppTok.textSoft(context);
        final accent = AppTok.accent(context);
        final card = AppTok.card(context);
        final border = AppTok.border(context);
        final admin = PlansService.I.isAdmin;

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              title: Text(t('plans_title_short')),
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              actions: [
                if (admin)
                  IconButton(
                    tooltip: t('plans_admin'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlansAdminScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: accent,
                    ),
                  ),
              ],
            ),
            body: StreamBuilder<List<SubscriptionPlan>>(
              stream: PlansService.I.watchPlans(),
              builder: (context, snap) {
                final plans = snap.data ?? const <SubscriptionPlan>[];
                if (snap.connectionState == ConnectionState.waiting &&
                    plans.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Column(
                        children: [
                          Text(
                            t('plans_title'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: text,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('plans_subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSoft,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Material(
                        color: card,
                        borderRadius: BorderRadius.circular(14),
                        child: SwitchListTile(
                          value: _compare,
                          onChanged: (v) => setState(() => _compare = v),
                          activeThumbColor: accent,
                          title: Text(
                            t('plans_compare'),
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                          subtitle: Text(
                            t('plans_compare_hint'),
                            style: TextStyle(color: textSoft, fontSize: 12),
                          ),
                          secondary: Icon(
                            Icons.compare_arrows_rounded,
                            color: accent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: border),
                          ),
                        ),
                      ),
                    ),
                    if (_compare)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: _CompareTable(plans: plans, isFa: isFa),
                      )
                    else
                      SizedBox(
                        height: 580,
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth;
                            final cardW = w >= 980
                                ? (w - 44) / 3
                                : (w < 420 ? w * 0.88 : 320.0);
                            return Directionality(
                              textDirection: TextDirection.ltr,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                scrollDirection: Axis.horizontal,
                                itemCount: plans.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final p = plans[i];
                                  return SizedBox(
                                    width: cardW,
                                    child: _PlanCard(
                                      plan: p,
                                      isFa: isFa,
                                      selected:
                                          p.id == widget.currentPlanId,
                                      onSelect: () => _onSelect(p),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _TrustBar(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.reviews_outlined, color: accent),
                          const SizedBox(width: 8),
                          Text(
                            t('plans_reviews_title'),
                            style: TextStyle(
                              color: text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ReviewForm(
                        plans: plans,
                        onSubmitted: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t('plans_review_thanks'))),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<PlanReview>>(
                      stream: PlansService.I.watchApprovedReviewsSimple(),
                      builder: (context, rSnap) {
                        final reviews = rSnap.data ?? const <PlanReview>[];
                        if (reviews.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              t('plans_reviews_empty'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textSoft),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            return _ReviewTile(review: reviews[i]);
                          },
                        );
                      },
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

  Future<void> _onSelect(SubscriptionPlan plan) async {
    const t = AppLang.tr;
    if (plan.isFree) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('plans_free_activated'))),
      );
      return;
    }
    final url = plan.paymentUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTok.card(ctx),
        surfaceTintColor: Colors.transparent,
        title: Text(
          plan.name(AppLang.I.isFa),
          style: TextStyle(color: AppTok.text(ctx)),
        ),
        content: Text(
          t('plans_payment_soon'),
          style: TextStyle(color: AppTok.textSoft(ctx), height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('ok'), style: TextStyle(color: AppTok.accent(ctx))),
          ),
        ],
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.plans, required this.isFa});
  final List<SubscriptionPlan> plans;
  final bool isFa;

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final accent = AppTok.accent(context);
    final dark = AppTok.isDark(context);
    final gold = dark ? AppDarkPalette.legacyGold : const Color(0xFFC4A574);

    final rowKeys = <String, String>{};
    for (final p in plans) {
      for (final f in p.features) {
        rowKeys.putIfAbsent(f.id, () => f.label(isFa));
      }
    }

    Widget headCell(SubscriptionPlan p) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(p.icon, size: 20, color: p.popular ? gold : accent),
            const SizedBox(height: 4),
            Text(
              p.name(isFa),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    Widget cellFor(SubscriptionPlan p, String fid) {
      PlanFeature? f;
      for (final x in p.features) {
        if (x.id == fid) {
          f = x;
          break;
        }
      }
      if (f == null) {
        return Icon(Icons.remove,
            size: 18, color: textSoft.withValues(alpha: 0.4));
      }
      if (!f.included) {
        return Icon(Icons.close_rounded,
            size: 20, color: textSoft.withValues(alpha: 0.5));
      }
      final v = f.value(isFa).trim();
      if (v.isEmpty) {
        return Icon(Icons.check_rounded, size: 20, color: accent);
      }
      return Text(
        v,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width - 32,
          ),
          child: DataTable(
            headingRowHeight: 64,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 52,
            columnSpacing: 18,
            columns: [
              DataColumn(
                label: Text(
                  t('plans_compare_feature'),
                  style:
                      TextStyle(color: textSoft, fontWeight: FontWeight.w700),
                ),
              ),
              ...plans.map((p) => DataColumn(label: headCell(p))),
            ],
            rows: [
              DataRow(cells: [
                DataCell(Text(
                  t('plans_compare_price'),
                  style: TextStyle(color: text, fontWeight: FontWeight.w700),
                )),
                ...plans.map((p) {
                  if (p.isFree) {
                    return DataCell(Text(
                      t('plans_price_free'),
                      style:
                          TextStyle(color: accent, fontWeight: FontWeight.w800),
                    ));
                  }
                  final toman = _PlansScreenState.fmtToman(p.finalToman);
                  final usd = _PlansScreenState.fmtUsd(p.finalUsd);
                  return DataCell(Text(
                    '$toman ${t('toman')}\n\$$usd',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                  ));
                }),
              ]),
              ...rowKeys.entries.map((e) {
                return DataRow(cells: [
                  DataCell(Text(
                    e.value,
                    style: TextStyle(color: text, fontSize: 12.5),
                  )),
                  ...plans.map(
                    (p) => DataCell(Center(child: cellFor(p, e.key))),
                  ),
                ]);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isFa,
    required this.onSelect,
    this.selected = false,
  });

  final SubscriptionPlan plan;
  final bool isFa;
  final VoidCallback onSelect;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final dark = AppTok.isDark(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final gold = dark ? AppDarkPalette.legacyGold : const Color(0xFFC4A574);
    final goldSoft =
        dark ? AppDarkPalette.legacyGoldSoft : const Color(0xFFE8D5B5);
    final highlight = plan.highlighted || plan.popular;
    final badge = plan.badge(isFa);

    return Directionality(
      textDirection: AppLang.I.direction,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(top: badge != null ? 14 : 6),
            decoration: BoxDecoration(
              color: highlight
                  ? (dark ? const Color(0xFF1A1824) : card)
                  : (dark ? AppTok.cardSoft(context) : card),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: (highlight ? gold : border).withValues(alpha: 0.95),
                width: highlight ? 1.6 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: highlight
                      ? gold.withValues(alpha: dark ? 0.22 : 0.16)
                      : AppTok.shadow(context),
                  blurRadius: highlight ? 26 : 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          (highlight ? gold : accent).withValues(alpha: 0.14),
                    ),
                    child: Icon(plan.icon, color: highlight ? gold : accent),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    plan.name(isFa),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.subtitle(isFa),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: textSoft, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  if (plan.isFree)
                    Text(
                      t('plans_price_free'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentDeep,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else ...[
                    if (plan.hasDiscount)
                      Text(
                        '${_PlansScreenState.fmtToman(plan.priceToman)} ${t('toman')}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSoft,
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      '${_PlansScreenState.fmtToman(plan.finalToman)} ${t('toman')}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: highlight ? goldSoft : text,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (plan.finalUsd > 0)
                      Text(
                        '\$ ${_PlansScreenState.fmtUsd(plan.finalUsd)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSoft,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (plan.hasDiscount) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${t('plans_discount')} ${_PlansScreenState.dig(plan.discountPercent.toString())}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      plan.period(isFa),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSoft, fontSize: 12),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: border, height: 1),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: plan.features.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final f = plan.features[i];
                        final v = f.value(isFa).trim();
                        final label = v.isEmpty
                            ? f.label(isFa)
                            : '${f.label(isFa)} ($v)';
                        return Row(
                          children: [
                            Icon(
                              f.included
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 17,
                              color: f.included
                                  ? (highlight ? gold : accent)
                                  : textSoft.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: f.included
                                      ? text
                                      : textSoft.withValues(alpha: 0.7),
                                  fontSize: 12.5,
                                  fontWeight: f.included
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 46,
                    child: highlight
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: dark
                                    ? [gold, goldSoft]
                                    : [const Color(0xFFD4B896), gold],
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: selected ? null : onSelect,
                                child: Center(
                                  child: Text(
                                    selected
                                        ? t('plans_current')
                                        : plan.cta(isFa),
                                    style: TextStyle(
                                      color: dark
                                          ? AppDarkPalette.background
                                          : const Color(0xFF2A241C),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: selected ? null : onSelect,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentDeep,
                              side: BorderSide(
                                color: accent.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              selected ? t('plans_current') : plan.cta(isFa),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: dark
                          ? [gold, goldSoft]
                          : [const Color(0xFFD4B896), gold],
                    ),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: dark
                          ? AppDarkPalette.background
                          : const Color(0xFF2A241C),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrustBar extends StatelessWidget {
  const _TrustBar();

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: AppTok.accent(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('plans_trust_title'),
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  t('plans_trust_body'),
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewForm extends StatefulWidget {
  const _ReviewForm({required this.plans, required this.onSubmitted});
  final List<SubscriptionPlan> plans;
  final VoidCallback onSubmitted;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _name = TextEditingController();
  final _comment = TextEditingController();
  double _rating = 5;
  String? _planId;
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final isFa = AppLang.I.isFa;
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final text = AppTok.text(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('plans_review_form_title'),
            style: TextStyle(color: text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: t('plans_review_name'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _planId,
            items: [
              DropdownMenuItem(value: null, child: Text(t('plans_review_any'))),
              ...widget.plans.map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name(isFa)),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _planId = v),
            decoration: InputDecoration(
              labelText: t('plans_review_plan'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(t('plans_review_rating'), style: TextStyle(color: text)),
              const Spacer(),
              for (var i = 1; i <= 5; i++)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => setState(() => _rating = i.toDouble()),
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFE0B84F),
                  ),
                ),
            ],
          ),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: t('plans_review_comment'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t('plans_review_send')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    const t = AppLang.tr;
    setState(() => _sending = true);
    try {
      await PlansService.I.submitReview(
        name: _name.text,
        rating: _rating,
        comment: _comment.text,
        planId: _planId ?? '',
      );
      _name.clear();
      _comment.clear();
      setState(() {
        _rating = 5;
        _planId = null;
      });
      widget.onSubmitted();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('plans_review_error'))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final PlanReview review;

  @override
  Widget build(BuildContext context) {
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    AppTok.accent(context).withValues(alpha: 0.15),
                child: Text(
                  review.name.isNotEmpty ? review.name.characters.first : '?',
                  style: TextStyle(
                    color: AppTok.accentDeep(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.name,
                  style: TextStyle(color: text, fontWeight: FontWeight.w800),
                ),
              ),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= review.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 16,
                      color: const Color(0xFFE0B84F),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(color: textSoft, height: 1.5, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}