import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.weddingId,
  });

  final String weddingId;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _service;
  List<AppNotification> _smart = [];
  bool _smartLoading = true;

  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  String fa(String s) {
    if (!AppLang.I.isFa) return s;
    return s.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _fa[i] : c;
    }).join();
  }

  String _displayNum(Object n) {
    final s = n.toString();
    return AppLang.I.isFa ? fa(s) : s;
  }

  @override
  void initState() {
    super.initState();
    _service = NotificationService(widget.weddingId);
    _loadSmart();
  }

  Future<void> _loadSmart() async {
    setState(() => _smartLoading = true);
    try {
      await _service.syncEventNotifications();
      final list = await _service.buildSmartReminders();
      if (!mounted) return;
      setState(() {
        _smart = list;
        _smartLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _smart = [];
        _smartLoading = false;
      });
    }
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return AppLang.tr('just_now');
    if (diff.inMinutes < 60) {
      return '${_displayNum(diff.inMinutes)} ${AppLang.tr('minutes_ago')}';
    }
    if (diff.inHours < 24) {
      return '${_displayNum(diff.inHours)} ${AppLang.tr('hours_ago')}';
    }
    if (diff.inDays < 7) {
      return '${_displayNum(diff.inDays)} ${AppLang.tr('days_ago')}';
    }

    final t =
        '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    return _displayNum(t);
  }

  Future<void> _onTap(AppNotification n) async {
    if (!n.isSmart && !n.read) {
      await _service.markRead(n.id);
    }
  }

  Future<void> _onMenuSelected(String value) async {
    if (value == 'read') {
      await _service.markAllRead();
      return;
    }

    if (value == 'clear') {
      if (!mounted) return;

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: AppLang.I.direction,
          child: AlertDialog(
            backgroundColor: AppTok.card(ctx),
            title: Text(
              AppLang.tr('clear_notifications'),
              style: TextStyle(color: AppTok.text(ctx)),
            ),
            content: Text(
              AppLang.tr('clear_notifications_body'),
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
                  AppLang.tr('clear'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      );

      if (ok == true) {
        await _service.clearAll();
      }
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
            appBar: AppBar(
              backgroundColor: AppTok.background(context),
              iconTheme: IconThemeData(color: AppTok.text(context)),
              title: Text(
                AppLang.tr('notifications'),
                style: TextStyle(color: AppTok.text(context)),
              ),
              actions: [
                IconButton(
                  tooltip: AppLang.tr('refresh_reminders'),
                  onPressed: _loadSmart,
                  icon: Icon(Icons.refresh, color: AppTok.textSoft(context)),
                ),
                PopupMenuButton<String>(
                  color: AppTok.card(context),
                  icon: Icon(Icons.more_vert, color: AppTok.textSoft(context)),
                  onSelected: _onMenuSelected,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'read',
                      child: Text(
                        AppLang.tr('mark_all_read'),
                        style: TextStyle(color: AppTok.text(context)),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear',
                      child: Text(
                        AppLang.tr('clear_stored_notifications'),
                        style: TextStyle(color: AppTok.text(context)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: StreamBuilder<List<AppNotification>>(
              stream: _service.watchStored(),
              builder: (context, snap) {
                final stored = snap.data ?? [];
                final items = <AppNotification>[..._smart, ...stored];
                items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                final unreadStored = stored.where((e) => !e.read).length;

                if (_smartLoading && !snap.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTok.accent(context),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTok.accent(context),
                  backgroundColor: AppTok.card(context),
                  onRefresh: _loadSmart,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppTok.card(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTok.accent(context).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '${AppLang.tr('notif_info_body')}\n'
                          '${_displayNum(unreadStored)} ${AppLang.tr('notif_unread_count')} · ${_displayNum(_smart.length)} ${AppLang.tr('notif_smart_count')}',
                          style: TextStyle(
                            color: AppTok.textSoft(context),
                            height: 1.55,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 56,
                                color: AppTok.textSoft(context)
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppLang.tr('no_notifications_yet'),
                                style: TextStyle(
                                  color: AppTok.textSoft(context),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...items.map(_tile),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _tile(AppNotification n) {
    final unread = !n.read && !n.isSmart;

    return Dismissible(
      key: ValueKey(n.id),
      direction:
          n.isSmart ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => _service.delete(n.id),
      background: Container(
        alignment:
            AppLang.I.isFa ? Alignment.centerLeft : Alignment.centerRight,
        padding: EdgeInsets.only(
          left: AppLang.I.isFa ? 20 : 0,
          right: AppLang.I.isFa ? 0 : 20,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: InkWell(
        onTap: () => _onTap(n),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(14),
            border: unread
                ? Border.all(
                    color: AppTok.accent(context).withValues(alpha: 0.35),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTok.accent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(n.icon, color: AppTok.accent(context), size: 22),
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
                            n.title,
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontWeight:
                                  unread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (n.isSmart)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTok.accent(context)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLang.tr('reminder'),
                              style: TextStyle(
                                color: AppTok.accent(context),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTok.accent(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${n.typeLabel} · ${_timeLabel(n.createdAt)}',
                      style: TextStyle(
                        color:
                            AppTok.textSoft(context).withValues(alpha: 0.85),
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
}