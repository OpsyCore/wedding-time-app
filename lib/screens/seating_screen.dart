import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/table_model.dart';
import '../widgets/app_drawer.dart';
import '../widgets/wedding_time_header.dart';

/// view:
/// null        = overview
/// tableId     = seat guests
/// __add__     = add/edit table
/// __layout__  = hall map
/// __detail__  = table details
class SeatingScreen extends StatefulWidget {
  final String weddingId;
  const SeatingScreen({super.key, required this.weddingId});

  @override
  State<SeatingScreen> createState() => _SeatingScreenState();
}

class _SeatingScreenState extends State<SeatingScreen> {
  String? _view;
  TableModel? _editingTable;
  TableModel? _detailTable;
  String? _typeFilter;
  String? _activeHallId;
  bool _hallsReady = false;

  CollectionReference<Map<String, dynamic>> get tablesRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('tables');

  CollectionReference<Map<String, dynamic>> get hallsRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('halls');

  CollectionReference get guestsRef => FirebaseFirestore.instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('guests');

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  String fa(String input) {
    if (!AppLang.I.isFa) return input;
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _faDigits[i] : c;
    }).join();
  }

  @override
  void initState() {
    super.initState();
    _ensureDefaultHall();
  }

  Future<void> _ensureDefaultHall() async {
    try {
      final snap = await hallsRef.orderBy('order').get();
      if (snap.docs.isEmpty) {
        final doc = await hallsRef.add({
          'name': AppLang.tr('main_hall'),
          'order': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // میزهای قدیمی بدون hallId → سالن اصلی
        final tables = await tablesRef.get();
        final batch = FirebaseFirestore.instance.batch();
        for (final t in tables.docs) {
          final hid = (t.data()['hallId'] ?? '').toString();
          if (hid.isEmpty) {
            batch.update(t.reference, {'hallId': doc.id});
          }
        }
        await batch.commit();
        if (mounted) {
          setState(() {
            _activeHallId = doc.id;
            _hallsReady = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _activeHallId ??= snap.docs.first.id;
            _hallsReady = true;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _hallsReady = true);
    }
  }

  void _openOverview() => setState(() {
        _view = null;
        _editingTable = null;
        _detailTable = null;
      });

  void _openTable(TableModel t) => setState(() {
        _view = t.id;
        _editingTable = null;
        _detailTable = null;
      });

  void _openAdd({TableModel? table}) => setState(() {
        _view = '__add__';
        _editingTable = table;
        _detailTable = null;
      });

  void _openLayout() => setState(() {
        _view = '__layout__';
        _editingTable = null;
        _detailTable = null;
      });

  void _openDetail(TableModel t) => setState(() {
        _view = '__detail__';
        _detailTable = t;
        _editingTable = null;
      });

  Future<void> _addHall() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
        builder: (_, __) => Directionality(
          textDirection: AppLang.I.direction,
          child: AlertDialog(
            backgroundColor: AppTok.card(ctx),
            title: Text(
              AppLang.tr('new_hall'),
              style: TextStyle(color: AppTok.text(ctx)),
            ),
            content: TextField(
              controller: c,
              autofocus: true,
              style: TextStyle(color: AppTok.text(ctx)),
              decoration: InputDecoration(
                hintText: AppLang.tr('hall_name_hint'),
                hintStyle: TextStyle(color: AppTok.textSoft(ctx)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppLang.tr('cancel'),
                  style: TextStyle(color: AppTok.textSoft(ctx)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, c.text.trim()),
                child: Text(
                  AppLang.tr('add'),
                  style: TextStyle(color: AppTok.accent(ctx)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (name == null || name.isEmpty) return;
    final all = await hallsRef.get();
    final doc = await hallsRef.add({
      'name': name,
      'order': all.docs.length,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) setState(() => _activeHallId = doc.id);
  }

  Future<void> _renameHall(HallModel hall) async {
    final c = TextEditingController(text: hall.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
        builder: (_, __) => Directionality(
          textDirection: AppLang.I.direction,
          child: AlertDialog(
            backgroundColor: AppTok.card(ctx),
            title: Text(
              AppLang.tr('hall_name'),
              style: TextStyle(color: AppTok.text(ctx)),
            ),
            content: TextField(
              controller: c,
              style: TextStyle(color: AppTok.text(ctx)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppLang.tr('cancel'),
                  style: TextStyle(color: AppTok.textSoft(ctx)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, c.text.trim()),
                child: Text(
                  AppLang.tr('save'),
                  style: TextStyle(color: AppTok.accent(ctx)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (name == null || name.isEmpty) return;
    await hallsRef.doc(hall.id).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteHall(HallModel hall, List<HallModel> halls) async {
    if (halls.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('min_one_hall'))),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
        builder: (_, __) => Directionality(
          textDirection: AppLang.I.direction,
          child: AlertDialog(
            backgroundColor: AppTok.card(ctx),
            title: Text(
              AppLang.tr('delete_hall_title'),
              style: TextStyle(color: AppTok.text(ctx)),
            ),
            content: Text(
              AppLang.tr('delete_hall_body').replaceAll('{name}', hall.name),
              style: TextStyle(color: AppTok.textSoft(ctx)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppLang.tr('cancel'),
                  style: TextStyle(color: AppTok.textSoft(ctx)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  AppLang.tr('delete'),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;

    final fallback = halls.firstWhere((h) => h.id != hall.id);
    final tables = await tablesRef.where('hallId', isEqualTo: hall.id).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final t in tables.docs) {
      batch.update(t.reference, {'hallId': fallback.id});
    }
    batch.delete(hallsRef.doc(hall.id));
    await batch.commit();
    if (mounted && _activeHallId == hall.id) {
      setState(() => _activeHallId = fallback.id);
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
            drawer: AppDrawer(weddingId: widget.weddingId),
            body: SafeArea(
              child: !_hallsReady
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppTok.accent(context),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: hallsRef.orderBy('order').snapshots(),
                      builder: (context, hallSnap) {
                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: tablesRef.orderBy('order').snapshots(),
                          builder: (context, tableSnap) {
                            return StreamBuilder<QuerySnapshot>(
                              stream: guestsRef.snapshots(),
                              builder: (context, guestSnap) {
                                if (!tableSnap.hasData || !guestSnap.hasData) {
                                  return Column(
                                    children: [
                                      Builder(
                                        builder: (context) =>
                                            WeddingTimeHeader(
                                          weddingId: widget.weddingId,
                                          onMenuPressed: () => Scaffold.of(
                                            context,
                                          ).openDrawer(),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppTok.accent(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final halls = (hallSnap.data?.docs ?? [])
                                    .map(HallModel.fromDoc)
                                    .toList();
                                if (halls.isNotEmpty &&
                                    (_activeHallId == null ||
                                        !halls.any(
                                          (h) => h.id == _activeHallId,
                                        ))) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(
                                        () => _activeHallId = halls.first.id,
                                      );
                                    }
                                  });
                                }

                                final activeHallId = _activeHallId ??
                                    (halls.isNotEmpty ? halls.first.id : '');

                                final allTables = tableSnap.data!.docs
                                    .map(TableModel.fromDoc)
                                    .toList();

                                final tables = allTables.where((t) {
                                  if (activeHallId.isEmpty) return true;
                                  if (t.hallId.isEmpty) {
                                    return halls.isEmpty ||
                                        t.hallId == activeHallId ||
                                        halls.first.id == activeHallId;
                                  }
                                  return t.hallId == activeHallId;
                                }).toList();

                                final guestMap =
                                    <String, Map<String, dynamic>>{};
                                for (final g in guestSnap.data!.docs) {
                                  guestMap[g.id] = {
                                    ...Map<String, dynamic>.from(
                                      g.data() as Map,
                                    ),
                                    'id': g.id,
                                  };
                                }

                                if (_view == '__add__') {
                                  return _AddTableView(
                                    tablesRef: tablesRef,
                                    existingCount: allTables.length,
                                    hallId: activeHallId,
                                    editing: _editingTable,
                                    onBack: _openOverview,
                                    onSaved: (_) => _openOverview(),
                                    fa: fa,
                                  );
                                }

                                if (_view == '__layout__') {
                                  return _HallLayoutView(
                                    halls: halls,
                                    activeHallId: activeHallId,
                                    onSelectHall: (id) =>
                                        setState(() => _activeHallId = id),
                                    onAddHall: _addHall,
                                    onRenameHall: (h) => _renameHall(h),
                                    onDeleteHall: (h) =>
                                        _deleteHall(h, halls),
                                    tables: tables,
                                    tablesRef: tablesRef,
                                    onBack: _openOverview,
                                    onOpenTable: _openTable,
                                    onAdd: () => _openAdd(),
                                    fa: fa,
                                  );
                                }

                                if (_view == '__detail__' &&
                                    _detailTable != null) {
                                  final live = allTables
                                      .where((t) => t.id == _detailTable!.id);
                                  final table = live.isNotEmpty
                                      ? live.first
                                      : _detailTable!;
                                  return _TableInfoView(
                                    table: table,
                                    tablesRef: tablesRef,
                                    onBack: _openOverview,
                                    onManageGuests: () => _openTable(table),
                                    onEdit: () => _openAdd(table: table),
                                    fa: fa,
                                  );
                                }

                                if (_view != null) {
                                  final found =
                                      allTables.where((t) => t.id == _view);
                                  if (found.isEmpty) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback(
                                      (_) => _openOverview(),
                                    );
                                    return const SizedBox();
                                  }
                                  return _TableSeatsView(
                                    table: found.first,
                                    tablesRef: tablesRef,
                                    allTables: allTables,
                                    guestMap: guestMap,
                                    onBack: _openOverview,
                                    onEdit: () =>
                                        _openAdd(table: found.first),
                                    onDetails: () =>
                                        _openDetail(found.first),
                                    fa: fa,
                                  );
                                }

                                return _OverviewView(
                                  weddingId: widget.weddingId,
                                  halls: halls,
                                  activeHallId: activeHallId,
                                  onSelectHall: (id) =>
                                      setState(() => _activeHallId = id),
                                  onAddHall: _addHall,
                                  onRenameHall: _renameHall,
                                  onDeleteHall: (h) =>
                                      _deleteHall(h, halls),
                                  tables: tables,
                                  guestMap: guestMap,
                                  typeFilter: _typeFilter,
                                  onTypeFilter: (v) =>
                                      setState(() => _typeFilter = v),
                                  onOpenTable: _openTable,
                                  onOpenDetail: _openDetail,
                                  onAddTable: () => _openAdd(),
                                  onOpenLayout: _openLayout,
                                  fa: fa,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════
// شکل میز — مستطیل واقعاً کشیده
// ═══════════════════════════════════════

class TableShape extends StatelessWidget {
  final String type;
  final double size;
  final bool selected;
  final Widget child;
  final VoidCallback? onTap;
  final bool isVip;
  final bool expand;

  const TableShape({
    super.key,
    required this.type,
    required this.child,
    this.size = 96,
    this.selected = false,
    this.onTap,
    this.isVip = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected || isVip
        ? AppTok.accent(context)
        : AppTok.accent(context).withValues(alpha: 0.55);

    final dims = TableModel.layoutSize(type, base: size);
    final w = expand ? double.infinity : dims.w;
    final h = expand ? double.infinity : dims.h;

    late Decoration decoration;
    switch (type) {
      case 'square':
        decoration = BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.6),
        );
        break;
      case 'rect':
        decoration = BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.6),
        );
        break;
      case 'round':
      default:
        decoration = BoxDecoration(
          color: AppTok.card(context),
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.6),
        );
    }

    final shapeChild = Container(
      width: w,
      height: h,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Center(child: child),
          if (isVip)
            Positioned(
              top: 5,
              left: 0,
              right: 0,
              child: Icon(
                Icons.star,
                color: AppTok.accent(context),
                size: 12,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return shapeChild;
    return GestureDetector(onTap: onTap, child: shapeChild);
  }
}

IconData tableTypeIcon(String type) {
  switch (type) {
    case 'square':
      return Icons.crop_square;
    case 'rect':
      return Icons.rectangle_outlined;
    case 'round':
    default:
      return Icons.circle_outlined;
  }
}

String tableTypeLabel(String type) {
  switch (type) {
    case 'square':
      return AppLang.tr('table_square');
    case 'rect':
      return AppLang.tr('table_rect');
    case 'round':
    default:
      return AppLang.tr('table_round');
  }
}

// ═══════════════════════════════════════
// انتخاب سالن
// ═══════════════════════════════════════

class _HallSelector extends StatelessWidget {
  final List<HallModel> halls;
  final String activeHallId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final void Function(HallModel) onRename;
  final void Function(HallModel) onDelete;

  const _HallSelector({
    required this.halls,
    required this.activeHallId,
    required this.onSelect,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = halls.where((h) => h.id == activeHallId);
    final title = active.isEmpty ? AppLang.tr('hall') : active.first.name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: PopupMenuButton<String>(
              color: AppTok.card(context),
              onSelected: (v) {
                if (v == '__add__') {
                  onAdd();
                } else {
                  onSelect(v);
                }
              },
              itemBuilder: (_) => [
                ...halls.map(
                  (h) => PopupMenuItem(
                    value: h.id,
                    child: Row(
                      children: [
                        Icon(
                          h.id == activeHallId
                              ? Icons.check_circle
                              : Icons.meeting_room_outlined,
                          size: 18,
                          color: h.id == activeHallId
                              ? AppTok.accent(context)
                              : AppTok.textSoft(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            h.name,
                            style: TextStyle(color: AppTok.text(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: '__add__',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: AppTok.accent(context),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLang.tr('new_hall'),
                        style: TextStyle(color: AppTok.accent(context)),
                      ),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.apartment_outlined,
                      color: AppTok.accent(context),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppTok.text(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTok.textSoft(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (active.isNotEmpty) ...[
            IconButton(
              tooltip: AppLang.tr('rename'),
              onPressed: () => onRename(active.first),
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppTok.textSoft(context),
              ),
            ),
            IconButton(
              tooltip: AppLang.tr('delete_hall'),
              onPressed: () => onDelete(active.first),
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: AppTok.textSoft(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// A — نمای کلی
// ═══════════════════════════════════════

class _OverviewView extends StatelessWidget {
  final String weddingId;
  final List<HallModel> halls;
  final String activeHallId;
  final ValueChanged<String> onSelectHall;
  final VoidCallback onAddHall;
  final void Function(HallModel) onRenameHall;
  final void Function(HallModel) onDeleteHall;
  final List<TableModel> tables;
  final Map<String, Map<String, dynamic>> guestMap;
  final String? typeFilter;
  final ValueChanged<String?> onTypeFilter;
  final void Function(TableModel) onOpenTable;
  final void Function(TableModel) onOpenDetail;
  final VoidCallback onAddTable;
  final VoidCallback onOpenLayout;
  final String Function(String) fa;

  const _OverviewView({
    required this.weddingId,
    required this.halls,
    required this.activeHallId,
    required this.onSelectHall,
    required this.onAddHall,
    required this.onRenameHall,
    required this.onDeleteHall,
    required this.tables,
    required this.guestMap,
    required this.typeFilter,
    required this.onTypeFilter,
    required this.onOpenTable,
    required this.onOpenDetail,
    required this.onAddTable,
    required this.onOpenLayout,
    required this.fa,
  });

  int get totalGuests => guestMap.length;

  int get seatedGuests {
    final seated = <String>{};
    for (final t in tables) {
      seated.addAll(t.guestIds);
    }
    return seated.length;
  }

  int get withoutTable => (totalGuests - seatedGuests).clamp(0, 1 << 30);

  List<TableModel> get visibleTables {
    if (typeFilter == null) return tables;
    return tables.where((t) => t.type == typeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Builder(
          builder: (context) => WeddingTimeHeader(
            weddingId: weddingId,
            onMenuPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: onOpenLayout,
                icon: Icon(Icons.map_outlined, color: AppTok.accent(context)),
                tooltip: AppLang.tr('hall_layout'),
              ),
              Expanded(
                child: Text(
                  AppLang.tr('table_layout_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onAddTable,
                icon: Icon(Icons.add, color: AppTok.text(context)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _HallSelector(
                halls: halls,
                activeHallId: activeHallId,
                onSelect: onSelectHall,
                onAdd: onAddHall,
                onRename: onRenameHall,
                onDelete: onDeleteHall,
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppLang.tr('table_type'),
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _typeChip(
                    context,
                    null,
                    AppLang.tr('all'),
                    Icons.grid_view_rounded,
                  ),
                  const SizedBox(width: 8),
                  _typeChip(
                    context,
                    'round',
                    AppLang.tr('table_round'),
                    Icons.circle_outlined,
                  ),
                  const SizedBox(width: 8),
                  _typeChip(
                    context,
                    'square',
                    AppLang.tr('table_square'),
                    Icons.crop_square,
                  ),
                  const SizedBox(width: 8),
                  _typeChip(
                    context,
                    'rect',
                    AppLang.tr('table_rect'),
                    Icons.rectangle_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _statBox(
                      context,
                      AppLang.tr('total_guests'),
                      fa(totalGuests.toString()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statBox(
                      context,
                      AppLang.tr('without_table'),
                      fa(withoutTable.toString()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLang.tr('tables_in_hall')} (${fa(visibleTables.length.toString())})',
                    style: TextStyle(
                      color: AppTok.text(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenLayout,
                    child: Text(
                      AppLang.tr('hall_map'),
                      style: TextStyle(
                        color: AppTok.accent(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  ...visibleTables.map((t) => _tableTile(context, t)),
                  _addTile(context),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typeChip(
    BuildContext context,
    String? value,
    String label,
    IconData icon,
  ) {
    final selected = typeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppTok.accent(context)
                  : AppTok.border(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? AppTok.accent(context)
                    : AppTok.textSoft(context),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? AppTok.accent(context)
                      : AppTok.textSoft(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTok.text(context),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableTile(BuildContext context, TableModel t) {
    final label = t.name.trim().isNotEmpty
        ? t.name
        : '${AppLang.tr('table_n')}${fa((t.order + 1).toString())}';
    final cap =
        '${fa(t.seatedCount.toString())}/${fa(t.capacity.toString())}';
    final dims = TableModel.layoutSize(t.type, base: 88);

    return SizedBox(
      width: dims.w,
      height: dims.h + 4,
      child: TableShape(
        type: t.type,
        size: 88,
        isVip: t.isVip,
        onTap: () => onOpenTable(t),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                cap,
                style: TextStyle(
                  color: AppTok.accent(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addTile(BuildContext context) {
    return GestureDetector(
      onTap: onAddTable,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTok.card(context),
          border: Border.all(color: AppTok.border(context), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppTok.textSoft(context)),
            const SizedBox(height: 4),
            Text(
              AppLang.tr('new_table'),
              style: TextStyle(
                color: AppTok.textSoft(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// B — مهمانان میز
// ═══════════════════════════════════════

class _TableSeatsView extends StatefulWidget {
  final TableModel table;
  final CollectionReference tablesRef;
  final List<TableModel> allTables;
  final Map<String, Map<String, dynamic>> guestMap;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDetails;
  final String Function(String) fa;

  const _TableSeatsView({
    required this.table,
    required this.tablesRef,
    required this.allTables,
    required this.guestMap,
    required this.onBack,
    required this.onEdit,
    required this.onDetails,
    required this.fa,
  });

  @override
  State<_TableSeatsView> createState() => _TableSeatsViewState();
}

class _TableSeatsViewState extends State<_TableSeatsView> {
  late List<String> _guestIds;
  final _searchC = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _guestIds = List<String>.from(widget.table.guestIds);
  }

  @override
  void didUpdateWidget(covariant _TableSeatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table.id != widget.table.id) {
      _guestIds = List<String>.from(widget.table.guestIds);
    }
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _availableGuests {
    final elsewhere = <String>{};
    for (final t in widget.allTables) {
      if (t.id == widget.table.id) continue;
      elsewhere.addAll(t.guestIds);
    }
    return widget.guestMap.values.where((g) {
      final id = g['id'] as String;
      if (_guestIds.contains(id)) return false;
      if (elsewhere.contains(id)) return false;
      return true;
    }).toList();
  }

  /// نام‌های نمایشی برای پنل مهمان بدون لاگین (GuestSeatingTab)
  List<String> _namesForIds(List<String> ids) {
    final names = <String>[];
    for (final id in ids) {
      final n = widget.guestMap[id]?['name']?.toString().trim() ?? '';
      if (n.isNotEmpty) names.add(n);
    }
    return names;
  }

  Future<void> _save() async {
    if (widget.table.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('table_locked'))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final names = _namesForIds(_guestIds);
      await widget.tablesRef.doc(widget.table.id).update({
        'guestIds': _guestIds,
        'guestNames': names,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLang.tr('changes_saved'))),
        );
        widget.onBack();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.table.name.trim().isEmpty
        ? '${AppLang.tr('table_n')}${widget.fa((widget.table.order + 1).toString())}'
        : widget.table.displayName;
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;

    final search = _searchC.text.trim().toLowerCase();
    final available = _availableGuests.where((g) {
      if (search.isEmpty) return true;
      return (g['name'] ?? '').toString().toLowerCase().contains(search);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(
                  AppLang.I.isFa ? Icons.arrow_forward : Icons.arrow_back,
                  color: AppTok.text(context),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                color: AppTok.card(context),
                icon: Icon(Icons.more_vert, color: AppTok.textSoft(context)),
                onSelected: (v) async {
                  if (v == 'details') widget.onDetails();
                  if (v == 'edit') widget.onEdit();
                  if (v == 'delete') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTok.card(ctx),
                        title: Text(
                          AppLang.tr('delete_table'),
                          style: TextStyle(color: AppTok.text(ctx)),
                        ),
                        content: Text(
                          AppLang.tr('delete_table_confirm'),
                          style: TextStyle(color: AppTok.textSoft(ctx)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              AppLang.tr('cancel'),
                              style: TextStyle(color: AppTok.textSoft(ctx)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              AppLang.tr('delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await widget.tablesRef.doc(widget.table.id).delete();
                      widget.onBack();
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'details',
                    child: Text(
                      AppLang.tr('table_details'),
                      style: TextStyle(color: AppTok.text(context)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      AppLang.tr('edit_table'),
                      style: TextStyle(color: AppTok.text(context)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      AppLang.tr('delete_table'),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppTok.card(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      AppLang.tr('table_capacity'),
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TableShape(
                          type: widget.table.type,
                          size: 36,
                          child: Icon(
                            tableTypeIcon(widget.table.type),
                            color: AppTok.accent(context),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.fa(_guestIds.length.toString())}/${widget.fa(widget.table.capacity.toString())}',
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppLang.tr('guests_at_table'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              if (_guestIds.isEmpty)
                Text(
                  AppLang.tr('no_guests_at_table'),
                  style: TextStyle(color: AppTok.textSoft(context)),
                )
              else
                ..._guestIds.asMap().entries.map((e) {
                  final id = e.value;
                  final name = widget.guestMap[id]?['name']?.toString() ??
                      AppLang.tr('deleted_guest');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTok.card(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTok.accent(context)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            widget.fa((e.key + 1).toString()),
                            style: TextStyle(
                              color: AppTok.accent(context),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _guestIds.remove(id)),
                          child: Icon(
                            Icons.close,
                            color: AppTok.textSoft(context),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 18),
              Text(
                AppLang.tr('add_guest'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTok.card(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchC,
                  style: TextStyle(color: AppTok.text(context)),
                  decoration: InputDecoration(
                    hintText: AppLang.tr('search_guest_hint'),
                    hintStyle: TextStyle(color: AppTok.textSoft(context)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppTok.textSoft(context),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 8),
              ...available.map((g) {
                final id = g['id'] as String;
                final name = (g['name'] ?? '').toString();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    name,
                    style: TextStyle(
                      color: AppTok.text(context),
                      fontSize: 14,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      if (_guestIds.length >= widget.table.capacity) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLang.tr('table_full'))),
                        );
                        return;
                      }
                      setState(() => _guestIds.add(id));
                    },
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppTok.accent(context),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTok.accent(context),
                    foregroundColor: onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: onAccent,
                          ),
                        )
                      : Text(
                          AppLang.tr('save_changes'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════
// C — افزودن / ویرایش میز
// ═══════════════════════════════════════

class _AddTableView extends StatefulWidget {
  final CollectionReference tablesRef;
  final int existingCount;
  final String hallId;
  final TableModel? editing;
  final VoidCallback onBack;
  final void Function(String? id) onSaved;
  final String Function(String) fa;

  const _AddTableView({
    required this.tablesRef,
    required this.existingCount,
    required this.hallId,
    required this.editing,
    required this.onBack,
    required this.onSaved,
    required this.fa,
  });

  @override
  State<_AddTableView> createState() => _AddTableViewState();
}

class _AddTableViewState extends State<_AddTableView> {
  late String _type;
  late int _capacity;
  late TextEditingController _nameC;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.editing?.type ?? 'round';
    _capacity = widget.editing?.capacity ?? 8;
    _nameC = TextEditingController(text: widget.editing?.name ?? '');
  }

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (widget.editing == null) {
        final col = widget.existingCount % 3;
        final row = widget.existingCount ~/ 3;
        final doc = await widget.tablesRef.add({
          'name': _nameC.text.trim(),
          'type': _type,
          'capacity': _capacity,
          'order': widget.existingCount,
          'guestIds': <String>[],
          'guestNames': <String>[],
          'isVip': false,
          'isLocked': false,
          'isFamily': false,
          'hallId': widget.hallId,
          'posX': 0.18 + col * 0.28,
          'posY': 0.18 + row * 0.22,
          'createdAt': FieldValue.serverTimestamp(),
        });
        widget.onSaved(doc.id);
      } else {
        await widget.tablesRef.doc(widget.editing!.id).update({
          'name': _nameC.text.trim(),
          'type': _type,
          'capacity': _capacity,
        });
        widget.onSaved(widget.editing!.id);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(
                  AppLang.I.isFa ? Icons.arrow_forward : Icons.arrow_back,
                  color: AppTok.text(context),
                ),
              ),
              Expanded(
                child: Text(
                  isEdit
                      ? AppLang.tr('edit_table')
                      : AppLang.tr('add_new_table'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Text(
                AppLang.tr('choose_table_type'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: TableShape(
                  type: _type,
                  size: 100,
                  selected: true,
                  child: Text(
                    widget.fa(_capacity.toString()),
                    style: TextStyle(
                      color: AppTok.accent(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _type == 'rect'
                    ? AppLang.tr('rect_wider_hint')
                    : tableTypeLabel(_type),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _typeCard(
                      'round',
                      AppLang.tr('table_round'),
                      Icons.circle_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeCard(
                      'square',
                      AppLang.tr('table_square'),
                      Icons.crop_square,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeCard(
                      'rect',
                      AppLang.tr('table_rect'),
                      Icons.rectangle_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                AppLang.tr('table_capacity'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTok.card(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _step(Icons.remove, () {
                      if (_capacity > 1) setState(() => _capacity--);
                    }),
                    Text(
                      widget.fa(_capacity.toString()),
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _step(Icons.add, () {
                      if (_capacity < 30) setState(() => _capacity++);
                    }, filled: true),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                AppLang.tr('table_name_optional'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameC,
                style: TextStyle(color: AppTok.text(context)),
                decoration: InputDecoration(
                  hintText: AppLang.tr('table_name_example'),
                  hintStyle: TextStyle(color: AppTok.textSoft(context)),
                  filled: true,
                  fillColor: AppTok.card(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTok.accent(context),
                    foregroundColor: onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: onAccent,
                          ),
                        )
                      : Text(
                          isEdit
                              ? AppLang.tr('save_changes')
                              : AppLang.tr('add_table'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typeCard(String type, String label, IconData icon) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTok.accent(context)
                : AppTok.border(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            TableShape(
              type: type,
              size: 34,
              selected: selected,
              child: const SizedBox(),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppTok.accent(context)
                    : AppTok.textSoft(context),
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(IconData icon, VoidCallback onTap, {bool filled = false}) {
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: filled ? AppTok.accent(context) : AppTok.background(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: filled ? onAccent : AppTok.textSoft(context),
          size: 20,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// D — نقشه سالن (درگ نرم + چند سالن)
// ═══════════════════════════════════════

class _HallLayoutView extends StatelessWidget {
  final List<HallModel> halls;
  final String activeHallId;
  final ValueChanged<String> onSelectHall;
  final VoidCallback onAddHall;
  final void Function(HallModel) onRenameHall;
  final void Function(HallModel) onDeleteHall;
  final List<TableModel> tables;
  final CollectionReference tablesRef;
  final VoidCallback onBack;
  final void Function(TableModel) onOpenTable;
  final VoidCallback onAdd;
  final String Function(String) fa;

  const _HallLayoutView({
    required this.halls,
    required this.activeHallId,
    required this.onSelectHall,
    required this.onAddHall,
    required this.onRenameHall,
    required this.onDeleteHall,
    required this.tables,
    required this.tablesRef,
    required this.onBack,
    required this.onOpenTable,
    required this.onAdd,
    required this.fa,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTok.isDark(context);
    final onAccent = dark ? AppDarkPalette.background : Colors.white;
    // تختهٔ نقشه: در dark همان بنفش دودی؛ در light کارت نرم
    final boardColor =
        dark ? const Color(0xFF1A1824) : AppTok.cardSoft(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(
                  AppLang.I.isFa ? Icons.arrow_forward : Icons.arrow_back,
                  color: AppTok.text(context),
                ),
              ),
              Expanded(
                child: Text(
                  AppLang.tr('hall_layout'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: AppLang.tr('new_table'),
                onPressed: onAdd,
                icon: Icon(Icons.add, color: AppTok.accent(context)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _HallSelector(
            halls: halls,
            activeHallId: activeHallId,
            onSelect: onSelectHall,
            onAdd: onAddHall,
            onRename: onRenameHall,
            onDelete: onDeleteHall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: Text(
            AppLang.tr('drag_hint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTok.textSoft(context).withValues(alpha: 0.9),
              fontSize: 11.5,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardW = constraints.maxWidth - 32;
              final boardH = constraints.maxHeight - 8;
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                width: boardW,
                height: boardH,
                decoration: BoxDecoration(
                  color: boardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTok.border(context)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GridPainter(
                            lineColor: dark
                                ? Colors.white.withValues(alpha: 0.04)
                                : AppTok.border(context)
                                    .withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      if (tables.isEmpty)
                        Center(
                          child: Text(
                            AppLang.tr('no_tables_in_hall'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTok.textSoft(context),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ...tables.map((t) {
                        final dims =
                            TableModel.layoutSize(t.type, base: 78);
                        return _FreeDragTable(
                          key: ValueKey(t.id),
                          table: t,
                          boardW: boardW,
                          boardH: boardH,
                          width: dims.w,
                          height: dims.h,
                          fa: fa,
                          onTap: () => onOpenTable(t),
                          onMoved: (nx, ny) async {
                            await tablesRef.doc(t.id).update({
                              'posX': nx,
                              'posY': ny,
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTok.text(context),
                    side: BorderSide(color: AppTok.border(context)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(AppLang.tr('table_list')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(AppLang.tr('add_table')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTok.accent(context),
                    foregroundColor: onAccent,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color lineColor;

  _GridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

/// درگ با pointer delta — دقیق و بدون warning
class _FreeDragTable extends StatefulWidget {
  final TableModel table;
  final double boardW;
  final double boardH;
  final double width;
  final double height;
  final String Function(String) fa;
  final VoidCallback onTap;
  final Future<void> Function(double nx, double ny) onMoved;

  const _FreeDragTable({
    super.key,
    required this.table,
    required this.boardW,
    required this.boardH,
    required this.width,
    required this.height,
    required this.fa,
    required this.onTap,
    required this.onMoved,
  });

  @override
  State<_FreeDragTable> createState() => _FreeDragTableState();
}

class _FreeDragTableState extends State<_FreeDragTable> {
  late double _x;
  late double _y;
  bool _dragging = false;

  double get _maxX =>
      (widget.boardW - widget.width).clamp(0.0, widget.boardW);

  double get _maxY =>
      (widget.boardH - widget.height).clamp(0.0, widget.boardH);

  @override
  void initState() {
    super.initState();
    _syncFromModel();
  }

  @override
  void didUpdateWidget(covariant _FreeDragTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging &&
        (oldWidget.table.posX != widget.table.posX ||
            oldWidget.table.posY != widget.table.posY ||
            oldWidget.boardW != widget.boardW ||
            oldWidget.boardH != widget.boardH ||
            oldWidget.width != widget.width ||
            oldWidget.height != widget.height)) {
      _syncFromModel();
    }
  }

  void _syncFromModel() {
    _x = (widget.table.posX * _maxX).clamp(0.0, _maxX);
    _y = (widget.table.posY * _maxY).clamp(0.0, _maxY);
  }

  Future<void> _persist() async {
    final nx = _maxX <= 0 ? 0.0 : (_x / _maxX).clamp(0.0, 1.0);
    final ny = _maxY <= 0 ? 0.0 : (_y / _maxY).clamp(0.0, 1.0);
    await widget.onMoved(nx, ny);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.table;
    final label = t.name.trim().isNotEmpty
        ? t.name
        : '${AppLang.tr('table_n')}${widget.fa((t.order + 1).toString())}';
    final cap =
        '${widget.fa(t.seatedCount.toString())}/${widget.fa(t.capacity.toString())}';

    return Positioned(
      left: _x,
      top: _y,
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onTap: _dragging ? null : widget.onTap,
        onPanStart: (_) {
          setState(() => _dragging = true);
        },
        onPanUpdate: (details) {
          setState(() {
            _x = (_x + details.delta.dx).clamp(0.0, _maxX);
            _y = (_y + details.delta.dy).clamp(0.0, _maxY);
          });
        },
        onPanEnd: (_) async {
          setState(() => _dragging = false);
          await _persist();
        },
        onPanCancel: () {
          setState(() => _dragging = false);
        },
        child: AnimatedScale(
          scale: _dragging ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: TableShape(
            type: t.type,
            size: 78,
            isVip: t.isVip,
            selected: _dragging,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTok.text(context),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cap,
                    style: TextStyle(
                      color: AppTok.accent(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// E — جزئیات میز
// ═══════════════════════════════════════

class _TableInfoView extends StatelessWidget {
  final TableModel table;
  final CollectionReference tablesRef;
  final VoidCallback onBack;
  final VoidCallback onManageGuests;
  final VoidCallback onEdit;
  final String Function(String) fa;

  const _TableInfoView({
    required this.table,
    required this.tablesRef,
    required this.onBack,
    required this.onManageGuests,
    required this.onEdit,
    required this.fa,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (table.fillPercent * 100).toInt();
    final empty =
        (table.capacity - table.seatedCount).clamp(0, table.capacity);
    final title = table.name.trim().isEmpty
        ? '${AppLang.tr('table_details_n')}${fa((table.order + 1).toString())}'
        : '${AppLang.tr('table_details_named')}${table.displayName}';
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(
                  AppLang.I.isFa ? Icons.arrow_forward : Icons.arrow_back,
                  color: AppTok.text(context),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppTok.textSoft(context),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: TableShape(
                  type: table.type,
                  size: 110,
                  isVip: table.isVip,
                  selected: true,
                  child: Text(
                    '${fa(percent.toString())}%',
                    style: TextStyle(
                      color: AppTok.accent(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _infoRow(
                context,
                AppLang.tr('total_capacity'),
                '${fa(table.capacity.toString())}${AppLang.tr('people_suffix')}',
              ),
              _infoRow(
                context,
                AppLang.tr('guest_count'),
                '${fa(table.seatedCount.toString())}${AppLang.tr('people_suffix')}',
              ),
              _infoRow(
                context,
                AppLang.tr('empty_seats'),
                '${fa(empty.toString())}${AppLang.tr('people_suffix')}',
              ),
              _infoRow(
                context,
                AppLang.tr('table_type'),
                tableTypeLabel(table.type),
              ),
              const SizedBox(height: 18),
              _toggleTile(
                context: context,
                title: AppLang.tr('vip_table'),
                icon: Icons.star,
                value: table.isVip,
                onChanged: (v) =>
                    tablesRef.doc(table.id).update({'isVip': v}),
              ),
              _toggleTile(
                context: context,
                title: AppLang.tr('locked_table'),
                icon: Icons.lock_outline,
                value: table.isLocked,
                onChanged: (v) =>
                    tablesRef.doc(table.id).update({'isLocked': v}),
              ),
              _toggleTile(
                context: context,
                title: AppLang.tr('family_table'),
                icon: Icons.groups_outlined,
                value: table.isFamily,
                onChanged: (v) =>
                    tablesRef.doc(table.id).update({'isFamily': v}),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTok.accent(context),
                    foregroundColor: onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onManageGuests,
                  child: Text(
                    AppLang.tr('manage_table_guests'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTok.card(ctx),
                        title: Text(
                          AppLang.tr('delete_table'),
                          style: TextStyle(color: AppTok.text(ctx)),
                        ),
                        content: Text(
                          AppLang.tr('delete_table_q'),
                          style: TextStyle(color: AppTok.textSoft(ctx)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              AppLang.tr('cancel'),
                              style: TextStyle(color: AppTok.textSoft(ctx)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              AppLang.tr('delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await tablesRef.doc(table.id).delete();
                      onBack();
                    }
                  },
                  child: Text(AppLang.tr('delete_table')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(color: AppTok.textSoft(context), fontSize: 13),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: AppTok.text(context),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTok.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          secondary: Icon(icon, color: AppTok.accent(context)),
          title: Text(
            title,
            style: TextStyle(color: AppTok.text(context)),
          ),
          value: value,
          activeThumbColor: AppTok.accent(context),
          activeTrackColor: AppTok.accent(context).withValues(alpha: 0.45),
          onChanged: onChanged,
        ),
      ),
    );
  }
}