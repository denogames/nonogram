import 'dart:convert';
import 'package:flutter/services.dart';
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
    for (final meta in categoryMetadata) {
      final catId = meta['id']!;
      final puzzles = _puzzlesByCategory[catId] ?? [];
      result.add(PuzzleCategory(
        id: catId,
        title: meta['title']!,
        iconName: meta['icon']!,
        puzzles: puzzles,
      ));
    }
    return result;
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
