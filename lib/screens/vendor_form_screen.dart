import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/vendor_model.dart';
import '../services/vendor_budget_sync.dart';
import 'vendor_payments_screen.dart';

class VendorFormScreen extends StatefulWidget {
  const VendorFormScreen({
    super.key,
    required this.weddingId,
    this.vendor,
  });

  final String weddingId;
  final VendorModel? vendor;

  bool get isEdit => vendor != null;

  @override
  State<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends State<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _category = VendorCategories.unassigned;
  String _status = VendorStatus.pending;
  bool _addToBudget = false;
  bool _saving = false;
  VendorModel? _liveVendor;

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

  @override
  void initState() {
    super.initState();
    final v = widget.vendor;
    _liveVendor = v;
    if (v != null) {
      _nameCtrl.text = v.name;
      _phoneCtrl.text = v.phone;
      _emailCtrl.text = v.email;
      _websiteCtrl.text = v.website;
      _addressCtrl.text = v.address;
      _costCtrl.text = v.cost > 0 ? v.cost.toInt().toString() : '';
      _noteCtrl.text = v.note;
      _category = v.category;
      _status = v.status;
      _addToBudget = v.addToBudget;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _costCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPayments() async {
    final v = _liveVendor ?? widget.vendor;
    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLang.tr('save_vendor_first_for_payments')),
          backgroundColor: AppTok.card(context),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorPaymentsScreen(
          weddingId: widget.weddingId,
          vendor: v,
        ),
      ),
    );

