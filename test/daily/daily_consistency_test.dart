import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/engine/generator/puzzle_generator.dart';
import 'package:nonogram/features/collections/domain/puzzle_repository.dart';

void main() {
  group('Daily Puzzle Consistency tests', () {
    late PuzzleRepository repository;

    setUp(() {
      repository = PuzzleRepository();
      repository.registerPuzzles([
        PuzzleGenerator.fromAsciiArt(
          id: 'p1',
          title: 'Heart',
          category: 'symbols',
          asciiLines: ['.#.#.', '#####', '#####', '.###.', '..#..'],
        ),
        PuzzleGenerator.fromAsciiArt(
          id: 'p2',
          title: 'Diamond',
          category: 'symbols',
          asciiLines: ['..#..', '.###.', '#####', '.###.', '..#..'],
        ),
        PuzzleGenerator.fromAsciiArt(
          id: 'p3',
          title: 'Tree',
          category: 'nature',
          asciiLines: ['..#..', '.###.', '#####', '..#..', '..#..'],
        ),
      ]);
    });

    test('Same date always yields identical daily puzzle (deterministic idempotency)', () {
      final date = DateTime(2026, 10, 9);
      final puzzle1 = repository.getDailyPuzzleForDate(date);
      final puzzle2 = repository.getDailyPuzzleForDate(date);
      final puzzle3 = repository.getDailyPuzzleForDate(DateTime(2026, 10, 9, 23, 59, 59));

      expect(puzzle1, isNotNull);
      expect(puzzle2, isNotNull);
      expect(puzzle1!.id, puzzle2!.id);
      expect(puzzle1.id, puzzle3!.id);
    });

    test('Consecutive dates select valid puzzles from pack', () {
      final day1 = repository.getDailyPuzzleForDate(DateTime(2026, 10, 9));
      final day2 = repository.getDailyPuzzleForDate(DateTime(2026, 10, 10));

      expect(day1, isNotNull);
      expect(day2, isNotNull);
      expect(repository.allPuzzles.map((p) => p.id), contains(day1!.id));
      expect(repository.allPuzzles.map((p) => p.id), contains(day2!.id));
    });
  });
}
