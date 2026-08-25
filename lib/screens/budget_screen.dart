import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/budget_group_model.dart';
import '../models/expense_item_model.dart';
import '../widgets/app_drawer.dart';
import '../widgets/wedding_time_header.dart';

class BudgetScreen extends StatefulWidget {
  final String weddingId;

  const BudgetScreen({super.key, required this.weddingId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<String> expandedGroups = {};
  bool _expandedInitialized = false;

  CollectionReference get groupsRef => FirebaseFirestore.instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('budgetGroups');

  /// رنگ هر تکهٔ حلقه / گروه (لوکس تیره)
  static const List<Color> _segmentColors = [
    Color(0xFFD4AF8C), // رزگلد
    Color(0xFF7EB6A4), // سبز-آبی
    Color(0xFF8BA3C7), // آبی ملایم
    Color(0xFFC9A0DC), // بنفش
    Color(0xFFE8A0A0), // صورتی ملایم
    Color(0xFFD4C07A), // طلایی
    Color(0xFF9BB7A0), // سبز
    Color(0xFFEFC4A8), // کرم-رز
    Color(0xFF6FA8C9), // آبی
    Color(0xFFB8A1A8), // صورتی خاکستری
  ];

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

  String _toPersianDigits(String input) {
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _persianDigits[i] : c;
    }).join();
  }

  String _displayNum(Object n) {
    final s = n.toString();
    return AppLang.I.isFa ? _toPersianDigits(s) : s;
  }

  String _formatAmount(num amount) {
    final intPart = amount.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i != 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return _displayNum(buffer.toString());
  }

  Color _colorForIndex(int index) =>
      _segmentColors[index % _segmentColors.length];

  IconData _iconForGroup(String title) {
    final t = title.toLowerCase();
    if (title.contains('عقد') || t.contains('ceremony')) {
      return Icons.favorite_border;
    }
    if (title.contains('جشن') ||
        title.contains('عروسی') ||
        t.contains('party') ||
        t.contains('wedding')) {
      return Icons.celebration_outlined;
    }
    if (title.contains('ماه‌عسل') ||
        title.contains('سفر') ||
        t.contains('honeymoon') ||
        t.contains('travel')) {
      return Icons.flight_takeoff_outlined;
    }
    if (title.contains('تأمین') || t.contains('vendor')) {
      return Icons.storefront_outlined;
    }
    return Icons.category_outlined;
  }

  IconData _iconForExpense(String title) {
    final t = title.toLowerCase();
    if (title.contains('سالن') ||
        title.contains('تالار') ||
        title.contains('باغ') ||
        t.contains('venue') ||
        t.contains('hall')) {
      return Icons.location_city_outlined;
    }
    if (title.contains('دفتر') ||
        title.contains('ثبت') ||
        t.contains('registry')) {
      return Icons.description_outlined;
    }
    if (title.contains('عکاس') ||
        title.contains('فیلم') ||
        t.contains('photo') ||
        t.contains('video')) {
      return Icons.camera_alt_outlined;
    }
    if (title.contains('گل') || t.contains('flower')) {
      return Icons.local_florist_outlined;
    }
    if (title.contains('لباس') || t.contains('dress') || t.contains('suit')) {
      return Icons.checkroom_outlined;
    }
    if (title.contains('کیک') ||
        title.contains('قنادی') ||
        t.contains('cake')) {
      return Icons.cake_outlined;
    }
    if (title.contains('موسیقی') ||
        title.contains('دی‌جی') ||
        t.contains('music') ||
        t.contains('dj')) {
      return Icons.music_note_outlined;
    }
    if (title.contains('سایر') || t.contains('other')) {
      return Icons.more_horiz;
    }
    return Icons.receipt_long_outlined;
  }

  /// کلید DB: shared | bride | groom
  Map<String, String> get payerMap => {
        'shared': AppLang.tr('payer_shared'),
        'bride': AppLang.tr('bride'),
        'groom': AppLang.tr('groom'),
      };

  /// مقدار ذخیره‌شده در Firestore همان رشتهٔ فارسی است (سازگار با دادهٔ موجود)
  List<String> get categoryOptions => const [
        'تشریفات',
        'پذیرایی',
        'لباس',
        'زیبایی',
        'عکاسی',
        'گل‌آرایی',
        'جواهرات',
        'هدایا',
        'حمل‌ونقل',
        'چاپ',
        'جهیزیه',
        'سایر',
      ];

