import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';
import '../../../engine/models/puzzle_definition.dart';
import '../../../engine/validator/puzzle_validator.dart';

class PuzzleCategory {
  final String id;
  final String title;
  final String iconName;
  final List<PuzzleDefinition> puzzles;

  const PuzzleCategory({
    required this.id,
    required this.title,
    required this.iconName,
    required this.puzzles,
  });
}

class PuzzleRepository {
  final Map<String, PuzzleDefinition> _puzzlesById = {};
  final Map<String, List<PuzzleDefinition>> _puzzlesByCategory = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<PuzzleDefinition> get allPuzzles => _puzzlesById.values.toList();

  static const List<Map<String, String>> categoryMetadata = [
    {'id': 'animals', 'title': 'Animals', 'icon': 'pets'},
    {'id': 'nature', 'title': 'Nature', 'icon': 'park'},
    {'id': 'food', 'title': 'Food & Drinks', 'icon': 'restaurant'},
    {'id': 'objects', 'title': 'Objects', 'icon': 'category'},
    {'id': 'symbols', 'title': 'Symbols', 'icon': 'favorite'},
  ];

  Future<void> loadBundledPuzzles() async {
    if (_isLoaded) return;

    for (final cat in categoryMetadata) {
      final catId = cat['id']!;
      try {
        final jsonString = await rootBundle.loadString('assets/puzzles/$catId.json');
        final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;

        final puzzles = <PuzzleDefinition>[];
        for (final item in list) {
          final puzzle = PuzzleDefinition.fromJson(item as Map<String, dynamic>);
          // Checksum verification
          if (puzzle.verifyChecksum()) {
            puzzles.add(puzzle);
            _puzzlesById[puzzle.id] = puzzle;
          }
        }
        _puzzlesByCategory[catId] = puzzles;
      } catch (e) {
        // Log error and continue
      }
    }

    _isLoaded = true;
  }

  /// Manually registers a list of puzzles (useful for tests or dynamic packs).
  void registerPuzzles(List<PuzzleDefinition> puzzles) {
    for (final p in puzzles) {
      _puzzlesById[p.id] = p;
      final catList = _puzzlesByCategory.putIfAbsent(p.category, () => []);
      if (!catList.any((existing) => existing.id == p.id)) {
        catList.add(p);
      }
    }
    _isLoaded = true;
  }

  PuzzleDefinition? getPuzzleById(String id) => _puzzlesById[id];

  List<PuzzleDefinition> getPuzzlesForCategory(String categoryId) =>
      _puzzlesByCategory[categoryId] ?? [];

  List<PuzzleCategory> getCategories() {
    final result = <PuzzleCategory>[];
    final processed = <String>{};
    for (final meta in categoryMetadata) {
      final catId = meta['id']!;
      processed.add(catId);
      final puzzles = _puzzlesByCategory[catId] ?? [];
      result.add(PuzzleCategory(
        id: catId,
        title: meta['title']!,
        iconName: meta['icon']!,
        puzzles: puzzles,
      ));
    }

    // Dynamic categories from remote LiveOps packs
    for (final entry in _puzzlesByCategory.entries) {
      if (!processed.contains(entry.key) && entry.value.isNotEmpty) {
        result.add(PuzzleCategory(
          id: entry.key,
          title: entry.key.isEmpty
              ? 'Bonus'
              : entry.key[0].toUpperCase() + entry.key.substring(1),
          iconName: 'extension',
          puzzles: entry.value,
        ));
      }
    }

    return result;
  }

  /// Fetches and registers dynamic level packs from LiveOps CMS.
  Future<void> loadLiveOpsPuzzles(
    LiveOpsConfigService liveOps, {
    List<String> packIds = const ['season_1_logic_grids'],
  }) async {
    for (final packId in packIds) {
      try {
        final packData = await liveOps.getPuzzleLevelPack(packId);
        final levels = packData['levels'] as List<dynamic>?;
        if (levels != null) {
          final newPuzzles = <PuzzleDefinition>[];
          for (final raw in levels) {
            if (raw is Map) {
              final puzzle = _parseLiveOpsPuzzle(packId, raw.cast<String, dynamic>());
              if (puzzle != null) {
                newPuzzles.add(puzzle);
              }
            }
          }
          if (newPuzzles.isNotEmpty) {
            registerPuzzles(newPuzzles);
          }
        }
      } catch (_) {
        // Fallback gracefully on parsing error
      }
    }
  }

