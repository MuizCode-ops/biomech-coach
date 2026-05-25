// lib/services/tts_coach.dart
// Text-to-Speech virtual coach for mid-rep audio cues.

import 'package:flutter_tts/flutter_tts.dart';

class TtsCoach {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  DateTime? _lastCueTime;

  /// Minimum ms between cues to avoid spamming.
  static const int _minCueIntervalMs = 1500;

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.55); // slightly slower for gym noise
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
  }

  /// Speak a coaching cue if enough time has passed since the last one.
  Future<void> speak(String message) async {
    final now = DateTime.now();
    if (_lastCueTime != null &&
        now.difference(_lastCueTime!).inMilliseconds < _minCueIntervalMs) {
      return;
    }
    if (_isSpeaking) {
      await _tts.stop();
    }
    _lastCueTime = now;
    await _tts.speak(message);
  }

  /// Speak a rep result cue.
  Future<void> announceRepResult({required bool isValid, required int validCount}) async {
    if (isValid) {
      await speak('Valid rep! $validCount');
    } else {
      await speak('Rep not counted. Fix your form.');
    }
  }

  /// Common cues for quick access.
  Future<void> cueDeeper() => speak('Go deeper!');
  Future<void> cueBackRounding() => speak('Back rounding! Brace your core.');
  Future<void> cueLockout() => speak('Full lockout!');
  Future<void> cueTouchChest() => speak('Touch your chest!');
  Future<void> cueKneesOut() => speak('Push your knees out!');
  Future<void> cueReady() => speak('Ready. Begin when ready.');

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
