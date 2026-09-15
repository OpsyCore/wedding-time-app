import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/support_item_model.dart';
import '../services/support_service.dart';
import '../widgets/support_progress_bar.dart';
import 'supports_guest_screen.dart';

class SupportsManageScreen extends StatefulWidget {
  const SupportsManageScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<SupportsManageScreen> createState() => _SupportsManageScreenState();
}

class _SupportsManageScreenState extends State<SupportsManageScreen>
    with SingleTickerProviderStateMixin {
  late final SupportService _svc;
  late final TabController _tabs;
  SupportSettings _settings = const SupportSettings();

  @override
  void initState() {
    super.initState();
    _svc = SupportService(widget.weddingId);
    _tabs = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _svc.fetchSettings();
    if (!mounted) return;
    setState(() => _settings = s);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        const t = AppLang.tr;
        final bg = AppTok.background(context);
        final accent = AppTok.accent(context);

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              title: Text(t('supports_title')),
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              actions: [
                IconButton(
                  tooltip: t('supports_preview_guest'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupportsGuestScreen(
                          weddingId: widget.weddingId,
                          previewMode: true,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.visibility_outlined, color: accent),
                ),
              ],
              bottom: TabBar(
                controller: _tabs,
                isScrollable: true,
                labelColor: accent,
                unselectedLabelColor: AppTok.textSoft(context),
                tabs: [
                  Tab(text: t('supports_tab_list')),
                  Tab(text: t('supports_tab_categories')),
                  Tab(text: t('supports_tab_settings')),
                ],
              ),
            ),
            floatingActionButton: ListenableBuilder(
              listenable: _tabs,
              builder: (context, _) {
                if (_tabs.index != 0) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  heroTag: 'supports_add_fab',
                  onPressed: () => _openItemEditor(),
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: Text(t('supports_add')),
                );
              },
            ),
            body: StreamBuilder<SupportSettings>(
              stream: _svc.watchSettings(),
              builder: (context, setSnap) {
                final settings = setSnap.data ?? _settings;
                return TabBarView(
                  controller: _tabs,
                  children: [
                    _ItemsTab(
                      svc: _svc,
                      settings: settings,
                      onEdit: (item) => _openItemEditor(item, settings),
                    ),
                    _CategoriesTab(
                      svc: _svc,
                      settings: settings,
                      onSaved: _loadSettings,
                    ),
                    _SettingsTab(svc: _svc, initial: settings),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openItemEditor([
    SupportItem? item,
    SupportSettings? settings,
  ]) async {
    const t = AppLang.tr;
    final s = settings ?? await _svc.fetchSettings();
    if (!mounted) return;

    final cats = s.enabledCategories.isEmpty
        ? SupportSettings.defaultCategories()
        : s.enabledCategories;

    final titleC = TextEditingController(text: item?.title ?? '');
    final noteC = TextEditingController(text: item?.note ?? '');
    final imageC = TextEditingController(text: item?.imageUrl ?? '');
    final purchaseUrlC = TextEditingController(text: item?.purchaseUrl ?? '');
    final targetTomanC =
        TextEditingController(text: item == null ? '' : '${item.targetToman}');
    final targetUsdC = TextEditingController(
      text: item == null || item.targetUsd == 0 ? '' : '${item.targetUsd}',
    );
    final raisedTomanC =
        TextEditingController(text: item == null ? '0' : '${item.raisedToman}');
    final raisedUsdC = TextEditingController(
      text: item == null || item.raisedUsd == 0 ? '0' : '${item.raisedUsd}',
    );

    var categoryId = item?.categoryId ?? cats.first.id;
    var allowPartial = item?.allowPartial ?? true;
    if (!cats.any((c) => c.id == categoryId)) {
      categoryId = cats.first.id;
    }

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
                      item == null ? t('supports_add') : t('supports_edit'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTok.text(ctx),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleC,
                      decoration: InputDecoration(
                        labelText: t('supports_item_title'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteC,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: t('supports_item_note'),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      items: [
                        for (final c in cats)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text(c.title(AppLang.I.isFa)),
                          ),
                      ],
                      onChanged: (v) =>
                          setLocal(() => categoryId = v ?? categoryId),
                      decoration: InputDecoration(
                        labelText: t('supports_item_category'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t('supports_goal_section'),
                      style: TextStyle(
                        color: AppTok.accent(ctx),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: targetTomanC,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: t('supports_target_toman'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: targetUsdC,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: t('supports_target_usd'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: raisedTomanC,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: t('supports_raised_toman'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: raisedUsdC,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: t('supports_raised_usd'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('supports_goal_hint'),
                      style: TextStyle(
                        color: AppTok.textSoft(ctx),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: allowPartial,
                      activeThumbColor: AppTok.accent(ctx),
                      title: Text(
                        t('supports_allow_partial'),
                        style: TextStyle(color: AppTok.text(ctx), fontSize: 13.5),
                      ),
                      subtitle: Text(
                        t('supports_allow_partial_hint'),
                        style: TextStyle(
                          color: AppTok.textSoft(ctx),
                          fontSize: 11.5,
                        ),
                      ),
                      onChanged: (v) => setLocal(() => allowPartial = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: imageC,
                      decoration: InputDecoration(
                        labelText: t('supports_item_image_url'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: purchaseUrlC,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: t('supports_purchase_url'),
                        hintText: 'https://...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(t('save')),
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

    final targetToman = int.tryParse(targetTomanC.text.trim()) ?? 0;
    final targetUsd = double.tryParse(targetUsdC.text.trim()) ?? 0;
    final raisedToman = int.tryParse(raisedTomanC.text.trim()) ?? 0;
    final raisedUsd = double.tryParse(raisedUsdC.text.trim()) ?? 0;

    try {
      if (item == null) {
        await _svc.addItem(
          title: titleC.text,
          note: noteC.text,
          imageUrl: imageC.text,
          purchaseUrl: purchaseUrlC.text,
          categoryId: categoryId,
          targetToman: targetToman,
          targetUsd: targetUsd,
          allowPartial: allowPartial,
        );
      } else {
        await _svc.updateItem(
          item.copyWith(
            title: titleC.text.trim(),
            note: noteC.text.trim(),
            imageUrl: imageC.text.trim(),
            purchaseUrl: purchaseUrlC.text.trim(),
            categoryId: categoryId,
            targetToman: targetToman,
            targetUsd: targetUsd,
            raisedToman: raisedToman,
            raisedUsd: raisedUsd,
            allowPartial: allowPartial,
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('item_saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('save_failed')}: $e')),
      );
    }
  }
}

// ───────────────── Items tab ─────────────────

class _ItemsTab extends StatelessWidget {
  const _ItemsTab({
    required this.svc,
    required this.settings,
    required this.onEdit,
  });

  final SupportService svc;
  final SupportSettings settings;
  final ValueChanged<SupportItem> onEdit;

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final isFa = AppLang.I.isFa;

    return StreamBuilder<List<SupportItem>>(
      stream: svc.watchItemsSimple(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const <SupportItem>[];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard_rounded,
                      size: 48, color: accent.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text(
                    t('supports_empty_manage'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSoft, height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }

        final cats = settings.enabledCategories.isEmpty
            ? SupportSettings.defaultCategories()
            : settings.enabledCategories;

        final byCat = <String, List<SupportItem>>{};
        for (final it in items) {
          byCat.putIfAbsent(it.categoryId, () => []).add(it);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          children: [
            for (final cat in cats) ...[
              if ((byCat[cat.id] ?? const []).isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        cat.title(isFa),
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${byCat[cat.id]!.length})',
                        style: TextStyle(color: textSoft, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ...byCat[cat.id]!.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ManageItemTile(
                      svc: svc,
                      item: item,
                      onEdit: () => onEdit(item),
                      settings: settings,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _ManageItemTile extends StatelessWidget {
  const _ManageItemTile({
    required this.svc,
    required this.item,
    required this.onEdit,
    required this.settings,
  });

  final SupportService svc;
  final SupportItem item;
  final VoidCallback onEdit;
  final SupportSettings settings;

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);

    return Container(
      padding: const EdgeInsets.all(12),
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
                    fontSize: 14.5,
                  ),
                ),
              ),
              _StatusBadge(item: item),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: textSoft),
                onSelected: (v) async {
                  if (v == 'edit') {
                    onEdit();
                  } else if (v == 'received') {
                    await svc.markReceived(item.id);
                  } else if (v == 'release') {
                    await svc.releaseClaim(item.id);
                  } else if (v == 'delete') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text(t('delete')),
                        content: Text(t('supports_delete_confirm')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: Text(t('cancel')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: Text(t('delete')),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await svc.deleteItem(item.id);
                  }
                },
                itemBuilder: (c) => [
                  PopupMenuItem(value: 'edit', child: Text(t('edit'))),
                  if (item.status != SupportStatus.received)
                    PopupMenuItem(
                      value: 'received',
                      child: Text(t('supports_mark_received')),
                    ),
                  if (item.status != SupportStatus.open)
                    PopupMenuItem(
                      value: 'release',
                      child: Text(t('supports_release')),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      t('delete'),
                      style: TextStyle(color: AppTok.danger(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.note.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.note, style: TextStyle(color: textSoft, fontSize: 12.5)),
          ],
          if (item.hasTarget) ...[
            const SizedBox(height: 8),
            SupportProgressBar(
              item: item,
              showRemaining: settings.showRemaining,
              currencyMode: settings.currencyMode,
            ),
          ],
          if (item.claimedByName.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: accent),
                const SizedBox(width: 4),
                Text(
                  '${t('supports_claimed_by')}: ${item.claimedByName}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.claimedByPhone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${item.claimedByPhone})',
                    style: TextStyle(color: textSoft, fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
          if (item.purchaseUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.link_rounded, size: 14, color: textSoft),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.purchaseUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textSoft, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.item});
  final SupportItem item;

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final accent = AppTok.accent(context);
    final soft = AppTok.textSoft(context);
    final deep = AppTok.accentDeep(context);

    String label;
    Color color;

    if (item.isFullyFunded && item.hasTarget) {
      label = t('supports_goal_reached');
      color = deep;
    } else {
      switch (item.status) {
        case SupportStatus.open:
          label = t('supports_status_open');
          color = accent;
          break;
        case SupportStatus.claimed:
          label = t('supports_status_claimed');
          color = soft;
          break;
        case SupportStatus.received:
          label = t('supports_status_received');
          color = deep;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ───────────────── Categories ─────────────────

class _CategoriesTab extends StatefulWidget {
  const _CategoriesTab({
    required this.svc,
    required this.settings,
    required this.onSaved,
  });

  final SupportService svc;
  final SupportSettings settings;
  final VoidCallback onSaved;

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  late List<SupportCategory> _cats;
  bool _saving = false;

  static const _icons = [
    'gift',
    'heart',
    'home',
    'kitchen',
    'appliances',
    'travel',
    'experience',
    'furniture',
    'decor',
    'ring',
    'party',
    'cash',
  ];

  @override
  void initState() {
    super.initState();
    _cats = [...widget.settings.categories];
    if (_cats.isEmpty) _cats = SupportSettings.defaultCategories();
  }

  @override
  void didUpdateWidget(covariant _CategoriesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.categories != widget.settings.categories) {
      _cats = [...widget.settings.categories];
      if (_cats.isEmpty) _cats = SupportSettings.defaultCategories();
    }
  }

  Future<void> _save() async {
    const t = AppLang.tr;
    setState(() => _saving = true);
    try {
      await widget.svc.saveSettings(
        widget.settings.copyWith(categories: _cats),
      );
      widget.onSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('settings_saved'))),
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

  void _add() {
    _openCatDialog();
  }

  void _edit(int index) {
    _openCatDialog(_cats[index], index);
  }

  Future<void> _openCatDialog([SupportCategory? cat, int? index]) async {
    const t = AppLang.tr;
    final titleFaC = TextEditingController(text: cat?.titleFa ?? '');
    final titleEnC = TextEditingController(text: cat?.titleEn ?? '');
    final descFaC = TextEditingController(text: cat?.descFa ?? '');
    final descEnC = TextEditingController(text: cat?.descEn ?? '');
    var iconKey = cat?.iconKey ?? 'gift';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setL) => AlertDialog(
          title: Text(cat == null ? t('supports_add_category') : t('edit')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleFaC,
                  decoration: InputDecoration(
                    labelText: t('supports_cat_title_fa'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleEnC,
                  decoration: InputDecoration(
                    labelText: t('supports_cat_title_en'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descFaC,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: t('supports_cat_desc_fa'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descEnC,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: t('supports_cat_desc_en'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    t('supports_cat_icon'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final k in _icons)
                      ChoiceChip(
                        selected: iconKey == k,
                        label: Text(k),
                        avatar: Icon(
                          SupportCategory(
                            id: '',
                            titleFa: '',
                            titleEn: '',
                            iconKey: k,
                          ).icon,
                          size: 16,
                        ),
                        onSelected: (_) => setL(() => iconKey = k),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t('save')),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final tFa = titleFaC.text.trim();
    if (tFa.isEmpty) return;

    final updated = SupportCategory(
      id: cat?.id ?? 'cat_${DateTime.now().millisecondsSinceEpoch}',
      titleFa: tFa,
      titleEn: titleEnC.text.trim(),
      descFa: descFaC.text.trim(),
      descEn: descEnC.text.trim(),
      iconKey: iconKey,
      sortOrder: cat?.sortOrder ?? _cats.length,
      enabled: cat?.enabled ?? true,
    );

    setState(() {
      if (index != null && index >= 0 && index < _cats.length) {
        _cats[index] = updated;
      } else {
        _cats.add(updated);
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final isFa = AppLang.I.isFa;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTok.cardSoft(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            t('supports_categories_help'),
            style: TextStyle(color: textSoft, fontSize: 12.5, height: 1.45),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _cats.length; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTok.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTok.border(context)),
            ),
            child: ListTile(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(_cats[i].icon, color: accent, size: 20),
              ),
              title: Text(
                _cats[i].title(isFa),
                style: TextStyle(color: text, fontWeight: FontWeight.w800),
              ),
              subtitle: _cats[i].desc(isFa).isNotEmpty
                  ? Text(
                      _cats[i].desc(isFa),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textSoft, fontSize: 12),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: t('edit'),
                    icon: Icon(Icons.edit_outlined, color: textSoft),
                    onPressed: _saving ? null : () => _edit(i),
                  ),
                  IconButton(
                    tooltip: t('delete'),
                    icon: Icon(Icons.delete_outline,
                        color: AppTok.danger(context)),
                    onPressed: _saving
                        ? null
                        : () async {
                            if (_cats.length <= 1) return;
                            setState(() => _cats.removeAt(i));
                            await _save();
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _saving ? null : _add,
          icon: const Icon(Icons.add),
          label: Text(t('supports_add_category')),
        ),
      ],
    );
  }
}

// ───────────────── Settings tab ─────────────────

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({required this.svc, required this.initial});

  final SupportService svc;
  final SupportSettings initial;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late bool _enabled;
  late bool _cardSectionEnabled;
  late bool _showProgress;
  late bool _showRemaining;
  late bool _guestClaimEnabled;
  late String _currencyMode;
  late TextEditingController _introFaC;
  late TextEditingController _introEnC;
  late TextEditingController _thanksFaC;
  late TextEditingController _thanksEnC;
  late List<SupportBankCard> _cards;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _apply(widget.initial);
  }

  @override
  void didUpdateWidget(covariant _SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _apply(widget.initial);
    }
  }

  void _apply(SupportSettings s) {
    _enabled = s.enabled;
    _cardSectionEnabled = s.cardSectionEnabled;
    _showProgress = s.showProgress;
    _showRemaining = s.showRemaining;
    _guestClaimEnabled = s.guestClaimEnabled;
    _currencyMode = s.currencyMode;
    _introFaC = TextEditingController(text: s.introFa);
    _introEnC = TextEditingController(text: s.introEn);
    _thanksFaC = TextEditingController(text: s.thanksFa);
    _thanksEnC = TextEditingController(text: s.thanksEn);
    _cards = [...s.cards];
  }

  @override
  void dispose() {
    _introFaC.dispose();
    _introEnC.dispose();
    _thanksFaC.dispose();
    _thanksEnC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    const t = AppLang.tr;
    setState(() => _saving = true);
    try {
      final updated = widget.initial.copyWith(
        enabled: _enabled,
        cardSectionEnabled: _cardSectionEnabled,
        showProgress: _showProgress,
        showRemaining: _showRemaining,
        guestClaimEnabled: _guestClaimEnabled,
        currencyMode: _currencyMode,
        introFa: _introFaC.text.trim(),
        introEn: _introEnC.text.trim(),
        thanksFa: _thanksFaC.text.trim(),
        thanksEn: _thanksEnC.text.trim(),
        cards: _cards,
      );
      await widget.svc.saveSettings(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('settings_saved'))),
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

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        Text(
          t('supports_settings_general'),
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _enabled,
          activeThumbColor: accent,
          title: Text(t('supports_enabled'), style: TextStyle(color: text)),
          subtitle: Text(
            t('supports_enabled_hint'),
            style: TextStyle(color: textSoft, fontSize: 12),
          ),
          onChanged: (v) => setState(() => _enabled = v),
        ),
        SwitchListTile(
          value: _guestClaimEnabled,
          activeThumbColor: accent,
          title: Text(t('supports_guest_claim'), style: TextStyle(color: text)),
          subtitle: Text(
            t('supports_guest_claim_hint'),
            style: TextStyle(color: textSoft, fontSize: 12),
          ),
          onChanged: (v) => setState(() => _guestClaimEnabled = v),
        ),
        SwitchListTile(
          value: _showProgress,
          activeThumbColor: accent,
          title: Text(t('supports_show_progress'), style: TextStyle(color: text)),
          subtitle: Text(
            t('supports_show_progress_hint'),
            style: TextStyle(color: textSoft, fontSize: 12),
          ),
          onChanged: (v) => setState(() => _showProgress = v),
        ),
        SwitchListTile(
          value: _showRemaining,
          activeThumbColor: accent,
          title:
              Text(t('supports_show_remaining'), style: TextStyle(color: text)),
          subtitle: Text(
            t('supports_show_remaining_hint'),
            style: TextStyle(color: textSoft, fontSize: 12),
          ),
          onChanged: (v) => setState(() => _showRemaining = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _currencyMode,
          items: [
            DropdownMenuItem(
              value: 'both',
              child: Text(t('supports_currency_both')),
            ),
            DropdownMenuItem(
              value: 'toman',
              child: Text(t('supports_currency_toman')),
            ),
            DropdownMenuItem(
              value: 'usd',
              child: Text(t('supports_currency_usd')),
            ),
          ],
          onChanged: (v) => setState(() => _currencyMode = v ?? 'both'),
          decoration: InputDecoration(
            labelText: t('supports_currency_mode'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t('supports_settings_texts'),
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _introFaC,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('supports_intro_fa'),
            helperText: t('supports_intro_help'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _introEnC,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('supports_intro_en'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _thanksFaC,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('supports_thanks_fa'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _thanksEnC,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('supports_thanks_en'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _cardSectionEnabled,
          activeThumbColor: accent,
          title: Text(t('supports_cards_enabled'), style: TextStyle(color: text)),
          subtitle: Text(
            t('supports_cards_enabled_hint'),
            style: TextStyle(color: textSoft, fontSize: 12),
          ),
          onChanged: (v) => setState(() => _cardSectionEnabled = v),
        ),
        if (_cardSectionEnabled) ...[
          const SizedBox(height: 8),
          for (var i = 0; i < _cards.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTok.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTok.border(context)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${t('card')} ${i + 1}',
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Switch(
                        value: _cards[i].enabled,
                        activeThumbColor: accent,
                        onChanged: (v) =>
                            setState(() => _cards[i] = _cards[i].copyWith(enabled: v)),
                      ),
                      IconButton(
                        tooltip: t('delete'),
                        icon: Icon(Icons.delete_outline,
                            color: AppTok.danger(context)),
                        onPressed: () => setState(() => _cards.removeAt(i)),
                      ),
                    ],
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: t('supports_card_holder'),
                    ),
                    controller:
                        TextEditingController(text: _cards[i].holderName)
                          ..selection = TextSelection.collapsed(
                            offset: _cards[i].holderName.length,
                          ),
                    onChanged: (v) => _cards[i] = _cards[i].copyWith(holderName: v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: t('supports_card_bank'),
                          ),
                          controller:
                              TextEditingController(text: _cards[i].bankName)
                                ..selection = TextSelection.collapsed(
                                  offset: _cards[i].bankName.length,
                                ),
                          onChanged: (v) =>
                              _cards[i] = _cards[i].copyWith(bankName: v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: t('supports_card_number'),
                          ),
                          controller:
                              TextEditingController(text: _cards[i].cardNumber)
                                ..selection = TextSelection.collapsed(
                                  offset: _cards[i].cardNumber.length,
                                ),
                          onChanged: (v) =>
                              _cards[i] = _cards[i].copyWith(cardNumber: v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(
              () => _cards.add(
                SupportBankCard(
                  id: 'card_${DateTime.now().millisecondsSinceEpoch}',
                ),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(t('supports_bank_cards')),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(t('save_settings')),
          ),
        ),
      ],
    );
  }
}
