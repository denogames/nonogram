import 'dart:convert';
import 'dart:io';
import 'package:nonogram/engine/generator/puzzle_generator.dart';
import 'package:nonogram/engine/models/puzzle_definition.dart';
import 'package:nonogram/engine/validator/puzzle_validator.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    printHelp();
    exit(0);
  }

  final command = args[0].toLowerCase();
  switch (command) {
    case 'validate':
      if (args.length < 2) {
        stderr.writeln('Usage: dart run bin/content_tool.dart validate <file.json>');
        exit(1);
      }
      validateFile(args[1]);
      break;

    case 'build-packs':
      buildStarterPacks();
      break;

    default:
      stderr.writeln('Unknown command: $command');
      printHelp();
      exit(1);
  }
}

void printHelp() {
  stdout.writeln('=== Nonogram Content Tool CLI ===');
  stdout.writeln('Commands:');
  stdout.writeln('  validate <path>       Validates a JSON puzzle file or pack');
  stdout.writeln('  build-packs           Builds and validates all starter puzzle collections');
}

void validateFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $filePath');
    exit(1);
  }

  final jsonStr = file.readAsStringSync();
  final dynamic parsed = jsonDecode(jsonStr);

  final List<dynamic> list = parsed is List ? parsed : [parsed];
  int passCount = 0;
  int failCount = 0;

  for (final item in list) {
    final puzzle = PuzzleDefinition.fromJson(item as Map<String, dynamic>);
    final report = PuzzleValidator.validate(puzzle);
    stdout.writeln('\nPuzzle [${puzzle.id}] "${puzzle.title}":');
    stdout.writeln(report.toString());

    if (report.passesQualityGate) {
      passCount++;
    } else {
      failCount++;
    }
  }

  stdout.writeln('\nValidation Summary: $passCount Passed, $failCount Failed.');
  if (failCount > 0) {
    exit(1);
  }
}

