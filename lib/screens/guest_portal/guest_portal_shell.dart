import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_effect_controller.dart';
import '../../core/app_effects.dart';
import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../core/app_theme_controller.dart';
import '../../models/invitation_model.dart';
import '../../widgets/ambient_music_controls.dart';
import '../../widgets/effect_background.dart';
import '../../widgets/effect_picker.dart';
import '../../widgets/page_glass.dart';
import '../guest_camera_screen.dart';
import '../public_invite_screen.dart';
import 'guest_home_tab.dart';
import 'guest_seating_tab.dart';
import 'guest_timeline_tab.dart';

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
  String _legacyEffectId = AppEffectStyle.noneId;

  @override
  void initState() {
    super.initState();
    _loadLegacyEffect();
  }

  Future<void> _loadLegacyEffect() async {
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

      if (mounted) setState(() => _legacyEffectId = style);
    } catch (_) {}
  }

  double get _legacyFxIntensity {
    switch (_legacyEffectId) {
      case AppEffectStyle.lavenderId:
      case AppEffectStyle.roseId:
        return 0.55;
      case AppEffectStyle.goldId:
      case AppEffectStyle.champagneId:
        return 0.45;
      case AppEffectStyle.midnightId:
        return 0.40;
      default:
        return 0.35;
    }
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLang.I,
        AppThemeController.I,
        AppEffectController.I,
      ]),
      builder: (context, _) {
        final pages = <Widget>[
          GuestHomeTab(
            weddingId: widget.weddingId,
            invitation: widget.invitation,
            onOpenTab: (i) => setState(() => _index = i),
          ),
          PublicInviteScreen(
            weddingId: widget.weddingId,
            invitation: widget.invitation,
            previewMode: false,
            showGuestPanelButton: false,
            allowPop: false,
          ),
          GuestTimelineTab(
            weddingId: widget.weddingId,
            invitation: widget.invitation,
          ),
          GuestCameraScreen(weddingId: widget.weddingId),
          GuestSeatingTab(weddingId: widget.weddingId),
        ];

        return Directionality(
          textDirection: AppLang.I.direction,
          child: EffectBackgroundStack(
            opacity: 0.9,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: GlassAppBar(
                opacity: 0.82,
                blurSigma: 12,
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
                leading: widget.onLeavePortal != null
                    ? IconButton(
                        tooltip: _t('back_to_invite', 'کارت دعوت', 'Invite card'),
                        onPressed: widget.onLeavePortal,
                        icon: Icon(
                          Icons.mail_outline_rounded,
                          color: AppTok.accent(context),
                          size: 22,
                        ),
                      )
                    : null,
                actions: [
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
                      size: 22,
                    ),
                  ),
                  const EffectActionButton(),
                  const AmbientMusicActionButton(),
                  const SizedBox(width: 4),
                ],
              ),
              body: Stack(
                children: [
                  Positioned.fill(
                    child: IndexedStack(index: _index, children: pages),
                  ),
                  if (AppEffectController.I.isNone &&
                      _legacyEffectId != AppEffectStyle.noneId)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.55,
                          child: AppEffectOverlay(
                            effectId: _legacyEffectId,
                            intensity: _legacyFxIntensity,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: GlassBottomBar(
                opacity: 0.84,
                blurSigma: 12,
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
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
            ),
          ),
        );
      },
    );
  }
}
