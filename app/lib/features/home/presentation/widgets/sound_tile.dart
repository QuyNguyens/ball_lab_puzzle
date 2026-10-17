import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../ball_lab/presentation/controllers/audio_controller.dart';

class SoundTile extends ConsumerWidget {
  const SoundTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSoundEnabled = ref.watch(audioSettingsControllerProvider);

    return SwitchListTile(
      secondary: Icon(
        isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      onChanged: (_) {
        ref.read(audioSettingsControllerProvider.notifier).toggleSound();
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      value: isSoundEnabled,
      title: Text(
        AppLocalizations.of(context).soundEffectsLabel,
        style: Theme.of(
          context,
        ).textTheme.titleMedium!.apply(fontWeightDelta: 2),
      ),
    );
  }
}
