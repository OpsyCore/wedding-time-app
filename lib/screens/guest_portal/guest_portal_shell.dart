import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_effects.dart';
import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../core/app_theme_controller.dart';
import '../../models/invitation_model.dart';
import '../guest_camera_screen.dart';
import '../public_invite_screen.dart';
import 'guest_gallery_tab.dart';
import 'guest_gifts_tab.dart';
import 'guest_home_tab.dart';
import 'guest_love_story_tab.dart';
import 'guest_seating_tab.dart';
import 'guest_supports_tab.dart';
import 'guest_timeline_tab.dart';
import 'guest_wishes_tab.dart';

class GuestPortalShell extends StatefulWidget {
  const GuestPortalShell({
    super.key,
    required this.weddingId,
    required this.invitation,
    this.onLeavePortal,
  });

  final String weddingId;
  final InvitationModel invitation;
  final VoidCallback? onLeavePortal;

  @override
  State<GuestPortalShell> createState() => _GuestPortalShellState();
}

class _GuestPortalShellState extends State<GuestPortalShell> {
  int _index = 0;
  String _effectStyleId = AppEffectStyle.noneId;

  @override
  void initState() {
    super.initState();
    _loadEffect();
  }

  Future<void> _loadEffect() async {
    try {
      final wid = widget.weddingId;
      String style = AppEffectStyle.noneId;

      final settings = await FirebaseFirestore.instance
          .collection('weddings')
          .doc(wid)
          .collection('musicSettings')
          .doc('main')
          .get();
      final s = settings.data() ?? {};
      final fx = s['effects'];
      if (fx is Map) {
        final sid = (fx['styleId'] ?? fx['effectId'] ?? '').toString().trim();
        if (sid.isNotEmpty && sid != 'none') {
          style = sid;
        } else if (fx['inviteHearts'] == true) {
          style = AppEffectStyle.lavenderId;
        } else if (fx['particles'] == true) {
          style = AppEffectStyle.goldId;
        }
      }

      if (style == AppEffectStyle.noneId) {
        final wedding = await FirebaseFirestore.instance
            .collection('weddings')
            .doc(wid)
            .get();
        final w = wedding.data() ?? {};
        final sid = (w['effectStyleId'] ?? '').toString().trim();
        if (sid.isNotEmpty) {
          style = sid;
        } else if (w['effectsInviteHearts'] == true) {
          style = AppEffectStyle.lavenderId;
        } else if (w['effectsParticles'] == true) {
          style = AppEffectStyle.goldId;
        }
      }

      if (mounted) setState(() => _effectStyleId = style);
    } catch (_) {}
  }