    final doc = await _ref.doc(v.id).get();
    if (doc.exists && mounted) {
      setState(() => _liveVendor = VendorModel.fromDoc(doc));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_addToBudget) {
      final cost =
          double.tryParse(_costCtrl.text.trim().replaceAll(',', '')) ?? 0;
      if (cost <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLang.tr('budget_cost_required')),
            backgroundColor: AppTok.card(context),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final cost =
          double.tryParse(_costCtrl.text.trim().replaceAll(',', '')) ?? 0;

      final prev = _liveVendor ?? widget.vendor;

      final model = VendorModel(
        id: prev?.id ?? '',
        name: _nameCtrl.text.trim(),
        category: _category,
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        cost: cost,
        addToBudget: _addToBudget,
        status: _status,
        note: _noteCtrl.text.trim(),
        budgetGroupId: prev?.budgetGroupId,
        budgetExpenseId: prev?.budgetExpenseId,
        paidTotal: prev?.paidTotal ?? 0,
        paymentCount: prev?.paymentCount ?? 0,
        unpaidCount: prev?.unpaidCount ?? 0,
        nextPaymentDue: prev?.nextPaymentDue,
      );

      late final String vendorId;

      if (widget.isEdit || prev != null) {
        vendorId = prev!.id;
        await _ref.doc(vendorId).set(
              model.toMap(isUpdate: true),
              SetOptions(merge: true),
            );
      } else {
        final doc = await _ref.add(model.toMap());
        vendorId = doc.id;
      }

      final synced = await VendorBudgetSync.sync(
        weddingId: widget.weddingId,
        vendorId: vendorId,
        vendor: model.copyWith(id: vendorId),
        previousGroupId: prev?.budgetGroupId,
        previousExpenseId: prev?.budgetExpenseId,
      );

      await VendorBudgetSync.refreshPaymentSummary(
        weddingId: widget.weddingId,
        vendorId: vendorId,
      );

      final fresh = await _ref.doc(vendorId).get();
      if (fresh.exists) {
        _liveVendor = VendorModel.fromDoc(fresh);
      }

      if (!mounted) return;

      if (!widget.isEdit && prev == null) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit || prev != null
                ? (_addToBudget
                    ? AppLang.tr('saved_and_synced_budget')
                    : AppLang.tr('saved'))
                : (_addToBudget
                    ? AppLang.tr('vendor_added_linked_budget')
                    : AppLang.tr('vendor_added')),
          ),
          backgroundColor: AppTok.card(context),
        ),
      );

      if (mounted && (widget.isEdit || prev != null)) {
        setState(() {});
      }

      // ignore unused
      synced;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLang.tr('error')}: $e'),
          backgroundColor: AppTok.danger(context),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, {bool required = false}) {
    final dark = AppTok.isDark(context);
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: TextStyle(color: AppTok.textSoft(context)),
      filled: true,
      fillColor: AppTok.card(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: dark ? Colors.white.withValues(alpha: 0.06) : AppTok.border(context),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppTok.accent(context),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.danger(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linked = (_liveVendor ?? widget.vendor)?.isLinkedToBudget == true;
    final v = _liveVendor ?? widget.vendor;
    final canPayments = v != null && v.id.isNotEmpty;
    final dark = AppTok.isDark(context);
    final onAccent = dark ? AppDarkPalette.background : Colors.white;

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
                widget.isEdit
                    ? AppLang.tr('edit_vendor')
                    : AppLang.tr('add_vendor'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTok.accent(context),
                          ),
                        )
                      : Icon(Icons.check, color: AppTok.accent(context)),
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  if (linked) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6FCF97).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              const Color(0xFF6FCF97).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.link,
                            color: Color(0xFF6FCF97),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLang.tr('linked_to_budget_banner'),
                              style: const TextStyle(
                                color: Color(0xFF6FCF97),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // کارت اقساط
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTok.card(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTok.accent(context).withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              color: AppTok.accent(context),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLang.tr('deposit_and_installments'),
                              style: TextStyle(
                                color: AppTok.text(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (v != null && v.hasPayments) ...[
                          Text(
                            '${AppLang.tr('paid_of_total_remaining')} ${_formatAmount(v.paidTotal)} ${AppLang.tr('of')} ${_formatAmount(v.cost)} · ${AppLang.tr('remaining')} ${_formatAmount(v.remaining)}',
                            style: TextStyle(
                              color: AppTok.textSoft(context),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          if (v.nextPaymentDue != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${AppLang.tr('next_due')}: ${_fa(v.nextPaymentDue!.year.toString())}/${_fa(v.nextPaymentDue!.month.toString().padLeft(2, '0'))}/${_fa(v.nextPaymentDue!.day.toString().padLeft(2, '0'))}',
                              style: TextStyle(
                                color: AppTok.accent(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ] else
                          Text(
                            canPayments
                                ? AppLang.tr('no_installments_yet')
                                : AppLang.tr('save_first_then_installments'),
                            style: TextStyle(
                              color: AppTok.textSoft(context),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: canPayments ? _openPayments : _save,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTok.accent(context),
                            side: BorderSide(color: AppTok.accent(context)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            canPayments
                                ? Icons.receipt_long_outlined
                                : Icons.save_outlined,
                          ),
                          label: Text(
                            canPayments
                                ? AppLang.tr('manage_installments_payments')
                                : AppLang.tr('save_continue_installments'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  TextFormField(
                    controller: _nameCtrl,
                    style: TextStyle(color: AppTok.text(context)),
                    textInputAction: TextInputAction.next,
                    decoration:
                        _dec(AppLang.tr('vendor_name'), required: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppLang.tr('enter_name');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    dropdownColor: AppTok.card(context),
                    style:
                        TextStyle(color: AppTok.text(context), fontSize: 14),
                    decoration: _dec(AppLang.tr('category')),
                    items: VendorCategories.ids
                        .map(
                          (id) => DropdownMenuItem(
                            value: id,
                            child: Text(VendorCategories.label(id)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    style: TextStyle(color: AppTok.text(context)),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(AppLang.tr('phone_number')),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCtrl,
                    style: TextStyle(color: AppTok.text(context)),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(AppLang.tr('email')),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _websiteCtrl,
                    style: TextStyle(color: AppTok.text(context)),
                    keyboardType: TextInputType.url,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(AppLang.tr('website')),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressCtrl,
                    style: TextStyle(color: AppTok.text(context)),
                    textInputAction: TextInputAction.next,
                    maxLines: 2,
                    decoration: _dec(AppLang.tr('address')),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _costCtrl,
                    style: TextStyle(color: AppTok.text(context)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: _dec(
                      AppLang.tr('contract_cost_toman'),
                      required: _addToBudget,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: AppTok.card(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppTok.accent(context),
                      activeTrackColor:
                          AppTok.accent(context).withValues(alpha: 0.45),
                      title: Text(
                        AppLang.tr('add_to_budget'),
                        style: TextStyle(
                          color: AppTok.text(context),
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _addToBudget
                            ? AppLang.tr('budget_on_hint')
                            : AppLang.tr('budget_off_hint'),
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          fontSize: 11,
                        ),
                      ),
                      value: _addToBudget,
                      onChanged: (v) => setState(() => _addToBudget = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLang.tr('status'),
                    style: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statusRadio(
                        VendorStatus.booked,
                        AppLang.tr('status_booked'),
                      ),
                      const SizedBox(width: 8),
                      _statusRadio(
                        VendorStatus.pending,
                        AppLang.tr('status_pending'),
                      ),
                      const SizedBox(width: 8),
                      _statusRadio(
                        VendorStatus.rejected,
                        AppLang.tr('status_rejected'),
                      ),
                    ],
                  ),
                  if (_addToBudget) ...[
                    const SizedBox(height: 10),
                    Text(
                      AppLang.tr('budget_installments_hint'),
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _noteCtrl,
                    style: TextStyle(color: AppTok.text(context)),
                    maxLines: 4,
                    decoration: _dec(AppLang.tr('note')),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTok.accent(context),
                        foregroundColor: onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        widget.isEdit
                            ? AppLang.tr('save_changes')
                            : AppLang.tr('register_vendor'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusRadio(String value, String label) {
    final selected = _status == value;
    Color c;
    switch (value) {
      case VendorStatus.booked:
        c = const Color(0xFF6FCF97);
        break;
      case VendorStatus.rejected:
        c = AppTok.danger(context);
        break;
      default:
        c = AppTok.accent(context);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? c.withValues(alpha: 0.15) : AppTok.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? c : AppTok.border(context).withValues(alpha: 0.5),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? c : AppTok.textSoft(context),
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? c : AppTok.textSoft(context),
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}