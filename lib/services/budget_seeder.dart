import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_lang.dart';

class BudgetSeeder {
  /// ساخت گروه‌ها و هزینه‌های پیش‌فرض برای یک مراسم مشخص
  /// category = فارسی legacy (DB) · title = زبان فعلی اپ هنگام seed
  static Future<void> seedDefaultBudget(String weddingId) async {
    final weddingRef =
        FirebaseFirestore.instance.collection('weddings').doc(weddingId);

    final groupsRef = weddingRef.collection('budgetGroups');

    final existingGroups = await groupsRef.get();

    if (existingGroups.docs.isNotEmpty) {
      // قبلاً ساخته شده
      return;
    }

    final defaultData = _defaultBudgetStructure();

    int orderIndex = 0;

    for (final group in defaultData) {
      final groupDoc = await groupsRef.add({
        'title': AppLang.tr(group['titleKey'] as String),
        'isDefault': true,
        'order': orderIndex,
        'createdAt': FieldValue.serverTimestamp(),
      });

      orderIndex++;

      final expensesRef = groupDoc.collection('expenses');
      final items = group['items'] as List<Map<String, String>>;

      for (final item in items) {
        await expensesRef.add({
          'title': AppLang.tr(item['titleKey']!),
          'category': item['category'], // legacy فارسی — UI با cat_*
          'estimatedAmount': 0,
          'actualAmount': 0,
          'payer': 'shared',
          'note': '',
          'isDefault': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// titleKey → AppLang · category → مقدار ثابت DB
  static List<Map<String, dynamic>> _defaultBudgetStructure() {
    return [
      {
        'titleKey': 'bseed_g_ceremony',
        'items': [
          {
            'titleKey': 'bseed_ceremony_venue',
            'category': 'تشریفات',
          },
          {
            'titleKey': 'bseed_ceremony_sofreh',
            'category': 'تشریفات',
          },
          {
            'titleKey': 'bseed_ceremony_officiant',
            'category': 'تشریفات',
          },
          {
            'titleKey': 'bseed_ceremony_registry',
            'category': 'چاپ',
          },
        ],
      },
      {
        'titleKey': 'bseed_g_reception',
        'items': [
          {
            'titleKey': 'bseed_party_venue',
            'category': 'تشریفات',
          },
          {
            'titleKey': 'bseed_party_catering',
            'category': 'پذیرایی',
          },
          {
            'titleKey': 'bseed_party_cake',
            'category': 'پذیرایی',
          },
          {
            'titleKey': 'bseed_party_music',
            'category': 'تشریفات',
          },
          {
            'titleKey': 'bseed_party_gifts',
            'category': 'هدایا',
          },
        ],
      },
      {
        'titleKey': 'bseed_g_attire',
        'items': [
          {
            'titleKey': 'bseed_dress_bride',
            'category': 'لباس',
          },
          {
            'titleKey': 'bseed_dress_groom',
            'category': 'لباس',
          },
          {
            'titleKey': 'bseed_beauty_makeup',
            'category': 'زیبایی',
          },
          {
            'titleKey': 'bseed_dress_accessories',
            'category': 'لباس',
          },
        ],
      },
      {
        'titleKey': 'bseed_g_photo',
        'items': [
          {
            'titleKey': 'bseed_photo_day',
            'category': 'عکاسی',
          },
          {
            'titleKey': 'bseed_photo_pre',
            'category': 'عکاسی',
          },
          {
            'titleKey': 'bseed_photo_album',
            'category': 'عکاسی',
          },
        ],
      },
      {
        'titleKey': 'bseed_g_flowers',
        'items': [
          {
            'titleKey': 'bseed_flower_bouquet',
            'category': 'گل‌آرایی',
          },
          {
            'titleKey': 'bseed_flower_hall',
            'category': 'گل‌آرایی',
          },
          {
            'titleKey': 'bseed_flower_car',
            'category': 'گل‌آرایی',
          },
        ],
      },
      {
        'titleKey': 'bseed_g_jewelry',
        'items': [
          {
            'titleKey': 'bseed_ring_bands',
            'category': 'جواهرات',
          },
          {
            'titleKey': 'bseed_ring_gold',
            'category': 'جواهرات',
          },
        ],
      },
      {
        'titleKey': 'bseed_g_other',
        'items': [
          {
            'titleKey': 'bseed_other_mehr',
            'category': 'سایر',
          },
          {
            'titleKey': 'bseed_other_trousseau',
            'category': 'جهیزیه',
          },
          {
            'titleKey': 'bseed_other_henna',
            'category': 'تشریفات',
          },
          {
            'titleKey': 'bseed_other_car',
            'category': 'حمل‌ونقل',
          },
          {
            'titleKey': 'bseed_other_invites',
            'category': 'چاپ',
          },
        ],
      },
    ];
  }
}