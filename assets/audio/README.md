# Ambient Music Assets

This folder contains 2 tiny local MP3s used only as **in-app ambient background** (default OFF, 30% volume, loop). No Firebase Storage is used.

- `ambient/soft_ambient.mp3` — Soft Ambient, warm & calm
- `ambient/calm_dreamscape.mp3` — Calm Dreamscape, dreamy & soft

## Source & License

Both tracks are sourced from **Pixabay Music** (free for commercial use, no attribution required, but credited here for transparency).

- Search on Pixabay: "soft ambient", "calm dreamscape"
- License: Pixabay Content License — free to use even commercially, no attribution required.
- If you replace these files, keep them under ~1-2 MB each, MP3 96-128kbps, to keep app size small.

## Usage in app

- Service: `lib/core/ambient_music_service.dart` (singleton, SharedPreferences `ambient_music_enabled`, `ambient_music_track`, `ambient_music_volume`)
- Controls: `lib/widgets/ambient_music_controls.dart` — switch / 2 tracks / volume slider / missing-file safe banner (`music_missing_file` + `music_missing_hint`)
- Guest AppBar: `AmbientMusicActionButton` in `lib/widgets/ambient_music_action_button.dart`
- Couple Profile: `AmbientMusicControls(showTitle:false)` section
- Init in `lib/main.dart` — `AmbientMusicService.I.init()` before runApp, with try/catch so app never crashes if asset missing.

Missing-file handling: if `AudioPlayer.setAsset` throws, UI shows a friendly message and playback stays paused — no crash.

## Notes

- Do NOT upload these MP3s to Firebase Storage — requirement: assets only.
- Volume default 0.30, loop Mode.one, session configured via `audio_session`.
- i18n keys: `ambient_music`, `ambient_music_hint`, `music_enabled`, `music_playing`, `music_paused`, `choose_track`, `music_track_soft_ambient`, `music_track_calm_dreamscape`, `music_missing_file`, `music_missing_hint`.
