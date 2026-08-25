import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_config.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/guest_media_model.dart';
import '../services/disposable_camera_service.dart';
import 'guest_camera_screen.dart';

/// مدیریت حرفه‌ای دوربین مهمان + تأیید عکس‌ها
class CameraManageScreen extends StatefulWidget {
  const CameraManageScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<CameraManageScreen> createState() => _CameraManageScreenState();
}

class _CameraManageScreenState extends State<CameraManageScreen> {
  late final DisposableCameraService _service;

  final _albumC = TextEditingController();
  final _maxShotsC = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  bool _enabled = true;
  bool _autoApprove = false;
  int _maxShots = 30;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _service = DisposableCameraService(widget.weddingId);
    _load();
  }

  @override
  void dispose() {
    _albumC.dispose();
    _maxShotsC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await _service.ensureSettings();
      final album = await _service.getExternalAlbumUrl();
      if (!mounted) return;
      setState(() {
        _enabled = s.enabled;
        _autoApprove = s.autoApprove;
        _maxShots = s.maxShotsPerGuest;
        _maxShotsC.text = '${s.maxShotsPerGuest}';
        _albumC.text = album;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('${AppLang.tr('load_error')}: $e', error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: AppTok.text(context))),
        backgroundColor:
            error ? AppTok.danger(context) : AppTok.card(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final parsed = int.tryParse(_maxShotsC.text.trim());
    final maxShots =
        (parsed == null || parsed < 1) ? 30 : (parsed > 200 ? 200 : parsed);

    setState(() => _saving = true);
    try {
      final album = _albumC.text.trim();
      final model = CameraSettingsModel(
        enabled: _enabled,
        maxShotsPerGuest: maxShots,
        maxVideosPerGuest: 0,
        autoApprove: _autoApprove,
        externalAlbumUrl: album,
      );

      await _service.updateSettings(model);
      await _service.syncAlbumToGallerySettings(album);

      if (!mounted) return;
      setState(() {
        _maxShots = maxShots;
        _maxShotsC.text = '$maxShots';
      });
      _toast(AppLang.tr('settings_saved'));
    } catch (e) {
      _toast('${AppLang.tr('save_failed')}: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAlbum() async {
    final ok = await _service.openExternalAlbum(_albumC.text.trim());
    if (!ok) _toast(AppLang.tr('album_link_invalid'), error: true);
  }

  Future<void> _copyAlbum() async {
    final t = _albumC.text.trim();
    if (t.isEmpty) {
      _toast(AppLang.tr('no_link'), error: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: t));
    _toast(AppLang.tr('link_copied'));
  }

  void _previewGuest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuestCameraScreen(
          weddingId: widget.weddingId,
          isHostPreview: true,
        ),
      ),
    );
  }

  Future<void> _setStatus(GuestMediaModel item, String status) async {
    try {
      await _service.setStatus(item.id, status);
      _toast(
        status == 'approved'
            ? AppLang.tr('approved_toast')
            : AppLang.tr('rejected_toast'),
      );
    } catch (e) {
      _toast('${AppLang.tr('error')}: $e', error: true);
    }
  }

  Future<void> _delete(GuestMediaModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(ctx),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            AppLang.tr('delete_photo_title'),
            style: TextStyle(
              color: AppTok.text(ctx),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppLang.tr('delete_photo_body'),
            style: TextStyle(color: AppTok.textSoft(ctx), height: 1.4),
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
      await _service.deleteMedia(item);
      _toast(AppLang.tr('deleted'));
    } catch (e) {
      _toast('${AppLang.tr('delete_failed')}: $e', error: true);
    }
  }

  Future<void> _approveAllPending(List<GuestMediaModel> pending) async {
    if (pending.isEmpty) {
      _toast(AppLang.tr('no_pending_photos'));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(ctx),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            AppLang.tr('approve_all_title'),
            style: TextStyle(color: AppTok.text(ctx)),
          ),
          content: Text(
            '${pending.length} ${AppLang.tr('approve_all_body')}',
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
                AppLang.tr('approve_all'),
                style: TextStyle(color: AppTok.accent(ctx)),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      for (final m in pending) {
        await _service.setStatus(m.id, 'approved');
      }
      _toast(AppLang.tr('all_approved_toast'));
    } catch (e) {
      _toast('${AppLang.tr('error')}: $e', error: true);
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
            body: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTok.accent(context),
                    ),
                  )
                : NestedScrollView(
                    headerSliverBuilder: (context, _) => [
                      SliverAppBar(
                        pinned: true,
                        elevation: 0,
                        backgroundColor: AppTok.background(context),
                        surfaceTintColor: Colors.transparent,
                        leading: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_forward,
                            color: AppTok.text(context),
                          ),
                        ),
                        centerTitle: true,
                        title: Column(
                          children: [
                            Text(
                              AppLang.tr('manage_images'),
                              style: TextStyle(
                                color: AppTok.text(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppLang.tr('guest_camera_sub'),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 11,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          IconButton(
                            tooltip: AppLang.tr('preview_guest'),
                            onPressed: _previewGuest,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTok.card(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.visibility_outlined,
                                color: AppTok.accent(context),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ],
                    body: StreamBuilder<List<GuestMediaModel>>(
                      stream: _service.watchMedia(status: 'all'),
                      builder: (context, snap) {
                        final all = snap.data ?? [];
                        final pending = all
                            .where((m) => m.isPending)
                            .toList(growable: false);
                        final approved = all
                            .where((m) => m.isApproved)
                            .toList(growable: false);
                        final total = all.length;

                        final filtered = _filter == 'pending'
                            ? pending
                            : _filter == 'approved'
                                ? approved
                                : all;

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
                          children: [
                            _heroHeader(
                              context,
                              enabled: _enabled,
                              imgbbOk: AppConfig.hasImgbbKey,
                            ),
                            const SizedBox(height: 14),
                            _statsRow(
                              context,
                              total: total,
                              approved: approved.length,
                              pending: pending.length,
                            ),
                            const SizedBox(height: 18),
                            _sectionLabel(
                              context,
                              AppLang.tr('camera_settings'),
                              Icons.tune_rounded,
                            ),
                            const SizedBox(height: 10),
                            _settingsCard(context),
                            const SizedBox(height: 12),
                            _saveButton(context),
                            const SizedBox(height: 22),
                            _sectionLabel(
                              context,
                              AppLang.tr('backup_album'),
                              Icons.link_rounded,
                              trailing: AppLang.tr('optional'),
                            ),
                            const SizedBox(height: 10),
                            _albumCard(context),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: _sectionLabel(
                                    context,
                                    AppLang.tr('guest_gallery'),
                                    Icons.photo_library_outlined,
                                  ),
                                ),
                                if (pending.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () =>
                                        _approveAllPending(pending),
                                    icon: const Icon(
                                      Icons.done_all_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      AppLang.tr('approve_all'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTok.accent(context),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _autoApprove
                                  ? AppLang.tr('auto_approve_on_hint')
                                  : AppLang.tr('auto_approve_off_hint'),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _filterRow(
                              context,
                              pendingCount: pending.length,
                              approvedCount: approved.length,
                              allCount: total,
                            ),
                            const SizedBox(height: 14),
                            if (snap.connectionState ==
                                    ConnectionState.waiting &&
                                all.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTok.accent(context),
                                  ),
                                ),
                              )
                            else if (filtered.isEmpty)
                              _emptyGallery(context)
                            else
                              _mediaGrid(context, filtered),
                            const SizedBox(height: 20),
                            _footerNote(context),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }

  // ─── UI blocks ─────────────────────────────────────────────

  Widget _heroHeader(
    BuildContext context, {
    required bool enabled,
    required bool imgbbOk,
  }) {
    final dark = AppTok.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF2A2438),
                  Color(0xFF1A1826),
                  Color(0xFF12101A),
                ],
              )
            : LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppTok.card(context),
                  AppTok.cardSoft(context),
                  AppTok.background(context),
                ],
              ),
        border: Border.all(
          color: AppTok.accent(context).withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTok.accent(context).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTok.accent(context).withValues(alpha: 0.14),
                  border: Border.all(
                    color: AppTok.accent(context).withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: AppTok.accent(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLang.tr('disposable_camera_control'),
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLang.tr('imgbb_no_firebase'),
                      style: TextStyle(
                        color: AppTok.textSoft(context).withValues(alpha: 0.9),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniStatus(
                  label: enabled
                      ? AppLang.tr('camera_on')
                      : AppLang.tr('camera_off'),
                  ok: enabled,
                  icon: enabled
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStatus(
                  label: imgbbOk
                      ? AppLang.tr('upload_ready')
                      : AppLang.tr('imgbb_key_missing'),
                  ok: imgbbOk,
                  icon: imgbbOk
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _previewGuest,
              icon: const Icon(Icons.smartphone_rounded, size: 18),
              label: Text(AppLang.tr('preview_guest_page')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTok.accent(context),
                side: BorderSide(
                  color: AppTok.accent(context).withValues(alpha: 0.45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatus({
    required String label,
    required bool ok,
    required IconData icon,
  }) {
    final c = ok ? const Color(0xFF4CD37B) : const Color(0xFFE8A33D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(
    BuildContext context, {
    required int total,
    required int approved,
    required int pending,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.collections_outlined,
            label: AppLang.tr('total_uploads'),
            value: '$total',
            color: AppTok.accent(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.verified_outlined,
            label: AppLang.tr('approved_count'),
            value: '$approved',
            color: const Color(0xFF4CD37B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.hourglass_top_rounded,
            label: AppLang.tr('waiting'),
            value: '$pending',
            color: const Color(0xFFE8A33D),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: AppTok.textSoft(context),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(
    BuildContext context,
    String title,
    IconData icon, {
    String? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTok.accent(context)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppTok.text(context),
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTok.accent(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                color: AppTok.accent(context),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _settingsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTok.border(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          _switchTile(
            context,
            title: AppLang.tr('guest_camera_enabled'),
            subtitle: AppLang.tr('guests_can_send_photos'),
            icon: Icons.power_settings_new_rounded,
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          Divider(
            color: AppTok.border(context).withValues(alpha: 0.6),
            height: 8,
          ),
          _switchTile(
            context,
            title: AppLang.tr('auto_approve'),
            subtitle: _autoApprove
                ? AppLang.tr('auto_approve_on_sub')
                : AppLang.tr('auto_approve_off_sub'),
            icon: Icons.bolt_rounded,
            value: _autoApprove,
            onChanged: (v) => setState(() => _autoApprove = v),
          ),
          Divider(
            color: AppTok.border(context).withValues(alpha: 0.6),
            height: 8,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTok.accent(context).withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.filter_1_rounded,
                  color: AppTok.accent(context),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLang.tr('max_shots_per_guest'),
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLang.tr('max_shots_lock_hint'),
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stepBtn(context, Icons.remove_rounded, () {
                final n = int.tryParse(_maxShotsC.text) ?? _maxShots;
                if (n > 1) {
                  setState(() {
                    _maxShots = n - 1;
                    _maxShotsC.text = '$_maxShots';
                  });
                }
              }),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _maxShotsC,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTok.background(context),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixText: AppLang.tr('photo_unit'),
                    suffixStyle: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 12,
                    ),
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null) setState(() => _maxShots = n);
                  },
                ),
              ),
              const SizedBox(width: 10),
              _stepBtn(
                context,
                Icons.add_rounded,
                () {
                  final n = int.tryParse(_maxShotsC.text) ?? _maxShots;
                  if (n < 200) {
                    setState(() {
                      _maxShots = n + 1;
                      _maxShotsC.text = '$_maxShots';
                    });
                  }
                },
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTok.accent(context).withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: AppTok.accent(context), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppTok.accent(context),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(
    BuildContext context,
    IconData icon,
    VoidCallback onTap, {
    bool filled = false,
  }) {
    return Material(
      color: filled ? AppTok.accent(context) : AppTok.background(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: filled ? Colors.white : AppTok.textSoft(context),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _saveButton(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTok.accent(context),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppTok.accent(context).withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLang.tr('save_settings'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _albumCard(BuildContext context) {
    final has = _albumC.text.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            has
                ? AppLang.tr('album_link_has')
                : AppLang.tr('album_link_empty'),
            style: TextStyle(
              color: AppTok.textSoft(context),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _albumC,
            style: TextStyle(color: AppTok.text(context), fontSize: 13),
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'https://photos.google.com/share/...',
              hintStyle: TextStyle(
                color: AppTok.textSoft(context),
                fontSize: 12,
              ),
              prefixIcon: Icon(
                Icons.link_rounded,
                color: AppTok.accent(context).withValues(alpha: 0.7),
                size: 20,
              ),
              filled: true,
              fillColor: AppTok.background(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _softAction(
                  context,
                  icon: Icons.open_in_new_rounded,
                  label: AppLang.tr('open'),
                  onTap: has ? _openAlbum : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _softAction(
                  context,
                  icon: Icons.copy_rounded,
                  label: AppLang.tr('copy_link'),
                  onTap: has ? _copyAlbum : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _softAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor:
            enabled ? AppTok.accent(context) : AppTok.textSoft(context),
        side: BorderSide(
          color: enabled
              ? AppTok.accent(context).withValues(alpha: 0.4)
              : AppTok.border(context),
        ),
        minimumSize: const Size.fromHeight(42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _filterRow(
    BuildContext context, {
    required int pendingCount,
    required int approvedCount,
    required int allCount,
  }) {
    Widget chip(String id, String label, int count, Color accent) {
      final sel = _filter == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _filter = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: sel ? accent.withValues(alpha: 0.14) : AppTok.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel
                    ? accent.withValues(alpha: 0.55)
                    : AppTok.border(context),
                width: sel ? 1.3 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    color: sel ? accent : AppTok.text(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: sel ? accent : AppTok.textSoft(context),
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          'pending',
          AppLang.tr('waiting'),
          pendingCount,
          const Color(0xFFE8A33D),
        ),
        const SizedBox(width: 8),
        chip(
          'approved',
          AppLang.tr('approved_filter'),
          approvedCount,
          const Color(0xFF4CD37B),
        ),
        const SizedBox(width: 8),
        chip('all', AppLang.tr('all'), allCount, AppTok.accent(context)),
      ],
    );
  }

  Widget _emptyGallery(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTok.border(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTok.accent(context).withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.photo_outlined,
              color: AppTok.accent(context).withValues(alpha: 0.7),
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _filter == 'pending'
                ? AppLang.tr('no_pending_filter')
                : _filter == 'approved'
                    ? AppLang.tr('no_approved_yet')
                    : AppLang.tr('no_photos_sent'),
            style: TextStyle(
              color: AppTok.text(context),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLang.tr('send_test_photo_hint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTok.textSoft(context),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _previewGuest,
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(AppLang.tr('open_guest_camera')),
            style: TextButton.styleFrom(
              foregroundColor: AppTok.accent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaGrid(BuildContext context, List<GuestMediaModel> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, i) => _mediaTile(context, items[i]),
    );
  }

  Widget _mediaTile(BuildContext context, GuestMediaModel m) {
    final pending = m.isPending;
    final statusColor = pending
        ? const Color(0xFFE8A33D)
        : (m.isApproved ? const Color(0xFF4CD37B) : AppTok.textSoft(context));

    return Container(
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pending
              ? statusColor.withValues(alpha: 0.4)
              : AppTok.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTok.shadow(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                m.url.isEmpty
                    ? ColoredBox(
                        color: AppTok.cardSoft(context),
                        child: Icon(
                          Icons.broken_image,
                          color: AppTok.textSoft(context),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: m.url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.broken_image,
                          color: AppTok.textSoft(context),
                        ),
                      ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      pending
                          ? AppLang.tr('status_waiting')
                          : (m.isApproved
                              ? AppLang.tr('status_approved')
                              : m.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.uploaderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (pending) ...[
                      _actionPill(
                        icon: Icons.check_rounded,
                        color: const Color(0xFF4CD37B),
                        onTap: () => _setStatus(m, 'approved'),
                      ),
                      const SizedBox(width: 6),
                      _actionPill(
                        icon: Icons.close_rounded,
                        color: AppTok.danger(context),
                        onTap: () => _setStatus(m, 'rejected'),
                      ),
                    ] else if (!m.isApproved) ...[
                      _actionPill(
                        icon: Icons.check_rounded,
                        color: const Color(0xFF4CD37B),
                        onTap: () => _setStatus(m, 'approved'),
                      ),
                      const SizedBox(width: 6),
                    ],
                    const Spacer(),
                    _actionPill(
                      icon: Icons.delete_outline_rounded,
                      color: AppTok.textSoft(context),
                      onTap: () => _delete(m),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _footerNote(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTok.card(context).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppTok.textSoft(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLang.tr('camera_manage_footer'),
              style: TextStyle(
                color: AppTok.textSoft(context),
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}