import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Speaks turn-by-turn announcements during navigation. Single instance per
/// process — keeps a TTS engine alive across navigation sessions so the first
/// announcement isn't swallowed by cold-start latency.
class NavigationVoiceService {
  NavigationVoiceService._();
  static final NavigationVoiceService instance = NavigationVoiceService._();

  static const _muteKey = 'nav_voice_muted_v1';

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _muted = false;
  String _lastSpoken = '';

  bool get muted => _muted;

  Future<void> init(String languageTag) async {
    if (!_initialized) {
      final prefs = await SharedPreferences.getInstance();
      _muted = prefs.getBool(_muteKey) ?? false;
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _initialized = true;
    }
    // Re-apply language each session so a system-locale change is honoured.
    final lang = _resolveLanguage(languageTag);
    await _tts.setLanguage(lang);
  }

  Future<void> setMuted(bool value) async {
    _muted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_muteKey, value);
    if (value) {
      await _tts.stop();
    }
  }

  Future<void> toggleMuted() => setMuted(!_muted);

  Future<void> speak(String text) async {
    if (_muted || text.isEmpty) return;
    // Avoid re-saying the exact same phrase back-to-back if the screen
    // updates jitter between two GPS frames inside the same phase.
    if (text == _lastSpoken) return;
    _lastSpoken = text;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _lastSpoken = '';
  }

  String _resolveLanguage(String tag) {
    final lower = tag.toLowerCase();
    if (lower.startsWith('de')) return 'de-DE';
    if (lower.startsWith('en')) return 'en-US';
    return 'en-US';
  }
}
