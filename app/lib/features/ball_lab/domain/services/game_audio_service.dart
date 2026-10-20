import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralized audio service for Ball Lab Puzzle.
///
/// Manages high-performance sound effect (SFX) playback with:
/// - Low latency mode (Android SoundPool) for immediate response.
/// - Concurrency via multi-player round-robin pool to prevent clipping overlapping sounds.
/// - Safe error handling ensuring audio hardware issues never crash the app.
/// - Sound on/off master control with state persistence.
class GameAudioService {
  GameAudioService({bool initialSoundEnabled = true})
      : _isSoundEnabled = initialSoundEnabled {
    _initPlayers();
  }

  bool _isSoundEnabled;
  bool _isDisposed = false;

  late final AudioPlayer _player1;
  late final AudioPlayer _player2;
  int _roundRobinIndex = 0;

  /// Whether sound effects are currently active.
  bool get isSoundEnabled => _isSoundEnabled;

  /// Updates sound on/off state.
  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
    if (!enabled) {
      stopAll();
    }
  }

  void _initPlayers() {
    try {
      _player1 = AudioPlayer();
      _player2 = AudioPlayer();

      // Configure low-latency mode for rapid game responsive feedback
      _player1.setPlayerMode(PlayerMode.lowLatency).catchError((_) {});
      _player2.setPlayerMode(PlayerMode.lowLatency).catchError((_) {});

      _player1.setReleaseMode(ReleaseMode.stop).catchError((_) {});
      _player2.setReleaseMode(ReleaseMode.stop).catchError((_) {});
    } catch (e) {
      debugPrint('GameAudioService: Initialization warning: $e');
    }
  }

  AudioPlayer get _availablePlayer {
    _roundRobinIndex = (_roundRobinIndex + 1) % 2;
    return _roundRobinIndex == 0 ? _player1 : _player2;
  }

  Future<void> _playSfx(String sfxFileName, {double volume = 1.0}) async {
    if (!_isSoundEnabled || _isDisposed) return;
    try {
      final AudioPlayer player = _availablePlayer;
      await player.stop().catchError((_) {});
      await player.setVolume(volume).catchError((_) {});
      await player
          .play(
        AssetSource('audio/sfx/$sfxFileName'),
        volume: volume,
      )
          .catchError((Object err) {
        debugPrint('GameAudioService: Failed to play $sfxFileName: $err');
      });
    } catch (e) {
      debugPrint('GameAudioService: Safe error intercept on $sfxFileName: $e');
    }
  }

  /// 1. Successful ball transfer into target tube.
  Future<void> playBallMove() => _playSfx('ball_move.wav', volume: 0.90);

  /// 2. Successful undo step.
  Future<void> playUndo() => _playSfx('undo.wav', volume: 0.85);

  /// 3. Valid hint discovery delivered to player.
  Future<void> playHint() => _playSfx('hint.wav', volume: 0.95);

  /// 4. Remaining moves drop down to warning threshold (<= 3 moves).
  Future<void> playLowMovesWarning() => _playSfx('low_moves.wav', volume: 0.85);

  /// 5. Critical warning: player is at 1 remaining move without winning.
  Future<void> playCriticalMovesWarning() =>
      _playSfx('critical_moves.wav', volume: 0.90);

  /// 6. All free and bonus lives exhausted.
  Future<void> playOutOfLives() => _playSfx('out_of_lives.wav', volume: 0.95);

  /// Immediately terminates all active audio playback.
  Future<void> stopAll() async {
    try {
      await _player1.stop().catchError((_) {});
      await _player2.stop().catchError((_) {});
    } catch (_) {}
  }

  /// Disposes all player instances.
  void dispose() {
    _isDisposed = true;
    try {
      _player1.dispose().catchError((_) {});
      _player2.dispose().catchError((_) {});
    } catch (_) {}
  }
}