  static List<int> _cluesForLine(List<int> line) {
    final clues = <int>[];
    int run = 0;
    for (final val in line) {
      if (val == 1) {
        run++;
      } else if (run > 0) {
        clues.add(run);
        run = 0;
      }
    }
    if (run > 0) clues.add(run);
    return clues.isEmpty ? [0] : clues;
  }

  PuzzleDefinition? _parseLiveOpsPuzzle(String packId, Map<String, dynamic> raw) {
    if (raw.containsKey('rowHints') && raw.containsKey('columnHints')) {
      return PuzzleDefinition.fromJson(raw);
    }

    if (raw.containsKey('solutionRows')) {
      final rawRows = (raw['solutionRows'] as List)
          .map((r) => (r as List).map((c) => (c as num).toInt()).toList())
          .toList();
      final h = rawRows.length;
      if (h == 0) return null;
      final w = rawRows[0].length;
      if (w == 0) return null;

      final rowHints = rawRows.map(_cluesForLine).toList();
      final columnHints = <List<int>>[];
      for (int c = 0; c < w; c++) {
        final colLine = <int>[];
        for (int r = 0; r < h; r++) {
          colLine.add(rawRows[r][c]);
        }
        columnHints.add(_cluesForLine(colLine));
      }

      final encodedSolution = rawRows
          .map((r) => r.map((c) => c == 1 ? '1' : '.').join())
          .join();

      final pId = raw['puzzleId'] as String? ??
          raw['id'] as String? ??
          '${packId}_lvl_${raw['levelNumber'] ?? 1}';
      final title = raw['title'] as String? ?? 'Logic Grid ${raw['levelNumber'] ?? 1}';
      final category = raw['category'] as String? ?? 'liveops';
      final difficulty = PuzzleDifficulty.fromString(
        raw['difficulty'] as String? ?? 'easy',
      );

      final checksum = PuzzleDefinition.calculateChecksum(
        id: pId,
        width: w,
        height: h,
        rowHints: rowHints,
        columnHints: columnHints,
        encodedSolution: encodedSolution,
      );

      return PuzzleDefinition(
        id: pId,
        title: title,
        category: category,
        width: w,
        height: h,
        rowHints: rowHints,
        columnHints: columnHints,
        encodedSolution: encodedSolution,
        difficulty: difficulty,
        checksum: checksum,
      );
    }

    return null;
  }

  /// Selects deterministic Daily Nonogram based on date string (YYYY-MM-DD).
  PuzzleDefinition? getDailyPuzzleForDate(DateTime date) {
    if (_puzzlesById.isEmpty) return null;

    final dateKey = '${date.year}-${date.month}-${date.day}';
    final hash = dateKey.hashCode.abs();
    final list = _puzzlesById.values.toList();
    return list[hash % list.length];
  }

  /// Validates and imports external/downloaded puzzle pack JSON.
  List<PuzzleDefinition> importExternalPackJson(String jsonContent) {
    final List<dynamic> list = jsonDecode(jsonContent) as List<dynamic>;
    final imported = <PuzzleDefinition>[];

    for (final item in list) {
      final puzzle = PuzzleDefinition.fromJson(item as Map<String, dynamic>);
      final report = PuzzleValidator.validate(puzzle);
      if (report.passesQualityGate) {
        imported.add(puzzle);
        _puzzlesById[puzzle.id] = puzzle;
        _puzzlesByCategory.putIfAbsent(puzzle.category, () => []).add(puzzle);
      }
    }

    return imported;
  }
}
