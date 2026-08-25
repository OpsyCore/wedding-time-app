import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/subscription_plan.dart';
import '../services/plans_service.dart';

class PlansAdminScreen extends StatefulWidget {
  const PlansAdminScreen({super.key});

  @override
  State<PlansAdminScreen> createState() => _PlansAdminScreenState();
}

class _PlansAdminScreenState extends State<PlansAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<SubscriptionPlan> _plans = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!PlansService.I.isAdmin) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final list = await PlansService.I.fetchPlans();
    if (!mounted) return;
    setState(() {
      _plans = list.map((e) => e.copyWith(features: [...e.features])).toList();
      _loading = false;
    });
  }

  Future<void> _save() async {
    const t = AppLang.tr;
    setState(() => _saving = true);
    try {
      await PlansService.I.savePlans(_plans);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('plans_admin_saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('save_failed')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _seed() async {
    await PlansService.I.seedDefaultsIfEmpty();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        const t = AppLang.tr;
        final bg = AppTok.background(context);
        final text = AppTok.text(context);
        final accent = AppTok.accent(context);

        if (!PlansService.I.isAdmin) {
          return Directionality(
            textDirection: AppLang.I.direction,
            child: Scaffold(
              backgroundColor: bg,
              appBar: AppBar(title: Text(t('plans_admin'))),
              body: Center(
                child: Text(
                  t('plans_admin_denied'),
                  style: TextStyle(color: text),
                ),
              ),
            ),
          );
        }

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              title: Text(t('plans_admin')),
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              actions: [
                TextButton(
                  onPressed: _loading ? null : _seed,
                  child: Text(
                    t('plans_admin_seed'),
                    style: TextStyle(color: accent),
                  ),
                ),
                TextButton(
                  onPressed: _saving || _loading ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          t('save'),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ],
              bottom: TabBar(
                controller: _tabs,
                labelColor: accent,
                unselectedLabelColor: AppTok.textSoft(context),
                tabs: [
                  Tab(text: t('plans_admin_tab_plans')),
                  Tab(text: t('plans_admin_tab_reviews')),
                ],
              ),
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _PlansEditor(
                        plans: _plans,
                        onChanged: (list) => setState(() => _plans = list),
                      ),
                      const _ReviewsAdmin(),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _PlansEditor extends StatelessWidget {
  const _PlansEditor({required this.plans, required this.onChanged});
  final List<SubscriptionPlan> plans;
  final ValueChanged<List<SubscriptionPlan>> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final p = plans[index];
        return _PlanEditorCard(
          plan: p,
          onChanged: (np) {
            final next = [...plans];
            next[index] = np;
            onChanged(next);
          },
        );
      },
    );
  }
}

class _PlanEditorCard extends StatefulWidget {
  const _PlanEditorCard({required this.plan, required this.onChanged});
  final SubscriptionPlan plan;
  final ValueChanged<SubscriptionPlan> onChanged;

  @override
  State<_PlanEditorCard> createState() => _PlanEditorCardState();
}

class _PlanEditorCardState extends State<_PlanEditorCard> {
  late TextEditingController nameFa;
  late TextEditingController nameEn;
  late TextEditingController subFa;
  late TextEditingController subEn;
  late TextEditingController ctaFa;
  late TextEditingController ctaEn;
  late TextEditingController periodFa;
  late TextEditingController periodEn;
  late TextEditingController badgeFa;
  late TextEditingController badgeEn;
  late TextEditingController priceToman;
  late TextEditingController priceUsd;
  late TextEditingController discount;
  late TextEditingController paymentUrl;

  @override
  void initState() {
    super.initState();
    _bind(widget.plan);
  }

  @override
  void didUpdateWidget(covariant _PlanEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan.id != widget.plan.id) {
      _disposeCtrls();
      _bind(widget.plan);
    }
  }

  @override
  void dispose() {
    _disposeCtrls();
    super.dispose();
  }

  void _disposeCtrls() {
    nameFa.dispose();
    nameEn.dispose();
    subFa.dispose();
    subEn.dispose();
    ctaFa.dispose();
    ctaEn.dispose();
    periodFa.dispose();
    periodEn.dispose();
    badgeFa.dispose();
    badgeEn.dispose();
    priceToman.dispose();
    priceUsd.dispose();
    discount.dispose();
    paymentUrl.dispose();
  }

  void _bind(SubscriptionPlan p) {
    nameFa = TextEditingController(text: p.nameFa);
    nameEn = TextEditingController(text: p.nameEn);
    subFa = TextEditingController(text: p.subtitleFa);
    subEn = TextEditingController(text: p.subtitleEn);
    ctaFa = TextEditingController(text: p.ctaFa);
    ctaEn = TextEditingController(text: p.ctaEn);
    periodFa = TextEditingController(text: p.periodFa);
    periodEn = TextEditingController(text: p.periodEn);
    badgeFa = TextEditingController(text: p.badgeFa ?? '');
    badgeEn = TextEditingController(text: p.badgeEn ?? '');
    priceToman = TextEditingController(text: '${p.priceToman}');
    priceUsd = TextEditingController(text: '${p.priceUsd}');
    discount = TextEditingController(text: '${p.discountPercent}');
    paymentUrl = TextEditingController(text: p.paymentUrl ?? '');
  }

  void _emit(SubscriptionPlan base) {
    widget.onChanged(
      base.copyWith(
        nameFa: nameFa.text.trim(),
        nameEn: nameEn.text.trim(),
        subtitleFa: subFa.text.trim(),
        subtitleEn: subEn.text.trim(),
        ctaFa: ctaFa.text.trim(),
        ctaEn: ctaEn.text.trim(),
        periodFa: periodFa.text.trim(),
        periodEn: periodEn.text.trim(),
        badgeFa: badgeFa.text.trim().isEmpty ? null : badgeFa.text.trim(),
        badgeEn: badgeEn.text.trim().isEmpty ? null : badgeEn.text.trim(),
        priceToman: int.tryParse(priceToman.text.trim()) ?? 0,
        priceUsd: double.tryParse(priceUsd.text.trim()) ?? 0,
        discountPercent:
            (int.tryParse(discount.text.trim()) ?? 0).clamp(0, 90),
        paymentUrl:
            paymentUrl.text.trim().isEmpty ? null : paymentUrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final p = widget.plan;
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final text = AppTok.text(context);
    final accent = AppTok.accent(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(p.icon, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${p.id} — ${p.nameFa}',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(t('plans_admin_popular')),
                selected: p.popular,
                onSelected: (v) {
                  widget.onChanged(
                    p.copyWith(popular: v, highlighted: v || p.highlighted),
                  );
                },
              ),
              FilterChip(
                label: Text(t('plans_admin_highlight')),
                selected: p.highlighted,
                onSelected: (v) =>
                    widget.onChanged(p.copyWith(highlighted: v)),
              ),
              FilterChip(
                label: Text(t('plans_admin_enabled')),
                selected: p.enabled,
                onSelected: (v) => widget.onChanged(p.copyWith(enabled: v)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _field(nameFa, 'نام FA', p),
          _field(nameEn, 'Name EN', p),
          _field(subFa, 'زیرعنوان FA', p),
          _field(subEn, 'Subtitle EN', p),
          _field(ctaFa, 'دکمه FA', p),
          _field(ctaEn, 'CTA EN', p),
          _field(periodFa, 'دوره FA', p),
          _field(periodEn, 'Period EN', p),
          _field(badgeFa, 'بج FA', p),
          _field(badgeEn, 'Badge EN', p),
          Row(
            children: [
              Expanded(
                child: _field(
                  priceToman,
                  t('plans_admin_price_toman'),
                  p,
                  number: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                  priceUsd,
                  t('plans_admin_price_usd'),
                  p,
                  number: true,
                ),
              ),
            ],
          ),
          _field(discount, t('plans_admin_discount'), p, number: true),
          _field(paymentUrl, t('plans_admin_payment_url'), p),
          const SizedBox(height: 8),
          Text(
            t('plans_admin_features'),
            style: TextStyle(color: text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...List.generate(p.features.length, (i) {
            final f = p.features[i];
            return _FeatureEditor(
              feature: f,
              onChanged: (nf) {
                final list = [...p.features];
                list[i] = nf;
                widget.onChanged(p.copyWith(features: list));
              },
              onDelete: () {
                final list = [...p.features]..removeAt(i);
                widget.onChanged(p.copyWith(features: list));
              },
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              final list = [
                ...p.features,
                PlanFeature(
                  id: 'f_${DateTime.now().millisecondsSinceEpoch}',
                  labelFa: 'قابلیت جدید',
                  labelEn: 'New feature',
                  included: true,
                ),
              ];
              widget.onChanged(p.copyWith(features: list));
            },
            icon: const Icon(Icons.add),
            label: Text(t('plans_admin_add_feature')),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _emit(p),
              icon: Icon(Icons.sync, color: accent),
              label: Text(
                t('plans_admin_apply_fields'),
                style: TextStyle(color: accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    SubscriptionPlan p, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        onChanged: (_) => _emit(p),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _FeatureEditor extends StatefulWidget {
  const _FeatureEditor({
    required this.feature,
    required this.onChanged,
    required this.onDelete,
  });

  final PlanFeature feature;
  final ValueChanged<PlanFeature> onChanged;
  final VoidCallback onDelete;

  @override
  State<_FeatureEditor> createState() => _FeatureEditorState();
}

class _FeatureEditorState extends State<_FeatureEditor> {
  late final TextEditingController labelFa;
  late final TextEditingController labelEn;
  late final TextEditingController valueFa;
  late final TextEditingController valueEn;

  @override
  void initState() {
    super.initState();
    labelFa = TextEditingController(text: widget.feature.labelFa);
    labelEn = TextEditingController(text: widget.feature.labelEn);
    valueFa = TextEditingController(text: widget.feature.valueFa);
    valueEn = TextEditingController(text: widget.feature.valueEn);
  }

  @override
  void dispose() {
    labelFa.dispose();
    labelEn.dispose();
    valueFa.dispose();
    valueEn.dispose();
    super.dispose();
  }

  void _push() {
    widget.onChanged(
      widget.feature.copyWith(
        labelFa: labelFa.text,
        labelEn: labelEn.text,
        valueFa: valueFa.text,
        valueEn: valueEn.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final border = AppTok.border(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Switch(
                value: widget.feature.included,
                onChanged: (v) =>
                    widget.onChanged(widget.feature.copyWith(included: v)),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onDelete,
                icon: Icon(Icons.delete_outline, color: AppTok.danger(context)),
              ),
            ],
          ),
          TextField(
            controller: labelFa,
            onChanged: (_) => _push(),
            decoration: const InputDecoration(
              labelText: 'برچسب FA',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: labelEn,
            onChanged: (_) => _push(),
            decoration: const InputDecoration(
              labelText: 'Label EN',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: valueFa,
                  onChanged: (_) => _push(),
                  decoration: const InputDecoration(
                    labelText: 'مقدار FA (۵۰ / ∞)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: valueEn,
                  onChanged: (_) => _push(),
                  decoration: const InputDecoration(
                    labelText: 'Value EN (50 / ∞)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewsAdmin extends StatelessWidget {
  const _ReviewsAdmin();

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    return StreamBuilder<List<PlanReview>>(
      stream: PlansService.I.watchAllReviewsAdmin(),
      builder: (context, snap) {
        final list = snap.data ?? const <PlanReview>[];
        if (list.isEmpty) {
          return Center(child: Text(t('plans_reviews_empty')));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = list[i];
            return ListTile(
              tileColor: AppTok.card(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTok.border(context)),
              ),
              title: Text(
                '${r.name}  ★ ${r.rating.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                r.comment,
                style: TextStyle(color: AppTok.textSoft(context)),
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: r.approved ? 'Hide' : 'Approve',
                    onPressed: () =>
                        PlansService.I.setReviewApproved(r.id, !r.approved),
                    icon: Icon(
                      r.approved
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTok.accent(context),
                    ),
                  ),
                  IconButton(
                    onPressed: () => PlansService.I.deleteReview(r.id),
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppTok.danger(context),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}