import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../widgets/effect_background.dart';
import '../widgets/page_glass.dart';
import '../widgets/full_color_picker.dart';

class WeddingPaletteScreen extends StatefulWidget {
  final String weddingId;
  const WeddingPaletteScreen({super.key, required this.weddingId});

  @override
  State<WeddingPaletteScreen> createState() => _WeddingPaletteScreenState();
}

class _WeddingPaletteScreenState extends State<WeddingPaletteScreen> {
  DocumentReference<Map<String, dynamic>> get _paletteDoc =>
      FirebaseFirestore.instance.collection('weddings').doc(widget.weddingId).collection('palette').doc('main');

  // ۸ پالت پیشنهادی آماده - با یک تپ پر میشه ولی باز هر رنگ قابل ویرایشه
  static const List<List<String>> _presetPalettes = [
    ['#FADADD', '#F8BBD0', '#E8A0BF', '#9B6B6B'], // Blush Classic
    ['#9CAF88', '#D4AF37', '#F5F1E8', '#5A6B4A'], // Sage & Gold
    ['#1A237E', '#283593', '#5C6BC0', '#FFD54F', '#FFFFFF'], // Midnight Navy
    ['#2E7D6F', '#A8D5BA', '#FFF8E1', '#D4A574'], // Emerald Garden
    ['#6D4C41', '#BCAAA4', '#FFECB3', '#4E342E'], // Mocha
    ['#9575CD', '#CE93D8', '#F8BBD0', '#FFF9C4'], // Lavender Dream
    ['#00897B', '#80CBC4', '#FFAB91', '#FFFDE7'], // Teal Peach
    ['#B71C1C', '#E53935', '#FFCDD2', '#3E2723'], // Royal Red
  ];

  String _hexFromColor(Color c) => '#${(c.r*255).round().toRadixString(16).padLeft(2,'0')}${(c.g*255).round().toRadixString(16).padLeft(2,'0')}${(c.b*255).round().toRadixString(16).padLeft(2,'0')}'.toUpperCase();

