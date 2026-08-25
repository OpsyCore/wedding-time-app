import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_lang.dart';

class HallModel {
  final String id;
  final String name;
  final int order;

  const HallModel({
    required this.id,
    required this.name,
    required this.order,
  });

  factory HallModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HallModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// نام نمایشی سالن (i18n برای پیش‌فرض)
  String get displayName {
    final n = name.trim();
    if (n.isEmpty || n == 'سالن') {
      return AppLang.tr('main_hall');
    }
    return n;
  }
}

class TableModel {
  final String id;
  final String name;
  final String type; // round | square | rect
  final int capacity;
  final int order;
  final List<String> guestIds;
  /// نام مهمانان روی میز — برای مهمان بدون لاگین (read tables)
  final List<String> guestNames;
  final bool isVip;
  final bool isLocked;
  final bool isFamily;
  final double posX; // 0..1
  final double posY; // 0..1
  final String hallId;

  TableModel({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.order,
    required this.guestIds,
    required this.guestNames,
    this.isVip = false,
    this.isLocked = false,
    this.isFamily = false,
    this.posX = 0.5,
    this.posY = 0.5,
    this.hallId = '',
  });

  factory TableModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TableModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'round',
      capacity: (data['capacity'] is num)
          ? (data['capacity'] as num).toInt()
          : int.tryParse('${data['capacity']}') ?? 8,
      order: (data['order'] is num)
          ? (data['order'] as num).toInt()
          : int.tryParse('${data['order']}') ?? 0,
      guestIds: List<String>.from(data['guestIds'] ?? const []),
      guestNames: List<String>.from(data['guestNames'] ?? const []),
      isVip: data['isVip'] == true,
      isLocked: data['isLocked'] == true,
      isFamily: data['isFamily'] == true,
      posX: (data['posX'] is num) ? (data['posX'] as num).toDouble() : 0.5,
      posY: (data['posY'] is num) ? (data['posY'] as num).toDouble() : 0.5,
      hallId: (data['hallId'] ?? '').toString(),
    );
  }

  TableModel copyWith({
    String? name,
    String? type,
    int? capacity,
    int? order,
    List<String>? guestIds,
    List<String>? guestNames,
    bool? isVip,
    bool? isLocked,
    bool? isFamily,
    double? posX,
    double? posY,
    String? hallId,
  }) {
    return TableModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      order: order ?? this.order,
      guestIds: guestIds ?? this.guestIds,
      guestNames: guestNames ?? this.guestNames,
      isVip: isVip ?? this.isVip,
      isLocked: isLocked ?? this.isLocked,
      isFamily: isFamily ?? this.isFamily,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      hallId: hallId ?? this.hallId,
    );
  }

  Map<String, dynamic> toMap({bool includeCreatedAt = true}) {
    return {
      'name': name,
      'type': type,
      'capacity': capacity,
      'order': order,
      'guestIds': guestIds,
      'guestNames': guestNames,
      'isVip': isVip,
      'isLocked': isLocked,
      'isFamily': isFamily,
      'posX': posX,
      'posY': posY,
      'hallId': hallId,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    return '${AppLang.tr('table_n')}${order + 1}';
  }

  int get seatedCount {
    if (guestIds.isNotEmpty) return guestIds.length;
    return guestNames.where((e) => e.trim().isNotEmpty).length;
  }

  bool get isFull => seatedCount >= capacity;

  double get fillPercent =>
      capacity == 0 ? 0 : (seatedCount / capacity).clamp(0.0, 1.0);

  /// اندازه منطقی برای نقشه سالن (عرض، ارتفاع)
  static ({double w, double h}) layoutSize(String type, {double base = 76}) {
    switch (type) {
      case 'rect':
        return (w: base * 1.65, h: base * 0.72);
      case 'square':
        return (w: base * 0.95, h: base * 0.95);
      case 'round':
      default:
        return (w: base, h: base);
    }
  }
}