import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';

enum AppNotificationType {
  wish,
  rsvp,
  gallery,
  checklist,
  payment,
  wedding,
  vendor,
  general,
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final String? relatedId;
  final bool isSmart;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.relatedId,
    this.isSmart = false,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: doc.id,
      type: AppNotificationTypeX.fromString(d['type']?.toString()),
      title: (d['title'] ?? '').toString(),
      body: (d['body'] ?? '').toString(),
      read: d['read'] == true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedId: d['relatedId']?.toString(),
      isSmart: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'body': body,
      'read': read,
      'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  IconData get icon {
    switch (type) {
      case AppNotificationType.wish:
        return Icons.favorite_border;
      case AppNotificationType.rsvp:
        return Icons.mark_email_read_outlined;
      case AppNotificationType.gallery:
        return Icons.photo_library_outlined;
      case AppNotificationType.checklist:
        return Icons.checklist_rtl;
      case AppNotificationType.payment:
        return Icons.payments_outlined;
      case AppNotificationType.wedding:
        return Icons.favorite;
      case AppNotificationType.vendor:
        return Icons.storefront_outlined;
      case AppNotificationType.general:
        return Icons.notifications_none;
    }
  }

  String get typeLabel {
    switch (type) {
      case AppNotificationType.wish:
        return AppLang.tr('notif_type_wish');
      case AppNotificationType.rsvp:
        return AppLang.tr('notif_type_rsvp');
      case AppNotificationType.gallery:
        return AppLang.tr('notif_type_gallery');
      case AppNotificationType.checklist:
        return AppLang.tr('notif_type_checklist');
      case AppNotificationType.payment:
        return AppLang.tr('notif_type_payment');
      case AppNotificationType.wedding:
        return AppLang.tr('notif_type_wedding');
      case AppNotificationType.vendor:
        return AppLang.tr('notif_type_vendor');
      case AppNotificationType.general:
        return AppLang.tr('notif_type_general');
    }
  }
}

extension AppNotificationTypeX on AppNotificationType {
  static AppNotificationType fromString(String? raw) {
    switch (raw) {
      case 'wish':
        return AppNotificationType.wish;
      case 'rsvp':
        return AppNotificationType.rsvp;
      case 'gallery':
        return AppNotificationType.gallery;
      case 'checklist':
        return AppNotificationType.checklist;
      case 'payment':
        return AppNotificationType.payment;
      case 'wedding':
        return AppNotificationType.wedding;
      case 'vendor':
        return AppNotificationType.vendor;
      default:
        return AppNotificationType.general;
    }
  }
}