import 'package:flutter/material.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../services/ambient_music_service.dart';

/// Ambient music controls — switch, 2 tracks, volume, missing-file safe
class AmbientMusicControls extends StatelessWidget {
  const AmbientMusicControls({
    super.key,
    this.compact = false,
    this.showTitle = true,
  });

  final bool compact;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AmbientMusicService.I]),
      builder: (context, _) {
        final svc = AmbientMusicService.I;
        final isDark = AppTok.isDark(context);
        final accent = AppTok.accent(context);
        final text = AppTok.text(context);
        final textSoft = AppTok.textSoft(context);
        final card = AppTok.card(context);
        final border = AppTok.border(context);

        if (!svc.ready) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLang.tr('loading'),
                  style: TextStyle(color: textSoft, fontSize: 12),
                ),
              ],
            ),
          );
        }

        if (compact) {
          return _compactControl(context, svc);
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTitle) ...[
                Row(
                  children: [
                    Icon(Icons.music_note_rounded, color: accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLang.tr('ambient_music'),
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (svc.missingAsset)
                      Icon(Icons.warning_amber_rounded,
                          color: AppTok.danger(context), size: 18),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              // enable switch
              Material(
                color: AppTok.cardSoft(context),
                borderRadius: BorderRadius.circular(12),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  secondary: Icon(
                    svc.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: svc.enabled ? accent : textSoft,
                  ),
                  title: Text(
                    AppLang.tr('music_enabled'),
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: svc.missingAsset
                      ? Text(
                          AppLang.tr('music_missing_file'),
                          style: TextStyle(
                            color: AppTok.danger(context),
                            fontSize: 11,
                          ),
                        )
                      : Text(
                          svc.isPlaying
                              ? AppLang.tr('music_playing')
                              : AppLang.tr('music_paused'),
                          style: TextStyle(color: textSoft, fontSize: 11),
                        ),
                  value: svc.enabled,
                  activeThumbColor: accent,
                  onChanged: (v) => svc.setEnabled(v),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLang.tr('choose_track'),
                style: TextStyle(
                  color: textSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...AmbientMusicService.tracks.map((t) {
                final selected = svc.trackId == t.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected
                        ? accent.withValues(alpha: isDark ? 0.18 : 0.12)
                        : AppTok.cardSoft(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => svc.setTrack(t.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? accent : border,
                            width: selected ? 1.2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected ? accent : textSoft,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLang.tr(t.nameKey),
                                style: TextStyle(
                                  color: text,
                                  fontWeight:
                                      selected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (selected && svc.loading)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accent,
                                ),
                              )
                            else if (selected && svc.isPlaying)
                              Icon(Icons.equalizer_rounded,
                                  color: accent, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.volume_down_rounded, color: textSoft, size: 18),
                  Expanded(
                    child: Slider(
                      value: svc.volume.clamp(0.0, 1.0),
                      min: 0,
                      max: 1,
                      divisions: 10,
                      activeColor: accent,
                      inactiveColor: AppTok.ringTrack(context),
                      onChanged: (v) => svc.setVolume(v),
                    ),
                  ),
                  Icon(Icons.volume_up_rounded, color: textSoft, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${(svc.volume * 100).round()}%',
                    style: TextStyle(
                      color: textSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (svc.missingAsset) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTok.danger(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTok.danger(context).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    AppLang.tr('music_missing_hint'),
                    style: TextStyle(
                      color: AppTok.danger(context),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _compactControl(BuildContext context, AmbientMusicService svc) {
    final accent = AppTok.accent(context);
    final textSoft = AppTok.textSoft(context);
    final isDark = AppTok.isDark(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: AppLang.tr('ambient_music'),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: AppTok.card(context),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              builder: (_) => const _MusicSheet(),
            );
          },
          icon: Icon(
            svc.enabled && svc.isPlaying
                ? Icons.music_note_rounded
                : Icons.music_note_outlined,
            color: svc.enabled
                ? accent
                : (isDark ? textSoft : accent.withValues(alpha: 0.7)),
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _MusicSheet extends StatelessWidget {
  const _MusicSheet();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AmbientMusicService.I]),
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.music_note_rounded,
                            color: AppTok.accent(context), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLang.tr('ambient_music'),
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close,
                              color: AppTok.textSoft(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const AmbientMusicControls(
                      compact: false,
                      showTitle: false,
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

/// Small action button for AppBar
class AmbientMusicActionButton extends StatelessWidget {
  const AmbientMusicActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AmbientMusicService.I,
      builder: (context, _) {
        final svc = AmbientMusicService.I;
        final accent = AppTok.accent(context);
        final isDark = AppTok.isDark(context);
        final textSoft = AppTok.textSoft(context);

        return IconButton(
          tooltip: AppLang.tr('ambient_music'),
          onPressed: () async {
            if (!svc.ready) {
              await svc.init();
            }
            if (!svc.enabled) {
              await svc.setEnabled(true);
            } else {
              await svc.togglePlay();
            }
          },
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: AppTok.card(context),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              builder: (_) => const _MusicSheet(),
            );
          },
          icon: Icon(
            svc.enabled && svc.isPlaying
                ? Icons.music_note_rounded
                : (svc.enabled
                    ? Icons.music_note_outlined
                    : Icons.music_off_outlined),
            color: svc.enabled
                ? accent
                : (isDark ? textSoft : accent.withValues(alpha: 0.6)),
            size: 22,
          ),
        );
      },
    );
  }
}
