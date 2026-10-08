import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'clue_data.dart';

enum PuzzleDifficulty {
  easy,
  medium,
  hard,
  expert;

  String get displayName {
    switch (this) {
      case PuzzleDifficulty.easy:
        return 'Easy';
      case PuzzleDifficulty.medium:
        return 'Medium';
      case PuzzleDifficulty.hard:
        return 'Hard';
      case PuzzleDifficulty.expert:
        return 'Expert';
    }
  }

  static PuzzleDifficulty fromString(String val) {
    switch (val.toLowerCase()) {
      case 'easy':
        return PuzzleDifficulty.easy;
      case 'medium':
        return PuzzleDifficulty.medium;
      case 'hard':
        return PuzzleDifficulty.hard;
      case 'expert':
        return PuzzleDifficulty.expert;
      default:
        return PuzzleDifficulty.easy;
    }
  }
}

enum PublicationStatus {
  published,
  draft,
  archived;

  static PublicationStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'published':
        return PublicationStatus.published;
      case 'draft':
        return PublicationStatus.draft;
      case 'archived':
        return PublicationStatus.archived;
      default:
        return PublicationStatus.published;
    }
  }
}

/// Versioned, immutable definition of a Nonogram puzzle.
@immutable
class PuzzleDefinition {
  final String id;
  final int revision;
  final String title;
  final String category;
  final Map<String, String> categoryTitles;
  final int width;
  final int height;
  final List<List<int>> rowHints;
  final List<List<int>> columnHints;
  final String encodedSolution;
  final PuzzleDifficulty difficulty;
  final int contentVersion;
  final PublicationStatus publicationStatus;
  final String author;
  final String license;
  final List<String> tags;
  final String checksum;

  /// Optional custom pixel art color hex codes for reveal (e.g. ['#3B82F6', '#1E3A8A'])
  final List<String>? colorPalette;

  const PuzzleDefinition({
    required this.id,
    this.revision = 1,
    required this.title,
    required this.category,
    this.categoryTitles = const {},
    required this.width,
    required this.height,
    required this.rowHints,
    required this.columnHints,
    required this.encodedSolution,
    required this.difficulty,
    this.contentVersion = 1,
    this.publicationStatus = PublicationStatus.published,
    this.author = 'Antigravity Studio',
    this.license = 'Proprietary',
    this.tags = const [],
    required this.checksum,
    this.colorPalette,
  });

  ClueData get clues => ClueData(rowClues: rowHints, colClues: columnHints);

  /// Returns true if cell at (row, col) is filled in the solution.
  bool isSolutionFilled(int row, int col) {
    if (row < 0 || row >= height || col < 0 || col >= width) return false;
    final index = row * width + col;
    if (index >= encodedSolution.length) return false;
    final ch = encodedSolution[index];
    return ch == '1' || ch == '#';
  }

  /// Returns 2D boolean grid representing the solution.
  List<List<bool>> get solutionGrid {
    final grid = <List<bool>>[];
    for (int r = 0; r < height; r++) {
      final row = <bool>[];
      for (int c = 0; c < width; c++) {
        row.add(isSolutionFilled(r, c));
      }
      grid.add(row);
    }
    return grid;
  }

  /// Total number of cells that must be filled.
  int get totalSolutionFilledCount {
    int count = 0;
    for (int i = 0; i < encodedSolution.length; i++) {
      if (encodedSolution[i] == '1' || encodedSolution[i] == '#') {
        count++;
      }
    }
    return count;
  }

  /// Calculates SHA256 checksum of canonical puzzle representation.
  static String calculateChecksum({
    required String id,
    required int width,
    required int height,
    required List<List<int>> rowHints,
    required List<List<int>> columnHints,
    required String encodedSolution,
  }) {
    final canonicalString = '$id:$width:$height:${jsonEncode(rowHints)}:${jsonEncode(columnHints)}:$encodedSolution';
    final bytes = utf8.encode(canonicalString);
    return sha256.convert(bytes).toString();
  }

  /// Verifies checksum validity.
  bool verifyChecksum() {
    final expected = calculateChecksum(
      id: id,
      width: width,
      height: height,
      rowHints: rowHints,
      columnHints: columnHints,
      encodedSolution: encodedSolution,
    );
    return checksum == expected;
  }

  Map<String, dynamic> toJson() {
    return {
      'puzzleId': id,
      'revision': revision,
      'title': title,
      'category': category,
      'categoryTitles': categoryTitles,
      'width': width,
      'height': height,
      'rowHints': rowHints,
      'columnHints': columnHints,
      'encodedSolution': encodedSolution,
      'difficulty': difficulty.name,
      'contentVersion': contentVersion,
      'publicationStatus': publicationStatus.name,
      'author': author,
      'license': license,
      'tags': tags,
      'checksum': checksum,
      if (colorPalette != null) 'colorPalette': colorPalette,
    };
  }

  factory PuzzleDefinition.fromJson(Map<String, dynamic> json) {
    final id = json['puzzleId'] as String? ?? json['id'] as String;
    final width = json['width'] as int;
    final height = json['height'] as int;
    final rawRowHints = (json['rowHints'] as List)
        .map((e) => (e as List).map((n) => (n as num).toInt()).toList())
        .toList();
    final rawColHints = (json['columnHints'] as List)
        .map((e) => (e as List).map((n) => (n as num).toInt()).toList())
        .toList();
    final encodedSolution = json['encodedSolution'] as String;
    final storedChecksum = json['checksum'] as String? ??
        calculateChecksum(
          id: id,
          width: width,
          height: height,
          rowHints: rawRowHints,
          columnHints: rawColHints,
          encodedSolution: encodedSolution,
        );

    return PuzzleDefinition(
      id: id,
      revision: json['revision'] as int? ?? 1,
      title: json['title'] as String? ?? 'Untitled',
      category: json['category'] as String? ?? 'general',
      categoryTitles: (json['categoryTitles'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      width: width,
      height: height,
      rowHints: rawRowHints,
      columnHints: rawColHints,
      encodedSolution: encodedSolution,
      difficulty: PuzzleDifficulty.fromString(json['difficulty'] as String? ?? 'easy'),
      contentVersion: json['contentVersion'] as int? ?? 1,
      publicationStatus: PublicationStatus.fromString(
        json['publicationStatus'] as String? ?? 'published',
      ),
      author: json['author'] as String? ?? 'Antigravity Studio',
      license: json['license'] as String? ?? 'Proprietary',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      checksum: storedChecksum,
      colorPalette: (json['colorPalette'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}
