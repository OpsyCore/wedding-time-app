import 'package:flutter/material.dart';

class PlanFeature {
  const PlanFeature({
    required this.id,
    required this.labelFa,
    required this.labelEn,
    required this.included,
    this.valueFa = '',
    this.valueEn = '',
  });

  final String id;
  final String labelFa;
  final String labelEn;
  final bool included;
  final String valueFa;
  final String valueEn;

  String label(bool isFa) => isFa ? labelFa : labelEn;
  String value(bool isFa) => isFa ? valueFa : valueEn;

  PlanFeature copyWith({
    String? id,
    String? labelFa,
    String? labelEn,
    bool? included,
    String? valueFa,
    String? valueEn,
  }) {
    return PlanFeature(
      id: id ?? this.id,
      labelFa: labelFa ?? this.labelFa,
      labelEn: labelEn ?? this.labelEn,
      included: included ?? this.included,
      valueFa: valueFa ?? this.valueFa,
      valueEn: valueEn ?? this.valueEn,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'labelFa': labelFa,
        'labelEn': labelEn,
        'included': included,
        'valueFa': valueFa,
        'valueEn': valueEn,
      };

  factory PlanFeature.fromMap(Map<String, dynamic> map) {
    return PlanFeature(
      id: (map['id'] ?? 'f').toString(),
      labelFa: (map['labelFa'] ?? map['label'] ?? '').toString(),
      labelEn: (map['labelEn'] ?? map['label'] ?? '').toString(),
      included: map['included'] == true,
      valueFa: (map['valueFa'] ?? map['value'] ?? '').toString(),
      valueEn: (map['valueEn'] ?? map['value'] ?? '').toString(),
    );
  }
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.subtitleFa,
    required this.subtitleEn,
    required this.ctaFa,
    required this.ctaEn,
    required this.iconCode,
    required this.features,
    this.priceToman = 0,
    this.priceUsd = 0,
    this.discountPercent = 0,
    this.periodFa = '',
    this.periodEn = '',
    this.badgeFa,
    this.badgeEn,
    this.popular = false,
    this.highlighted = false,
    this.enabled = true,
    this.sortOrder = 0,
    this.paymentUrl,
  });

  final String id;
  final String nameFa;
  final String nameEn;
  final String subtitleFa;
  final String subtitleEn;
  final String ctaFa;
  final String ctaEn;
  final int iconCode;
  final int priceToman;
  final double priceUsd;
  final int discountPercent;
  final String periodFa;
  final String periodEn;
  final String? badgeFa;
  final String? badgeEn;
  final bool popular;
  final bool highlighted;
  final bool enabled;
  final int sortOrder;
  final List<PlanFeature> features;
  final String? paymentUrl;

  bool get isFree => (priceToman <= 0 && priceUsd <= 0) || id == 'free';

  int get finalToman {
    if (discountPercent <= 0) return priceToman;
    return (priceToman * (100 - discountPercent) / 100).round();
  }

  double get finalUsd {
    if (discountPercent <= 0) return priceUsd;
    return priceUsd * (100 - discountPercent) / 100;
  }

  bool get hasDiscount =>
      discountPercent > 0 && (priceToman > 0 || priceUsd > 0);

  String name(bool isFa) => isFa ? nameFa : nameEn;
  String subtitle(bool isFa) => isFa ? subtitleFa : subtitleEn;
  String cta(bool isFa) => isFa ? ctaFa : ctaEn;
  String period(bool isFa) => isFa ? periodFa : periodEn;

  String? badge(bool isFa) {
    final v = isFa ? badgeFa : badgeEn;
    if (v == null || v.trim().isEmpty) return null;
    return v;
  }

    IconData get icon {
    switch (id) {
      case 'free':
        return Icons.card_giftcard_rounded;
      case 'pro':
        return Icons.workspace_premium_rounded;
      case 'premium':
        return Icons.diamond_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  SubscriptionPlan copyWith({
    String? id,
    String? nameFa,
    String? nameEn,
    String? subtitleFa,
    String? subtitleEn,
    String? ctaFa,
    String? ctaEn,
    int? iconCode,
    int? priceToman,
    double? priceUsd,
    int? discountPercent,
    String? periodFa,
    String? periodEn,
    String? badgeFa,
    String? badgeEn,
    bool? popular,
    bool? highlighted,
    bool? enabled,
    int? sortOrder,
    List<PlanFeature>? features,
    String? paymentUrl,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      nameFa: nameFa ?? this.nameFa,
      nameEn: nameEn ?? this.nameEn,
      subtitleFa: subtitleFa ?? this.subtitleFa,
      subtitleEn: subtitleEn ?? this.subtitleEn,
      ctaFa: ctaFa ?? this.ctaFa,
      ctaEn: ctaEn ?? this.ctaEn,
      iconCode: iconCode ?? this.iconCode,
      priceToman: priceToman ?? this.priceToman,
      priceUsd: priceUsd ?? this.priceUsd,
      discountPercent: discountPercent ?? this.discountPercent,
      periodFa: periodFa ?? this.periodFa,
      periodEn: periodEn ?? this.periodEn,
      badgeFa: badgeFa ?? this.badgeFa,
      badgeEn: badgeEn ?? this.badgeEn,
      popular: popular ?? this.popular,
      highlighted: highlighted ?? this.highlighted,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
      features: features ?? this.features,
      paymentUrl: paymentUrl ?? this.paymentUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nameFa': nameFa,
        'nameEn': nameEn,
        'subtitleFa': subtitleFa,
        'subtitleEn': subtitleEn,
        'ctaFa': ctaFa,
        'ctaEn': ctaEn,
        'iconCode': iconCode,
        'priceToman': priceToman,
        'priceUsd': priceUsd,
        'discountPercent': discountPercent,
        'periodFa': periodFa,
        'periodEn': periodEn,
        'badgeFa': badgeFa,
        'badgeEn': badgeEn,
        'popular': popular,
        'highlighted': highlighted,
        'enabled': enabled,
        'sortOrder': sortOrder,
        'paymentUrl': paymentUrl,
        'features': features.map((e) => e.toMap()).toList(),
      };

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    final rawFeatures = map['features'];
    final features = <PlanFeature>[];
    if (rawFeatures is List) {
      for (final f in rawFeatures) {
        if (f is Map) {
          features.add(PlanFeature.fromMap(Map<String, dynamic>.from(f)));
        }
      }
    }
    return SubscriptionPlan(
      id: (map['id'] ?? '').toString(),
      nameFa: (map['nameFa'] ?? '').toString(),
      nameEn: (map['nameEn'] ?? '').toString(),
      subtitleFa: (map['subtitleFa'] ?? '').toString(),
      subtitleEn: (map['subtitleEn'] ?? '').toString(),
      ctaFa: (map['ctaFa'] ?? '').toString(),
      ctaEn: (map['ctaEn'] ?? '').toString(),
      iconCode: (map['iconCode'] is int)
          ? map['iconCode'] as int
          : int.tryParse('${map['iconCode']}') ?? Icons.star.codePoint,
      priceToman: (map['priceToman'] is int)
          ? map['priceToman'] as int
          : int.tryParse('${map['priceToman'] ?? 0}') ?? 0,
      priceUsd: (map['priceUsd'] is num)
          ? (map['priceUsd'] as num).toDouble()
          : double.tryParse('${map['priceUsd'] ?? 0}') ?? 0,
      discountPercent: (map['discountPercent'] is int)
          ? map['discountPercent'] as int
          : int.tryParse('${map['discountPercent'] ?? 0}') ?? 0,
      periodFa: (map['periodFa'] ?? '').toString(),
      periodEn: (map['periodEn'] ?? '').toString(),
      badgeFa: map['badgeFa']?.toString(),
      badgeEn: map['badgeEn']?.toString(),
      popular: map['popular'] == true,
      highlighted: map['highlighted'] == true,
      enabled: map['enabled'] != false,
      sortOrder: (map['sortOrder'] is int)
          ? map['sortOrder'] as int
          : int.tryParse('${map['sortOrder'] ?? 0}') ?? 0,
      paymentUrl: map['paymentUrl']?.toString(),
      features: features,
    );
  }
}

class PlanReview {
  const PlanReview({
    required this.id,
    required this.name,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.approved = true,
    this.planId = '',
  });

  final String id;
  final String name;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool approved;
  final String planId;

  Map<String, dynamic> toMap() => {
        'name': name,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'approved': approved,
        'planId': planId,
      };

  factory PlanReview.fromMap(String id, Map<String, dynamic> map) {
    DateTime dt;
    final raw = map['createdAt'];
    if (raw is DateTime) {
      dt = raw;
    } else if (raw != null &&
        raw.runtimeType.toString().contains('Timestamp')) {
      try {
        dt = (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        dt = DateTime.now();
      }
    } else {
      dt = DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
    }
    return PlanReview(
      id: id,
      name: (map['name'] ?? '').toString(),
      rating: (map['rating'] is num)
          ? (map['rating'] as num).toDouble()
          : double.tryParse('${map['rating'] ?? 5}') ?? 5,
      comment: (map['comment'] ?? '').toString(),
      createdAt: dt,
      approved: map['approved'] != false,
      planId: (map['planId'] ?? '').toString(),
    );
  }
}