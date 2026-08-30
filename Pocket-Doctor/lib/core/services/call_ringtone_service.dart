import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class CallRingtoneService {
  static bool _isPlaying = false;

  /// Start playing default call ringtone
  static Future<void> startRingtone() async {
    if (kIsWeb) return;
    if (_isPlaying) return;
    try {
      _isPlaying = true;
      await FlutterRingtonePlayer().playRingtone(
        asAlarm: true,
        looping: true,
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('Error playing ringtone: $e');
    }
  }

  /// Stop ringtone sound
  static Future<void> stopRingtone() async {
    if (kIsWeb) return;
    if (!_isPlaying) return;
    try {
      _isPlaying = false;
      await FlutterRingtonePlayer().stop();
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
  }
}
