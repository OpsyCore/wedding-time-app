import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../core/app_theme_controller.dart';
import '../../models/table_model.dart';
import '../../services/guest_local_store.dart';

/// چیدمان مهمان — فقط مشاهده + پیدا کردن میز من
class GuestSeatingTab extends StatefulWidget {
  const GuestSeatingTab({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<GuestSeatingTab> createState() => _GuestSeatingTabState();
}

class _GuestSeatingTabState extends State<GuestSeatingTab> {
  String? _activeHallId;
  bool _listMode = false;
  final _nameC = TextEditingController();
  String _query = '';
  String? _highlightTableId;

  CollectionReference<Map<String, dynamic>> get _tablesRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('tables');

  CollectionReference<Map<String, dynamic>> get _hallsRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('halls');

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  Future<void> _loadSavedName() async {
    final n = await GuestLocalStore.loadDisplayName(widget.weddingId);
    if (!mounted) return;
    if ((n ?? '').trim().isNotEmpty) {
      _nameC.text = n!.trim();
      setState(() => _query = n.trim());
    }
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  String _fa(String input) {
    if (!AppLang.I.isFa) return input;
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _faDigits[i] : c;
    }).join();
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'square':
        return _t('table_square', 'مربع', 'Square');
      case 'rect':
        return _t('table_rect', 'مستطیل', 'Rectangle');
      case 'round':
      default:
        return _t('table_round', 'گرد', 'Round');
    }
  }