  double get _fxIntensity {
    switch (_effectStyleId) {
      case AppEffectStyle.lavenderId:
      case AppEffectStyle.roseId:
        return 0.85;
      case AppEffectStyle.goldId:
      case AppEffectStyle.champagneId:
        return 0.75;
      case AppEffectStyle.midnightId:
        return 0.65;
      default:
        return 0.55;
    }
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final pages = <Widget>[
          GuestHomeTab(
            weddingId: widget.weddingId,
            invitation: widget.invitation,
          ),
          PublicInviteScreen(
            weddingId: widget.weddingId,
            invitation: widget.invitation,
            previewMode: false,
            showGuestPanelButton: false,
            allowPop: false,
          ),
          // برنامه کارت دعوت + کالکشن timeline
          GuestTimelineTab(
            weddingId: widget.weddingId,
            invitation: widget.invitation,
          ),
          GuestCameraScreen(weddingId: widget.weddingId),
          GuestSeatingTab(weddingId: widget.weddingId),
        ];

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: AppTok.background(context),
            appBar: AppBar(
              backgroundColor: AppTok.background(context),
              elevation: 0,
              centerTitle: true,
              // مهم: leading سفارشی نگذار تا همبرگری drawer بماند
              automaticallyImplyLeading: true,
              title: Text(
                widget.invitation.coupleTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'serif',
                ),
              ),
              actions: [
                if (widget.onLeavePortal != null)
                  IconButton(
                    tooltip: _t('back_to_invite', 'کارت دعوت', 'Invite card'),
                    onPressed: widget.onLeavePortal,
                    icon: Icon(
                      Icons.mail_outline,
                      color: AppTok.accent(context),
                    ),
                  ),
                IconButton(
                  tooltip: AppThemeController.I.isDark
                      ? _t('light_mode', 'روز', 'Light')
                      : _t('dark_mode', 'شب', 'Dark'),
                  onPressed: () {
                    AppThemeController.I.setDark(!AppThemeController.I.isDark);
                  },
                  icon: Icon(
                    AppThemeController.I.isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: AppTok.accent(context),
                  ),
                ),
              ],
            ),
            drawer: _GuestDrawer(
              coupleTitle: widget.invitation.coupleTitle,
              onLoveStory: () => _openPage(
                GuestLoveStoryTab(weddingId: widget.weddingId),
              ),
              onWishes: () => _openPage(
                GuestWishesTab(weddingId: widget.weddingId),
              ),
              onGallery: () => _openPage(
                Scaffold(
                  backgroundColor: AppTok.background(context),
                  appBar: AppBar(
                    backgroundColor: AppTok.background(context),
                    elevation: 0,
                    title: Text(
                      _t('gallery', 'گالری', 'Gallery'),
                      style: TextStyle(color: AppTok.text(context)),
                    ),
                    iconTheme: IconThemeData(color: AppTok.text(context)),
                  ),
                  body: GuestGalleryTab(weddingId: widget.weddingId),
                ),
              ),
              onSupports: () => _openPage(
                GuestSupportsTab(weddingId: widget.weddingId),
              ),
              onGifts: () => _openPage(
                Scaffold(
                  backgroundColor: AppTok.background(context),
                  appBar: AppBar(
                    backgroundColor: AppTok.background(context),
                    elevation: 0,
                    title: Text(
                      _t('gifts', 'هدایا', 'Gifts'),
                      style: TextStyle(color: AppTok.text(context)),
                    ),
                    iconTheme: IconThemeData(color: AppTok.text(context)),
                  ),
                  body: GuestGiftsTab(weddingId: widget.weddingId),
                ),
              ),
              onToggleTheme: () {
                AppThemeController.I.setDark(!AppThemeController.I.isDark);
              },
              onBackToInvite: widget.onLeavePortal,
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: IndexedStack(index: _index, children: pages),
                ),
                if (_effectStyleId != AppEffectStyle.noneId)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AppEffectOverlay(
                        effectId: _effectStyleId,
                        intensity: _fxIntensity,
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: AppTok.card(context),
              indicatorColor: AppTok.accent(context).withValues(alpha: 0.18),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon:
                      Icon(Icons.home, color: AppTok.accent(context)),
                  label: _t('guest_tab_home', 'خانه', 'Home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.mail_outline),
                  selectedIcon:
                      Icon(Icons.mail, color: AppTok.accent(context)),
                  label: _t('guest_tab_invite', 'دعوت‌نامه', 'Invite'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.view_timeline_outlined),
                  selectedIcon: Icon(Icons.view_timeline,
                      color: AppTok.accent(context)),
                  label: _t('guest_tab_timeline', 'تایم‌لاین', 'Timeline'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.photo_camera_outlined),
                  selectedIcon: Icon(Icons.photo_camera,
                      color: AppTok.accent(context)),
                  label: _t('guest_tab_camera', 'دوربین', 'Camera'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.event_seat_outlined),
                  selectedIcon: Icon(Icons.event_seat,
                      color: AppTok.accent(context)),
                  label: _t('guest_tab_seating', 'صندلی', 'Seats'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GuestDrawer extends StatelessWidget {
  const _GuestDrawer({
    required this.coupleTitle,
    required this.onLoveStory,
    required this.onWishes,
    required this.onGallery,
    required this.onSupports,
    required this.onGifts,
    required this.onToggleTheme,
    this.onBackToInvite,
  });

  final String coupleTitle;
  final VoidCallback onLoveStory;
  final VoidCallback onWishes;
  final VoidCallback onGallery;
  final VoidCallback onSupports;
  final VoidCallback onGifts;
  final VoidCallback onToggleTheme;
  final VoidCallback? onBackToInvite;

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.I.isDark;

    return Drawer(
      backgroundColor: AppTok.background(context),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: AppTok.drawerHeaderGradient(context),
                border: Border(
                  bottom: BorderSide(color: AppTok.border(context)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite, color: AppTok.accent(context), size: 28),
                  const SizedBox(height: 10),
                  Text(
                    coupleTitle,
                    style: TextStyle(
                      color: AppTok.text(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t('guest_menu', 'منوی مهمان', 'Guest menu'),
                    style: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            _tile(context, Icons.auto_stories_outlined,
                _t('love_story', 'داستان عشق', 'Love story'), onLoveStory),
            _tile(context, Icons.favorite_border,
                _t('wishes', 'آرزوها', 'Wishes'), onWishes),
            _tile(context, Icons.photo_library_outlined,
                _t('gallery', 'گالری', 'Gallery'), onGallery),
            _tile(context, Icons.volunteer_activism_outlined,
                _t('supports_title', 'حمایت‌ها', 'Supports'), onSupports),
            _tile(context, Icons.card_giftcard_outlined,
                _t('gifts', 'هدایا', 'Gifts'), onGifts),
            const Divider(),
            SwitchListTile(
              value: isDark,
              onChanged: (_) => onToggleTheme(),
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppTok.accent(context),
              ),
              title: Text(
                isDark
                    ? _t('dark_mode', 'تم شب', 'Dark mode')
                    : _t('light_mode', 'تم روز', 'Light mode'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onBackToInvite != null) ...[
              const Divider(),
              ListTile(
                leading:
                    Icon(Icons.mail_outline, color: AppTok.accent(context)),
                title: Text(
                  _t('back_to_invite_card', 'بازگشت به کارت دعوت',
                      'Back to invite card'),
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onBackToInvite!();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTok.accent(context)),
      title: Text(
        title,
        style: TextStyle(
          color: AppTok.text(context),
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