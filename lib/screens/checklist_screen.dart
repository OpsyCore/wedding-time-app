import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/wedding_progress_bar.dart';
import '../widgets/wedding_time_header.dart';

enum _StatusFilter { all, pending, done }

/// چند کار اول هر ماه به‌صورت پیش‌فرض در چک‌لیست باشد
const int kDefaultVisiblePerGroup = 3;

class ChecklistScreen extends StatefulWidget {
  final String weddingId;

  const ChecklistScreen({super.key, required this.weddingId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> tasks = [];
  String searchQuery = '';
  bool isLoading = true;
  _StatusFilter statusFilter = _StatusFilter.all;

  final Set<String> expandedGroups = {};
  bool _expandedInitialized = false;

  /// کلید ذخیره‌شده در Firestore (با defaultTasks هم‌خوان) — عوض نشود
  final List<String> groups = const [
    'بیش از ۱۲ ماه مانده',
    '۹ تا ۱۱ ماه مانده',
    '۶ تا ۸ ماه مانده',
    '۳ تا ۵ ماه مانده',
    '۲ ماه مانده',
    '۱ ماه مانده',
    '۲ هفته مانده',
    'هفته آخر',
  ];

  CollectionReference get ref => FirebaseFirestore.instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('checklist');

  String _groupLabel(String key) {
    const map = {
      'بیش از ۱۲ ماه مانده': 'cl_g_12plus',
      '۹ تا ۱۱ ماه مانده': 'cl_g_9_11',
      '۶ تا ۸ ماه مانده': 'cl_g_6_8',
      '۳ تا ۵ ماه مانده': 'cl_g_3_5',
      '۲ ماه مانده': 'cl_g_2m',
      '۱ ماه مانده': 'cl_g_1m',
      '۲ هفته مانده': 'cl_g_2w',
      'هفته آخر': 'cl_g_last_week',
    };
    final trKey = map[key];
    return trKey != null ? AppLang.tr(trKey) : key;
  }

  /// عنوان نمایشی — titleKey اولویت دارد (تغییر زبان زنده)
  String _taskTitle(Map<String, dynamic> t) {
    final key = t['titleKey']?.toString().trim() ?? '';
    if (key.isNotEmpty) {
      final tr = AppLang.tr(key);
      if (tr != key) return tr;
    }
    return (t['title'] ?? '').toString();
  }

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  bool _isInChecklist(Map<String, dynamic> t) {
    if (!t.containsKey('inChecklist')) return true;
    return t['inChecklist'] == true;
  }

  bool _isSuggestion(Map<String, dynamic> t) => !_isInChecklist(t);

  Future<void> loadTasks() async {
    final snapshot = await ref.get();

    if (snapshot.docs.isEmpty) {
      await seedDefaultTasks();
      await loadTasks();
      return;
    }

    if (!mounted) return;
    setState(() {
      tasks = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data() as Map);
        data['id'] = d.id;
        return data;
      }).toList();
      isLoading = false;
    });
  }

  Future<void> seedDefaultTasks() async {
    final byGroup = <String, List<Map<String, dynamic>>>{};
    for (final raw in defaultTasks) {
      final g = (raw['group'] ?? groups.first).toString();
      byGroup.putIfAbsent(g, () => []).add(Map<String, dynamic>.from(raw));
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final group in groups) {
      final list = byGroup[group] ?? [];
      for (var i = 0; i < list.length; i++) {
        final task = Map<String, dynamic>.from(list[i]);
        final titleKey = (task['titleKey'] ?? '').toString();
        task['done'] = false;
        task['inChecklist'] = i < kDefaultVisiblePerGroup;
        task['financial'] = task['financial'] == true;
        task['desc'] = (task['desc'] ?? '').toString();
        task['group'] = group;
        if (titleKey.isNotEmpty) {
          task['titleKey'] = titleKey;
          task['title'] = AppLang.tr(titleKey);
        } else {
          task['title'] = (task['title'] ?? '').toString();
        }
        task.remove('titleKey'); // keep below
        // titleKey را نگه دار برای i18n نمایش
        if (titleKey.isNotEmpty) task['titleKey'] = titleKey;
        batch.set(ref.doc(), task);
      }
    }

    for (final entry in byGroup.entries) {
      if (groups.contains(entry.key)) continue;
      for (var i = 0; i < entry.value.length; i++) {
        final task = Map<String, dynamic>.from(entry.value[i]);
        final titleKey = (task['titleKey'] ?? '').toString();
        task['done'] = false;
        task['inChecklist'] = i < kDefaultVisiblePerGroup;
        task['financial'] = task['financial'] == true;
        task['desc'] = (task['desc'] ?? '').toString();
        if (titleKey.isNotEmpty) {
          task['titleKey'] = titleKey;
          task['title'] = AppLang.tr(titleKey);
        }
        batch.set(ref.doc(), task);
      }
    }

    await batch.commit();
  }

  Future<void> addTask(Map<String, dynamic> taskData) async {
    final payload = Map<String, dynamic>.from(taskData);
    payload['inChecklist'] = payload['inChecklist'] ?? true;
    payload['done'] = payload['done'] ?? false;
    final doc = await ref.add(payload);
    payload['id'] = doc.id;
    setState(() => tasks.add(payload));
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    final index = tasks.indexWhere((t) => t['id'] == id);
    if (index == -1) return;

    final merged = {...tasks[index], ...data};
    // اگر کاربر title را دستی عوض کرد، titleKey را بردار تا هاردکد نشود
    if (data.containsKey('title') && !data.containsKey('titleKey')) {
      merged.remove('titleKey');
    }
    setState(() => tasks[index] = merged);
    await ref.doc(id).set(merged, SetOptions(merge: true));
  }

  Future<void> deleteTask(String id) async {
    await ref.doc(id).delete();
    setState(() => tasks.removeWhere((t) => t['id'] == id));
  }

  Future<void> addFromSuggestions(Map<String, dynamic> task) async {
    await updateTask(task['id'], {
      'inChecklist': true,
      'done': false,
    });
  }

  Future<void> moveToSuggestions(Map<String, dynamic> task) async {
    await updateTask(task['id'], {
      'inChecklist': false,
      'done': false,
    });
  }

  Future<void> resetChecklist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTok.card(context),
        title: Text(
          AppLang.tr('reset_checklist'),
          style: TextStyle(color: AppTok.text(context)),
        ),
        content: Text(
          AppLang.tr('reset_checklist_body'),
          style: TextStyle(color: AppTok.textSoft(context), height: 1.5),
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
              AppLang.tr('reset'),
              style: TextStyle(color: AppTok.danger(context)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => isLoading = true);
      final docs = await ref.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await seedDefaultTasks();
      await loadTasks();
    }
  }

  Future<bool> confirmMoveToSuggestions(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTok.card(context),
        title: Text(
          AppLang.tr('move_to_suggestions'),
          style: TextStyle(color: AppTok.text(context)),
        ),
        content: Text(
          AppLang.tr('move_to_suggestions_body').replaceAll(
            '{title}',
            _taskTitle(task),
          ),
          style: TextStyle(color: AppTok.textSoft(context), height: 1.45),
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
              AppLang.tr('move_to_suggestions_action'),
              style: TextStyle(color: AppTok.accent(context)),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> confirmDeleteForever(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTok.card(context),
        title: Text(
          AppLang.tr('delete_forever'),
          style: TextStyle(color: AppTok.text(context)),
        ),
        content: Text(
          AppLang.tr('delete_forever_body').replaceAll(
            '{title}',
            _taskTitle(task),
          ),
          style: TextStyle(color: AppTok.textSoft(context), height: 1.45),
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
              AppLang.tr('delete_forever'),
              style: TextStyle(color: AppTok.danger(context)),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void openSuggestions(String group) {
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
              child: StatefulBuilder(
                builder: (context, setModal) {
                  final suggestions = tasks
                      .where((t) => t['group'] == group && _isSuggestion(t))
                      .toList();

                  return DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.62,
                    minChildSize: 0.4,
                    maxChildSize: 0.92,
                    builder: (context, scrollController) {
                      return Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTok.textSoft(context)
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLang.tr('suggestions'),
                                        style: TextStyle(
                                          color: AppTok.text(context),
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLang.tr('suggestions_sheet_hint'),
                                        style: TextStyle(
                                          color: AppTok.textSoft(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.close,
                                    color: AppTok.textSoft(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTok.accent(context)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _groupLabel(group),
                                style: TextStyle(
                                  color: AppTok.accent(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: suggestions.isEmpty
                                ? Center(
                                    child: Text(
                                      AppLang.tr('no_more_suggestions'),
                                      style: TextStyle(
                                        color: AppTok.textSoft(context),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      28,
                                    ),
                                    itemCount: suggestions.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final t = suggestions[index];
                                      final financial = t['financial'] == true;
                                      return Material(
                                        color: AppTok.background(context),
                                        borderRadius: BorderRadius.circular(14),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          onTap: () async {
                                            await addFromSuggestions(t);
                                            setModal(() {});
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: AppTok.accent(
                                                      context,
                                                    ).withValues(
                                                      alpha: 0.15,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.add,
                                                    color:
                                                        AppTok.accent(context),
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        _taskTitle(t),
                                                        style: TextStyle(
                                                          color: AppTok.text(
                                                            context,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 13.5,
                                                        ),
                                                      ),
                                                      if ((t['desc'] ?? '')
                                                          .toString()
                                                          .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                            top: 3,
                                                          ),
                                                          child: Text(
                                                            t['desc']
                                                                .toString(),
                                                            style: TextStyle(
                                                              color: AppTok
                                                                  .textSoft(
                                                                context,
                                                              ),
                                                              fontSize: 11.5,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (financial)
                                                  const Text(
                                                    '💰',
                                                    style:
                                                        TextStyle(fontSize: 14),
                                                  ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  AppLang.tr('add'),
                                                  style: TextStyle(
                                                    color:
                                                        AppTok.accent(context),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() {});
    });
  }

  void openTaskForm({Map<String, dynamic>? task}) {
    final titleController =
        TextEditingController(text: task == null ? '' : _taskTitle(task));
    final descController = TextEditingController(text: task?['desc'] ?? '');

    String selectedGroup = task?['group'] ?? groups.first;
    bool isFinancial = task?['financial'] ?? false;

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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            task == null
                                ? AppLang.tr('add_task')
                                : AppLang.tr('edit_task'),
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
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('task_title'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descController,
                            style: TextStyle(color: AppTok.text(context)),
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('task_desc'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: selectedGroup,
                            dropdownColor: AppTok.card(context),
                            style: TextStyle(color: AppTok.text(context)),
                            items: groups
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(_groupLabel(g)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => selectedGroup = value);
                              }
                            },
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('time_group'),
                            ),
                          ),
                          Material(
                            color: AppTok.card(context),
                            child: SwitchListTile(
                              value: isFinancial,
                              activeThumbColor: AppTok.accent(context),
                              activeTrackColor: AppTok.accent(context)
                                  .withValues(alpha: 0.45),
                              onChanged: (v) =>
                                  setModalState(() => isFinancial = v),
                              title: Text(
                                AppLang.tr('is_financial'),
                                style: TextStyle(color: AppTok.text(context)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                if (titleController.text.trim().isEmpty) return;

                                final data = <String, dynamic>{
                                  'title': titleController.text.trim(),
                                  'desc': descController.text.trim(),
                                  'group': selectedGroup,
                                  'done': task?['done'] ?? false,
                                  'financial': isFinancial,
                                  'inChecklist': true,
                                };

                                if (task == null) {
                                  await addTask(data);
                                } else {
                                  data['id'] = task['id'];
                                  // ویرایش دستی → titleKey پاک شود
                                  await updateTask(task['id'], {
                                    ...data,
                                    'titleKey': FieldValue.delete(),
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
                          if (task != null) ...[
                            const SizedBox(height: 8),
                            if (_isInChecklist(task))
                              TextButton.icon(
                                onPressed: () async {
                                  await moveToSuggestions(task);
                                  if (context.mounted) Navigator.pop(context);
                                },
                                icon: Icon(
                                  Icons.lightbulb_outline,
                                  size: 18,
                                  color: AppTok.accent(context),
                                ),
                                label: Text(
                                  AppLang.tr('move_to_suggestions'),
                                  style: TextStyle(
                                    color: AppTok.accent(context),
                                  ),
                                ),
                              ),
                            TextButton.icon(
                              onPressed: () async {
                                final ok = await confirmDeleteForever(task);
                                if (!ok) return;
                                await deleteTask(task['id']);
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppTok.danger(context),
                              ),
                              label: Text(
                                AppLang.tr('delete_forever'),
                                style: TextStyle(color: AppTok.danger(context)),
                              ),
                            ),
                          ],
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        if (isLoading) {
          return Scaffold(
            backgroundColor: AppTok.background(context),
            body: Center(
              child: CircularProgressIndicator(color: AppTok.accent(context)),
            ),
          );
        }

        final activeTasks = tasks.where(_isInChecklist).toList();

        final matchesSearchAndStatus = activeTasks.where((t) {
          final matchesSearch = _taskTitle(t)
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
          final matchesStatus = switch (statusFilter) {
            _StatusFilter.all => true,
            _StatusFilter.pending => t['done'] != true,
            _StatusFilter.done => t['done'] == true,
          };
          return matchesSearch && matchesStatus;
        }).toList();

        final doneCount = activeTasks.where((t) => t['done'] == true).length;
        final pendingCount = activeTasks.length - doneCount;

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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppLang.tr('checklist_title'),
                                  style: TextStyle(
                                    color: AppTok.text(context),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                color: AppTok.card(context),
                                icon: Icon(
                                  Icons.more_vert,
                                  color: AppTok.textSoft(context),
                                ),
                                onSelected: (v) {
                                  if (v == 'reset') resetChecklist();
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'reset',
                                    child: Text(
                                      AppLang.tr('reset_checklist'),
                                      style: TextStyle(
                                        color: AppTok.text(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_displayNum(doneCount)} ${AppLang.tr('of')} ${_displayNum(activeTasks.length)} ${AppLang.tr('tasks_done_label')}'
                              ' · ${_displayNum(tasks.where(_isSuggestion).length)} ${AppLang.tr('suggestions_count_label')}',
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildFilterChips(
                            context,
                            doneCount,
                            pendingCount,
                            activeTasks.length,
                          ),
                          const SizedBox(height: 14),
                          _buildSearch(context),
                          const SizedBox(height: 14),
                          Expanded(
                            child: _buildGroupsList(
                              context,
                              matchesSearchAndStatus,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildProgressFooter(
                            context,
                            doneCount: doneCount,
                            total: activeTasks.length,
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'checklist_fab',
              backgroundColor: AppTok.accent(context),
              foregroundColor: Colors.white,
              onPressed: () => openTaskForm(),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    int doneCount,
    int pendingCount,
    int totalActive,
  ) {
    Widget chip(String label, _StatusFilter value) {
      final isActive = statusFilter == value;
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: GestureDetector(
          onTap: () => setState(() => statusFilter = value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isActive ? AppTok.accent(context) : AppTok.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTok.textSoft(context),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            '${AppLang.tr('all')} (${_displayNum(totalActive)})',
            _StatusFilter.all,
          ),
          chip(
            '${AppLang.tr('filter_not_done')} (${_displayNum(pendingCount)})',
            _StatusFilter.pending,
          ),
          chip(
            '${AppLang.tr('filter_done')} (${_displayNum(doneCount)})',
            _StatusFilter.done,
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        style: TextStyle(color: AppTok.text(context)),
        decoration: InputDecoration(
          hintText: AppLang.tr('search_task_hint'),
          hintStyle: TextStyle(color: AppTok.textSoft(context)),
          prefixIcon: Icon(Icons.search, color: AppTok.textSoft(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (v) => setState(() => searchQuery = v),
      ),
    );
  }

  Widget _buildGroupsList(
    BuildContext context,
    List<Map<String, dynamic>> filteredTasks,
  ) {
    if (!_expandedInitialized && groups.isNotEmpty) {
      expandedGroups.add(groups.first);
      _expandedInitialized = true;
    }

    final visibleGroups = groups.where((g) {
      final hasActive = filteredTasks.any((t) => t['group'] == g);
      final hasSuggestions =
          tasks.any((t) => t['group'] == g && _isSuggestion(t));
      if (searchQuery.isEmpty && statusFilter == _StatusFilter.all) {
        return hasActive || hasSuggestions;
      }
      return hasActive;
    }).toList();

    if (visibleGroups.isEmpty) {
      return Center(
        child: Text(
          AppLang.tr('task_not_found'),
          style: TextStyle(color: AppTok.textSoft(context)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: visibleGroups.map((group) {
        final groupTasks =
            filteredTasks.where((t) => t['group'] == group).toList();
        final groupActive =
            tasks.where((t) => t['group'] == group && _isInChecklist(t));
        final groupTotal = groupActive.length;
        final groupDone = groupActive.where((t) => t['done'] == true).length;
        final suggestionCount =
            tasks.where((t) => t['group'] == group && _isSuggestion(t)).length;
        final isExpanded = expandedGroups.contains(group);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      expandedGroups.remove(group);
                    } else {
                      expandedGroups.add(group);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTok.textSoft(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _groupLabel(group),
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppTok.accent(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_displayNum(groupDone)}/${_displayNum(groupTotal)}',
                          style: TextStyle(
                            color: AppTok.accent(context),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                if (groupTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      AppLang.tr('no_active_tasks_month'),
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ...groupTasks.map((t) => _buildTaskRow(context, t)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                  child: OutlinedButton.icon(
                    onPressed: () => openSuggestions(group),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTok.accent(context),
                      side: BorderSide(
                        color: AppTok.accent(context).withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.lightbulb_outline, size: 18),
                    label: Text(
                      suggestionCount > 0
                          ? '${AppLang.tr('suggestions_plus')} (${_displayNum(suggestionCount)})'
                          : AppLang.tr('suggestions_plus'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // TASK 1 — premium checklist progress footer
  Widget _buildProgressFooter(
    BuildContext context, {
    required int doneCount,
    required int total,
  }) {
    return ChecklistProgressFooter(
      doneCount: doneCount,
      total: total,
    );
  }

  Widget _buildTaskRow(BuildContext context, Map<String, dynamic> task) {
    final hasDesc = (task['desc'] ?? '').toString().isNotEmpty;
    final isDone = task['done'] == true;

    return Dismissible(
      key: ValueKey(task['id'] ?? task.hashCode),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmMoveToSuggestions(task),
      onDismissed: (_) => moveToSuggestions(task),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppTok.accent(context).withValues(alpha: 0.12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, color: AppTok.accent(context)),
            const SizedBox(width: 8),
            Text(
              AppLang.tr('suggestions'),
              style: TextStyle(
                color: AppTok.accent(context),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: () => openTaskForm(task: task),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  updateTask(task['id'], {'done': !isDone});
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isDone ? AppTok.accent(context) : Colors.transparent,
                    border: Border.all(
                      color: isDone
                          ? AppTok.accent(context)
                          : AppTok.textSoft(context),
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
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
                            _taskTitle(task),
                            style: TextStyle(
                              color: isDone
                                  ? AppTok.textSoft(context)
                                  : AppTok.text(context),
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (task['financial'] == true)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Text('💰', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    if (hasDesc)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          task['desc'],
                          style: TextStyle(
                            color: AppTok.textSoft(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                AppLang.I.isFa ? Icons.chevron_left : Icons.chevron_right,
                color: AppTok.textSoft(context),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// seed پیش‌فرض — group = کلید legacy فارسی · titleKey = AppLang
final List<Map<String, dynamic>> defaultTasks = [
  {'titleKey': 'cl_t_set_budget', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_set_date', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_proposal', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_baleh_boroon', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_book_venue', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_guest_list_draft', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_book_photo', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_theme_colors', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_family_agree', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_mehrieh', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_planner', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_joint_account', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_city', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_compare_venues', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_book_music', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_bridal_party', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_find_home', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_trousseau_plan', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_style', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_customs', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_priorities', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_cost_share', 'desc': '', 'group': 'بیش از ۱۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_book_catering', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_bride_dress', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_book_makeup', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_sofreh_designer', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_groom_suit', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_book_studio', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_notify_guests', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_finalize_guests', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_book_car', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_honeymoon', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_rings_jewelry', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_book_flowers', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_menu', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_guest_hotels', 'desc': '', 'group': '۹ تا ۱۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_order_invites', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_order_cake', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_medical_tests', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_officiant', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_counseling', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_ceremony_outfits', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_ceremony_location', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_sofreh_flowers', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_av', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_trousseau_shop', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_dress_fitting1', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_favors', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_playlist', 'desc': '', 'group': '۶ تا ۸ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_finalize_menu', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_finalize_sofreh', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_buy_rings', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_confirm_guest_count', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_food_tasting', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_makeup_trial', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_move_trousseau', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_confirm_photo_plan', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_finalize_music', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_buy_ceremony_clothes', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_coord_day', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_seating_plan', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_sofreh_items', 'desc': '', 'group': '۳ تا ۵ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_legal_marriage', 'desc': '', 'group': '۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_final_fitting', 'desc': '', 'group': '۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_confirm_venue_catering', 'desc': '', 'group': '۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_henna_coord', 'desc': '', 'group': '۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_bouquet', 'desc': '', 'group': '۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_couple_gifts', 'desc': '', 'group': '۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_finalize_honeymoon', 'desc': '', 'group': '۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_guest_seating_prep', 'desc': '', 'group': '۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_coord_party', 'desc': '', 'group': '۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_confirm_car', 'desc': '', 'group': '۲ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_patakhti', 'desc': '', 'group': '۲ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_confirm_all_vendors', 'desc': '', 'group': '۱ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_beauty_care', 'desc': '', 'group': '۱ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_day_timeline', 'desc': '', 'group': '۱ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_prep_payments', 'desc': '', 'group': '۱ ماه مانده', 'financial': true},
  {'titleKey': 'cl_t_final_outfits', 'desc': '', 'group': '۱ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_final_officiant', 'desc': '', 'group': '۱ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_day_essentials', 'desc': '', 'group': '۱ ماه مانده', 'financial': false},
  {'titleKey': 'cl_t_final_guest_calls', 'desc': '', 'group': '۲ هفته مانده', 'financial': false},
  {'titleKey': 'cl_t_prep_clothes', 'desc': '', 'group': '۲ هفته مانده', 'financial': false},
  {'titleKey': 'cl_t_final_sofreh', 'desc': '', 'group': '۲ هفته مانده', 'financial': false},
  {'titleKey': 'cl_t_cash_ready', 'desc': '', 'group': '۲ هفته مانده', 'financial': true},
  {'titleKey': 'cl_t_henna_party', 'desc': '', 'group': 'هفته آخر', 'financial': false},
  {'titleKey': 'cl_t_salon_day', 'desc': '', 'group': 'هفته آخر', 'financial': false},
  {'titleKey': 'cl_t_wedding_day', 'desc': '', 'group': 'هفته آخر', 'financial': false},
  {'titleKey': 'cl_t_pack_honeymoon', 'desc': '', 'group': 'هفته آخر', 'financial': false},
  {'titleKey': 'cl_t_rest', 'desc': '', 'group': 'هفته آخر', 'financial': false},
  {'titleKey': 'cl_t_handoff_docs', 'desc': '', 'group': 'هفته آخر', 'financial': false},
];