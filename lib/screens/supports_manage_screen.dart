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
        SnackBar(content: Text(t('saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('save_failed')}: $e')),
      );
    }
  }
}

// ───────────────── Items ─────────────────

class _ItemsTab extends StatelessWidget {
  const _ItemsTab({
    required this.svc,
    required this.settings,
    required this.onEdit,
  });

  final SupportService svc;
  final SupportSettings settings;
  final void Function(SupportItem item) onEdit;

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final danger = AppTok.danger(context);
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final isFa = AppLang.I.isFa;

    return StreamBuilder<List<SupportItem>>(
      stream: svc.watchItemsSimple(),
      builder: (context, snap) {
        final items = snap.data ?? const <SupportItem>[];
        if (snap.connectionState == ConnectionState.waiting && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                t('supports_empty_manage'),
                textAlign: TextAlign.center,
                style: TextStyle(color: textSoft, height: 1.5),
              ),
            ),
          );
        }

        final catMap = {for (final c in settings.categories) c.id: c};

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final item = items[i];
            final cat = catMap[item.categoryId];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (cat != null) ...[
                        Icon(cat.icon, size: 18, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          cat.title(isFa),
                          style: TextStyle(
                            color: accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                      ] else
                        const Spacer(),
                      _StatusChip(status: item.status, item: item),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                  if (item.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(item.note,
                        style: TextStyle(color: textSoft, height: 1.45)),
                  ],
                  if (item.hasTarget && settings.showProgress) ...[
                    const SizedBox(height: 12),
                    SupportProgressBar(
                      item: item,
                      showRemaining: settings.showRemaining,
                      currencyMode: settings.currencyMode,
                    ),
                  ],
                  if (item.isClaimed && item.claimedByName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${t('supports_claimed_by')}: ${item.claimedByName}'
                        '${item.claimedByPhone.isEmpty ? '' : ' · ${item.claimedByPhone}'}'
                        '${item.claimedNote.isEmpty ? '' : '\n${item.claimedNote}'}',
                        style: TextStyle(color: text, height: 1.45, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () => onEdit(item),
                        icon: Icon(Icons.edit_outlined, size: 18, color: accent),
                        label: Text(t('edit'), style: TextStyle(color: accent)),
                      ),
                      if (item.status == SupportStatus.claimed)
                        TextButton.icon(
                          onPressed: () => svc.markReceived(item.id),
                          icon: Icon(Icons.done_all, size: 18, color: accent),
                          label: Text(t('supports_mark_received'),
                              style: TextStyle(color: accent)),
                        ),
                      if (item.isClaimed || item.raisedToman > 0)
                        TextButton.icon(
                          onPressed: () => svc.releaseClaim(item.id),
                          icon: Icon(Icons.undo, size: 18, color: textSoft),
                          label: Text(t('supports_release'),
                              style: TextStyle(color: textSoft)),
                        ),
                      TextButton.icon(
                        onPressed: () async {
                          final sure = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTok.card(ctx),
                              title: Text(t('delete'),
                                  style: TextStyle(color: AppTok.text(ctx))),
                              content: Text(t('supports_delete_confirm'),
                                  style:
                                      TextStyle(color: AppTok.textSoft(ctx))),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(t('cancel')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(t('delete'),
                                      style: TextStyle(
                                          color: AppTok.danger(ctx))),
                                ),
                              ],
                            ),
                          );
                          if (sure == true) await svc.deleteItem(item.id);
                        },
                        icon:
                            Icon(Icons.delete_outline, size: 18, color: danger),
                        label:
                            Text(t('delete'), style: TextStyle(color: danger)),
                      ),
                    ],
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.item});
  final SupportStatus status;
  final SupportItem item;

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final accent = AppTok.accent(context);
    final soft = AppTok.textSoft(context);
    final deep = AppTok.accentDeep(context);

    late String label;
    late Color color;

    if (item.isFullyFunded && item.hasTarget) {
      label = t('supports_goal_reached');
      color = const Color(0xFF5FA777);
    } else {
      switch (status) {
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
    'travel',
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
    setState(() {
      _cats = [
        ..._cats,
        SupportCategory(
          id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
          titleFa: 'دسته جدید',
          titleEn: 'New category',
          descFa: '',
          descEn: '',
          iconKey: 'gift',
          sortOrder: _cats.length,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final text = AppTok.text(context);
    final accent = AppTok.accent(context);
    final card = AppTok.card(context);
    final border = AppTok.border(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          t('supports_categories_help'),
          style: TextStyle(
            color: AppTok.textSoft(context),
            height: 1.5,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _add,
            icon: Icon(Icons.add, color: accent),
            label: Text(t('supports_add_category'),
                style: TextStyle(color: accent)),
          ),
        ),
        for (var i = 0; i < _cats.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(_cats[i].icon, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _cats[i].titleFa.isEmpty
                            ? _cats[i].id
                            : _cats[i].titleFa,
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Switch(
                      value: _cats[i].enabled,
                      activeThumbColor: accent,
                      onChanged: (v) {
                        setState(() {
                          _cats[i] = _cats[i].copyWith(enabled: v);
                        });
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _cats = [..._cats]..removeAt(i));
                      },
                      icon: Icon(Icons.delete_outline,
                          color: AppTok.danger(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _cats[i].titleFa,
                  onChanged: (v) =>
                      _cats[i] = _cats[i].copyWith(titleFa: v),
                  decoration: InputDecoration(
                    labelText: t('supports_cat_title_fa'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _cats[i].titleEn,
                  onChanged: (v) =>
                      _cats[i] = _cats[i].copyWith(titleEn: v),
                  decoration: InputDecoration(
                    labelText: t('supports_cat_title_en'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _cats[i].descFa,
                  maxLines: 3,
                  onChanged: (v) =>
                      _cats[i] = _cats[i].copyWith(descFa: v),
                  decoration: InputDecoration(
                    labelText: t('supports_cat_desc_fa'),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _cats[i].descEn,
                  maxLines: 3,
                  onChanged: (v) =>
                      _cats[i] = _cats[i].copyWith(descEn: v),
                  decoration: InputDecoration(
                    labelText: t('supports_cat_desc_en'),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _icons.contains(_cats[i].iconKey)
                      ? _cats[i].iconKey
                      : 'gift',
                  items: [
                    for (final k in _icons)
                      DropdownMenuItem(value: k, child: Text(k)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _cats[i] = _cats[i].copyWith(iconKey: v));
                  },
                  decoration: InputDecoration(
                    labelText: t('supports_cat_icon'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t('save_settings')),
          ),
        ),
      ],
    );
  }
}

// ───────────────── Settings ─────────────────

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({required this.svc, required this.initial});
  final SupportService svc;
  final SupportSettings initial;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late SupportSettings _local;
  bool _saving = false;

  final _introFa = TextEditingController();
  final _introEn = TextEditingController();
  final _thanksFa = TextEditingController();
  final _thanksEn = TextEditingController();
  final _holderCtrls = <TextEditingController>[];
  final _bankCtrls = <TextEditingController>[];
  final _numberCtrls = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _bind(widget.initial);
  }

  @override
  void didUpdateWidget(covariant _SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && !_saving) {
      // keep local edits unless first load empty cards mismatch
    }
  }

  void _bind(SupportSettings s) {
    _local = s;
    _introFa.text = s.introFa;
    _introEn.text = s.introEn;
    _thanksFa.text = s.thanksFa;
    _thanksEn.text = s.thanksEn;
    _disposeCardCtrls();
    for (final c in s.cards) {
      _holderCtrls.add(TextEditingController(text: c.holderName));
      _bankCtrls.add(TextEditingController(text: c.bankName));
      _numberCtrls.add(TextEditingController(text: c.cardNumber));
    }
  }

  void _disposeCardCtrls() {
    for (final c in _holderCtrls) {
      c.dispose();
    }
    for (final c in _bankCtrls) {
      c.dispose();
    }
    for (final c in _numberCtrls) {
      c.dispose();
    }
    _holderCtrls.clear();
    _bankCtrls.clear();
    _numberCtrls.clear();
  }

  @override
  void dispose() {
    _introFa.dispose();
    _introEn.dispose();
    _thanksFa.dispose();
    _thanksEn.dispose();
    _disposeCardCtrls();
    super.dispose();
  }

  List<SupportBankCard> _collectCards() {
    final out = <SupportBankCard>[];
    for (var i = 0; i < _local.cards.length; i++) {
      out.add(
        _local.cards[i].copyWith(
          holderName:
              i < _holderCtrls.length ? _holderCtrls[i].text.trim() : '',
          bankName: i < _bankCtrls.length ? _bankCtrls[i].text.trim() : '',
          cardNumber:
              i < _numberCtrls.length ? _numberCtrls[i].text.trim() : '',
        ),
      );
    }
    return out;
  }

  Future<void> _save() async {
    const t = AppLang.tr;
    setState(() => _saving = true);
    try {
      final next = _local.copyWith(
        introFa: _introFa.text.trim(),
        introEn: _introEn.text.trim(),
        thanksFa: _thanksFa.text.trim(),
        thanksEn: _thanksEn.text.trim(),
        cards: _collectCards(),
      );
      await widget.svc.saveSettings(next);
      if (!mounted) return;
      setState(() => _local = next);
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

  void _addCard() {
    final cards = [
      ..._collectCards(),
      SupportBankCard(id: 'c_${DateTime.now().millisecondsSinceEpoch}'),
    ];
    _disposeCardCtrls();
    for (final c in cards) {
      _holderCtrls.add(TextEditingController(text: c.holderName));
      _bankCtrls.add(TextEditingController(text: c.bankName));
      _numberCtrls.add(TextEditingController(text: c.cardNumber));
    }
    setState(() => _local = _local.copyWith(cards: cards));
  }

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final s = _local;
    final text = AppTok.text(context);
    final accent = AppTok.accent(context);
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final soft = AppTok.textSoft(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(t('supports_settings_general'),
            style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
        SwitchListTile(
          value: s.enabled,
          activeThumbColor: accent,
          title: Text(t('supports_enabled'), style: TextStyle(color: text)),
          subtitle: Text(t('supports_enabled_hint'),
              style: TextStyle(color: soft, fontSize: 12)),
          onChanged: (v) => setState(() => _local = s.copyWith(enabled: v)),
        ),
        SwitchListTile(
          value: s.showProgress,
          activeThumbColor: accent,
          title: Text(t('supports_show_progress'), style: TextStyle(color: text)),
          subtitle: Text(t('supports_show_progress_hint'),
              style: TextStyle(color: soft, fontSize: 12)),
          onChanged: (v) =>
              setState(() => _local = s.copyWith(showProgress: v)),
        ),
        SwitchListTile(
          value: s.showRemaining,
          activeThumbColor: accent,
          title:
              Text(t('supports_show_remaining'), style: TextStyle(color: text)),
          subtitle: Text(t('supports_show_remaining_hint'),
              style: TextStyle(color: soft, fontSize: 12)),
          onChanged: (v) =>
              setState(() => _local = s.copyWith(showRemaining: v)),
        ),
        SwitchListTile(
          value: s.cardSectionEnabled,
          activeThumbColor: accent,
          title:
              Text(t('supports_cards_enabled'), style: TextStyle(color: text)),
          subtitle: Text(t('supports_cards_enabled_hint'),
              style: TextStyle(color: soft, fontSize: 12)),
          onChanged: (v) =>
              setState(() => _local = s.copyWith(cardSectionEnabled: v)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: ['toman', 'usd', 'both'].contains(s.currencyMode)
              ? s.currencyMode
              : 'both',
          items: [
            DropdownMenuItem(
                value: 'both', child: Text(t('supports_currency_both'))),
            DropdownMenuItem(
                value: 'toman', child: Text(t('supports_currency_toman'))),
            DropdownMenuItem(
                value: 'usd', child: Text(t('supports_currency_usd'))),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _local = s.copyWith(currencyMode: v));
          },
          decoration: InputDecoration(
            labelText: t('supports_currency_mode'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(t('supports_settings_texts'),
            style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: _introFa,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: t('supports_intro_fa'),
            alignLabelWithHint: true,
            helperText: t('supports_intro_help'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _introEn,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: t('supports_intro_en'),
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _thanksFa,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('supports_thanks_fa'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _thanksEn,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('supports_thanks_en'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(t('supports_bank_cards'),
                  style: TextStyle(color: text, fontWeight: FontWeight.w800)),
            ),
            TextButton.icon(
              onPressed: _addCard,
              icon: Icon(Icons.add, color: accent),
              label: Text(t('add'), style: TextStyle(color: accent)),
            ),
          ],
        ),
        for (var i = 0; i < s.cards.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.cards[i].enabled,
                  activeThumbColor: accent,
                  title: Text(t('supports_card_enabled'),
                      style: TextStyle(color: text, fontSize: 13)),
                  onChanged: (v) {
                    final next = [..._collectCards()];
                    next[i] = next[i].copyWith(enabled: v);
                    _disposeCardCtrls();
                    for (final c in next) {
                      _holderCtrls
                          .add(TextEditingController(text: c.holderName));
                      _bankCtrls.add(TextEditingController(text: c.bankName));
                      _numberCtrls
                          .add(TextEditingController(text: c.cardNumber));
                    }
                    setState(() => _local = s.copyWith(cards: next));
                  },
                ),
                TextField(
                  controller: _holderCtrls[i],
                  decoration: InputDecoration(
                    labelText: t('supports_card_holder'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bankCtrls[i],
                  decoration: InputDecoration(
                    labelText: t('supports_card_bank'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _numberCtrls[i],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t('supports_card_number'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      final next = [..._collectCards()]..removeAt(i);
                      _disposeCardCtrls();
                      for (final c in next) {
                        _holderCtrls
                            .add(TextEditingController(text: c.holderName));
                        _bankCtrls
                            .add(TextEditingController(text: c.bankName));
                        _numberCtrls
                            .add(TextEditingController(text: c.cardNumber));
                      }
                      setState(() => _local = s.copyWith(cards: next));
                    },
                    icon: Icon(Icons.delete_outline,
                        color: AppTok.danger(context)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t('save_settings')),
          ),
        ),
      ],
    );
  }
}