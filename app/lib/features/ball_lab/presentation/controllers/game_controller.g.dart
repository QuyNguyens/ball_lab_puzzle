// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the pure Dart [GameEngine].

@ProviderFor(gameEngine)
final gameEngineProvider = GameEngineProvider._();

/// Provider for the pure Dart [GameEngine].

final class GameEngineProvider
    extends $FunctionalProvider<GameEngine, GameEngine, GameEngine>
    with $Provider<GameEngine> {
  /// Provider for the pure Dart [GameEngine].
  GameEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameEngineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameEngineHash();

  @$internal
  @override
  $ProviderElement<GameEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GameEngine create(Ref ref) {
    return gameEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameEngine>(value),
    );
  }
}

String _$gameEngineHash() => r'765eab5754217c81448f858819f3cf34c75641fe';

/// Provider for the [LevelProviderService].

@ProviderFor(levelProviderService)
final levelProviderServiceProvider = LevelProviderServiceProvider._();

/// Provider for the [LevelProviderService].

final class LevelProviderServiceProvider
    extends
        $FunctionalProvider<
          LevelProviderService,
          LevelProviderService,
          LevelProviderService
        >
    with $Provider<LevelProviderService> {
  /// Provider for the [LevelProviderService].
  LevelProviderServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'levelProviderServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$levelProviderServiceHash();

  @$internal
  @override
  $ProviderElement<LevelProviderService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LevelProviderService create(Ref ref) {
    return levelProviderService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LevelProviderService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LevelProviderService>(value),
    );
  }
}

String _$levelProviderServiceHash() =>
    r'6dde4d05d3c3eb01494fc5b2329a19b6a51bfd39';

/// Gameplay controller managing the active Ball Lab puzzle board.
///
/// Implements the two-tap interaction model:
/// 1. Tapping a valid source selects it.
/// 2. Tapping the same source deselects it.
/// 3. Tapping a valid destination executes the ball transfer.
/// 4. Tapping another valid source switches the selection.
/// 5. Tapping an invalid destination retains the source selection for retry.

@ProviderFor(GameController)
final gameControllerProvider = GameControllerProvider._();

/// Gameplay controller managing the active Ball Lab puzzle board.
///
/// Implements the two-tap interaction model:
/// 1. Tapping a valid source selects it.
/// 2. Tapping the same source deselects it.
/// 3. Tapping a valid destination executes the ball transfer.
/// 4. Tapping another valid source switches the selection.
/// 5. Tapping an invalid destination retains the source selection for retry.
final class GameControllerProvider
    extends $NotifierProvider<GameController, GamePlayState> {
  /// Gameplay controller managing the active Ball Lab puzzle board.
  ///
  /// Implements the two-tap interaction model:
  /// 1. Tapping a valid source selects it.
  /// 2. Tapping the same source deselects it.
  /// 3. Tapping a valid destination executes the ball transfer.
  /// 4. Tapping another valid source switches the selection.
  /// 5. Tapping an invalid destination retains the source selection for retry.
  GameControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameControllerHash();

  @$internal
  @override
  GameController create() => GameController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GamePlayState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GamePlayState>(value),
    );
  }
}

String _$gameControllerHash() => r'ae13f396a889e8deef483d625a73480e2cb1965b';

/// Gameplay controller managing the active Ball Lab puzzle board.
///
/// Implements the two-tap interaction model:
/// 1. Tapping a valid source selects it.
/// 2. Tapping the same source deselects it.
/// 3. Tapping a valid destination executes the ball transfer.
/// 4. Tapping another valid source switches the selection.
/// 5. Tapping an invalid destination retains the source selection for retry.

abstract class _$GameController extends $Notifier<GamePlayState> {
  GamePlayState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GamePlayState, GamePlayState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GamePlayState, GamePlayState>,
              GamePlayState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