  Color _colorFromHex(String hex) {
    var h = hex.trim().replaceAll('#', '');
    if (h.length == 6) {
      final v = int.tryParse(h, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return const Color(0xFFE53935);
  }

  Future<void> _savePalette({required bool enabled, required List<String> colors, String? note}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await _paletteDoc.set({
      'enabled': enabled,
      'colors': colors,
      if (note != null) 'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    }, SetOptions(merge: true));
  }

  Future<Color?> _pickColor(Color initial) async {
    return showDialog<Color>(
      context: context,
      builder: (_) => FullColorPickerDialog(initialColor: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final isFa = AppLang.I.isFa;
        return Directionality(
          textDirection: AppLang.I.direction,
          child: EffectBackgroundStack(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: GlassAppBar(
                opacity: 0.84,
                blurSigma: 12,
                title: Text(isFa ? 'پالت رنگی عروسی' : 'Wedding Palette', style: TextStyle(color: AppTok.text(context), fontWeight: FontWeight.w800, fontSize: 16)),
                leading: Navigator.canPop(context)
                    ? IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTok.accent(context), size: 20),
                        onPressed: () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                      )
                    : null,
              ),
              body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _paletteDoc.snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data() ?? {};
                  final enabled = data['enabled'] == true;
                  final rawColors = (data['colors'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
                  final colors = rawColors.where((h) => h.trim().isNotEmpty).toList();
                  final note = (data['note'] ?? '').toString();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      // Toggle card
                      PageGlass(
                        opacity: 0.86,
                        blurSigma: 12,
                        borderRadius: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTok.accent(context).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.palette_outlined, color: AppTok.accent(context))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isFa ? 'نمایش پالت برای مهمان‌ها' : 'Show to guests', style: TextStyle(color: AppTok.text(context), fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(isFa ? (enabled ? 'فعال — مهمان‌ها پالت را در دعوت می‌بینند' : 'خاموش — فقط شما می‌بینید') : (enabled ? 'On — guests see it in invite' : 'Off — only you'), style: TextStyle(color: AppTok.textSoft(context), fontSize: 11.5)),
                                ],
                              ),
                            ),
                            Switch(
                              value: enabled,
                              activeColor: AppTok.accent(context),
                              onChanged: (v) => _savePalette(enabled: v, colors: colors, note: note),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Counts + actions
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: AppTok.cardSoft(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTok.border(context))),
                            child: Text(isFa ? '${colors.length} / ۷ رنگ' : '${colors.length} / 7 colors', style: TextStyle(color: AppTok.textSoft(context), fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                          const Spacer(),
                          if (colors.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => _savePalette(enabled: enabled, colors: [], note: note),
                              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                              label: Text(isFa ? 'پاک کردن همه' : 'Clear all'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Colors grid - 1..7
                      PageGlass(
                        opacity: 0.86,
                        blurSigma: 12,
                        borderRadius: 18,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isFa ? 'رنگ‌های انتخابی (تا ۷ رنگ)' : 'Selected colors (up to 7)', style: TextStyle(color: AppTok.text(context), fontWeight: FontWeight.w800, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(isFa ? 'از هر جای پالت فول انتخاب کن — Grid / Spectrum / Sliders' : 'Pick from full palette — Grid / Spectrum / Sliders', style: TextStyle(color: AppTok.textSoft(context), fontSize: 11.5)),
                            const SizedBox(height: 14),
                            if (colors.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(color: AppTok.cardSoft(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTok.border(context))),
                                child: Column(
                                  children: [
                                    Icon(Icons.color_lens_outlined, size: 36, color: AppTok.textSoft(context).withValues(alpha: 0.6)),
                                    const SizedBox(height: 8),
                                    Text(isFa ? 'هنوز رنگی انتخاب نشده' : 'No colors yet', style: TextStyle(color: AppTok.textSoft(context))),
                                    const SizedBox(height: 4),
                                    Text(isFa ? 'دکمه + را بزن و از پالت فول رنگ بردار' : 'Tap + to pick from full palette', style: TextStyle(color: AppTok.textSoft(context), fontSize: 11)),
                                  ],
                                ),
                              )
                            else
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (int i = 0; i < colors.length; i++)
                                    _colorChip(
                                      hex: colors[i],
                                      index: i,
                                      onEdit: () async {
                                        final picked = await _pickColor(_colorFromHex(colors[i]));
                                        if (picked != null) {
                                          final next = List<String>.from(colors);
                                          next[i] = _hexFromColor(picked);
                                          await _savePalette(enabled: enabled, colors: next, note: note);
                                        }
                                      },
                                      onDelete: () async {
                                        final next = List<String>.from(colors)..removeAt(i);
                                        await _savePalette(enabled: enabled, colors: next, note: note);
                                      },
                                      onCopy: () async {
                                        await Clipboard.setData(ClipboardData(text: colors[i]));
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFa ? 'کپی شد ${colors[i]}' : 'Copied ${colors[i]}')));
                                      },
                                    ),
                                  if (colors.length < 7)
                                    _addChip(onTap: () async {
                                      final picked = await _pickColor(const Color(0xFFE53935));
                                      if (picked != null) {
                                        final next = List<String>.from(colors)..add(_hexFromColor(picked));
                                        await _savePalette(enabled: enabled, colors: next, note: note);
                                      }
                                    }),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Presets
                      PageGlass(
                        opacity: 0.84,
                        blurSigma: 12,
                        borderRadius: 18,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isFa ? 'پالت‌های پیشنهادی — یک‌ضرب اعمال کن' : 'Preset palettes — apply in one tap', style: TextStyle(color: AppTok.text(context), fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 78,
                              child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(
                                  dragDevices: {
                                    PointerDeviceKind.touch,
                                    PointerDeviceKind.mouse,
                                    PointerDeviceKind.trackpad,
                                    PointerDeviceKind.stylus,
                                  },
                                ),
                                child: Scrollbar(
                                  thumbVisibility: false,
                                  interactive: true,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    clipBehavior: Clip.none,
                                    itemCount: _presetPalettes.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                                    itemBuilder: (context, idx) {
                                  final preset = _presetPalettes[idx];
                                  return InkWell(
                                    onTap: () async {
                                      // اعمال تا ۷ رنگ - برش به ۷
                                      final take = preset.take(7).toList();
                                      await _savePalette(enabled: true, colors: take, note: note);
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 140,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTok.cardSoft(context),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppTok.border(context)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [for (final h in preset.take(5)) Container(margin: const EdgeInsets.only(right: 4), width: 18, height: 18, decoration: BoxDecoration(color: _colorFromHex(h), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]))]),
                                          const Spacer(),
                                          Text(isFa ? 'اعمال پالت ${idx + 1}' : 'Apply ${idx + 1}', style: TextStyle(color: AppTok.accent(context), fontSize: 11, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Note
                      _PaletteNoteField(
                        initialNote: note,
                        enabled: enabled,
                        colors: colors,
                        onSave: (newNote) => _savePalette(enabled: enabled, colors: colors, note: newNote),
                      ),
                      const SizedBox(height: 14),
                      // Guest preview (what guests will see)
                      if (enabled && colors.isNotEmpty)
                        PageGlass(
                          opacity: 0.86,
                          blurSigma: 12,
                          borderRadius: 18,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [Icon(Icons.visibility_outlined, size: 18, color: AppTok.accent(context)), const SizedBox(width: 8), Text(isFa ? 'پیش‌نمایش مهمان' : 'Guest preview', style: TextStyle(color: AppTok.text(context), fontWeight: FontWeight.w800))]),
                              const SizedBox(height: 12),
                              Wrap(spacing: 10, runSpacing: 10, children: [for (final h in colors) Column(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: _colorFromHex(h), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)])), const SizedBox(height: 4), Text(h, style: TextStyle(color: AppTok.textSoft(context), fontSize: 10, fontWeight: FontWeight.w600))])]),
                              if (note.trim().isNotEmpty) ...[const SizedBox(height: 10), Text(note, style: TextStyle(color: AppTok.textSoft(context), fontSize: 12))],
                            ],
                          ),
                        ),
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

  Widget _colorChip({required String hex, required int index, required VoidCallback onEdit, required VoidCallback onDelete, required VoidCallback onCopy}) {
    final c = _colorFromHex(hex);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 86,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppTok.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTok.border(context)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
            ),
            child: Column(
              children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 10)])),
                const SizedBox(height: 6),
                Text(hex, style: TextStyle(color: AppTok.textSoft(context), fontSize: 10.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                InkWell(onTap: onCopy, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppTok.cardSoft(context), borderRadius: BorderRadius.circular(20)), child: Text(AppLang.I.isFa ? 'کپی' : 'Copy', style: TextStyle(color: AppTok.textSoft(context), fontSize: 9)))),
              ],
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: onDelete,
            child: Container(width: 22, height: 22, decoration: BoxDecoration(color: const Color(0xFFE53935), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), child: const Icon(Icons.close_rounded, size: 12, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _addChip({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 86,
        height: 106,
        decoration: BoxDecoration(
          color: AppTok.cardSoft(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTok.accent(context).withValues(alpha: 0.35), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTok.accent(context).withValues(alpha: 0.12), shape: BoxShape.circle, border: Border.all(color: AppTok.accent(context).withValues(alpha: 0.25))), child: Icon(Icons.add_rounded, color: AppTok.accent(context))),
            const SizedBox(height: 8),
            Text(AppLang.I.isFa ? 'افزودن رنگ' : 'Add color', style: TextStyle(color: AppTok.textSoft(context), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PaletteNoteField extends StatefulWidget {
  final String initialNote;
  final bool enabled;
  final List<String> colors;
  final ValueChanged<String> onSave;
  const _PaletteNoteField({required this.initialNote, required this.enabled, required this.colors, required this.onSave});
  @override
  State<_PaletteNoteField> createState() => _PaletteNoteFieldState();
}

class _PaletteNoteFieldState extends State<_PaletteNoteField> {
  late TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNote);
  }
  @override
  void didUpdateWidget(covariant _PaletteNoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialNote != widget.initialNote && _ctrl.text != widget.initialNote) {
      _ctrl.text = widget.initialNote;
    }
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final isFa = AppLang.I.isFa;
    return PageGlass(
      opacity: 0.84,
      blurSigma: 12,
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isFa ? 'یادداشت برای مهمان (راهنمای ست)' : 'Note for guests', style: TextStyle(color: AppTok.text(context), fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: isFa ? 'مثلاً: تم ما صورتی-طلاییه، لطفاً با همین طیف ست کنید...' : 'e.g. Our theme is blush & gold, please match...',
              filled: true,
              fillColor: AppTok.cardSoft(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTok.border(context))),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: () {
                widget.onSave(_ctrl.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFa ? 'ذخیره شد' : 'Saved')));
              },
              child: Text(isFa ? 'ذخیره یادداشت' : 'Save note'),
            ),
          ),
        ],
      ),
    );
  }
}