  IconData _typeIcon(String type) {
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

  String _tableLabel(TableModel t) {
    if (t.name.trim().isNotEmpty) return t.name.trim();
    return '${_t('table_n', 'میز ', 'Table ')}${_fa((t.order + 1).toString())}';
  }

  List<TableModel> _tablesForHall(
    List<TableModel> all,
    List<HallModel> halls,
    String activeHallId,
  ) {
    if (activeHallId.isEmpty) return all;
    return all.where((t) {
      if (t.hallId.isEmpty) {
        return halls.isEmpty || halls.first.id == activeHallId;
      }
      return t.hallId == activeHallId;
    }).toList();
  }

  bool _nameMatchesTable(TableModel t, String rawName) {
    final q = GuestLocalStore.normalizeName(rawName);
    if (q.isEmpty) return false;
    for (final n in t.guestNames) {
      final nn = GuestLocalStore.normalizeName(n);
      if (nn.isEmpty) continue;
      if (nn == q || nn.contains(q) || q.contains(nn)) return true;
    }
    return false;
  }

  TableModel? _findMyTable(List<TableModel> tables) {
    final q = _query.trim();
    if (q.isEmpty) return null;
    final nq = GuestLocalStore.normalizeName(q);
    for (final t in tables) {
      for (final n in t.guestNames) {
        if (GuestLocalStore.normalizeName(n) == nq) return t;
      }
    }
    for (final t in tables) {
      if (_nameMatchesTable(t, q)) return t;
    }
    return null;
  }

  Future<void> _applyFind(List<TableModel> allTables) async {
    final name = _nameC.text.trim();
    setState(() {
      _query = name;
      _highlightTableId = null;
    });
    if (name.isEmpty) return;

    await GuestLocalStore.saveDisplayName(
      weddingId: widget.weddingId,
      name: name,
    );

    final mine = _findMyTable(allTables);
    if (!mounted) return;
    if (mine == null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: AppLang.I.direction,
          child: AlertDialog(
            backgroundColor: AppTok.card(ctx),
            title: Text(
              _t('seat_not_found_title', 'میز پیدا نشد', 'Seat not found'),
              style: TextStyle(color: AppTok.text(ctx)),
            ),
            content: Text(
              _t(
                'seat_not_found_body',
                'هنوز میزی با این نام ثبت نشده. از عروس/داماد بپرسید یا همان نام لیست مهمانان را بنویسید.',
                'No table is assigned to this name yet. Ask the couple or use the exact guest list name.',
              ),
              style: TextStyle(color: AppTok.textSoft(ctx), height: 1.45),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  _t('ok', 'باشه', 'OK'),
                  style: TextStyle(color: AppTok.accent(ctx)),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() {
      _highlightTableId = mine.id;
      if (mine.hallId.isNotEmpty) _activeHallId = mine.hallId;
      _listMode = false;
    });
    _showTableInfo(mine, isMine: true);
  }

  void _showTableInfo(TableModel t, {bool isMine = false}) {
    final label = _tableLabel(t);
    final empty = (t.capacity - t.seatedCount).clamp(0, t.capacity);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTok.border(ctx),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isMine)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTok.accent(ctx).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _t('your_table', 'میز شما', 'Your table'),
                        style: TextStyle(
                          color: AppTok.accent(ctx),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  _GuestTableShape(
                    type: t.type,
                    size: 88,
                    isVip: t.isVip,
                    highlight: isMine,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTok.text(ctx),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_fa(t.seatedCount.toString())}/${_fa(t.capacity.toString())}',
                            style: TextStyle(
                              color: AppTok.accent(ctx),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTok.text(ctx),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(
                      'seating_readonly_hint',
                      'فقط مشاهده — بدون تغییر',
                      'View only — no changes',
                    ),
                    style: TextStyle(
                      color: AppTok.textSoft(ctx),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow(
                    ctx,
                    _t('table_type', 'نوع میز', 'Type'),
                    _typeLabel(t.type),
                    _typeIcon(t.type),
                  ),
                  _infoRow(
                    ctx,
                    _t('table_capacity', 'ظرفیت', 'Capacity'),
                    _fa(t.capacity.toString()),
                    Icons.event_seat_outlined,
                  ),
                  _infoRow(
                    ctx,
                    _t('empty_seats', 'صندلی خالی', 'Empty'),
                    _fa(empty.toString()),
                    Icons.chair_outlined,
                  ),
                  if (t.guestNames.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _t('guests_at_table', 'مهمانان این میز', 'Guests'),
                        style: TextStyle(
                          color: AppTok.textSoft(ctx),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: t.guestNames
                          .where((e) => e.trim().isNotEmpty)
                          .map(
                            (n) => Chip(
                              label:
                                  Text(n, style: const TextStyle(fontSize: 12)),
                              backgroundColor:
                                  AppTok.accent(ctx).withValues(alpha: 0.10),
                              side: BorderSide(
                                color:
                                    AppTok.accent(ctx).withValues(alpha: 0.25),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTok.background(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTok.accent(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppTok.textSoft(context), fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTok.text(context),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _tablesRef.orderBy('order').snapshots(),
          builder: (context, tableSnap) {
            if (tableSnap.hasError) {
              return _message(
                context,
                _t(
                  'seating_load_error',
                  'چیدمان در دسترس نیست',
                  'Seating unavailable',
                ),
              );
            }
            if (!tableSnap.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppTok.accent(context),
                ),
              );
            }

            final allTables =
                tableSnap.data!.docs.map(TableModel.fromDoc).toList();

            if (allTables.isEmpty) {
              return _message(
                context,
                _t(
                  'no_seating_yet',
                  'هنوز چیدمان صندلی ثبت نشده',
                  'No seating chart yet',
                ),
              );
            }

            final myTable = _findMyTable(allTables);

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _hallsRef.orderBy('order').snapshots(),
              builder: (context, hallSnap) {
                final halls = <HallModel>[];
                if (hallSnap.hasData) {
                  halls.addAll(hallSnap.data!.docs.map(HallModel.fromDoc));
                }

                var activeHallId = _activeHallId ?? '';
                if (halls.isNotEmpty) {
                  final exists = halls.any((h) => h.id == activeHallId);
                  if (!exists) activeHallId = halls.first.id;
                } else {
                  activeHallId = '';
                }

                final tables = _tablesForHall(allTables, halls, activeHallId);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        decoration: BoxDecoration(
                          color: AppTok.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTok.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _t(
                                'find_my_seat',
                                'میز من کجاست؟',
                                'Find my seat',
                              ),
                              style: TextStyle(
                                color: AppTok.text(context),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _t(
                                'find_my_seat_hint',
                                'همان نامی که زوج در لیست مهمان نوشته‌اند را وارد کنید',
                                'Enter the exact name from the couple’s guest list',
                              ),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameC,
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (_) => _applyFind(allTables),
                                    style:
                                        TextStyle(color: AppTok.text(context)),
                                    decoration: InputDecoration(
                                      hintText: _t(
                                        'your_name',
                                        'نام شما',
                                        'Your name',
                                      ),
                                      hintStyle: TextStyle(
                                        color: AppTok.textSoft(context),
                                      ),
                                      filled: true,
                                      fillColor: AppTok.background(context),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.person_search_outlined,
                                        color: AppTok.accent(context),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () => _applyFind(allTables),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTok.accent(context),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _t('find', 'پیدا کن', 'Find'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (myTable != null) ...[
                              const SizedBox(height: 10),
                              Material(
                                color: AppTok.accent(context)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      _highlightTableId = myTable.id;
                                      if (myTable.hallId.isNotEmpty) {
                                        _activeHallId = myTable.hallId;
                                      }
                                      _listMode = false;
                                    });
                                    _showTableInfo(myTable, isMine: true);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.celebration_outlined,
                                          color: AppTok.accent(context),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${_t('your_table', 'میز شما', 'Your table')}: ${_tableLabel(myTable)} · ${_typeLabel(myTable.type)}',
                                            style: TextStyle(
                                              color: AppTok.text(context),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_left,
                                          color: AppTok.accent(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _t(
                                'seating_readonly_hint',
                                'نقشه میزها — فقط مشاهده',
                                'Hall map — view only',
                              ),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: _listMode
                                ? _t('hall_map', 'نقشه سالن', 'Hall map')
                                : _t('table_list', 'لیست میزها', 'List'),
                            onPressed: () =>
                                setState(() => _listMode = !_listMode),
                            icon: Icon(
                              _listMode
                                  ? Icons.map_outlined
                                  : Icons.view_list_outlined,
                              color: AppTok.accent(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (halls.length > 1)
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: halls.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final h = halls[i];
                            final selected = h.id == activeHallId;
                            return ChoiceChip(
                              label: Text(h.displayName),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _activeHallId = h.id),
                              selectedColor: AppTok.accent(context)
                                  .withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: selected
                                    ? AppTok.accent(context)
                                    : AppTok.text(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppTok.accent(context)
                                    : AppTok.border(context),
                              ),
                              backgroundColor: AppTok.card(context),
                            );
                          },
                        ),
                      ),
                    Expanded(
                      child: tables.isEmpty
                          ? _message(
                              context,
                              _t(
                                'no_tables_in_hall',
                                'میزی در این سالن نیست',
                                'No tables in this hall',
                              ),
                            )
                          : _listMode
                              ? _buildList(context, tables)
                              : _buildMap(context, tables),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _message(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTok.textSoft(context), height: 1.4),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<TableModel> tables) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: tables.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = tables[i];
        final mine =
            t.id == _highlightTableId || _nameMatchesTable(t, _query);
        return Material(
          color: mine
              ? AppTok.accent(context).withValues(alpha: 0.12)
              : AppTok.card(context),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTableInfo(t, isMine: mine),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      mine ? AppTok.accent(context) : AppTok.border(context),
                  width: mine ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  _GuestTableShape(
                    type: t.type,
                    size: 52,
                    isVip: t.isVip,
                    highlight: mine,
                    child: Icon(
                      _typeIcon(t.type),
                      size: 18,
                      color: AppTok.accent(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tableLabel(t),
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_typeLabel(t.type)} · ${_fa(t.seatedCount.toString())}/${_fa(t.capacity.toString())}',
                          style: TextStyle(
                            color: AppTok.textSoft(context),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (mine)
                    Icon(Icons.star, color: AppTok.accent(context), size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap(BuildContext context, List<TableModel> tables) {
    final dark = AppTok.isDark(context);
    final boardColor =
        dark ? const Color(0xFF1A1824) : AppTok.cardSoft(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardW = constraints.maxWidth - 24;
        final boardH = constraints.maxHeight - 16;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                    painter: _GuestGridPainter(
                      lineColor: dark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppTok.border(context).withValues(alpha: 0.55),
                    ),
                  ),
                ),
                ...tables.map((t) {
                  final dims = TableModel.layoutSize(t.type, base: 78);
                  final maxX = (boardW - dims.w).clamp(0.0, boardW);
                  final maxY = (boardH - dims.h).clamp(0.0, boardH);
                  final x = (t.posX.clamp(0.0, 1.0) * maxX);
                  final y = (t.posY.clamp(0.0, 1.0) * maxY);
                  final mine = t.id == _highlightTableId ||
                      _nameMatchesTable(t, _query);
                  final label = _tableLabel(t);
                  final cap =
                      '${_fa(t.seatedCount.toString())}/${_fa(t.capacity.toString())}';

                  return Positioned(
                    left: x,
                    top: y,
                    width: dims.w,
                    height: dims.h,
                    child: GestureDetector(
                      onTap: () => _showTableInfo(t, isMine: mine),
                      child: AnimatedScale(
                        scale: mine ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        child: _GuestTableShape(
                          type: t.type,
                          size: 78,
                          isVip: t.isVip,
                          highlight: mine,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  mine
                                      ? _t('your_table', 'میز شما', 'Yours')
                                      : cap,
                                  style: TextStyle(
                                    color: AppTok.accent(context),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GuestTableShape extends StatelessWidget {
  const _GuestTableShape({
    required this.type,
    required this.child,
    this.size = 78,
    this.isVip = false,
    this.highlight = false,
  });

  final String type;
  final Widget child;
  final double size;
  final bool isVip;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlight || isVip
        ? AppTok.accent(context)
        : AppTok.accent(context).withValues(alpha: 0.55);
    final dims = TableModel.layoutSize(type, base: size);

    BoxDecoration decoration;
    switch (type) {
      case 'square':
        decoration = BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: highlight ? 2.4 : 1.6),
          boxShadow: [
            BoxShadow(
              color: (highlight ? AppTok.accent(context) : Colors.black)
                  .withValues(alpha: highlight ? 0.28 : 0.12),
              blurRadius: highlight ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
        break;
      case 'rect':
        decoration = BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: highlight ? 2.4 : 1.6),
          boxShadow: [
            BoxShadow(
              color: (highlight ? AppTok.accent(context) : Colors.black)
                  .withValues(alpha: highlight ? 0.28 : 0.12),
              blurRadius: highlight ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
        break;
      case 'round':
      default:
        decoration = BoxDecoration(
          color: AppTok.card(context),
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: highlight ? 2.4 : 1.6),
          boxShadow: [
            BoxShadow(
              color: (highlight ? AppTok.accent(context) : Colors.black)
                  .withValues(alpha: highlight ? 0.28 : 0.12),
              blurRadius: highlight ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
    }

    return Container(
      width: dims.w,
      height: dims.h,
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
              child: Icon(Icons.star, color: AppTok.accent(context), size: 12),
            ),
        ],
      ),
    );
  }
}

class _GuestGridPainter extends CustomPainter {
  _GuestGridPainter({required this.lineColor});

  final Color lineColor;

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
  bool shouldRepaint(covariant _GuestGridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}