import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      // feedbacks/{id}
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'weddingId': widget.weddingId,
        'uid': user?.uid,
        'email': user?.email,
        'type': _type, // feedback یا bug
        'message': text,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });

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