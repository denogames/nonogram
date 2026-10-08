import 'dart:developer' as dev;
import 'analytics_event.dart';

abstract class AnalyticsProvider {
  Future<void> logEvent(AnalyticsEvent event);
}

class DebugConsoleAnalyticsProvider implements AnalyticsProvider {
  final List<AnalyticsEvent> recordedEvents = [];

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    recordedEvents.add(event);
    dev.log(
      '📊 [Analytics] ${event.name}: ${event.parameters}',
      name: 'AnalyticsService',
    );
  }
}

class AnalyticsService {
  final List<AnalyticsProvider> _providers;
  static AnalyticsService? _instance;

  AnalyticsService({List<AnalyticsProvider>? providers})
      : _providers = providers ?? [DebugConsoleAnalyticsProvider()];

  static AnalyticsService get instance =>
      _instance ??= AnalyticsService();

  Future<void> logEvent(String name, [Map<String, dynamic> parameters = const {}]) async {
    final event = AnalyticsEvent(name: name, parameters: parameters);
    for (final provider in _providers) {
      await provider.logEvent(event);
    }
  }

  // Convenience methods matching exact requirement names:
  Future<void> logPuzzleStarted({
    required String puzzleId,
    required String category,
    required int width,
    required int height,
    required String difficulty,
  }) =>
      logEvent(AnalyticsEventNames.puzzleStarted, {
        'puzzle_id': puzzleId,
        'category': category,
        'width': width,
        'height': height,
        'difficulty': difficulty,
      });

  Future<void> logPuzzleCompleted({
    required String puzzleId,
    required int elapsedSeconds,
    required int mistakes,
    required int hintsUsed,
    required bool isDaily,
  }) =>
      logEvent(AnalyticsEventNames.puzzleCompleted, {
        'puzzle_id': puzzleId,
        'elapsed_seconds': elapsedSeconds,
        'mistakes': mistakes,
        'hints_used': hintsUsed,
        'is_daily': isDaily,
      });

  Future<void> logPuzzleAbandoned({
    required String puzzleId,
    required int elapsedSeconds,
  }) =>
      logEvent(AnalyticsEventNames.puzzleAbandoned, {
        'puzzle_id': puzzleId,
        'elapsed_seconds': elapsedSeconds,
      });

  Future<void> logPuzzleRetry({required String puzzleId}) =>
      logEvent(AnalyticsEventNames.puzzleRetry, {'puzzle_id': puzzleId});

  Future<void> logHintUsed({required String puzzleId, required int remaining}) =>
      logEvent(AnalyticsEventNames.hintUsed, {
        'puzzle_id': puzzleId,
        'hints_remaining': remaining,
      });

  Future<void> logMistakeMade({required String puzzleId, required int mistakeCount}) =>
      logEvent(AnalyticsEventNames.mistakeMade, {
        'puzzle_id': puzzleId,
        'mistake_count': mistakeCount,
      });

  Future<void> logUndoUsed({required String puzzleId}) =>
      logEvent(AnalyticsEventNames.undoUsed, {'puzzle_id': puzzleId});

  Future<void> logGridZoomed({required double scale}) =>
      logEvent(AnalyticsEventNames.gridZoomed, {'scale': scale});

  Future<void> logInputModeChanged({required String mode}) =>
      logEvent(AnalyticsEventNames.inputModeChanged, {'mode': mode});

  Future<void> logDailyChallengeCompleted({
    required String dateKey,
    required int elapsedSeconds,
  }) =>
      logEvent(AnalyticsEventNames.dailyChallengeCompleted, {
        'date_key': dateKey,
        'elapsed_seconds': elapsedSeconds,
      });

  Future<void> logAdImpression({required String placement}) =>
      logEvent(AnalyticsEventNames.adImpression, {'placement': placement});

  Future<void> logRewardedAdCompleted({required String reward}) =>
      logEvent(AnalyticsEventNames.rewardedAdCompleted, {'reward': reward});

  Future<void> logPurchaseVerified({
    required String productId,
    required String transactionId,
  }) =>
      logEvent(AnalyticsEventNames.purchaseVerified, {
        'product_id': productId,
        'transaction_id': transactionId,
      });

  Future<void> logAdsFreeActivated({required String source}) =>
      logEvent(AnalyticsEventNames.adsFreeActivated, {'source': source});
}
