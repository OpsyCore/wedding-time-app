import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_config.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/guest_media_model.dart';
import '../services/disposable_camera_service.dart';

/// دوربین یک‌بارمصرف مهمان — UI لوکس + آپلود ImgBB
class GuestCameraScreen extends StatefulWidget {
  final String weddingId;
  final bool isHostPreview;

  const GuestCameraScreen({
    super.key,
    required this.weddingId,
    this.isHostPreview = false,
  });

  @override
  State<GuestCameraScreen> createState() => _GuestCameraScreenState();
}

class _GuestCameraScreenState extends State<GuestCameraScreen>
    with SingleTickerProviderStateMixin {
  late final DisposableCameraService _service;
  final _picker = ImagePicker();
  final _nameC = TextEditingController();

  late final AnimationController _pulse;

  bool _loading = true;
  bool _busy = false;
  String _coupleTitle = '';
  CameraSettingsModel _settings = CameraSettingsModel.defaults();
  String _albumUrl = '';
  String _uploaderKey = '';
  int _usedPhotos = 0;

  Uint8List? _previewBytes;
  bool _uploadSuccess = false;

  @override
  void initState() {
    super.initState();
    _coupleTitle = AppLang.tr('bride_and_groom');
    _service = DisposableCameraService(widget.weddingId);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _bootstrap();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _nameC.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final wedding = await FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .get();
      final data = wedding.data() ?? {};
      final bride = (data['brideName'] ?? '').toString().trim();
      final groom = (data['groomName'] ?? '').toString().trim();

      _settings = await _service.ensureSettings();
      _albumUrl = await _service.getExternalAlbumUrl();
      _uploaderKey = await _service.getUploaderKey();
      final name = await _service.getUploaderName();
      final usage = await _service.getUsage(_uploaderKey);

      if (!mounted) return;
      setState(() {
        _nameC.text =
            (name == 'مهمان' || name == AppLang.tr('guest')) ? '' : name;
        _usedPhotos = usage['photos'] ?? 0;
        if (bride.isEmpty && groom.isEmpty) {
          _coupleTitle = AppLang.tr('bride_and_groom');
        } else if (bride.isEmpty) {
          _coupleTitle = groom;
        } else if (groom.isEmpty) {
          _coupleTitle = bride;
        } else {
          _coupleTitle = '$groom  &  $bride';
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _enabled => _settings.enabled || widget.isHostPreview;
  bool get _hasAlbum => _albumUrl.trim().isNotEmpty;
  int get _maxShots => _settings.maxShotsPerGuest;
  int get _remaining => (_maxShots - _usedPhotos).clamp(0, _maxShots);
  bool get _canShoot =>
      _enabled && _remaining > 0 && AppConfig.hasImgbbKey && !_busy;

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
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
      ),
    );
  }

  Future<void> _persistName() async {
    final n = _nameC.text.trim();
    if (n.isNotEmpty) await _service.setUploaderName(n);
  }

  Future<void> _capture(ImageSource source) async {
    if (!_enabled) {
      _toast(AppLang.tr('guest_camera_disabled'), error: true);
      return;
    }
    if (!AppConfig.hasImgbbKey) {
      _toast(AppLang.tr('upload_key_missing'), error: true);
      return;
    }
    if (_remaining <= 0) {
      _toast(
        '${AppLang.tr('shots_limit_reached')} ($_maxShots)',
        error: true,
      );
      return;
    }

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        _toast(AppLang.tr('empty_file'), error: true);
        return;
      }

      if (!mounted) return;
      setState(() {
        _previewBytes = bytes;
        _uploadSuccess = false;
      });
    } catch (e) {
      _toast('${AppLang.tr('capture_error')}: $e', error: true);
    }
  }

  Future<void> _uploadPreview() async {
    final bytes = _previewBytes;
    if (bytes == null || bytes.isEmpty) return;

    setState(() => _busy = true);
    try {
      await _persistName();
      final name = _nameC.text.trim().isEmpty
          ? AppLang.tr('guest')
          : _nameC.text.trim();

      await _service.uploadBytes(
        bytes: bytes,
        type: 'photo',
        uploaderName: name,
        uploaderKey: _uploaderKey,
        autoApprove: _settings.autoApprove || widget.isHostPreview,
      );

      final usage = await _service.getUsage(_uploaderKey);
      if (!mounted) return;
      setState(() {
        _usedPhotos = usage['photos'] ?? _usedPhotos + 1;
        _uploadSuccess = true;
        _busy = false;
      });

      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      setState(() {
        _previewBytes = null;
        _uploadSuccess = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('${AppLang.tr('upload_failed')}: $e', error: true);
    }
  }

  void _discardPreview() {
    if (_busy) return;
    setState(() {
      _previewBytes = null;
      _uploadSuccess = false;
    });
  }

  Future<void> _openAlbum() async {
    if (!_hasAlbum) {
      _toast(AppLang.tr('backup_album_not_set'));
      return;
    }
    final ok = await _service.openExternalAlbum(_albumUrl);
    if (!ok && mounted) {
      _toast(AppLang.tr('album_open_failed'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final dark = AppTok.isDark(context);
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
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.35),
                            radius: 1.15,
                            colors: dark
                                ? const [
                                    Color(0xFF1C1728),
                                    Color(0xFF0B0A12),
                                  ]
                                : [
                                    AppTok.cardSoft(context),
                                    AppTok.background(context),
                                  ],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: _previewBytes != null
                            ? _buildCaptureStage(context)
                            : _buildHomeStage(context),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHomeStage(BuildContext context) {
    final camW = MediaQuery.sizeOf(context).width * 0.78;

    return Column(
      children: [
        _topBar(context),
        if (widget.isHostPreview) _hostBanner(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  AppLang.tr('capture_love'),
                  style: TextStyle(
                    color: AppTok.accent(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLang.tr('share_moments_hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),

                // دوربین حرفه‌ای — قابل لمس
                FadeTransition(
                  opacity: Tween(begin: 0.94, end: 1.0).animate(_pulse),
                  child: ScaleTransition(
                    scale: Tween(begin: 0.985, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _pulse,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: _canShoot
                          ? () => _capture(ImageSource.camera)
                          : () {
                              if (!_enabled) {
                                _toast(
                                  AppLang.tr('camera_is_off'),
                                  error: true,
                                );
                              } else if (_remaining <= 0) {
                                _toast(
                                  AppLang.tr('shots_exhausted'),
                                  error: true,
                                );
                              }
                            },
                      child: Column(
                        children: [
                          _ProGuestCameraArt(
                            width: camW.clamp(240.0, 340.0),
                            enabled: _canShoot,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _canShoot
                                ? AppLang.tr('tap_camera_to_shoot')
                                : (!_enabled
                                    ? AppLang.tr('camera_off_by_host')
                                    : AppLang.tr('cannot_take_photo')),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTok.accent(context)
                                  .withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  AppLang.tr('shots_remaining'),
                  style: TextStyle(
                    color: AppTok.accent(context).withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$_remaining',
                        style: TextStyle(
                          color: AppTok.accentSoft(context),
                          fontSize: 42,
                          fontWeight: FontWeight.w300,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: '  /  $_maxShots',
                        style: TextStyle(
                          color: AppTok.textSoft(context)
                              .withValues(alpha: 0.75),
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                TextField(
                  controller: _nameC,
                  style: TextStyle(color: AppTok.text(context), fontSize: 14),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _persistName(),
                  decoration: InputDecoration(
                    hintText: AppLang.tr('your_name_optional'),
                    hintStyle: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: AppTok.accent(context).withValues(alpha: 0.75),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppTok.card(context).withValues(alpha: 0.9),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _modeButton(
                        context,
                        icon: Icons.photo_camera_rounded,
                        label: AppLang.tr('camera'),
                        filled: true,
                        onTap: _canShoot
                            ? () => _capture(ImageSource.camera)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _modeButton(
                        context,
                        icon: Icons.photo_library_outlined,
                        label: AppLang.tr('gallery_label'),
                        filled: false,
                        onTap: _canShoot
                            ? () => _capture(ImageSource.gallery)
                            : null,
                      ),
                    ),
                  ],
                ),

                if (_hasAlbum) ...[
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _openAlbum,
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: AppTok.accent(context).withValues(alpha: 0.85),
                    ),
                    label: Text(
                      AppLang.tr('backup_album_btn'),
                      style: TextStyle(
                        color: AppTok.accent(context).withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],

                if (!AppConfig.hasImgbbKey) ...[
                  const SizedBox(height: 12),
                  _warn(context, AppLang.tr('imgbb_key_no_upload')),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureStage(BuildContext context) {
    return Column(
      children: [
        _topBar(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _uploadSuccess
                      ? _statusPill(
                          key: const ValueKey('ok'),
                          icon: Icons.check_circle_rounded,
                          text: AppLang.tr('photo_saved_ok'),
                          color: const Color(0xFF4CD37B),
                        )
                      : _busy
                          ? _statusPill(
                              key: const ValueKey('up'),
                              icon: Icons.cloud_upload_outlined,
                              text: AppLang.tr('photo_uploading'),
                              color: AppTok.accent(context),
                            )
                          : _statusPill(
                              key: const ValueKey('prev'),
                              icon: Icons.favorite_border_rounded,
                              text: AppLang.tr('preview_send_or_cancel'),
                              color: AppTok.accentSoft(context),
                            ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppTok.accent(context).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTok.accent(context).withValues(alpha: 0.1),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_previewBytes!, fit: BoxFit.cover),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 120,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_busy)
                          Container(
                            color: Colors.black45,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      color: AppTok.accent(context),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLang.tr('sending'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_uploadSuccess)
                          Container(
                            color: Colors.black38,
                            child: const Center(
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF4CD37B),
                                size: 64,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _circleAction(
                      context,
                      icon: Icons.close_rounded,
                      label: AppLang.tr('cancel'),
                      onTap: _busy || _uploadSuccess ? null : _discardPreview,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap:
                          (_busy || _uploadSuccess) ? null : _uploadPreview,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTok.accent(context)
                                .withValues(alpha: 0.85),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTok.accent(context)
                                  .withValues(alpha: 0.28),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTok.accentSoft(context),
                                AppTok.accent(context),
                                AppTok.accent(context)
                                    .withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          Text(
                            AppLang.tr('remaining_short'),
                            style: TextStyle(
                              color: AppTok.textSoft(context)
                                  .withValues(alpha: 0.8),
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_remaining',
                            style: TextStyle(
                              color: AppTok.accentSoft(context),
                              fontSize: 26,
                              fontWeight: FontWeight.w300,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _busy
                      ? AppLang.tr('please_wait')
                      : (_uploadSuccess
                          ? AppLang.tr('returning')
                          : AppLang.tr('gold_button_send')),
                  style: TextStyle(
                    color: AppTok.textSoft(context).withValues(alpha: 0.75),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: AppLang.tr('back'),
            onPressed: () {
              if (_previewBytes != null && !_busy) {
                _discardPreview();
              } else if (!_busy) {
                Navigator.pop(context);
              }
            },
            icon: Icon(
              AppLang.I.isFa ? Icons.arrow_forward : Icons.arrow_back,
              color: AppTok.text(context),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _coupleTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTok.accent(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.favorite,
                  size: 11,
                  color: AppTok.accent(context).withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppLang.tr('home'),
            onPressed: _busy ? null : _goHome,
            icon: Icon(Icons.home_outlined, color: AppTok.textSoft(context)),
          ),
        ],
      ),
    );
  }

  Widget _hostBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTok.accent(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppLang.tr('host_preview_banner'),
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTok.accent(context), fontSize: 11.5),
      ),
    );
  }

  Widget _modeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    if (filled) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTok.accent(context),
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppTok.border(context).withValues(alpha: 0.4),
            disabledForegroundColor: AppTok.textSoft(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              enabled ? AppTok.accent(context) : AppTok.textSoft(context),
          side: BorderSide(
            color: enabled
                ? AppTok.accent(context).withValues(alpha: 0.55)
                : AppTok.border(context),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _circleAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Material(
            color: AppTok.card(context),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  icon,
                  color: onTap == null
                      ? AppTok.textSoft(context).withValues(alpha: 0.4)
                      : AppTok.textSoft(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTok.textSoft(context).withValues(alpha: 0.8),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill({
    required Key key,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warn(BuildContext context, String t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTok.danger(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTok.danger(context), fontSize: 12),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// دوربین حرفه‌ای — شبیه رفرنس: گریپ مشکی + mint + لنز چندلایه
// ═══════════════════════════════════════════════════════════════

class _ProGuestCameraArt extends StatelessWidget {
  const _ProGuestCameraArt({
    required this.width,
    this.enabled = true,
  });

  final double width;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.50;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SizedBox(
        width: width,
        height: h + 14,
        child: CustomPaint(
          painter: _ProCameraPainter(
            glow: AppTok.accent(context).withValues(alpha: 0.22),
          ),
        ),
      ),
    );
  }
}

class _ProCameraPainter extends CustomPainter {
  _ProCameraPainter({required this.glow});

  final Color glow;

  static const mint = Color(0xFF9BB8A8);
  static const mintDeep = Color(0xFF7F9E90);
  static const mintHi = Color(0xFFB7D0C4);
  static const grip = Color(0xFF2A2A2E);
  static const gripDark = Color(0xFF1A1A1E);
  static const gripHi = Color(0xFF3A3A40);
  static const accentDot = Color(0xFFD4A574);
  static const redDot = Color(0xFFC45C5C);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - 10;
    const top = 10.0;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, top, w, h),
      const Radius.circular(20),
    );

    // سایه
    canvas.drawRRect(
      body.shift(const Offset(0, 7)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      body.shift(const Offset(0, 2)),
      Paint()
        ..color = glow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // بدنه mint
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [mintHi, mint, mintDeep],
        ).createShader(Rect.fromLTWH(0, top, w, h)),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    final gripW = w * 0.155;

    // گریپ چپ
    final gL = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, top, gripW, h),
      topLeft: const Radius.circular(20),
      bottomLeft: const Radius.circular(20),
    );
    canvas.drawRRect(
      gL,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [gripDark, grip, gripHi],
        ).createShader(Rect.fromLTWH(0, top, gripW, h)),
    );

    // گریپ راست
    final gR = RRect.fromRectAndCorners(
      Rect.fromLTWH(w - gripW, top, gripW, h),
      topRight: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );
    canvas.drawRRect(
      gR,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [gripDark, grip, gripHi],
        ).createShader(Rect.fromLTWH(w - gripW, top, gripW, h)),
    );

    // بافت گریپ
    final groove = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final y = top + 16 + i * (h / 8.2);
      canvas.drawLine(Offset(11, y), Offset(gripW - 10, y), groove);
      canvas.drawLine(
        Offset(w - gripW + 10, y),
        Offset(w - 11, y),
        groove,
      );
    }

    // نوار بالای میانی
    final topY = top + h * 0.11;
    final topH = h * 0.24;
    final bridge = RRect.fromRectAndRadius(
      Rect.fromLTWH(gripW + 10, topY, w - gripW * 2 - 20, topH),
      const Radius.circular(9),
    );
    canvas.drawRRect(
      bridge,
      Paint()..color = mintDeep.withValues(alpha: 0.5),
    );

    // چرم/نقطه چپ
    final leather = Offset(gripW + 24, topY + topH / 2);
    canvas.drawCircle(leather, 6.5, Paint()..color = accentDot);
    canvas.drawCircle(
      leather,
      6.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black26,
    );

    // ویزور چپ
    _viewfinder(canvas, Offset(gripW + 52, topY + topH / 2), 12.5);
    // فلش
    _flash(canvas, Offset(w * 0.5 - 12, topY + topH / 2 - 5));
    // ویزور راست
    _viewfinder(canvas, Offset(w - gripW - 52, topY + topH / 2), 14.5);

    // شاتر روی گریپ راست
    final shutter = Offset(w - gripW * 0.5, top + h * 0.40);
    canvas.drawCircle(shutter, 12, Paint()..color = const Color(0xFF4A4A52));
    canvas.drawCircle(shutter, 8, Paint()..color = const Color(0xFF2A2A30));
    canvas.drawCircle(
      shutter.translate(-2, -2),
      3.2,
      Paint()..color = Colors.white24,
    );

    // دکمه کوچک mint
    final mini = Offset(w - gripW - 20, top + h * 0.74);
    canvas.drawCircle(mini, 5.5, Paint()..color = grip);
    canvas.drawCircle(mini, 2.8, Paint()..color = const Color(0xFF5A5A62));

    // نقطه قرمز گریپ چپ
    canvas.drawCircle(
      Offset(gripW * 0.5, top + h * 0.22),
      3.4,
      Paint()..color = redDot,
    );

    // —— لنز ——
    final lensC = Offset(w * 0.5, top + h * 0.62);
    final r = h * 0.33;

    canvas.drawCircle(lensC, r + 7, Paint()..color = const Color(0xFF3D3D44));
    canvas.drawCircle(lensC, r + 3.5, Paint()..color = const Color(0xFF2A2A30));
    canvas.drawCircle(lensC, r, Paint()..color = const Color(0xFF141418));

    canvas.drawCircle(
      lensC,
      r * 0.84,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..color = const Color(0xFF505058),
    );
    canvas.drawCircle(
      lensC,
      r * 0.74,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF6E6E76),
    );

    final glassR = r * 0.64;
    canvas.drawCircle(
      lensC,
      glassR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6A7A82).withValues(alpha: 0.9),
            const Color(0xFF2C3338),
            const Color(0xFF12161A),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: lensC, radius: glassR)),
    );

    canvas.drawCircle(
      lensC,
      glassR * 0.40,
      Paint()..color = const Color(0xFF0C0E12),
    );
    canvas.drawCircle(
      lensC,
      glassR * 0.20,
      Paint()..color = const Color(0xFF1A2228),
    );

    // هایلایت شیشه
    canvas.drawOval(
      Rect.fromCenter(
        center: lensC.translate(-glassR * 0.28, -glassR * 0.30),
        width: glassR * 0.55,
        height: glassR * 0.26,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.20),
    );
  }

  void _viewfinder(Canvas canvas, Offset c, double r) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: r * 2.15, height: r * 1.55),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF1A1A1E));
    canvas.drawRRect(
      rect.deflate(2.3),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7A8A92).withValues(alpha: 0.75),
            const Color(0xFF2A3036),
          ],
        ).createShader(rect.outerRect),
    );
    canvas.drawCircle(
      c.translate(-r * 0.18, -r * 0.12),
      r * 0.18,
      Paint()..color = Colors.white24,
    );
  }

  void _flash(Canvas canvas, Offset c) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(c.dx, c.dy, 24, 13),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF2A2A2E));
    final p = Paint()
      ..color = const Color(0xFFC8CCD2)
      ..strokeWidth = 1.15;
    for (var i = 0; i < 4; i++) {
      final x = c.dx + 5 + i * 4.5;
      canvas.drawLine(Offset(x, c.dy + 3.5), Offset(x, c.dy + 9.5), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ProCameraPainter oldDelegate) =>
      oldDelegate.glow != glow;
}