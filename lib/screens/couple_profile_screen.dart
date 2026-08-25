import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../services/media_upload_service.dart';

/// پروفایل عروس و داماد
/// - آپلود: ImgBB از طریق MediaUploadService (static)
/// - بدون Firebase Storage / بدون dart:io
/// - درصد تکمیل واقعی
/// - تم: AppTok + i18n
class CoupleProfileScreen extends StatefulWidget {
  const CoupleProfileScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<CoupleProfileScreen> createState() => _CoupleProfileScreenState();
}

class _CoupleProfileScreenState extends State<CoupleProfileScreen> {
  final _brideFullCtrl = TextEditingController();
  final _brideShortCtrl = TextEditingController();
  final _brideBioCtrl = TextEditingController();
  final _groomFullCtrl = TextEditingController();
  final _groomShortCtrl = TextEditingController();
  final _groomBioCtrl = TextEditingController();

  String? _couplePhotoUrl;
  String? _bridePhotoUrl;
  String? _groomPhotoUrl;
  String? _coupleStoragePath;
  String? _brideStoragePath;
  String? _groomStoragePath;

  String _rsvpMode = 'everyone';
  String _nameOrder = 'groom_first';

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _uploadingKind;

  /// 0.0 .. 1.0
  double _completePercent = 0;

  final _picker = ImagePicker();

  DocumentReference<Map<String, dynamic>> get _weddingRef =>
      FirebaseFirestore.instance.collection('weddings').doc(widget.weddingId);

  DocumentReference<Map<String, dynamic>> get _profileRef =>
      _weddingRef.collection('profile').doc('main');

  @override
  void initState() {
    super.initState();
    _brideFullCtrl.addListener(_onFieldChanged);
    _brideShortCtrl.addListener(_onFieldChanged);
    _brideBioCtrl.addListener(_onFieldChanged);
    _groomFullCtrl.addListener(_onFieldChanged);
    _groomShortCtrl.addListener(_onFieldChanged);
    _groomBioCtrl.addListener(_onFieldChanged);
    _load();
  }