  String _categoryLabel(String key) {
    const map = {
      'تشریفات': 'cat_ceremony',
      'پذیرایی': 'cat_catering',
      'لباس': 'cat_clothing',
      'زیبایی': 'cat_beauty',
      'عکاسی': 'cat_photography',
      'گل‌آرایی': 'cat_flowers',
      'جواهرات': 'cat_jewelry',
      'هدایا': 'cat_gifts',
      'حمل‌ونقل': 'cat_transport',
      'چاپ': 'cat_print',
      'جهیزیه': 'cat_trousseau',
      'سایر': 'cat_other',
    };
    final trKey = map[key];
    return trKey != null ? AppLang.tr(trKey) : key;
  }

  void openGroupForm() {
    final titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ListenableBuilder(
          listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
          builder: (context, _) {
            return Directionality(
              textDirection: AppLang.I.direction,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLang.tr('add_group'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTok.text(context),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: AppTok.text(context)),
                      cursorColor: AppTok.accent(context),
                      decoration: _fieldDecoration(
                        context,
                        AppLang.tr('group_title_hint'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTok.accent(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) return;

                          final existing = await groupsRef.get();

                          await groupsRef.add({
                            'title': titleController.text.trim(),
                            'isDefault': false,
                            'order': existing.docs.length,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(
                          AppLang.tr('save'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void openExpenseForm({String? groupId, ExpenseItemModel? expense}) {
    final titleController =
        TextEditingController(text: expense?.title ?? '');
    final estimatedController = TextEditingController(
      text: expense != null ? expense.estimatedAmount.toString() : '',
    );
    final actualController = TextEditingController(
      text: expense != null ? expense.actualAmount.toString() : '',
    );
    final noteController = TextEditingController(text: expense?.note ?? '');

    String payer = expense?.payer ?? 'shared';
    String category = expense?.category ?? categoryOptions.last;
    final String? originalGroupId = groupId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ListenableBuilder(
              listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
              builder: (context, _) {
                return Directionality(
                  textDirection: AppLang.I.direction,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      left: 20,
                      right: 20,
                      top: 20,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            expense == null
                                ? AppLang.tr('add_expense')
                                : AppLang.tr('edit_expense'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTok.text(context),
                            ),
                          ),
                          const SizedBox(height: 15),
                          StreamBuilder<QuerySnapshot>(
                            stream: groupsRef.orderBy('order').snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox();
                              }
                              final groupOptions = snapshot.data!.docs
                                  .map((d) => BudgetGroupModel.fromDoc(d))
                                  .toList();

                              groupId ??= groupOptions.isNotEmpty
                                  ? groupOptions.first.id
                                  : null;

                              final validValue =
                                  groupOptions.any((g) => g.id == groupId)
                                      ? groupId
                                      : (groupOptions.isNotEmpty
                                          ? groupOptions.first.id
                                          : null);

                              return Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: validValue,
                                    dropdownColor: AppTok.card(context),
                                    style: TextStyle(
                                      color: AppTok.text(context),
                                    ),
                                    items: groupOptions
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g.id,
                                            child: Text(g.title),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setModalState(() => groupId = value);
                                    },
                                    decoration: _fieldDecoration(
                                      context,
                                      AppLang.tr('select_budget_group'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              );
                            },
                          ),
                          TextField(
                            controller: titleController,
                            style: TextStyle(color: AppTok.text(context)),
                            cursorColor: AppTok.accent(context),
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('budget_name_required'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: estimatedController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppTok.text(context)),
                            cursorColor: AppTok.accent(context),
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('estimated_amount_toman'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: actualController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppTok.text(context)),
                            cursorColor: AppTok.accent(context),
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('actual_amount_toman'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              AppLang.tr('payer'),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 6,
                            runSpacing: 6,
                            children: payerMap.entries.map((e) {
                              final isSelected = payer == e.key;
                              return GestureDetector(
                                onTap: () =>
                                    setModalState(() => payer = e.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTok.accent(context)
                                        : AppTok.background(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTok.accent(context)
                                          : AppTok.border(context),
                                    ),
                                  ),
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTok.textSoft(context),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: categoryOptions.contains(category)
                                ? category
                                : categoryOptions.last,
                            dropdownColor: AppTok.card(context),
                            style: TextStyle(color: AppTok.text(context)),
                            items: categoryOptions
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(_categoryLabel(c)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setModalState(() => category = value!);
                            },
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('select_category'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: noteController,
                            style: TextStyle(color: AppTok.text(context)),
                            cursorColor: AppTok.accent(context),
                            maxLines: 3,
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('note'),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTok.accent(context),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                if (titleController.text.trim().isEmpty ||
                                    groupId == null) {
                                  return;
                                }

                                final data = {
                                  'title': titleController.text.trim(),
                                  'estimatedAmount': int.tryParse(
                                        estimatedController.text.trim(),
                                      ) ??
                                      0,
                                  'actualAmount': int.tryParse(
                                        actualController.text.trim(),
                                      ) ??
                                      0,
                                  'payer': payer,
                                  'category': category,
                                  'note': noteController.text.trim(),
                                  'isDefault': expense?.isDefault ?? false,
                                };

                                final expensesRef = groupsRef
                                    .doc(groupId)
                                    .collection('expenses');

                                if (expense == null) {
                                  await expensesRef.add({
                                    ...data,
                                    'createdAt':
                                        FieldValue.serverTimestamp(),
                                  });
                                } else if (groupId == originalGroupId) {
                                  await expensesRef
                                      .doc(expense.id)
                                      .update(data);
                                } else {
                                  await groupsRef
                                      .doc(originalGroupId)
                                      .collection('expenses')
                                      .doc(expense.id)
                                      .delete();
                                  await expensesRef.add({
                                    ...data,
                                    'createdAt':
                                        FieldValue.serverTimestamp(),
                                  });
                                }

                                if (context.mounted) Navigator.pop(context);
                              },
                              child: Text(
                                AppLang.tr('save'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTok.textSoft(context)),
      filled: true,
      fillColor: AppTok.background(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.accent(context)),
      ),
    );
  }

  Future<void> deleteExpense(String groupId, ExpenseItemModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(context),
          title: Text(
            AppLang.tr('delete_expense'),
            style: TextStyle(color: AppTok.text(context)),
          ),
          content: Text(
            AppLang.tr('delete_expense_confirm')
                .replaceAll('{title}', expense.title),
            style: TextStyle(color: AppTok.textSoft(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppLang.tr('cancel'),
                style: TextStyle(color: AppTok.textSoft(context)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLang.tr('delete'),
                style: TextStyle(color: AppTok.danger(context)),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await groupsRef
          .doc(groupId)
          .collection('expenses')
          .doc(expense.id)
          .delete();
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
            key: _scaffoldKey,
            backgroundColor: AppTok.background(context),
            drawer: AppDrawer(weddingId: widget.weddingId),
            body: SafeArea(
              child: Column(
                children: [
                  WeddingTimeHeader(
                    weddingId: widget.weddingId,
                    onMenuPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLang.tr('budget_total_title'),
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTok.accent(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildHeroCard(context),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppLang.tr('expense_details'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTok.text(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: openGroupForm,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTok.card(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTok.accent(context)
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add_circle_outline,
                                    color: AppTok.accent(context),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildGroupsList(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'budget_fab',
              backgroundColor: AppTok.accent(context),
              foregroundColor: Colors.white,
              onPressed: () => openExpenseForm(),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: groupsRef.orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppTok.accent(context)),
            ),
          );
        }

        final groups = snapshot.data!.docs
            .map((d) => BudgetGroupModel.fromDoc(d))
            .toList();

        return FutureBuilder<_BudgetTotals>(
          future: _calculateTotals(groups),
          builder: (context, totalSnap) {
            if (!totalSnap.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: AppTok.accent(context),
                  ),
                ),
              );
            }

            final totals = totalSnap.data!;
            final totalEstimated = totals.estimated;
            final totalActual = totals.actual;
            final remaining =
                (totalEstimated - totalActual).clamp(0, totalEstimated);
            final progress = totalEstimated <= 0
                ? 0.0
                : (totalActual / totalEstimated).clamp(0.0, 1.5);

            // تکه‌های رنگی = سهم هر گروه از «هزینه واقعی»
            // اگر هنوز هزینه‌ای ثبت نشده، از تخمین گروه استفاده می‌شود
            final useActual = totalActual > 0;
            final rawSegments = <_BudgetSegment>[];
            for (var i = 0; i < totals.groups.length; i++) {
              final g = totals.groups[i];
              final value = useActual ? g.actual : g.estimated;
              if (value <= 0) continue;
              rawSegments.add(
                _BudgetSegment(
                  id: g.id,
                  title: g.title,
                  value: value.toDouble(),
                  color: _colorForIndex(i),
                ),
              );
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTok.card(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTok.accent(context).withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLang.tr('total_amount'),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(totalEstimated),
                              style: TextStyle(
                                color: AppTok.text(context),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              AppLang.tr('toman'),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              AppLang.tr('spent_amount'),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(totalActual),
                              style: TextStyle(
                                color: AppTok.text(context),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              AppLang.tr('toman'),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              AppLang.tr('remaining'),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(remaining),
                              style: TextStyle(
                                color: totalActual > totalEstimated &&
                                        totalEstimated > 0
                                    ? AppTok.danger(context)
                                    : AppTok.accentSoft(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MultiColorBudgetRing(
                        size: 124,
                        strokeWidth: 14,
                        segments: rawSegments,
                        // پس‌زمینهٔ خالی = باقی‌مانده نسبت به بودجه تخمینی
                        trackValue: totalEstimated > 0
                            ? math.max(
                                totalEstimated.toDouble() -
                                    (useActual
                                        ? totalActual.toDouble()
                                        : rawSegments.fold<double>(
                                            0, (s, e) => s + e.value)),
                                0,
                              )
                            : 0,
                        trackColor: AppTok.ringTrack(context),
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_displayNum((progress * 100).clamp(0, 999).toInt())}%',
                              style: TextStyle(
                                color: AppTok.text(context),
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              AppLang.tr('spent_percent_label'),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (rawSegments.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Divider(
                      color: AppTok.border(context).withValues(alpha: 0.5),
                      height: 1,
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: rawSegments.map((s) {
                          final sum = rawSegments.fold<double>(
                            0,
                            (a, b) => a + b.value,
                          );
                          final pct =
                              sum <= 0 ? 0 : ((s.value / sum) * 100).round();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTok.cardSoft(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: s.color.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 110),
                                  child: Text(
                                    s.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppTok.text(context),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_displayNum(pct)}%',
                                  style: TextStyle(
                                    color: s.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: groupsRef.orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final groups = snapshot.data!.docs
            .map((d) => BudgetGroupModel.fromDoc(d))
            .toList();

        if (!_expandedInitialized && groups.isNotEmpty) {
          expandedGroups.add(groups.first.id);
          _expandedInitialized = true;
        }

        if (groups.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTok.card(context),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTok.accent(context).withValues(alpha: 0.7),
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  AppLang.tr('add_group'),
                  style: TextStyle(color: AppTok.textSoft(context)),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < groups.length; i++)
              _buildGroupCard(context, groups[i], _colorForIndex(i)),
          ],
        );
      },
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    BudgetGroupModel group,
    Color accentColor,
  ) {
    final isExpanded = expandedGroups.contains(group.id);
    final expensesRef = groupsRef.doc(group.id).collection('expenses');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: expensesRef.snapshots(),
        builder: (context, expenseSnap) {
          final expenses = (expenseSnap.data?.docs ?? [])
              .map((d) => ExpenseItemModel.fromDoc(d))
              .toList();

          final groupEstimated = expenses.fold<int>(
            0,
            (total, e) => total + e.estimatedAmount,
          );
          final groupActual = expenses.fold<int>(
            0,
            (total, e) => total + e.actualAmount,
          );
          final groupProgress = groupEstimated <= 0
              ? 0.0
              : (groupActual / groupEstimated).clamp(0.0, 1.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      expandedGroups.remove(group.id);
                    } else {
                      expandedGroups.add(group.id);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _iconForGroup(group.title),
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${AppLang.tr('group_total_prefix')}${_formatAmount(groupEstimated)}${AppLang.tr('group_total_suffix')}'
                            ' · ${AppLang.tr('spent_amount')} ${_formatAmount(groupActual)}',
                            style: TextStyle(
                              color: AppTok.textSoft(context),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: groupProgress,
                              minHeight: 5,
                              backgroundColor: AppTok.cardSoft(context),
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTok.textSoft(context),
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 14),
                Divider(
                  color: AppTok.border(context).withValues(alpha: 0.5),
                  height: 1,
                ),
                const SizedBox(height: 10),
                if (expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      AppLang.tr('add_expense_to_group'),
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ...expenses.map((expense) {
                  return Dismissible(
                    key: ValueKey(expense.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      await deleteExpense(group.id, expense);
                      return false;
                    },
                    background: Container(
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Icon(
                        Icons.delete_outline,
                        color: AppTok.danger(context),
                        size: 18,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => openExpenseForm(
                        groupId: group.id,
                        expense: expense,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _iconForExpense(expense.title),
                              color: accentColor.withValues(alpha: 0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.title,
                                    style: TextStyle(
                                      color: AppTok.text(context),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (expense.category.isNotEmpty)
                                    Text(
                                      _categoryLabel(expense.category),
                                      style: TextStyle(
                                        color: AppTok.textSoft(context),
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatAmount(expense.estimatedAmount),
                                  style: TextStyle(
                                    color: AppTok.text(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (expense.actualAmount > 0)
                                  Text(
                                    '${AppLang.tr('paid')} ${_formatAmount(expense.actualAmount)}',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: AppTok.textSoft(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => openExpenseForm(groupId: group.id),
                    icon: Icon(
                      Icons.add,
                      size: 16,
                      color: accentColor,
                    ),
                    label: Text(
                      AppLang.tr('add_expense_to_group'),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<_BudgetTotals> _calculateTotals(
    List<BudgetGroupModel> groups,
  ) async {
    int totalEstimated = 0;
    int totalActual = 0;
    final groupStats = <_GroupMoney>[];

    for (final group in groups) {
      final expensesSnapshot =
          await groupsRef.doc(group.id).collection('expenses').get();

      int gEst = 0;
      int gAct = 0;
      for (final doc in expensesSnapshot.docs) {
        final expense = ExpenseItemModel.fromDoc(doc);
        gEst += expense.estimatedAmount;
        gAct += expense.actualAmount;
      }

      totalEstimated += gEst;
      totalActual += gAct;
      groupStats.add(
        _GroupMoney(
          id: group.id,
          title: group.title,
          estimated: gEst,
          actual: gAct,
        ),
      );
    }

    return _BudgetTotals(
      estimated: totalEstimated,
      actual: totalActual,
      groups: groupStats,
    );
  }
}

// ═══════════════════════════════════════
// Multi-color ring
// ═══════════════════════════════════════

class _BudgetSegment {
  const _BudgetSegment({
    required this.id,
    required this.title,
    required this.value,
    required this.color,
  });

  final String id;
  final String title;
  final double value;
  final Color color;
}

class _GroupMoney {
  const _GroupMoney({
    required this.id,
    required this.title,
    required this.estimated,
    required this.actual,
  });

  final String id;
  final String title;
  final int estimated;
  final int actual;
}

class _BudgetTotals {
  const _BudgetTotals({
    required this.estimated,
    required this.actual,
    required this.groups,
  });

  final int estimated;
  final int actual;
  final List<_GroupMoney> groups;
}

class _MultiColorBudgetRing extends StatelessWidget {
  const _MultiColorBudgetRing({
    required this.size,
    required this.strokeWidth,
    required this.segments,
    required this.trackValue,
    required this.trackColor,
    required this.center,
  });

  final double size;
  final double strokeWidth;
  final List<_BudgetSegment> segments;
  final double trackValue;
  final Color trackColor;
  final Widget center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _MultiColorRingPainter(
              segments: segments,
              trackValue: trackValue,
              strokeWidth: strokeWidth,
              trackColor: trackColor,
            ),
          ),
          center,
        ],
      ),
    );
  }
}

class _MultiColorRingPainter extends CustomPainter {
  _MultiColorRingPainter({
    required this.segments,
    required this.trackValue,
    required this.strokeWidth,
    required this.trackColor,
  });

  final List<_BudgetSegment> segments;
  final double trackValue;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // حلقهٔ پس‌زمینه کامل
    canvas.drawCircle(center, radius, trackPaint);

    final totalSeg =
        segments.fold<double>(0, (s, e) => s + e.value) + trackValue;
    if (totalSeg <= 0) return;

    // شروع از بالای دایره
    const full = 2 * math.pi;
    const gap = 0.045; // فاصلهٔ کوچک بین تکه‌ها
    double start = -math.pi / 2;

    final usable = full - (segments.isEmpty ? 0 : segments.length * gap);

    for (final seg in segments) {
      final sweep = usable * (seg.value / totalSeg);
      if (sweep <= 0) continue;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _MultiColorRingPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.trackValue != trackValue ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}