import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../screens/bridal_party_screen.dart';
import '../screens/camera_manage_screen.dart';
import '../screens/couple_profile_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/gift_manage_screen.dart';
import '../screens/guest_camera_screen.dart';
import '../screens/invitation_screen.dart';
import '../screens/login_screen.dart';
import '../screens/love_story_screen.dart';
import '../screens/media_library_screen.dart';
import '../screens/music_effects_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/plans_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/qr_gallery_screen.dart';
import '../screens/rsvp_inbox_screen.dart';
import '../screens/supports_manage_screen.dart';
import '../screens/timeline_screen.dart';
import '../screens/vendors_screen.dart';
import '../screens/wishes_screen.dart';
import '../services/notification_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.weddingId,
  });

  final String weddingId;

  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  String _faDigits(String s) {
    if (!AppLang.I.isFa) return s;
    return s.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _fa[i] : c;
    }).join();
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const t = AppLang.tr;

    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final bg = AppTok.background(context);
        final text = AppTok.text(context);
        final textSoft = AppTok.textSoft(context);
        final accent = AppTok.accent(context);
        final accentDeep = AppTok.accentDeep(context);
        final border = AppTok.border(context);
        final dark = AppTok.isDark(context);
        final greenSoft =
            dark ? AppDarkPalette.brandGreenSoft : AppPalette.brandGreenSoft;

        return Drawer(
          backgroundColor: bg,
          child: SafeArea(
            child: Column(
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: user == null
                      ? null
                      : FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                  builder: (context, snap) {
                    final data = snap.data?.data() ?? {};
                    final name = (data['displayName'] ??
                            data['name'] ??
                            user?.email?.split('@').first ??
                            t('user'))
                        .toString();
                    final email =
                        (data['email'] ?? user?.email ?? '').toString();
                    final photo = (data['photoUrl'] ?? '').toString();
                    final role = (data['role'] ?? '').toString();

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(weddingId: weddingId),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 28, 16, 22),
                        decoration: BoxDecoration(
                          gradient: AppTok.drawerHeaderGradient(context),
                          border: Border(
                            bottom: BorderSide(color: border),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.55),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 34,
                                backgroundColor: greenSoft,
                                backgroundImage: photo.isNotEmpty
                                    ? NetworkImage(photo)
                                    : null,
                                child: photo.isEmpty
                                    ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: accentDeep,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: text,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textSoft,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  if (role.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: accent.withValues(alpha: 0.28),
                                        ),
                                      ),
                                      child: Text(
                                        role == 'bride' ? t('bride') : t('groom'),
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLang.I.isFa
                                        ? 'مشاهده پروفایل'
                                        : 'View profile',
                                    style: TextStyle(
                                      color: accentDeep,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              AppLang.I.isFa
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                              color: textSoft,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // پروفایل از لیست حذف شد — فقط از هدر
                      _item(
                        context,
                        Icons.favorite_outline,
                        t('couple_profile'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CoupleProfileScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _item(
                        context,
                        Icons.auto_stories_outlined,
                        t('love_story'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LoveStoryScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _item(context, Icons.favorite_border, t('wishes'), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WishesScreen(weddingId: weddingId),
                          ),
                        );
                      }),
                      _item(
                        context,
                        Icons.groups_2_outlined,
                        t('bridal_party'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BridalPartyScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _item(
                        context,
                        Icons.view_timeline_outlined,
                        t('timeline'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TimelineScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      Divider(color: AppTok.border(context)),
                      _item(
                        context,
                        Icons.photo_library_outlined,
                        t('gallery'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QrGalleryScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _item(
                        context,
                        Icons.collections_outlined,
                        t('media_library'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MediaLibraryScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _item(
                        context,
                        Icons.manage_accounts_outlined,
                        t('camera_manage'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CameraManageScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _item(
                        context,
                        Icons.camera_alt_outlined,
                        t('guest_camera'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GuestCameraScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _item(context, Icons.mail_outline, t('invitation'), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InvitationScreen(weddingId: weddingId),
                          ),
                        );
                      }),
                      _item(
                        context,
                        Icons.mark_email_read_outlined,
                        t('rsvp_inbox'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RsvpInboxScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      // ── هدایای عروسی (زوج) ──
                      _item(
                        context,
                        Icons.card_giftcard_outlined,
                        _t('gift_manage_title', 'مدیریت هدایا', 'Gift registry'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GiftManageScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _item(
                        context,
                        Icons.storefront_outlined,
                        t('vendors'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  VendorsScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _item(
                        context,
                        Icons.music_note_outlined,
                        t('music_effects'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MusicEffectsScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _item(
                        context,
                        Icons.volunteer_activism_outlined,
                        t('supports_title'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupportsManageScreen(
                                weddingId: weddingId,
                              ),
                            ),
                          );
                        },
                      ),
                      _item(
                        context,
                        Icons.workspace_premium_outlined,
                        t('plans_title_short'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlansScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      Divider(color: AppTok.border(context)),
                      _item(
                        context,
                        Icons.feedback_outlined,
                        t('feedback'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FeedbackScreen(weddingId: weddingId),
                            ),
                          );
                        },
                      ),
                      _notificationsItem(context),
                      _item(
                        context,
                        Icons.info_outline,
                        t('photo_storage_info'),
                        () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTok.card(ctx),
                              surfaceTintColor: Colors.transparent,
                              title: Text(
                                t('photo_storage_title'),
                                style: TextStyle(color: AppTok.text(ctx)),
                              ),
                              content: Text(
                                t('photo_storage_body'),
                                style: TextStyle(
                                  color: AppTok.textSoft(ctx),
                                  height: 1.6,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    t('ok'),
                                    style: TextStyle(
                                      color: AppTok.accent(ctx),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Divider(color: AppTok.border(context)),
                      _item(
                        context,
                        Icons.logout,
                        t('logout'),
                        () async {
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (_) => false,
                          );
                        },
                        danger: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _notificationsItem(BuildContext context) {
    const t = AppLang.tr;
    final accent = AppTok.accent(context);
    final text = AppTok.text(context);
    final danger = AppTok.danger(context);

    return StreamBuilder<int>(
      stream: NotificationService(weddingId).watchUnreadCount(),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        final label = count > 99 ? '99+' : _faDigits('$count');

        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none, color: accent),
              if (count > 0)
                Positioned(
                  left: AppLang.I.isFa ? -4 : null,
                  right: AppLang.I.isFa ? null : -4,
                  top: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            t('notifications'),
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: count > 0
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: danger,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(weddingId: weddingId),
              ),
            );
          },
        );
      },
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final accent = AppTok.accent(context);
    final text = AppTok.text(context);
    final dangerColor = AppTok.danger(context);

    return ListTile(
      leading: Icon(
        icon,
        color: danger ? dangerColor : accent,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? dangerColor : text,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}