import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../core/map_launcher.dart';
import '../../models/invitation_model.dart';

class GuestHomeTab extends StatelessWidget {
  const GuestHomeTab({
    super.key,
    required this.weddingId,
    required this.invitation,
  });

  final String weddingId;
  final InvitationModel invitation;

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  String _dateLine(DateTime? d) {
    if (d == null) return AppLang.tr('to_be_announced');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}/$m/$day';
  }

  @override
  Widget build(BuildContext context) {
    final inv = invitation;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // هیرو — بعداً عکس واقعی
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTok.accent(context).withValues(alpha: 0.35),
                AppTok.cardSoft(context),
                AppTok.accentSoft(context).withValues(alpha: 0.25),
              ],
            ),
            border: Border.all(color: AppTok.border(context)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Icon(Icons.favorite, color: Colors.white.withValues(alpha: 0.9), size: 22),
                    const SizedBox(height: 8),
                    Text(
                      inv.coupleTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t(
                        'guest_home_welcome',
                        'به جشن ما خوش آمدید',
                        'Welcome to our wedding',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _infoCard(
          context,
          icon: Icons.calendar_month_outlined,
          title: _t('date', 'تاریخ', 'Date'),
          body: _dateLine(inv.weddingDate),
          sub: inv.eventTime.trim().isEmpty ? null : inv.eventTime.trim(),
        ),
        const SizedBox(height: 10),
        _infoCard(
          context,
          icon: Icons.location_on_outlined,
          title: AppLang.tr('location'),
          body: inv.venueName.trim().isEmpty
              ? AppLang.tr('to_be_announced')
              : inv.venueName.trim(),
          sub: [
            if (inv.venueCity.trim().isNotEmpty) inv.venueCity.trim(),
            if (inv.venueAddress.trim().isNotEmpty) inv.venueAddress.trim(),
          ].join(AppLang.I.isFa ? '، ' : ', '),
          trailing: (inv.venueName.trim().isNotEmpty || inv.hasGeo)
              ? TextButton.icon(
                  onPressed: () {
                    MapLauncher.openLocation(
                      name: inv.venueName,
                      address: inv.venueAddress,
                      lat: inv.lat,
                      lng: inv.lng,
                      mapUrl: inv.mapUrl,
                    );
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: Text(_t('directions', 'مسیریابی', 'Directions')),
                )
              : null,
        ),
        const SizedBox(height: 10),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('weddings')
              .doc(weddingId)
              .snapshots(),
          builder: (context, snap) {
            final d = snap.data?.data() ?? {};
            final bride = (d['brideName'] ?? inv.brideName).toString();
            final groom = (d['groomName'] ?? inv.groomName).toString();
            return _infoCard(
              context,
              icon: Icons.people_outline,
              title: _t('couple', 'عروس و داماد', 'Couple'),
              body: '$groom  &  $bride',
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          _t(
            'guest_home_hint',
            'از منوی بالا (☰) داستان عشق، آرزوها، گالری، حمایت و هدایا را ببینید.',
            'Use the menu (☰) for love story, wishes, gallery, supports and gifts.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    String? sub,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTok.accent(context), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: AppTok.text(context),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null && sub.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(color: AppTok.textSoft(context), fontSize: 12.5),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 8),
            trailing,
          ],
        ],
      ),
    );
  }
}