  @override
  void dispose() {
    _brideFullCtrl.removeListener(_onFieldChanged);
    _brideShortCtrl.removeListener(_onFieldChanged);
    _brideBioCtrl.removeListener(_onFieldChanged);
    _groomFullCtrl.removeListener(_onFieldChanged);
    _groomShortCtrl.removeListener(_onFieldChanged);
    _groomBioCtrl.removeListener(_onFieldChanged);
    _brideFullCtrl.dispose();
    _brideShortCtrl.dispose();
    _brideBioCtrl.dispose();
    _groomFullCtrl.dispose();
    _groomShortCtrl.dispose();
    _groomBioCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final next = _calcProgress();
    if ((next - _completePercent).abs() > 0.001) {
      setState(() => _completePercent = next);
    }
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

  String? _emptyToNull(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _load() async {
    try {
      final wedding = await _weddingRef.get();
      final w = wedding.data() ?? {};

      final profile = await _profileRef.get();
      final p = profile.data() ?? {};

      _brideFullCtrl.text =
          (p['brideFullName'] ?? w['brideName'] ?? '').toString();
      _brideShortCtrl.text = (p['brideShortName'] ?? '').toString();
      _brideBioCtrl.text = (p['brideBio'] ?? '').toString();

      _groomFullCtrl.text =
          (p['groomFullName'] ?? w['groomName'] ?? '').toString();
      _groomShortCtrl.text = (p['groomShortName'] ?? '').toString();
      _groomBioCtrl.text = (p['groomBio'] ?? '').toString();

      _couplePhotoUrl = _emptyToNull(p['couplePhotoUrl']?.toString());
      _bridePhotoUrl = _emptyToNull(p['bridePhotoUrl']?.toString());
      _groomPhotoUrl = _emptyToNull(p['groomPhotoUrl']?.toString());
      _coupleStoragePath = _emptyToNull(p['coupleStoragePath']?.toString());
      _brideStoragePath = _emptyToNull(p['brideStoragePath']?.toString());
      _groomStoragePath = _emptyToNull(p['groomStoragePath']?.toString());

      _rsvpMode = (p['rsvpMode'] ?? 'everyone').toString();
      if (!const ['everyone', 'invitees', 'off'].contains(_rsvpMode)) {
        _rsvpMode = 'everyone';
      }

      _nameOrder = (p['nameOrder'] ?? 'groom_first').toString();
      if (!const ['groom_first', 'bride_first'].contains(_nameOrder)) {
        _nameOrder = 'groom_first';
      }

      _completePercent = _calcProgress();
    } catch (e) {
      _toast('${AppLang.tr('load_error')}: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ۹ مورد واقعی (بدون زبان اپ)
  double _calcProgress() {
    const total = 9;
    int filled = 0;

    if ((_couplePhotoUrl ?? '').trim().isNotEmpty) filled++;
    if ((_bridePhotoUrl ?? '').trim().isNotEmpty) filled++;
    if ((_groomPhotoUrl ?? '').trim().isNotEmpty) filled++;
    if (_brideFullCtrl.text.trim().isNotEmpty) filled++;
    if (_brideShortCtrl.text.trim().isNotEmpty) filled++;
    if (_brideBioCtrl.text.trim().isNotEmpty) filled++;
    if (_groomFullCtrl.text.trim().isNotEmpty) filled++;
    if (_groomShortCtrl.text.trim().isNotEmpty) filled++;
    if (_groomBioCtrl.text.trim().isNotEmpty) filled++;

    return filled / total;
  }

  void _recalcProgress() {
    _completePercent = _calcProgress();
  }

  /// استخراج path/id از نتیجهٔ ImgBB بدون وابستگی به فیلد storagePath
  String _pathFromUploadResult(dynamic result, String url) {
    try {
      final dynamic id = result.id ??
          result.providerId ??
          result.imageId ??
          result.deleteUrl;
      if (id != null) {
        final s = id.toString().trim();
        if (s.isNotEmpty) return s.startsWith('imgbb:') ? s : 'imgbb:$s';
      }
    } catch (_) {}

    try {
      final dynamic path = result.path ?? result.storagePath ?? result.ref;
      if (path != null) {
        final s = path.toString().trim();
        if (s.isNotEmpty) return s;
      }
    } catch (_) {}

    // fallback پایدار
    final uri = Uri.tryParse(url);
    final last = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : 'photo';
    return 'imgbb:$last';
  }

  String _urlFromUploadResult(dynamic result) {
    try {
      final u = (result.url ?? result.displayUrl ?? result.imageUrl ?? '')
          .toString()
          .trim();
      if (u.isNotEmpty) return u;
    } catch (_) {}
    throw Exception(AppLang.tr('photo_upload_failed'));
  }

  Future<void> _pickAndUpload(String kind) async {
    if (_uploading) return;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (image == null) return;

      setState(() {
        _uploading = true;
        _uploadingKind = kind;
      });

      final raw = await image.readAsBytes();
      if (raw.isEmpty) {
        _toast(AppLang.tr('empty_file'), error: true);
        return;
      }

      final bytes = Uint8List.fromList(raw);
      final fileName =
          'profile_${kind}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // API واقعی پروژه: static + named param bytes
      final result = await MediaUploadService.uploadImageBytes(
        bytes: bytes,
        fileName: fileName,
      );

      final url = _urlFromUploadResult(result);
      final storagePath = _pathFromUploadResult(result, url);

      if (!mounted) return;

      setState(() {
        if (kind == 'couple') {
          _couplePhotoUrl = url;
          _coupleStoragePath = storagePath;
        } else if (kind == 'bride') {
          _bridePhotoUrl = url;
          _brideStoragePath = storagePath;
        } else {
          _groomPhotoUrl = url;
          _groomStoragePath = storagePath;
        }
        _recalcProgress();
      });

      _toast(AppLang.tr('photo_saved_ok'));
    } catch (e) {
      _toast('${AppLang.tr('photo_upload_failed')}: $e', error: true);
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadingKind = null;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_brideFullCtrl.text.trim().isEmpty ||
        _groomFullCtrl.text.trim().isEmpty) {
      _toast(AppLang.tr('bride_groom_name_required'), error: true);
      return;
    }

    setState(() {
      _recalcProgress();
      _saving = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final percent = _calcProgress();

      await _profileRef.set({
        'couplePhotoUrl': _couplePhotoUrl ?? '',
        'coupleStoragePath': _coupleStoragePath ?? '',
        'bridePhotoUrl': _bridePhotoUrl ?? '',
        'brideStoragePath': _brideStoragePath ?? '',
        'groomPhotoUrl': _groomPhotoUrl ?? '',
        'groomStoragePath': _groomStoragePath ?? '',
        'brideFullName': _brideFullCtrl.text.trim(),
        'brideShortName': _brideShortCtrl.text.trim(),
        'brideBio': _brideBioCtrl.text.trim(),
        'groomFullName': _groomFullCtrl.text.trim(),
        'groomShortName': _groomShortCtrl.text.trim(),
        'groomBio': _groomBioCtrl.text.trim(),
        'rsvpMode': _rsvpMode,
        'nameOrder': _nameOrder,
        'completePercent': percent,
        'completePercentInt': (percent * 100).round(),
        'provider': 'imgbb',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _weddingRef.set({
        'brideName': _brideFullCtrl.text.trim(),
        'groomName': _groomFullCtrl.text.trim(),
        'profileCompletePercent': percent,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _completePercent = percent);
      _toast(AppLang.tr('info_saved'));
      Navigator.pop(context);
    } catch (e) {
      _toast('${AppLang.tr('save_error')}: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTok.accent(context),
                  size: 20,
                ),
              ),
              title: Text(
                AppLang.tr('couple_profile'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: (_saving || _uploading) ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTok.accent(context),
                          ),
                        )
                      : Icon(
                          Icons.check_rounded,
                          color: AppTok.accent(context),
                          size: 26,
                        ),
                ),
              ],
            ),
            body: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTok.accent(context),
                    ),
                  )
                : Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          _progressHeader(context),
                          const SizedBox(height: 14),
                          _couplePhotoCard(context),
                          const SizedBox(height: 14),
                          _sectionCard(
                            context,
                            icon: Icons.woman_2_rounded,
                            title: AppLang.tr('bride_info'),
                            child: _personBlock(
                              context,
                              isBride: true,
                              photoUrl: _bridePhotoUrl,
                              kind: 'bride',
                              onPickPhoto: () => _pickAndUpload('bride'),
                              fullCtrl: _brideFullCtrl,
                              shortCtrl: _brideShortCtrl,
                              bioCtrl: _brideBioCtrl,
                              fullLabel: AppLang.tr('bride_full_name'),
                              shortLabel: AppLang.tr('bride_short_name'),
                              bioLabel: AppLang.tr('bride_bio'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sectionCard(
                            context,
                            icon: Icons.man_2_rounded,
                            title: AppLang.tr('groom_info'),
                            child: _personBlock(
                              context,
                              isBride: false,
                              photoUrl: _groomPhotoUrl,
                              kind: 'groom',
                              onPickPhoto: () => _pickAndUpload('groom'),
                              fullCtrl: _groomFullCtrl,
                              shortCtrl: _groomShortCtrl,
                              bioCtrl: _groomBioCtrl,
                              fullLabel: AppLang.tr('groom_full_name'),
                              shortLabel: AppLang.tr('groom_short_name'),
                              bioLabel: AppLang.tr('groom_bio'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sectionCard(
                            context,
                            icon: Icons.tune_rounded,
                            title: AppLang.tr('settings_section'),
                            child: Column(
                              children: [
                                _dropdownTile(
                                  context,
                                  label: AppLang.tr('rsvp_confirm_label'),
                                  value: _rsvpMode,
                                  items: {
                                    'everyone': AppLang.tr('rsvp_everyone'),
                                    'invitees':
                                        AppLang.tr('rsvp_invitees_only'),
                                    'off': AppLang.tr('rsvp_off'),
                                  },
                                  onChanged: (v) =>
                                      setState(() => _rsvpMode = v),
                                ),
                                const SizedBox(height: 12),
                                _dropdownTile(
                                  context,
                                  label: AppLang.tr('name_order'),
                                  value: _nameOrder,
                                  items: {
                                    'groom_first': AppLang.tr('groom_first'),
                                    'bride_first': AppLang.tr('bride_first'),
                                  },
                                  onChanged: (v) =>
                                      setState(() => _nameOrder = v),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    AppLang.tr('language_hint'),
                                    style: TextStyle(
                                      color: AppTok.textSoft(context)
                                          .withValues(alpha: 0.85),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed:
                                  (_saving || _uploading) ? null : _save,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTok.accent(context),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppTok.accent(context)
                                    .withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _saving
                                    ? AppLang.tr('saving')
                                    : AppLang.tr('save_changes'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_uploading)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black54,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: AppTok.card(context),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: CircularProgressIndicator(
                                        color: AppTok.accent(context),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      AppLang.tr('photo_uploading'),
                                      style: TextStyle(
                                        color: AppTok.text(context),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _progressHeader(BuildContext context) {
    final pct = (_completePercent * 100).round().clamp(0, 100);
    final label = pct == 0
        ? AppLang.tr('progress_start')
        : pct < 40
            ? AppLang.tr('progress_good_start')
            : pct < 70
                ? AppLang.tr('progress_taking_shape')
                : pct < 100
                    ? AppLang.tr('progress_almost')
                    : AppLang.tr('progress_ready');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTok.accent(context).withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTok.accent(context).withValues(alpha: 0.06),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 5,
                  color: AppTok.cardSoft(context),
                ),
                CircularProgressIndicator(
                  value: _completePercent.clamp(0.0, 1.0),
                  strokeWidth: 5,
                  color: AppTok.accent(context),
                  backgroundColor: Colors.transparent,
                ),
                Text(
                  '$pct${AppLang.tr('percent_unit')}',
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLang.tr('wedding_progress'),
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _completePercent.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppTok.cardSoft(context),
                    color: AppTok.accent(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _couplePhotoCard(BuildContext context) {
    final busy = _uploading && _uploadingKind == 'couple';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTok.accent(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTok.accent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppTok.accent(context),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLang.tr('couple_photo'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: busy ? null : () => _pickAndUpload('couple'),
                  child: Container(
                    height: 128,
                    decoration: BoxDecoration(
                      color: AppTok.cardSoft(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTok.border(context),
                      ),
                      image: (_couplePhotoUrl ?? '').isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_couplePhotoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (_couplePhotoUrl ?? '').isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border_rounded,
                                color:
                                    AppTok.accent(context).withValues(alpha: 0.9),
                                size: 34,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLang.tr('bride_and_groom_label'),
                                style: TextStyle(
                                  color: AppTok.textSoft(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: busy ? null : () => _pickAndUpload('couple'),
                child: Container(
                  width: 96,
                  height: 128,
                  decoration: BoxDecoration(
                    color: AppTok.cardSoft(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTok.accent(context).withValues(alpha: 0.45),
                    ),
                  ),
                  child: busy
                      ? Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppTok.accent(context),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              color: AppTok.accent(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLang.tr('add_photo'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppLang.tr('tap_to_add_couple_photo'),
            style: TextStyle(color: AppTok.textSoft(context), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTok.accent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTok.accent(context), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _personBlock(
    BuildContext context, {
    required bool isBride,
    required String? photoUrl,
    required String kind,
    required VoidCallback onPickPhoto,
    required TextEditingController fullCtrl,
    required TextEditingController shortCtrl,
    required TextEditingController bioCtrl,
    required String fullLabel,
    required String shortLabel,
    required String bioLabel,
  }) {
    final busy = _uploading && _uploadingKind == kind;
    final photoPlaceholder = AppTok.isDark(context)
        ? AppTok.cardSoft(context)
        : const Color(0xFFF4EFEA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLang.tr('photo_required'),
          style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: busy ? null : onPickPhoto,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: photoPlaceholder,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTok.accent(context).withValues(alpha: 0.25),
                    ),
                    image: (photoUrl ?? '').isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: busy
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppTok.accent(context),
                              ),
                            ),
                          ),
                        )
                      : (photoUrl ?? '').isEmpty
                          ? Icon(
                              isBride
                                  ? Icons.woman_2_rounded
                                  : Icons.man_2_rounded,
                              color: AppTok.accent(context),
                              size: 64,
                            )
                          : null,
                ),
                if (!busy)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTok.accent(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTok.card(context),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _labeledField(
                context,
                label: '$fullLabel *',
                controller: fullCtrl,
                hint: AppLang.tr('full_name_hint'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _labeledField(
                context,
                label: shortLabel,
                controller: shortCtrl,
                hint: AppLang.tr('short_name_hint'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _labeledField(
          context,
          label: bioLabel,
          controller: bioCtrl,
          hint: AppLang.tr('short_bio_hint'),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: AppTok.text(context)),
          cursorColor: AppTok.accent(context),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTok.textSoft(context).withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: AppTok.cardSoft(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTok.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTok.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTok.accent(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownTile(
    BuildContext context, {
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTok.cardSoft(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTok.border(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.containsKey(value) ? value : items.keys.first,
              dropdownColor: AppTok.card(context),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTok.textSoft(context),
              ),
              style: TextStyle(color: AppTok.text(context), fontSize: 14),
              items: items.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}