import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_effect_controller.dart';
import '../core/app_font_controller.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../services/ambient_music_service.dart';
import '../services/media_upload_service.dart';
import '../widgets/ambient_music_controls.dart';
import '../widgets/image_crop_screen.dart';
import '../widgets/effect_background.dart';
import '../widgets/effect_picker.dart';
import '../widgets/invite_code_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.weddingId});
  final String weddingId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String _email = '';
  String _role = '';
  String _photoUrl = '';
  bool _uploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};

    _nameCtrl.text = (data['displayName'] ?? data['name'] ?? '').toString();
    _email = (data['email'] ?? user.email ?? '').toString();
    _role = (data['role'] ?? '').toString();
    _photoUrl = (data['photoUrl'] ?? '').toString();

    final lang = (data['language'] ?? '').toString();
    if (lang == 'fa' || lang == 'en') {
      await AppLang.I.setLanguage(lang);
    }

    final theme = (data['themeMode'] ?? '').toString().toLowerCase();
    if (theme == 'dark' || theme == 'light') {
      await AppThemeController.I.setDark(theme == 'dark');
    }

    final font = (data['fontFamily'] ?? '').toString().trim();
    if (font.isNotEmpty) {
      await AppFontController.I.setFont(font);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _changePhoto() async {
    if (_uploadingPhoto) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1200,
      );
      if (image == null) return;
      if (!mounted) return;

      final raw = await image.readAsBytes();
      if (!mounted) return;
      if (raw.isEmpty) return;

      final cropped = await ImageCropScreen.crop(
        context,
        bytes: Uint8List.fromList(raw),
        initialAspectRatio: 1.0,
        title: AppLang.tr('crop_image'),
      );
      if (cropped == null || !mounted) return;

      setState(() => _uploadingPhoto = true);

      final result = await MediaUploadService.uploadImageBytes(
        bytes: cropped,
        fileName: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final url = result.url.trim();
      if (url.isEmpty) throw Exception(AppLang.tr('photo_upload_failed'));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'photoUrl': url,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('photo_saved_ok'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLang.tr('photo_upload_failed')}: $e')),
      );
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _nameCtrl.text.trim(),
        'language': AppLang.I.code,
        'themeMode': AppThemeController.I.isDark ? 'dark' : 'light',
        'fontFamily': AppFontController.I.family,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('profile_saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLang.tr('error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeLanguage(String code) async {
    await AppLang.I.setLanguage(code);
    if (mounted) setState(() {});
  }

  Future<void> _onThemeChanged(bool dark) async {
    await AppThemeController.I.setDark(dark);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'themeMode': dark ? 'dark' : 'light',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> _onFontChanged(String family) async {
    await AppFontController.I.setFont(family);
    if (mounted) setState(() {});
  }

  String _tf(String key, String fallback) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return fallback;
    return v;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const t = AppLang.tr;
    final roleLabel = _role == 'bride'
        ? t('bride')
        : _role == 'groom'
            ? t('groom')
            : '—';

    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLang.I,
        AppThemeController.I,
        AppEffectController.I,
        AppFontController.I,
        AmbientMusicService.I,
      ]),
      builder: (context, _) {
        final isDark = AppTok.isDark(context);
        final bg = AppTok.background(context);
        final card = AppTok.card(context);
        final text = AppTok.text(context);
        final textSoft = AppTok.textSoft(context);
        final accent = AppTok.accent(context);
        final border = AppTok.border(context);
        final onAccent = isDark ? AppDarkPalette.background : Colors.white;

        return Directionality(
          textDirection: AppLang.I.direction,
          child: EffectBackgroundStack(
            child: Scaffold(
              backgroundColor: bg,
              appBar: AppBar(
                backgroundColor: bg,
                title: Text(
                  t('profile'),
                  style: TextStyle(color: text),
                ),
                iconTheme: IconThemeData(color: text),
                actions: const [
                  EffectActionButton(),
                  AmbientMusicActionButton(),
                  SizedBox(width: 6),
                ],
              ),
              body: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: accent),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: accent.withValues(alpha: 0.2),
                                backgroundImage: _photoUrl.isNotEmpty
                                    ? NetworkImage(_photoUrl)
                                    : null,
                                child: _photoUrl.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        color: accent,
                                        size: 46,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: InkWell(
                                  onTap: _changePhoto,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: bg,
                                        width: 2,
                                      ),
                                    ),
                                    child: _uploadingPhoto
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        InviteCodeCard(weddingId: widget.weddingId),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nameCtrl,
                          style: TextStyle(color: text),
                          decoration: _dec(
                            context,
                            t('display_name'),
                            Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(text: _email),
                          style: TextStyle(color: textSoft),
                          decoration: _dec(
                            context,
                            t('email'),
                            Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(text: roleLabel),
                          style: TextStyle(color: textSoft),
                          decoration: _dec(
                            context,
                            t('role'),
                            Icons.favorite_border,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          _tf(
                            'appearance',
                            AppLang.I.isFa ? 'ظاهر' : 'Appearance',
                          ),
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tf(
                            'theme_hint',
                            AppLang.I.isFa
                                ? 'با یک ضربه تم Material عوض می‌شود؛ صفحات به‌تدریج کامل می‌شوند'
                                : 'Material theme switches instantly; screens migrate gradually',
                          ),
                          style: TextStyle(
                            color: textSoft,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            secondary: Icon(
                              isDark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: accent,
                            ),
                            title: Text(
                              _tf(
                                'dark_mode',
                                AppLang.I.isFa ? 'حالت تاریک' : 'Dark mode',
                              ),
                              style: TextStyle(
                                color: text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              isDark
                                  ? _tf(
                                      'theme_dark_on',
                                      AppLang.I.isFa
                                          ? 'تم طلایی کلاسیک'
                                          : 'Classic gold dark',
                                    )
                                  : _tf(
                                      'theme_light_on',
                                      AppLang.I.isFa
                                          ? 'تم روشن موکاپ'
                                          : 'Light mockup',
                                    ),
                              style: TextStyle(
                                color: textSoft,
                                fontSize: 11.5,
                              ),
                            ),
                            value: isDark,
                            activeThumbColor: accent,
                            activeTrackColor: accent.withValues(alpha: 0.45),
                            onChanged: _onThemeChanged,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          AppLang.tr('effect'),
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLang.tr('effect_hint'),
                          style: TextStyle(color: textSoft, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        const EffectPicker(),
                        const SizedBox(height: 22),
                        Text(
                          AppLang.tr('ambient_music'),
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLang.tr('ambient_music_hint'),
                          style: TextStyle(color: textSoft, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        const AmbientMusicControls(),
                        const SizedBox(height: 22),
                        // ── فونت — بین موزیک و زبان ──
                        Text(
                          _tf(
                            'font_family',
                            AppLang.I.isFa ? 'فونت برنامه' : 'App font',
                          ),
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tf(
                            'font_hint',
                            AppLang.I.isFa
                                ? 'فونت همهٔ متن‌های برنامه را فوراً عوض می‌کند'
                                : 'Changes the font across the whole app — applied instantly',
                          ),
                          style: TextStyle(color: textSoft, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        _fontPicker(context),
                        const SizedBox(height: 22),
                        Text(
                          t('language'),
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t('language_hint'),
                          style: TextStyle(
                            color: textSoft,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _langTile(
                                context: context,
                                code: 'fa',
                                title: t('lang_fa'),
                                subtitle: 'RTL',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _langTile(
                                context: context,
                                code: 'en',
                                title: t('lang_en'),
                                subtitle: 'LTR',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: onAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: onAccent,
                                  ),
                                )
                              : Text(
                                  t('save_changes'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
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

  Widget _fontPicker(BuildContext context) {
    final accent = AppTok.accent(context);
    final card = AppTok.card(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final border = AppTok.border(context);
    final current = AppFontController.I.family;

    final preview = AppLang.I.isFa
        ? 'عروسی ما — Wedding Time ۱۲۳'
        : 'Wedding Time — Our Day 123';

    return Column(
      children: AppFontOptions.ordered.map((fam) {
        final selected = current == fam;
        final faName = AppFontController.displayNameFa(fam);
        final enName = AppFontController.displayNameEn(fam);
        final descFa = AppFontController.displayLabelFa(fam);
        final descEn = AppFontController.displayLabelEn(fam);
        final isFa = AppLang.I.isFa;
        final title = isFa ? faName : enName;
        final sub = isFa ? descFa : descEn;
        // برای خانوادهٔ MjParand که تک‌وزن است، پیش‌نمایش را کمی بزرگ‌تر نشان بده
        final previewStyle = TextStyle(
          fontFamily: fam,
          color: selected ? text : textSoft,
          fontSize: fam == 'MjParand' ? 17 : 15,
          fontWeight: FontWeight.w600,
          height: 1.2,
        );
        final titleStyle = TextStyle(
          fontFamily: fam,
          color: selected ? text : textSoft,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _onFontChanged(fam),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? accent : border,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: 0.15)
                          : border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.text_fields_rounded,
                      color: selected ? accent : textSoft,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: titleStyle),
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          style: TextStyle(color: textSoft, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preview,
                          style: previewStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? accent : textSoft.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _langTile({
    required BuildContext context,
    required String code,
    required String title,
    required String subtitle,
  }) {
    final selected = AppLang.I.code == code;
    final card = AppTok.card(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final border = AppTok.border(context);

    return GestureDetector(
      onTap: () => _changeLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.language,
              color: selected ? accent : textSoft,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? text : textSoft,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: textSoft, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(BuildContext context, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTok.textSoft(context)),
      prefixIcon: Icon(icon, color: AppTok.accent(context)),
      filled: true,
      fillColor: AppTok.card(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
