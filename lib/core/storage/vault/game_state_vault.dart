import 'package:studio_core_sdk/studio_core_sdk.dart';

/// Crash-safe model representing a saved puzzle state or completed record.
class SavedPuzzleState {
  final String puzzleId;
  final bool isCompleted;
  final int stars;
  final int bestTimeSeconds;
  final DateTime lastPlayed;
  final String? savedBoardState;
  final int savedMistakes;
  final int savedHintsUsed;
  final int savedElapsedSeconds;

  const SavedPuzzleState({
    required this.puzzleId,
    required this.isCompleted,
    required this.stars,
    required this.bestTimeSeconds,
    required this.lastPlayed,
    this.savedBoardState,
    this.savedMistakes = 0,
    this.savedHintsUsed = 0,
    this.savedElapsedSeconds = 0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'puzzleId': puzzleId,
        'isCompleted': isCompleted,
        'stars': stars,
        'bestTimeSeconds': bestTimeSeconds,
        'lastPlayed': lastPlayed.toIso8601String(),
        'savedBoardState': savedBoardState,
        'savedMistakes': savedMistakes,
        'savedHintsUsed': savedHintsUsed,
        'savedElapsedSeconds': savedElapsedSeconds,
      };

  factory SavedPuzzleState.fromJson(Map<String, dynamic> json) =>
      SavedPuzzleState(
        puzzleId: json['puzzleId'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        stars: (json['stars'] as num?)?.toInt() ?? 0,
        bestTimeSeconds: (json['bestTimeSeconds'] as num?)?.toInt() ?? 0,
        lastPlayed: json['lastPlayed'] != null
            ? DateTime.tryParse(json['lastPlayed'] as String) ?? DateTime.now()
            : DateTime.now(),
        savedBoardState: json['savedBoardState'] as String?,
        savedMistakes: (json['savedMistakes'] as num?)?.toInt() ?? 0,
        savedHintsUsed: (json['savedHintsUsed'] as num?)?.toInt() ?? 0,
        savedElapsedSeconds:
            (json['savedElapsedSeconds'] as num?)?.toInt() ?? 0,
      );
}

/// Crash-safe persistent vault managing game state, in-progress grids, and progress
/// backed by SDK's [EncryptedStorageBox].
class GameStateVault {
  static GameStateVault? _instance;
  static GameStateVault get instance => _instance ??= GameStateVault._();

  EncryptedStorageBox? _storageBox;

  GameStateVault._();

  bool get isInitialized => _storageBox != null && _storageBox!.isInitialized;

  EncryptedStorageBox get box {
    final b = _storageBox;
    if (b == null) {
      throw StateError('GameStateVault has not been initialized. Call initialize() first.');
    }
    return b;
  }

  Future<void> initialize({
    required String storageDirectoryPath,
    String encryptionKey = 'nonogram_prod_hmac_secret_2026',
  }) async {
    final box = EncryptedStorageBox(
      boxName: 'nonogram_game_state',
      encryptionKey: encryptionKey,
      storageDirectoryPath: storageDirectoryPath,
    );
    await box.initialize();
    _storageBox = box;
  }

  Future<void> savePuzzleState(SavedPuzzleState state) async {
    if (!isInitialized) return;
    await box.put('puzzle_${state.puzzleId}', state.toJson());
  }

  SavedPuzzleState? getPuzzleState(String puzzleId) {
    if (!isInitialized) return null;
    final raw = box.get<Map<String, dynamic>>('puzzle_$puzzleId');
    if (raw == null) return null;
    return SavedPuzzleState.fromJson(raw);
  }

  List<SavedPuzzleState> getAllSavedPuzzles() {
    if (!isInitialized) return const <SavedPuzzleState>[];
    final result = <SavedPuzzleState>[];
    for (final key in box.keys) {
      if (key.startsWith('puzzle_')) {
        final raw = box.get<Map<String, dynamic>>(key);
        if (raw != null) {
          result.add(SavedPuzzleState.fromJson(raw));
        }
      }
    }
    return result;
  }

  Future<void> clearAll() async {
    if (isInitialized) {
      await box.clear();
    }
  }
}