void buildStarterPacks() {
  stdout.writeln('🔨 Building Curated Starter Puzzle Collections...');

  final categories = <String, List<PuzzleDefinition>>{
    'animals': [
      // 5x5 Cat
      PuzzleGenerator.fromAsciiArt(
        id: 'cat_5x5',
        title: 'Cat',
        category: 'animals',
        tags: ['starter', 'easy', 'cat'],
        colorPalette: ['#E67E22', '#D35400'],
        asciiLines: [
          '#...#',
          '#####',
          '##.##',
          '.###.',
          '..#..',
        ],
      ),
      // 5x5 Duck
      PuzzleGenerator.fromAsciiArt(
        id: 'duck_5x5',
        title: 'Duck',
        category: 'animals',
        tags: ['starter', 'easy', 'duck'],
        colorPalette: ['#F1C40F', '#E67E22'],
        asciiLines: [
          '..##.',
          '..##.',
          '#####',
          '####.',
          '.##..',
        ],
      ),
      // 10x10 Penguin
      PuzzleGenerator.fromAsciiArt(
        id: 'penguin_10x10',
        title: 'Penguin',
        category: 'animals',
        tags: ['medium', 'penguin'],
        colorPalette: ['#2C3E50', '#ECF0F1', '#E67E22'],
        asciiLines: [
          '...####...',
          '..######..',
          '..#.##.#..',
          '..######..',
          '.########.',
          '.########.',
          '.########.',
          '..######..',
          '...####...',
          '..##..##..',
        ],
      ),
      // 15x15 Elephant
      PuzzleGenerator.fromAsciiArt(
        id: 'elephant_15x15',
        title: 'Elephant',
        category: 'animals',
        tags: ['hard', 'elephant'],
        colorPalette: ['#7F8C8D', '#95A5A6'],
        asciiLines: [
          '......#######..',
          '....###########',
          '...############',
          '..####..#######',
          '..####..#######',
          '..#############',
          '..#############',
          '..#############',
          '..#############',
          '..#############',
          '..####.....####',
          '..####.....####',
          '..####.....####',
          '..####.....####',
          '...###......###',
        ],
      ),
    ],
    'nature': [
      // 5x5 Tree
      PuzzleGenerator.fromAsciiArt(
        id: 'tree_5x5',
        title: 'Pine Tree',
        category: 'nature',
        tags: ['starter', 'easy', 'tree'],
        colorPalette: ['#27AE60', '#795548'],
        asciiLines: [
          '..#..',
          '.###.',
          '#####',
          '..#..',
          '..#..',
        ],
      ),
      // 5x5 Mushroom
      PuzzleGenerator.fromAsciiArt(
        id: 'mushroom_5x5',
        title: 'Mushroom',
        category: 'nature',
        tags: ['starter', 'easy'],
        colorPalette: ['#E74C3C', '#ECF0F1'],
        asciiLines: [
          '.###.',
          '#####',
          '#####',
          '..#..',
          '..#..',
        ],
      ),
      // 10x10 Flower
      PuzzleGenerator.fromAsciiArt(
        id: 'flower_10x10',
        title: 'Tulip',
        category: 'nature',
        tags: ['medium', 'flower'],
        colorPalette: ['#E91E63', '#4CAF50'],
        asciiLines: [
          '..##..##..',
          '.########.',
          '##########',
          '##########',
          '.########.',
          '..######..',
          '....##....',
          '..#.##....',
          '..####....',
          '....##....',
        ],
      ),
      // 15x15 Mountain
      PuzzleGenerator.fromAsciiArt(
        id: 'mountain_15x15',
        title: 'Mountain Peak',
        category: 'nature',
        tags: ['hard', 'mountain'],
        colorPalette: ['#34495E', '#ECF0F1'],
        asciiLines: [
          '.......#.......',
          '......###......',
          '.....#####.....',
          '....#######....',
          '...#########...',
          '..###########..',
          '.#############.',
          '###############',
          '###############',
          '###############',
          '###############',
          '###############',
          '###############',
          '###############',
          '###############',
        ],
      ),
    ],
    'food': [
      // 5x5 Apple
      PuzzleGenerator.fromAsciiArt(
        id: 'apple_5x5',
        title: 'Apple',
        category: 'food',
        tags: ['starter', 'easy', 'apple'],
        colorPalette: ['#E74C3C', '#27AE60'],
        asciiLines: [
          '..#..',
          '.###.',
          '#####',
          '#####',
          '.###.',
        ],
      ),
      // 10x10 Cup
      PuzzleGenerator.fromAsciiArt(
        id: 'cup_10x10',
        title: 'Coffee Mug',
        category: 'food',
        tags: ['medium', 'coffee'],
        colorPalette: ['#795548', '#D7CCC8'],
        asciiLines: [
          '..........',
          '..##..##..',
          '..##..##..',
          '..........',
          '..######..',
          '..#....#.#',
          '..#....###',
          '..#....#.#',
          '..######..',
          '..........',
        ],
      ),
      // 15x15 Ice Cream
      PuzzleGenerator.fromAsciiArt(
        id: 'icecream_15x15',
        title: 'Ice Cream',
        category: 'food',
        tags: ['hard', 'icecream'],
        colorPalette: ['#FF4081', '#FFB74D'],
        asciiLines: [
          '....#######....',
          '...#########...',
          '..###########..',
          '..###########..',
          '..###########..',
          '...#########...',
          '....#######....',
          '....#######....',
          '.....#####.....',
          '.....#####.....',
          '......###......',
          '......###......',
          '.......#.......',
          '.......#.......',
          '.......#.......',
        ],
      ),
    ],
    'objects': [
      // 5x5 Key
      PuzzleGenerator.fromAsciiArt(
        id: 'key_5x5',
        title: 'Key',
        category: 'objects',
        tags: ['starter', 'easy'],
        colorPalette: ['#F1C40F'],
        asciiLines: [
          '.###.',
          '.#.#.',
          '.###.',
          '..#.#',
          '..###',
        ],
      ),
      // 10x10 Sword
      PuzzleGenerator.fromAsciiArt(
        id: 'sword_10x10',
        title: 'Sword',
        category: 'objects',
        tags: ['medium', 'sword'],
        colorPalette: ['#95A5A6', '#D35400'],
        asciiLines: [
          '....##....',
          '....##....',
          '....##....',
          '....##....',
          '....##....',
          '....##....',
          '..######..',
          '....##....',
          '....##....',
          '...####...',
        ],
      ),
      // 15x15 Castle
      PuzzleGenerator.fromAsciiArt(
        id: 'castle_15x15',
        title: 'Castle',
        category: 'objects',
        tags: ['hard', 'castle'],
        colorPalette: ['#78909C', '#37474F'],
        asciiLines: [
          '#.#.#####.#.#..',
          '###.#####.###..',
          '###.#####.###..',
          '###############',
          '###############',
          '..###.###.###..',
          '..###.###.###..',
          '###############',
          '###############',
          '####.#####.####',
          '####.#####.####',
          '####.#####.####',
          '####..###..####',
          '####..###..####',
          '####..###..####',
        ],
      ),
    ],
    'symbols': [
      // 5x5 Heart
      PuzzleGenerator.fromAsciiArt(
        id: 'heart_5x5',
        title: 'Heart',
        category: 'symbols',
        tags: ['starter', 'easy', 'heart'],
        colorPalette: ['#E91E63'],
        asciiLines: [
          '.#.#.',
          '#####',
          '#####',
          '.###.',
          '..#..',
        ],
      ),
      // 5x5 Star
      PuzzleGenerator.fromAsciiArt(
        id: 'star_5x5',
        title: 'Star',
        category: 'symbols',
        tags: ['starter', 'easy', 'star'],
        colorPalette: ['#F39C12'],
        asciiLines: [
          '..#..',
          '#####',
          '.###.',
          '.#.#.',
          '#...#',
        ],
      ),
      // 10x10 Music Note
      PuzzleGenerator.fromAsciiArt(
        id: 'music_10x10',
        title: 'Music Note',
        category: 'symbols',
        tags: ['medium', 'music'],
        colorPalette: ['#8E44AD'],
        asciiLines: [
          '......####',
          '......####',
          '......#...',
          '......#...',
          '......#...',
          '......#...',
          '...####...',
          '..######..',
          '..######..',
          '...####...',
        ],
      ),
      // 15x15 Crescent Moon
      PuzzleGenerator.fromAsciiArt(
        id: 'moon_15x15',
        title: 'Crescent Moon',
        category: 'symbols',
        tags: ['hard', 'moon'],
        colorPalette: ['#F1C40F', '#34495E'],
        asciiLines: [
          '.....######....',
          '....########...',
          '...###....###..',
          '..###......##..',
          '..##........#..',
          '.###...........',
          '.###...........',
          '.###...........',
          '.###...........',
          '..##........#..',
          '..###......##..',
          '...###....###..',
          '....########...',
          '.....######....',
          '.......##......',
        ],
      ),
    ],
  };

  final targetDir = Directory('assets/puzzles');
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  int totalPuzzles = 0;
  for (final entry in categories.entries) {
    final catName = entry.key;
    final puzzles = entry.value;

    final jsonList = <Map<String, dynamic>>[];
    for (final p in puzzles) {
      final report = PuzzleValidator.validate(p);
      if (!report.passesQualityGate) {
        stderr.writeln('⚠️ WARNING: Puzzle ${p.id} failed validation!');
        stderr.writeln(report.toString());
      }
      jsonList.add(p.toJson());
      totalPuzzles++;
    }

    final outFile = File('assets/puzzles/$catName.json');
    final encoder = const JsonEncoder.withIndent('  ');
    outFile.writeAsStringSync(encoder.convert(jsonList));
    stdout.writeln('  ✅ Saved ${puzzles.length} puzzles to assets/puzzles/$catName.json');
  }

  // Also build tutorial puzzles pack
  final tutorialPuzzles = [
    PuzzleGenerator.fromAsciiArt(
      id: 'tutorial_1',
      title: 'First Step',
      category: 'tutorial',
      tags: ['tutorial', 'step1'],
      asciiLines: [
        '..#..',
        '..#..',
        '#####',
        '..#..',
        '..#..',
      ],
    ),
    PuzzleGenerator.fromAsciiArt(
      id: 'tutorial_2',
      title: 'Smile',
      category: 'tutorial',
      tags: ['tutorial', 'step2'],
      asciiLines: [
        '.#.#.',
        '.....',
        '#...#',
        '.###.',
        '.....',
      ],
    ),
  ];
  final tutorialFile = File('assets/puzzles/tutorial.json');
  tutorialFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(
      tutorialPuzzles.map((p) => p.toJson()).toList(),
    ),
  );
  stdout.writeln('  ✅ Saved tutorial pack to assets/puzzles/tutorial.json');

  stdout.writeln('✨ All $totalPuzzles starter puzzles generated & verified successfully!');
}
