import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_date_picker.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/vendor_model.dart';
import '../models/vendor_payment_model.dart';
import '../services/notification_service.dart';
import '../services/vendor_budget_sync.dart';

class VendorPaymentsScreen extends StatefulWidget {
  const VendorPaymentsScreen({
    super.key,
    required this.weddingId,
    required this.vendor,
  });

  final String weddingId;
  final VendorModel vendor;

  @override
  State<VendorPaymentsScreen> createState() => _VendorPaymentsScreenState();
}

class _VendorPaymentsScreenState extends State<VendorPaymentsScreen> {
  late VendorModel _vendor;

  CollectionReference<Map<String, dynamic>> get _payRef =>
      VendorBudgetSync.paymentsRef(widget.weddingId, widget.vendor.id);

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

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return _fa('${d.year}/$m/$day');
  }

  @override
  void initState() {
    super.initState();
    _vendor = widget.vendor;
  }

  Future<void> _reloadVendor() async {
    final doc = await FirebaseFirestore.instance
        .collection('weddings')
        .doc(widget.weddingId)
        .collection('vendors')
        .doc(widget.vendor.id)
        .get();
    if (doc.exists && mounted) {
      setState(() => _vendor = VendorModel.fromDoc(doc));
    }
  }

  Future<void> _afterPaymentChange() async {
    await VendorBudgetSync.refreshPaymentSummary(
      weddingId: widget.weddingId,
      vendorId: widget.vendor.id,
    );
    await _reloadVendor();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? AppTok.danger(context) : AppTok.card(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPaymentForm({VendorPaymentModel? payment}) async {
    final titleC = TextEditingController(text: payment?.title ?? '');
    final amountC = TextEditingController(
      text: payment != null && payment.amount > 0
          ? payment.amount.toInt().toString()
          : '',
    );
    final noteC = TextEditingController(text: payment?.note ?? '');
    var type = payment?.type ?? VendorPaymentType.installment;
    var dueDate = payment?.dueDate;
    var isPaid = payment?.isPaid ?? false;

    if (payment == null && titleC.text.isEmpty) {
      titleC.text = VendorPaymentType.label(type);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 18,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
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
                      const SizedBox(height: 14),
                      Text(
                        payment == null
                            ? AppLang.tr('add_payment')
                            : AppLang.tr('edit_payment'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTok.text(ctx),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLang.tr('type'),
                        style: TextStyle(
                          color: AppTok.textSoft(ctx),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: VendorPaymentType.ids.map((id) {
                          final selected = type == id;
                          return ChoiceChip(
                            label: Text(VendorPaymentType.label(id)),
                            selected: selected,
                            onSelected: (_) {
                              setModal(() {
                                type = id;
                                if (titleC.text.isEmpty ||
                                    VendorPaymentType.ids.any(
                                      (t) =>
                                          titleC.text ==
                                          VendorPaymentType.label(t),
                                    )) {
                                  titleC.text = VendorPaymentType.label(id);
                                }
                              });
                            },
                            selectedColor: AppTok.accent(ctx),
                            labelStyle: TextStyle(
                              color: selected
                                  ? onAccent
                                  : AppTok.text(ctx),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            backgroundColor: AppTok.background(ctx),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleC,
                        style: TextStyle(color: AppTok.text(ctx)),
                        decoration: _dec(ctx, AppLang.tr('title')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountC,
                        style: TextStyle(color: AppTok.text(ctx)),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _dec(ctx, AppLang.tr('amount_toman')),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showAppDatePicker(
                            ctx,
                            initialDate: dueDate ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 6),
                          );
                          if (picked != null) {
                            setModal(() => dueDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppTok.background(ctx),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_outlined,
                                color: AppTok.accent(ctx),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                dueDate == null
                                    ? AppLang.tr('due_date_optional')
                                    : '${AppLang.tr('due_prefix')}: ${_formatDate(dueDate)}',
                                style: TextStyle(
                                  color: dueDate == null
                                      ? AppTok.textSoft(ctx)
                                      : AppTok.text(ctx),
                                ),
                              ),
                              const Spacer(),
                              if (dueDate != null)
                                GestureDetector(
                                  onTap: () =>
                                      setModal(() => dueDate = null),
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: AppTok.textSoft(ctx),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isPaid,
                          onChanged: (v) => setModal(() => isPaid = v),
                          activeThumbColor: AppTok.accent(ctx),
                          activeTrackColor:
                              AppTok.accent(ctx).withValues(alpha: 0.45),
                          title: Text(
                            AppLang.tr('is_paid'),
                            style: TextStyle(color: AppTok.text(ctx)),
                          ),
                          subtitle: Text(
                            AppLang.tr('mark_if_settled'),
                            style: TextStyle(
                              color: AppTok.textSoft(ctx),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      TextField(
                        controller: noteC,
                        style: TextStyle(color: AppTok.text(ctx)),
                        maxLines: 2,
                        decoration: _dec(ctx, AppLang.tr('note')),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTok.accent(ctx),
                            foregroundColor: onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final title = titleC.text.trim();
                            final amount = double.tryParse(
                                  amountC.text.trim().replaceAll(',', ''),
                                ) ??
                                0;
                            if (title.isEmpty) {
                              _toast(AppLang.tr('enter_title'), error: true);
                              return;
                            }
                            if (amount <= 0) {
                              _toast(AppLang.tr('invalid_amount'),
                                  error: true);
                              return;
                            }

                            final model = VendorPaymentModel(
                              id: payment?.id ?? '',
                              title: title,
                              type: type,
                              amount: amount,
                              dueDate: dueDate,
                              isPaid: isPaid,
                              paidAt: isPaid ? DateTime.now() : null,
                              note: noteC.text.trim(),
                            );

                            try {
                              if (payment == null) {
                                final doc = await _payRef.add(model.toMap());

                                if (isPaid) {
                                  await NotificationService(widget.weddingId)
                                      .notifyPayment(
                                    vendorName: _vendor.name,
                                    amount: amount,
                                    paymentId: doc.id,
                                  );
                                }
                              } else {
                                await _payRef.doc(payment.id).set(
                                      model.toMap(isUpdate: true),
                                      SetOptions(merge: true),
                                    );

                                if (isPaid && payment.isPaid == false) {
                                  await NotificationService(widget.weddingId)
                                      .notifyPayment(
                                    vendorName: _vendor.name,
                                    amount: amount,
                                    paymentId: payment.id,
                                  );
                                }
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              await _afterPaymentChange();
                              _toast(AppLang.tr('saved'));
                            } catch (e) {
                              _toast('${AppLang.tr('error')}: $e',
                                  error: true);
                            }
                          },
                          child: Text(
                            payment == null
                                ? AppLang.tr('add')
                                : AppLang.tr('save'),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  InputDecoration _dec(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTok.textSoft(context)),
      filled: true,
      fillColor: AppTok.background(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _togglePaid(VendorPaymentModel p) async {
    try {
      final nowPaid = !p.isPaid;
      await _payRef.doc(p.id).set({
        'isPaid': nowPaid,
        'paidAt': nowPaid ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (nowPaid) {
        await NotificationService(widget.weddingId).notifyPayment(
          vendorName: _vendor.name,
          amount: p.amount,
          paymentId: p.id,
        );
      }

      await _afterPaymentChange();
    } catch (e) {
      _toast('${AppLang.tr('error')}: $e', error: true);
    }
  }

  Future<void> _deletePayment(VendorPaymentModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(ctx),
          title: Text(
            AppLang.tr('delete_payment'),
            style: TextStyle(color: AppTok.text(ctx)),
          ),
          content: Text(
            '«${p.title}» ${AppLang.tr('delete_named_confirm')}',
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
    if (ok != true) return;
    try {
      await _payRef.doc(p.id).delete();
      await _afterPaymentChange();
      _toast(AppLang.tr('deleted'));
    } catch (e) {
      _toast('${AppLang.tr('error')}: $e', error: true);
    }
  }

  Future<void> _quickSetup() async {
    if (_vendor.cost <= 0) {
      _toast(
        AppLang.tr('set_contract_total_first'),
        error: true,
      );
      return;
    }

    final depositC = TextEditingController(
      text: (_vendor.cost * 0.3).round().toString(),
    );
    final countC = TextEditingController(text: '3');
    var firstDue = DateTime.now().add(const Duration(days: 7));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return AlertDialog(
                backgroundColor: AppTok.card(ctx),
                title: Text(
                  AppLang.tr('quick_installments_title'),
                  style: TextStyle(color: AppTok.text(ctx)),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: depositC,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(color: AppTok.text(ctx)),
                      decoration: _dec(ctx, AppLang.tr('deposit_toman')),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: countC,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(color: AppTok.text(ctx)),
                      decoration:
                          _dec(ctx, AppLang.tr('installments_after_deposit')),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${AppLang.tr('first_due')}: ${_formatDate(firstDue)}',
                        style: TextStyle(
                          color: AppTok.text(ctx),
                          fontSize: 13,
                        ),
                      ),
                      trailing: Icon(
                        Icons.calendar_month,
                        color: AppTok.accent(ctx),
                      ),
                      onTap: () async {
                        final picked = await showAppDatePicker(
                          ctx,
                          initialDate: firstDue,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 3),
                          ),
                        );
                        if (picked != null) {
                          setModal(() => firstDue = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppLang.tr('contract_total')}: ${_formatAmount(_vendor.cost)} ${AppLang.tr('toman')}',
                      style: TextStyle(
                        color: AppTok.textSoft(ctx),
                        fontSize: 12,
                      ),
                    ),
                  ],
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
                      AppLang.tr('build'),
                      style: TextStyle(color: AppTok.accent(ctx)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (ok != true) return;

    final deposit =
        double.tryParse(depositC.text.trim()) ?? (_vendor.cost * 0.3);
    final n = int.tryParse(countC.text.trim()) ?? 0;
    if (deposit < 0 || deposit > _vendor.cost) {
      _toast(AppLang.tr('invalid_deposit'), error: true);
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final depRef = _payRef.doc();
      batch.set(
        depRef,
        VendorPaymentModel(
          id: depRef.id,
          title: AppLang.tr('deposit'),
          type: VendorPaymentType.deposit,
          amount: deposit,
          dueDate: DateTime.now(),
          isPaid: false,
        ).toMap(),
      );

      final rest = _vendor.cost - deposit;
      if (n > 0 && rest > 0) {
        final each = (rest / n).floorToDouble();
        var allocated = 0.0;
        for (var i = 0; i < n; i++) {
          final isLast = i == n - 1;
          final amount = isLast ? (rest - allocated) : each;
          allocated += amount;
          final due = DateTime(
            firstDue.year,
            firstDue.month + i,
            firstDue.day,
          );
          final r = _payRef.doc();
          final isFinal = isLast;
          batch.set(
            r,
            VendorPaymentModel(
              id: r.id,
              title: isFinal
                  ? AppLang.tr('final_installment')
                  : '${AppLang.tr('installment_n')} ${_fa((i + 1).toString())}',
              type: isFinal
                  ? VendorPaymentType.finalPay
                  : VendorPaymentType.installment,
              amount: amount,
              dueDate: due,
              isPaid: false,
            ).toMap(),
          );
        }
      } else if (rest > 0) {
        final r = _payRef.doc();
        batch.set(
          r,
          VendorPaymentModel(
            id: r.id,
            title: AppLang.tr('settlement'),
            type: VendorPaymentType.finalPay,
            amount: rest,
            dueDate: firstDue,
            isPaid: false,
          ).toMap(),
        );
      }

      await batch.commit();
      await _afterPaymentChange();
      _toast(AppLang.tr('installments_created'));
    } catch (e) {
      _toast('${AppLang.tr('error')}: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cost = _vendor.cost;
    final paid = _vendor.paidTotal;
    final remain = _vendor.remaining;
    final percent = _vendor.paidPercent;
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
                '${AppLang.tr('installments')} · ${_vendor.name}',
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: AppLang.tr('quick_setup'),
                  onPressed: _quickSetup,
                  icon: Icon(
                    Icons.auto_awesome,
                    color: AppTok.accent(context),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'vendor_payments_fab',
              onPressed: () => _openPaymentForm(),
              backgroundColor: AppTok.accent(context),
              foregroundColor: onAccent,
              icon: const Icon(Icons.add),
              label: Text(
                AppLang.tr('payment'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTok.card(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            AppTok.accent(context).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _mini(
                                AppLang.tr('contract'),
                                cost > 0 ? _formatAmount(cost) : '—',
                              ),
                            ),
                            Expanded(
                              child: _mini(
                                AppLang.tr('paid_amount'),
                                _formatAmount(paid),
                                color: const Color(0xFF6FCF97),
                              ),
                            ),
                            Expanded(
                              child: _mini(
                                AppLang.tr('remaining'),
                                _formatAmount(remain),
                                color: remain > 0
                                    ? const Color(0xFFF2C94C)
                                    : const Color(0xFF6FCF97),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: AppTok.background(context),
                            color: AppTok.accent(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_fa((percent * 100).round().toString())}% ${AppLang.tr('percent_paid')}'
                          '${_vendor.unpaidCount > 0 ? ' · ${_fa(_vendor.unpaidCount.toString())} ${AppLang.tr('open_items')}' : ''}',
                          style: TextStyle(
                            color: AppTok.textSoft(context),
                            fontSize: 12,
                          ),
                        ),
                        if (_vendor.nextPaymentDue != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${AppLang.tr('next_due')}: ${_formatDate(_vendor.nextPaymentDue)}',
                            style: TextStyle(
                              color: AppTok.accent(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _payRef.orderBy('dueDate').snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: _payRef.snapshots(),
                          builder: (context, snap2) {
                            if (!snap2.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppTok.accent(context),
                                ),
                              );
                            }
                            final list = snap2.data!.docs
                                .map(VendorPaymentModel.fromDoc)
                                .toList()
                              ..sort((a, b) {
                                if (a.dueDate == null && b.dueDate == null) {
                                  return 0;
                                }
                                if (a.dueDate == null) return 1;
                                if (b.dueDate == null) return -1;
                                return a.dueDate!.compareTo(b.dueDate!);
                              });
                            return _list(list);
                          },
                        );
                      }

                      if (!snap.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTok.accent(context),
                          ),
                        );
                      }

                      final list = snap.data!.docs
                          .map(VendorPaymentModel.fromDoc)
                          .toList();
                      return _list(list);
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

  Widget _mini(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppTok.text(context),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _list(List<VendorPaymentModel> list) {
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 56,
                color: AppTok.accent(context).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 14),
              Text(
                AppLang.tr('no_payments_yet'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLang.tr('payments_empty_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _quickSetup,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTok.accent(context),
                  foregroundColor: onAccent,
                ),
                icon: const Icon(Icons.auto_awesome),
                label: Text(AppLang.tr('create_quick_installments')),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = list[i];
        return _paymentCard(p);
      },
    );
  }

  Widget _paymentCard(VendorPaymentModel p) {
    Color statusColor;
    String statusText;
    if (p.isPaid) {
      statusColor = const Color(0xFF6FCF97);
      statusText = AppLang.tr('status_paid');
    } else if (p.isOverdue) {
      statusColor = AppTok.danger(context);
      statusText = AppLang.tr('status_overdue');
    } else if (p.isDueWithin(7)) {
      statusColor = const Color(0xFFF2C94C);
      statusText = AppLang.tr('status_soon');
    } else {
      statusColor = AppTok.accent(context);
      statusText = AppLang.tr('status_open');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openPaymentForm(payment: p),
        onLongPress: () => _deletePayment(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              InkWell(
                onTap: () => _togglePaid(p),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    p.isPaid ? Icons.check_circle : Icons.schedule,
                    color: statusColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.title,
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${VendorPaymentType.label(p.type)}'
                      '${p.dueDate != null ? ' · ${_formatDate(p.dueDate)}' : ''}',
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 12,
                      ),
                    ),
                    if (p.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        p.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatAmount(p.amount),
                style: TextStyle(
                  color: AppTok.accentSoft(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}