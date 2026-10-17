import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/services/game_audio_service.dart';

const String _soundSettingsKey = 'ball_lab_sound_enabled';

/// StateNotifier/Notifier controlling sound effects on/off state with Hive persistence.
final NotifierProvider<AudioSettingsController, bool>
    audioSettingsControllerProvider =
    NotifierProvider<AudioSettingsController, bool>(
  AudioSettingsController.new,
  name: 'audioSettingsControllerProvider',
);

class AudioSettingsController extends Notifier<bool> {
  @override
  bool build() {
    try {
      final Box<String> box = ref.watch(prefsBoxProvider);
      final String? saved = box.get(_soundSettingsKey);
      if (saved != null) {
        return saved == 'true';
      }
    } catch (_) {}
    return true; // Sound enabled by default
  }

  /// Toggles sound effects on or off.
  Future<void> toggleSound() async {
    final bool nextState = !state;
    state = nextState;
    ref.read(gameAudioServiceProvider).setSoundEnabled(nextState);

    try {
      final Box<String> box = ref.read(prefsBoxProvider);
      await box.put(_soundSettingsKey, nextState.toString());
    } catch (_) {}
  }

  /// Explicitly sets sound effects state.
  Future<void> setSound(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    ref.read(gameAudioServiceProvider).setSoundEnabled(enabled);

    try {
      final Box<String> box = ref.read(prefsBoxProvider);
      await box.put(_soundSettingsKey, enabled.toString());
    } catch (_) {}
  }
}

/// Provider exposing the centralized [GameAudioService] instance.
final Provider<GameAudioService> gameAudioServiceProvider =
    Provider<GameAudioService>((Ref ref) {
  final bool initialEnabled = ref.watch(audioSettingsControllerProvider);
  final GameAudioService service =
      GameAudioService(initialSoundEnabled: initialEnabled);

  // Synchronize runtime mute changes without tearing down AudioPlayer instances
  ref.listen<bool>(audioSettingsControllerProvider, (_, bool enabled) {
    service.setSoundEnabled(enabled);
  });

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}, name: 'gameAudioServiceProvider');
