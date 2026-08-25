import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/wedding_time_header.dart';

class GuestsScreen extends StatefulWidget {
  final String weddingId;

  const GuestsScreen({super.key, required this.weddingId});

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  String searchQuery = '';

  /// all | public_invite | manual | confirmed | pending | declined
  String _filter = 'all';

  CollectionReference get guestsRef => FirebaseFirestore.instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('guests');

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

  Map<String, String> get groupMap => {
        'bride': AppLang.tr('group_bride'),
        'groom': AppLang.tr('group_groom'),
        'bride_family': AppLang.tr('group_bride_family'),
        'groom_family': AppLang.tr('group_groom_family'),
        'friends': AppLang.tr('group_friends'),
        'coworkers': AppLang.tr('group_coworkers'),
        'vip': AppLang.tr('group_vip'),
        'other': AppLang.tr('group_other'),
      };

  Map<String, String> get statusMap => {
        'not_invited': AppLang.tr('status_not_invited'),
        'invited': AppLang.tr('status_invited'),
        'pending': AppLang.tr('status_pending_short'),
        'confirmed': AppLang.tr('status_confirmed'),
        'declined': AppLang.tr('status_declined'),
      };

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF4CD37B);
      case 'invited':
        return const Color(0xFF4DA3FF);
      case 'pending':
        return const Color(0xFFE8A33D);
      case 'declined':
        return const Color(0xFFEF5A7D);
      default:
        return AppTok.textSoft(context);
    }
  }

  bool _isPublicInvite(Map<String, dynamic> data) {
    return (data['rsvpSource'] ?? '').toString() == 'public_invite';
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString();
    final public = _isPublicInvite(data);

    switch (_filter) {
      case 'public_invite':
        return public;
      case 'manual':
        return !public;
      case 'confirmed':
        return status == 'confirmed';
      case 'pending':
        return status == 'pending' || status == 'invited';
      case 'declined':
        return status == 'declined';
      case 'all':
      default:
        return true;
    }
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

  void openGuestForm({DocumentSnapshot? guestDoc}) {
    final data = guestDoc?.data() as Map<String, dynamic>?;

    final nameC = TextEditingController(text: data?['name'] ?? '');
    final phoneC = TextEditingController(text: data?['phone'] ?? '');
    final noteC = TextEditingController(text: data?['note'] ?? '');
    String group = data?['group'] ?? 'bride';
    String status = data?['status'] ?? 'not_invited';
    final isPublic = data != null && _isPublicInvite(data);

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
                            guestDoc == null
                                ? AppLang.tr('add_guest')
                                : AppLang.tr('edit_guest'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTok.text(context),
                            ),
                          ),
                          if (isPublic) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTok.accent(context)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AppLang.tr('public_rsvp_guest_hint'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTok.accent(context),
                                  fontSize: 11.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 15),
                          TextField(
                            controller: nameC,
                            style: TextStyle(color: AppTok.text(context)),
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('guest_name'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: phoneC,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: AppTok.text(context)),
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('phone'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: group,
                            dropdownColor: AppTok.card(context),
                            style: TextStyle(color: AppTok.text(context)),
                            items: groupMap.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setModalState(() => group = v!),
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('group'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: status,
                            dropdownColor: AppTok.card(context),
                            style: TextStyle(color: AppTok.text(context)),
                            items: statusMap.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setModalState(() => status = v!),
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('status'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: noteC,
                            style: TextStyle(color: AppTok.text(context)),
                            maxLines: 2,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                if (nameC.text.trim().isEmpty) return;

                                final payload = <String, dynamic>{
                                  'name': nameC.text.trim(),
                                  'phone': phoneC.text.trim(),
                                  'group': group,
                                  'status': status,
                                  'note': noteC.text.trim(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                };

                                if (guestDoc == null) {
                                  await guestsRef.add({
                                    ...payload,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                } else {
                                  await guestsRef.doc(guestDoc.id).set(
                                        payload,
                                        SetOptions(merge: true),
                                      );
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

  Future<bool> confirmDeleteGuest(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTok.card(context),
        title: Text(
          AppLang.tr('delete_guest'),
          style: TextStyle(color: AppTok.text(context)),
        ),
        content: Text(
          AppLang.tr('delete_guest_confirm').replaceAll('{name}', name),
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
    );
    return confirmed == true;
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
              child: Column(
                children: [
                  Builder(
                    builder: (context) => WeddingTimeHeader(
                      weddingId: widget.weddingId,
                      onMenuPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: guestsRef.orderBy('createdAt').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppTok.accent(context),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        final total = docs.length;
                        final confirmed = docs
                            .where((d) =>
                                (d.data() as Map)['status'] == 'confirmed')
                            .length;
                        final pending = docs.where((d) {
                          final s =
                              (d.data() as Map)['status']?.toString() ?? '';
                          return s == 'pending' || s == 'invited';
                        }).length;
                        final declined = docs
                            .where((d) =>
                                (d.data() as Map)['status'] == 'declined')
                            .length;
                        final publicCount = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return _isPublicInvite(data);
                        }).length;
                        final manualCount = total - publicCount;

                        final filtered = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              (data['name'] ?? '').toString().toLowerCase();
                          if (!name.contains(searchQuery.toLowerCase())) {
                            return false;
                          }
                          return _matchesFilter(data);
                        }).toList();

                        final visibleGroups = groupMap.keys
                            .where(
                              (key) => filtered.any(
                                (doc) => (doc.data() as Map)['group'] == key,
                              ),
                            )
                            .toList();

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLang.tr('guests_title'),
                                  style: TextStyle(
                                    color: AppTok.text(context),
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  AppLang.I.isFa
                                      ? Icons.chevron_left
                                      : Icons.chevron_right,
                                  color: AppTok.textSoft(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    context,
                                    icon: Icons.groups_outlined,
                                    iconColor: AppTok.accent(context),
                                    value: total,
                                    label: AppLang.tr('stat_total'),
                                    selected: _filter == 'all',
                                    onTap: () =>
                                        setState(() => _filter = 'all'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _statCard(
                                    context,
                                    icon: Icons.check_circle_outline,
                                    iconColor: const Color(0xFF4CD37B),
                                    value: confirmed,
                                    label: AppLang.tr('stat_confirmed_short'),
                                    selected: _filter == 'confirmed',
                                    onTap: () => setState(
                                      () => _filter = 'confirmed',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _statCard(
                                    context,
                                    icon: Icons.access_time,
                                    iconColor: const Color(0xFFE8A33D),
                                    value: pending,
                                    label: AppLang.tr('stat_pending_short'),
                                    selected: _filter == 'pending',
                                    onTap: () =>
                                        setState(() => _filter = 'pending'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _statCard(
                                    context,
                                    icon: Icons.cancel_outlined,
                                    iconColor: const Color(0xFFEF5A7D),
                                    value: declined,
                                    label: AppLang.tr('stat_declined_short'),
                                    selected: _filter == 'declined',
                                    onTap: () =>
                                        setState(() => _filter = 'declined'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _sourceChip(
                                    context,
                                    label: AppLang.tr('digital_rsvp'),
                                    value: publicCount,
                                    selected: _filter == 'public_invite',
                                    color: const Color(0xFFB8A9FF),
                                    icon: Icons.mark_email_read_outlined,
                                    onTap: () => setState(
                                      () => _filter = 'public_invite',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _sourceChip(
                                    context,
                                    label: AppLang.tr('manual'),
                                    value: manualCount,
                                    selected: _filter == 'manual',
                                    color: const Color(0xFF56CCF2),
                                    icon: Icons.person_add_alt,
                                    onTap: () =>
                                        setState(() => _filter = 'manual'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTok.card(context),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                style: TextStyle(color: AppTok.text(context)),
                                decoration: InputDecoration(
                                  hintText: AppLang.tr('search_guest_hint'),
                                  hintStyle: TextStyle(
                                    color: AppTok.textSoft(context),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppTok.textSoft(context),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onChanged: (v) =>
                                    setState(() => searchQuery = v),
                              ),
                            ),
                            if (_filter != 'all') ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _filter = 'all'),
                                  icon: Icon(
                                    Icons.filter_alt_off,
                                    size: 16,
                                    color: AppTok.accent(context),
                                  ),
                                  label: Text(
                                    '${AppLang.tr('clear_filter')} · ${_filterLabel()}',
                                    style: TextStyle(
                                      color: AppTok.accent(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (docs.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Center(
                                  child: Text(
                                    AppLang.tr('no_guests_yet'),
                                    style: TextStyle(
                                      color: AppTok.textSoft(context),
                                    ),
                                  ),
                                ),
                              )
                            else if (visibleGroups.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Center(
                                  child: Text(
                                    searchQuery.isNotEmpty
                                        ? AppLang.tr('guest_not_found')
                                        : AppLang.tr('no_guests_for_filter'),
                                    style: TextStyle(
                                      color: AppTok.textSoft(context),
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...visibleGroups.map(
                                (key) =>
                                    _buildGroupCard(context, key, filtered),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'guests_fab',
              backgroundColor: AppTok.accent(context),
              foregroundColor: Colors.white,
              onPressed: () => openGuestForm(),
              child: const Icon(
                Icons.person_add_alt,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  String _filterLabel() {
    switch (_filter) {
      case 'public_invite':
        return AppLang.tr('digital_rsvp');
      case 'manual':
        return AppLang.tr('manual');
      case 'confirmed':
        return AppLang.tr('status_confirmed');
      case 'pending':
        return AppLang.tr('status_pending_short');
      case 'declined':
        return AppLang.tr('status_declined');
      default:
        return AppLang.tr('all');
    }
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required int value,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          selected ? iconColor.withValues(alpha: 0.14) : AppTok.card(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? iconColor.withValues(alpha: 0.55)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(height: 6),
              Text(
                _displayNum(value),
                style: TextStyle(
                  color: selected ? iconColor : AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? iconColor : AppTok.textSoft(context),
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceChip(
    BuildContext context, {
    required String label,
    required int value,
    required bool selected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? color.withValues(alpha: 0.15) : AppTok.card(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? color : AppTok.text(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_displayNum(value)}${AppLang.tr('guest_count_suffix')}',
                      style: TextStyle(
                        color: selected
                            ? color.withValues(alpha: 0.9)
                            : AppTok.textSoft(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    String groupKey,
    List<QueryDocumentSnapshot> filtered,
  ) {
    final groupGuests = filtered
        .where((doc) => (doc.data() as Map)['group'] == groupKey)
        .toList();
    final title = groupMap[groupKey] ?? groupKey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(
                  groupKey == 'vip' ? Icons.star : Icons.groups_outlined,
                  color: AppTok.accent(context),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  _displayNum(groupGuests.length),
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: AppTok.border(context).withValues(alpha: 0.5),
            height: 1,
          ),
          ...groupGuests.asMap().entries.expand((entry) {
            final index = entry.key + 1;
            final doc = entry.value;
            final isLast = entry.key == groupGuests.length - 1;

            return [
              _buildGuestRow(context, doc, index),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: AppTok.border(context).withValues(alpha: 0.35),
                    height: 1,
                  ),
                ),
            ];
          }),
        ],
      ),
    );
  }

  Widget _buildGuestRow(
    BuildContext context,
    QueryDocumentSnapshot doc,
    int index,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['name'] ?? '').toString();
    final status = (data['status'] ?? 'not_invited').toString();
    final statusLabel = statusMap[status] ?? '';
    final color = _statusColor(context, status);
    final isPublic = _isPublicInvite(data);

    return Dismissible(
      key: ValueKey(doc.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDeleteGuest(name),
      onDismissed: (_) async {
        await guestsRef.doc(doc.id).delete();
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(Icons.delete_outline, color: AppTok.danger(context)),
      ),
      child: InkWell(
        onTap: () => openGuestForm(guestDoc: doc),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTok.accent(context).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _displayNum(index),
                  style: TextStyle(
                    color: AppTok.accent(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontSize: 13,
                      ),
                    ),
                    if (isPublic) ...[
                      const SizedBox(height: 2),
                      Text(
                        AppLang.tr('from_digital_invite'),
                        style: const TextStyle(
                          color: Color(0xFFB8A9FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppTok.textSoft(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}