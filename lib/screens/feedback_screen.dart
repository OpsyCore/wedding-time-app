import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_config.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    super.key,
    required this.weddingId,
  });

  final String weddingId;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _ctrl = TextEditingController();
  String _type = 'feedback'; // feedback | bug
  bool _sending = false;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('enter_message'))),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      // ذخیره در:
      // weddings/{weddingId}/feedback/{id} + mirror به پشتیبانی مرکزی
      await FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('feedback')
          .add({
        'weddingId': widget.weddingId,
        'uid': user?.uid,
        'email': user?.email,
        'supportEmail': AppConfig.supportEmail,
        'type': _type, // feedback یا bug
        'message': text,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Mirror به inbox پشتیبانی (abrt1369@gmail.com)
      try {
        await FirebaseFirestore.instance.collection('support_inbox').add({
          'uid': user?.uid ?? '',
          'email': user?.email ?? '',
          'supportEmail': AppConfig.supportEmail,
          'weddingId': widget.weddingId,
          'type': _type,
          'message': text,
          'source': 'feedback',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      _ctrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('message_sent'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLang.tr('error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
                AppLang.tr('feedback_title'),
                style: TextStyle(color: AppTok.text(context)),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  AppLang.tr('feedback_storage_hint'),
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTok.card(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTok.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTok.accent(context).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.email_outlined, color: AppTok.accent(context), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLang.I.isFa ? 'ایمیل پشتیبانی' : 'Support email', style: TextStyle(color: AppTok.textSoft(context), fontSize: 11)),
                            Text(AppConfig.supportEmail, style: TextStyle(color: AppTok.text(context), fontSize: 13, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse('mailto:${AppConfig.supportEmail}?subject=Feedback');
                          try { if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(color: AppTok.accent(context), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () async {
                          await Clipboard.setData(const ClipboardData(text: AppConfig.supportEmail));
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLang.I.isFa ? 'کپی شد' : 'Copied')));
                        },
                        child: Icon(Icons.copy_rounded, color: AppTok.textSoft(context), size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  children: [
                    ChoiceChip(
                      label: Text(AppLang.tr('feedback_type')),
                      selected: _type == 'feedback',
                      selectedColor: AppTok.accent(context),
                      onSelected: (_) => setState(() => _type = 'feedback'),
                      labelStyle: TextStyle(
                        color: _type == 'feedback'
                            ? Colors.white
                            : AppTok.text(context),
                      ),
                    ),
                    ChoiceChip(
                      label: Text(AppLang.tr('bug_report')),
                      selected: _type == 'bug',
                      selectedColor: AppTok.accent(context),
                      onSelected: (_) => setState(() => _type = 'bug'),
                      labelStyle: TextStyle(
                        color: _type == 'bug'
                            ? Colors.white
                            : AppTok.text(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  maxLines: 7,
                  style: TextStyle(color: AppTok.text(context)),
                  decoration: InputDecoration(
                    hintText: AppLang.tr('message_hint'),
                    hintStyle: TextStyle(color: AppTok.textSoft(context)),
                    filled: true,
                    fillColor: AppTok.card(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTok.accent(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _sending
                        ? AppLang.tr('sending_message')
                        : AppLang.tr('send'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}