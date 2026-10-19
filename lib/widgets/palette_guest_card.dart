import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import 'page_glass.dart';

class PaletteGuestCard extends StatelessWidget {
  final String weddingId;
  const PaletteGuestCard({super.key, required this.weddingId});

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('weddings').doc(weddingId).collection('palette').doc('main');

  Color _hexToColor(String hex) {
    var h = hex.trim().replaceAll('#', '');
    if (h.length == 6) {
      final v = int.tryParse(h, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return const Color(0xFFBDBDBD);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _doc.snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final enabled = data['enabled'] == true;
        if (!enabled) return const SizedBox.shrink();
        final raw = (data['colors'] as List?)?.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() ?? [];
        if (raw.isEmpty) return const SizedBox.shrink();
        final note = (data['note'] ?? '').toString().trim();
        final isFa = AppLang.I.isFa;

        return PageGlass(
          opacity: 0.86,
          blurSigma: 12,
          borderRadius: 18,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppTok.accent(context).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.palette_outlined, color: AppTok.accent(context), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isFa ? 'پالت رنگی عروسی' : 'Wedding color palette', style: TextStyle(color: AppTok.text(context), fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(isFa ? 'برای ست لباس با تم زوج' : 'Match your outfit to our theme', style: TextStyle(color: AppTok.textSoft(context), fontSize: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final hex in raw)
                    Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _hexToColor(hex),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.2),
                            boxShadow: [BoxShadow(color: _hexToColor(hex).withValues(alpha: 0.35), blurRadius: 10), BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 3))],
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: hex));
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFa ? 'کپی شد $hex' : 'Copied $hex')));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTok.cardSoft(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTok.border(context))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(hex, style: TextStyle(color: AppTok.textSoft(context), fontSize: 10.5, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 4),
                                Icon(Icons.copy_rounded, size: 12, color: AppTok.textSoft(context)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTok.cardSoft(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTok.border(context))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppTok.accent(context)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(note, style: TextStyle(color: AppTok.textSoft(context), fontSize: 12, height: 1.5))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(isFa ? 'راهنما: یکی از این رنگ‌ها را در لباس، کراوات یا اکسسوری ست کنید.' : 'Tip: match one of these colors in your outfit, tie or accessories.', style: TextStyle(color: AppTok.textSoft(context).withValues(alpha: 0.9), fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ),
        );
      },
    );
  }
}
