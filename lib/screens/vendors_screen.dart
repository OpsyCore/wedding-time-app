import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/vendor_model.dart';
import '../services/vendor_budget_sync.dart';
import 'vendor_form_screen.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  String _search = '';
  String? _filterCategory;
  String? _filterStatus;

  CollectionReference<Map<String, dynamic>> get _ref => FirebaseFirestore
      .instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('vendors');

  static const _persianDigits = [
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  String _fa(String input) {
    if (!AppLang.I.isFa) return input;
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _persianDigits[i] : c;
    }).join();
  }

  String _formatAmount(num amount) {
    final intPart = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i != 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return _fa(buffer.toString());
  }

  Color _statusColor(String status) {
    switch (status) {
      case VendorStatus.booked:
        return const Color(0xFF6FCF97);
      case VendorStatus.rejected:
        return AppTok.danger(context);
      default:
        return AppTok.accent(context);
    }
  }

  Future<void> _openForm({VendorModel? vendor}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorFormScreen(
          weddingId: widget.weddingId,
          vendor: vendor,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(VendorModel v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(ctx),
          title: Text(
            AppLang.tr('delete_vendor'),
            style: TextStyle(color: AppTok.text(ctx)),
          ),
          content: Text(
            v.isLinkedToBudget
                ? '«${v.name}» ${AppLang.tr('delete_vendor_with_budget')}'
                : '«${v.name}» ${AppLang.tr('delete_vendor_confirm')}',
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
                style: TextStyle(color: AppTok.danger(ctx)),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await VendorBudgetSync.deleteLinkedExpense(
        weddingId: widget.weddingId,
        vendor: v,
      );
      await _ref.doc(v.id).delete();
    }
  }

  Future<void> _call(String phone) async {
    final p = phone.trim();
    if (p.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: p);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;

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
              iconTheme: IconThemeData(color: AppTok.text(context)),
              title: Text(
                AppLang.tr('vendors_title'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: AppLang.tr('filter'),
                  onPressed: _openFilterSheet,
                  icon: Icon(
                    _filterCategory != null || _filterStatus != null
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                    color: AppTok.accent(context),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'vendors_fab',
              onPressed: () => _openForm(),
              backgroundColor: AppTok.accent(context),
              foregroundColor: onAccent,
              icon: const Icon(Icons.add),
              label: Text(
                AppLang.tr('add'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    style: TextStyle(color: AppTok.text(context)),
                    decoration: InputDecoration(
                      hintText: AppLang.tr('search_vendor_hint'),
                      hintStyle: TextStyle(color: AppTok.textSoft(context)),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTok.textSoft(context),
                      ),
                      filled: true,
                      fillColor: AppTok.card(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream:
                        _ref.orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: _ref.snapshots(),
                          builder: (context, snap2) =>
                              _buildList(snap2.data?.docs ?? []),
                        );
                      }
                      if (!snap.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTok.accent(context),
                          ),
                        );
                      }
                      return _buildList(snap.data!.docs);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;
    var items = docs.map(VendorModel.fromDoc).toList();

    if (_filterCategory != null) {
      items = items.where((e) => e.category == _filterCategory).toList();
    }
    if (_filterStatus != null) {
      items = items.where((e) => e.status == _filterStatus).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      items = items.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.phone.contains(q) ||
            VendorCategories.label(e.category).contains(_search) ||
            e.note.toLowerCase().contains(q);
      }).toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 64,
                color: AppTok.accent(context).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                AppLang.tr('no_vendors_yet'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLang.tr('vendors_empty_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _openForm(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTok.accent(context),
                  foregroundColor: onAccent,
                ),
                icon: const Icon(Icons.add),
                label: Text(AppLang.tr('add_vendor')),
              ),
            ],
          ),
        ),
      );
    }

    final booked = items.where((e) => e.status == VendorStatus.booked).length;
    final pending =
        items.where((e) => e.status == VendorStatus.pending).length;
    final totalCost = items.fold<double>(0, (s, e) => s + e.cost);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTok.border(context)),
          ),
          child: Row(
            children: [
              _statChip(
                AppLang.tr('total'),
                _fa(items.length.toString()),
                AppTok.text(context),
              ),
              _statChip(
                AppLang.tr('booked'),
                _fa(booked.toString()),
                const Color(0xFF6FCF97),
              ),
              _statChip(
                AppLang.tr('waiting'),
                _fa(pending.toString()),
                AppTok.accent(context),
              ),
              Expanded(
                child: Text(
                  totalCost > 0
                      ? '${_formatAmount(totalCost)} ${AppLang.tr('toman_short')}'
                      : '—',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map(_vendorCard),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTok.textSoft(context),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vendorCard(VendorModel v) {
    final statusColor = _statusColor(v.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openForm(vendor: v),
          onLongPress: () => _confirmDelete(v),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            AppTok.accent(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        color: AppTok.accent(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.name,
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            VendorCategories.label(v.category),
                            style: TextStyle(
                              color: AppTok.textSoft(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        VendorStatus.label(v.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (v.isLinkedToBudget) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: Color(0xFF6FCF97),
                      ),
                    ],
                  ],
                ),
                if (v.phone.isNotEmpty || v.cost > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (v.phone.isNotEmpty)
                        GestureDetector(
                          onTap: () => _call(v.phone),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: AppTok.accent(context),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _fa(v.phone),
                                style: TextStyle(
                                  color: AppTok.textSoft(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      if (v.cost > 0)
                        Text(
                          '${_formatAmount(v.cost)} ${AppLang.tr('toman')}',
                          style: TextStyle(
                            color: AppTok.accentSoft(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ],
                if (v.hasPayments || v.paidTotal > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: v.paidPercent,
                      minHeight: 6,
                      backgroundColor: AppTok.background(context),
                      color: const Color(0xFF6FCF97),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppLang.tr('paid')} ${_formatAmount(v.paidTotal)} · ${AppLang.tr('remaining')} ${_formatAmount(v.remaining)}'
                    '${v.unpaidCount > 0 ? ' · ${_fa(v.unpaidCount.toString())} ${AppLang.tr('open_installments')}' : ''}',
                    style: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 11,
                    ),
                  ),
                ],
                if (v.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    v.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFilterSheet() {
    String? cat = _filterCategory;
    String? st = _filterStatus;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTok.card(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              final onAccent = AppTok.isDark(ctx)
                  ? AppDarkPalette.background
                  : Colors.white;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTok.textSoft(ctx)
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLang.tr('filter'),
                      style: TextStyle(
                        color: AppTok.text(ctx),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppLang.tr('category'),
                      style: TextStyle(color: AppTok.textSoft(ctx)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          ctx: ctx,
                          label: AppLang.tr('all'),
                          selected: cat == null,
                          onTap: () => setModal(() => cat = null),
                        ),
                        ...VendorCategories.ids.map(
                          (id) => _chip(
                            ctx: ctx,
                            label: VendorCategories.label(id),
                            selected: cat == id,
                            onTap: () => setModal(() => cat = id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLang.tr('status'),
                      style: TextStyle(color: AppTok.textSoft(ctx)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _chip(
                          ctx: ctx,
                          label: AppLang.tr('all'),
                          selected: st == null,
                          onTap: () => setModal(() => st = null),
                        ),
                        ...VendorStatus.labels.entries.map(
                          (e) => _chip(
                            ctx: ctx,
                            label: e.value,
                            selected: st == e.key,
                            onTap: () => setModal(() => st = e.key),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filterCategory = null;
                                _filterStatus = null;
                              });
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTok.textSoft(ctx),
                              side: BorderSide(
                                color: AppTok.border(ctx),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(AppLang.tr('clear')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _filterCategory = cat;
                                _filterStatus = st;
                              });
                              Navigator.pop(ctx);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTok.accent(ctx),
                              foregroundColor: onAccent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(AppLang.tr('apply')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _chip({
    required BuildContext ctx,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTok.accent(ctx).withValues(alpha: 0.2)
              : AppTok.background(ctx),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTok.accent(ctx)
                : AppTok.border(ctx),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTok.accent(ctx) : AppTok.textSoft(ctx),
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}