import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AmbientTrack {
  const AmbientTrack({
    required this.id,
    required this.assetPath,
    required this.nameKey,
  });

  final String id;
  final String assetPath;
  final String nameKey;
}

class AmbientMusicService extends ChangeNotifier {
  AmbientMusicService._();
  static final AmbientMusicService I = AmbientMusicService._();

  static const _kEnabled = 'ambient_music_enabled';
  static const _kTrack = 'ambient_music_track';
  static const _kVolume = 'ambient_music_volume';

  static const List<AmbientTrack> tracks = [
    AmbientTrack(
      id: 'soft_ambient',
      assetPath: 'assets/audio/ambient/soft_ambient.mp3',
      nameKey: 'music_track_soft_ambient',
    ),
    AmbientTrack(
      id: 'calm_dreamscape',
      assetPath: 'assets/audio/ambient/calm_dreamscape.mp3',
      nameKey: 'music_track_calm_dreamscape',
    ),
  ];

  final AudioPlayer _player = AudioPlayer();

  bool _ready = false;
  bool _enabled = false;
  String _trackId = tracks.first.id;
  double _volume = 0.30;
  bool _playing = false;
  bool _loading = false;
  bool _missingAsset = false;
  String? _error;

  bool get ready => _ready;
  bool get enabled => _enabled;
  String get trackId => _trackId;
  double get volume => _volume;
  bool get isPlaying => _playing;
  bool get loading => _loading;
  bool get missingAsset => _missingAsset;
  String? get error => _error;

  AmbientTrack get track => tracks.firstWhere(
        (t) => t.id == _trackId,
        orElse: () => tracks.first,
      );

  Future<void> init() async {
    if (_ready) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_kEnabled) ?? false;
      final savedTrack = prefs.getString(_kTrack);
      if (savedTrack != null && tracks.any((t) => t.id == savedTrack)) {
        _trackId = savedTrack;
      }
      final savedVol = prefs.getDouble(_kVolume);
      if (savedVol != null) {
        _volume = savedVol.clamp(0.0, 1.0).toDouble();
      }
    } catch (_) {}

    try {
      await _player.setLoopMode(LoopMode.one);
    } catch (_) {}

    _player.playerStateStream.listen(
      (state) {
        final playing = state.playing &&
            state.processingState != ProcessingState.idle &&
            state.processingState != ProcessingState.completed;
        if (playing != _playing) {
          _playing = playing;
          notifyListeners();
        }
      },
      onError: (Object e) {
        _missingAsset = true;
        _error = e.toString();
        _playing = false;
        notifyListeners();
      },
    );

    _ready = true;
    if (_enabled) {
      await _loadCurrent(autoplay: false);
    }
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    await _prefsBool(_kEnabled, value);
    if (value) {
      await _loadCurrent(autoplay: true);
    } else {
      await _stop();
    }
  }

  Future<void> setTrack(String id) async {
    final t = tracks.firstWhere((e) => e.id == id, orElse: () => tracks.first);
    if (t.id == _trackId && !_missingAsset) return;
    _trackId = t.id;
    notifyListeners();
    await _prefsString(_kTrack, _trackId);
    if (_enabled) {
      await _loadCurrent(autoplay: true);
    } else {
      await _stop();
    }
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0).toDouble();
    notifyListeners();
    await _prefsDouble(_kVolume, _volume);
    try {
      await _player.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> togglePlay() async {
    if (!_enabled) {
      await setEnabled(true);
      return;
    }
    if (_playing) {
      try {
        await _player.pause();
      } catch (_) {}
      _playing = false;
      notifyListeners();
    } else {
      await _loadCurrent(autoplay: true);
    }
  }

  Future<void> _loadCurrent({required bool autoplay}) async {
    _loading = true;
    _missingAsset = false;
    _error = null;
    notifyListeners();
    try {
      await _player.stop();
      await _player.setVolume(_volume);
      await _player.setLoopMode(LoopMode.one);
      await _player.setAsset(track.assetPath);
      if (autoplay) {
        await _player.play();
        _playing = true;
      }
    } catch (e) {
      _missingAsset = true;
      _error = e.toString();
      _playing = false;
      if (kDebugMode) {
        print('AmbientMusic load error: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _playing = false;
    notifyListeners();
  }

  Future<void> _prefsBool(String k, bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(k, v);
    } catch (_) {}
  }

  Future<void> _prefsString(String k, String v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(k, v);
    } catch (_) {}
  }

  Future<void> _prefsDouble(String k, double v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(k, v);
    } catch (_) {}
  }
}