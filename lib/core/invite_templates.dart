import 'package:flutter/material.dart';

import 'app_plans.dart';
import '../services/plan_access.dart' show PlanLimits;

/// قالب/تم دعوت‌نامه — سیستم قالب با ۴ تم؛ فقط «کلاسیک» رایگان است.
class InviteTemplate {
  const InviteTemplate({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.premium,
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.accent,
    required this.text,
    required this.textSoft,
    required this.border,
    required this.decor,
  });

  final String id;
  final String nameFa;
  final String nameEn;
  final bool premium;
  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color accent;
  final Color text;
  final Color textSoft;
  final Color border;

  /// ایموجی تزئینی سربرگ قالب
  final String decor;

  static const classic = InviteTemplate(
    id: 'classic',
    nameFa: 'کلاسیک',
    nameEn: 'Classic',
    premium: false,
    bgTop: Color(0xFF17141F),
    bgBottom: Color(0xFF241B2E),
    card: Color(0xFF221D2B),
    accent: Color(0xFFE8C9A8),
    text: Color(0xFFF3EFE6),
    textSoft: Color(0xFFB8B0C4),
    border: Color(0x4DE8C9A8),
    decor: '🤍',
  );

  static const royalGold = InviteTemplate(
    id: 'royal_gold',
    nameFa: 'سلطنتی طلایی',
    nameEn: 'Royal Gold',
    premium: true,
    bgTop: Color(0xFF120E08),
    bgBottom: Color(0xFF2A1F0E),
    card: Color(0xFF241B0D),
    accent: Color(0xFFE6C97A),
    text: Color(0xFFF7EFDC),
    textSoft: Color(0xFFC9B98F),
    border: Color(0x66E6C97A),
    decor: '👑',
  );

  static const floralRose = InviteTemplate(
    id: 'floral_rose',
    nameFa: 'گلدار رز',
    nameEn: 'Floral Rose',
    premium: true,
    bgTop: Color(0xFF1C0F16),
    bgBottom: Color(0xFF331423),
    card: Color(0xFF2A141D),
    accent: Color(0xFFF2A0B4),
    text: Color(0xFFFBEFF2),
    textSoft: Color(0xFFD8AEBA),
    border: Color(0x59F2A0B4),
    decor: '🌹',
  );

  static const minimalModern = InviteTemplate(
    id: 'minimal_modern',
    nameFa: 'مدرن مینیمال',
    nameEn: 'Minimal Modern',
    premium: true,
    bgTop: Color(0xFF0E1116),
    bgBottom: Color(0xFF161B22),
    card: Color(0xFF1A2028),
    accent: Color(0xFF8AB4F8),
    text: Color(0xFFEFF3F8),
    textSoft: Color(0xFFA8B3C0),
    border: Color(0x408AB4F8),
    decor: '✨',
  );

  static const List<InviteTemplate> all = [
    classic,
    royalGold,
    floralRose,
    minimalModern,
  ];

  static InviteTemplate byId(String? id) {
    final key = (id ?? '').trim();
    for (final t in all) {
      if (t.id == key) return t;
    }
    return classic;
  }

  /// قالب‌های مجاز برای یک پلن
  static List<InviteTemplate> allowedFor(PlanLimits limits) {
    return all.where((t) => limits.templates.contains(t.id)).toList();
  }

  String name(bool isFa) => isFa ? nameFa : nameEn;
}

/// کلید ذخیره در سند مراسم
const inviteTemplateField = 'inviteTemplateId';

/// آیا این پلن رایگان است؟ (برای بج پرمیوم روی قالب‌ها)
bool templateAllowedOnFree(String id) =>
    PlanLimits.forPlanId(AppPlans.freeId).templates.contains(id);
