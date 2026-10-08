/// Standard structured analytics event names.
class AnalyticsEventNames {
  static const puzzleStarted = 'puzzle_started';
  static const puzzleCompleted = 'puzzle_completed';
  static const puzzleAbandoned = 'puzzle_abandoned';
  static const puzzleRetry = 'puzzle_retry';
  static const hintUsed = 'hint_used';
  static const mistakeMade = 'mistake_made';
  static const undoUsed = 'undo_used';
  static const gridZoomed = 'grid_zoomed';
  static const inputModeChanged = 'input_mode_changed';
  static const dailyChallengeCompleted = 'daily_challenge_completed';
  static const adImpression = 'ad_impression';
  static const rewardedAdCompleted = 'rewarded_ad_completed';
  static const purchaseVerified = 'purchase_verified';
  static const adsFreeActivated = 'ads_free_activated';
}

/// Strongly-typed analytics event.
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    this.parameters = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AnalyticsEvent($name, $parameters)';
}
