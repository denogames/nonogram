// Remote content (Content Studio) integration: the game's RemoteContentService and
// PuzzleRepository driven through the real Studio Core SDK adapter against a loopback HTTP
// server that speaks the backend contract (guest sign-in, content catalog, packs with ETag).
// The opt-in test against a real backend is remote_content_live_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/core/content/remote_content_config.dart';
import 'package:nonogram/core/content/remote_content_service.dart';
import 'package:nonogram/core/storage/database/app_database.dart';
import 'package:nonogram/core/storage/saved_board.dart';
import 'package:nonogram/core/storage/vault/game_state_vault.dart';
import 'package:nonogram/engine/game/puzzle_engine.dart';
import 'package:nonogram/engine/models/cell_state.dart';
import 'package:nonogram/engine/models/puzzle_definition.dart';
import 'package:nonogram/features/collections/domain/puzzle_repository.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';

/// Real puzzles from the game's own bundle, re-identified as a studio would publish them
/// (new ids, checksum recomputed for the new id).
List<Map<String, Object?>> studioLevels(List<String> sourceIds, {String category = 'seasonal', Map<String, String> titles = const {}}) {
  final all = <Map<String, dynamic>>[];
  for (final f in ['animals', 'nature', 'food', 'objects', 'symbols']) {
    all.addAll((jsonDecode(File('assets/puzzles/$f.json').readAsStringSync()) as List).cast<Map<String, dynamic>>());
  }
  return [
    for (final id in sourceIds)
      () {
        final p = Map<String, Object?>.from(all.firstWhere((x) => x['puzzleId'] == id));
        final newId = 'studio_$id';
        p['puzzleId'] = newId;
        p['category'] = category;
        p['title'] = titles[id] ?? p['title'];
        p['checksum'] = PuzzleDefinition.calculateChecksum(
          id: newId,
          width: p['width']! as int,
          height: p['height']! as int,
          rowHints: (p['rowHints']! as List).map((r) => (r as List).cast<int>()).toList(),
          columnHints: (p['columnHints']! as List).map((r) => (r as List).cast<int>()).toList(),
          encodedSolution: p['encodedSolution']! as String,
        );
        return p;
      }(),
  ];
}

/// [level] published under [id] (checksum recomputed): a puzzle whose solution changed while
/// its id and size stayed the same.
Map<String, Object?> underId(Map<String, Object?> level, String id) {
  final p = Map<String, Object?>.from(level)..['puzzleId'] = id;
  p['checksum'] = PuzzleDefinition.calculateChecksum(
    id: id,
    width: p['width']! as int,
    height: p['height']! as int,
    rowHints: (p['rowHints']! as List).map((r) => (r as List).cast<int>()).toList(),
    columnHints: (p['columnHints']! as List).map((r) => (r as List).cast<int>()).toList(),
    encodedSolution: p['encodedSolution']! as String,
  );
  return p;
}

/// A stand-in for studio-core-backend's player endpoints.
class FakeContentBackend {
  late HttpServer _server;
  final List<String> requests = [];
  final Map<String, ({int revision, Map<String, Object?> payload, String contentType, int schema})> packs = {};
  int guestCalls = 0;
  bool refuseGuest = false;
  bool down = false;
  int expireNextCalls = 0;
  int _tokens = 0;
  String? _validToken;

  String get url => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  void publish(String packId, int revision, List<Map<String, Object?>> levels, {String contentType = 'nonogram', int schema = 1, Object? rawLevels}) {
    packs[packId] = (
      revision: revision,
      contentType: contentType,
      schema: schema,
      payload: {'packId': packId, 'version': revision, 'gameId': 'nonogram', 'contentType': contentType, 'schemaVersion': schema, 'levels': rawLevels ?? levels},
    );
  }

  String _etag(String packId) => '"${packId}_r${packs[packId]!.revision}"';

  Future<void> _handle(HttpRequest req) async {
    final body = await utf8.decoder.bind(req).join();
    requests.add('${req.method} ${req.uri.path}');
    final res = req.response..headers.contentType = ContentType.json;
    void send(int status, Object json) {
      res.statusCode = status;
      res.write(jsonEncode(json));
    }

    if (down) {
      send(503, {'error': 'UNAVAILABLE'});
    } else if (req.method == 'POST' && req.uri.path == '/v1/auth/guest') {
      guestCalls++;
      final device = (jsonDecode(body) as Map)['device_id'];
      if (refuseGuest) {
        send(401, {'error': 'HMAC_INVALID'});
      } else {
        _validToken = 'tok-${++_tokens}';
        send(200, {
          'token': _validToken,
          'studio_player_id': 'player-$device',
          'game_profile_id': 'profile-$device',
          'game_id': 'nonogram',
          'state_version': 1,
          'server_time_ms': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } else if (req.headers.value('authorization') != 'Bearer $_validToken' || expireNextCalls > 0) {
      if (expireNextCalls > 0) {
        expireNextCalls--;
        _validToken = null;
      }
      send(401, {'error': 'UNAUTHORIZED'});
    } else if (req.uri.path == '/v1/content/packs') {
      final type = req.uri.queryParameters['content_type'];
      send(200, {
        'schema_version': 1,
        'game_id': 'nonogram',
        'packs': [
          for (final e in packs.entries)
            if (type == null || e.value.contentType == type)
              {'pack_id': e.key, 'content_type': e.value.contentType, 'content_schema_version': e.value.schema, 'revision': e.value.revision, 'etag': _etag(e.key), 'entry_count': 1, 'title': e.key},
        ],
      });
    } else if (req.uri.path.startsWith('/v1/content/packs/')) {
      final id = req.uri.pathSegments.last;
      final pack = packs[id];
      if (pack == null) {
        send(404, {'error': 'PACK_NOT_PUBLISHED'});
      } else if (req.headers.value(HttpHeaders.ifNoneMatchHeader) == _etag(id)) {
        res.statusCode = 304;
      } else {
        res.headers.set(HttpHeaders.etagHeader, _etag(id));
        send(200, {
          'schema_version': 1,
          'game_id': 'nonogram',
          'pack': {
            'pack_id': id,
            'content_type': pack.contentType,
            'content_schema_version': pack.schema,
            'revision': pack.revision,
            'title': id,
            'localized_titles': <String, String>{},
            'assets': <String, String>{},
            'entry_count': 1,
            'payload': pack.payload,
          },
        });
      }
    } else {
      send(404, {'error': 'NOT_FOUND'});
    }
    await res.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test answers every real HTTP request with 400; these tests talk to a loopback server.
  HttpOverrides.global = null;
  late FakeContentBackend backend;
  late Directory dir;

  setUp(() async {
    backend = FakeContentBackend();
    await backend.start();
    dir = await Directory.systemTemp.createTemp('nonogram_remote_');
  });
  tearDown(() async {
    await backend.stop();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  RemoteContentConfig enabled() => RemoteContentConfig.of(flag: true, backendUrl: backend.url);

  Future<PuzzleRepository> bundledRepository() async {
    final repo = PuzzleRepository();
    await repo.loadBundledPuzzles();
    return repo;
  }

  Future<(PuzzleRepository, RemoteContentService)> launch() async {
    final repo = await bundledRepository();
    final service = await startRemoteContent(config: enabled(), repository: repo, storageDirectoryPath: dir.path);
    return (repo, service!);
  }

  group('feature flag', () {
    test('off by default, off without a usable URL, always off in release builds', () {
      expect(RemoteContentConfig.fromEnvironment().enabled, isFalse);
      expect(RemoteContentConfig.of(flag: true, backendUrl: '').enabled, isFalse);
      expect(RemoteContentConfig.of(flag: false, backendUrl: 'http://127.0.0.1:1').enabled, isFalse);
      expect(RemoteContentConfig.of(flag: true, backendUrl: 'ftp://x').enabled, isFalse);
      expect(RemoteContentConfig.of(flag: true, backendUrl: 'http://127.0.0.1:1').enabled, isTrue);
      expect(RemoteContentConfig.of(flag: true, backendUrl: 'https://content.example.com', releaseBuild: true).enabled, isFalse);
    });

    test('the game carries no backend secret: the reader signs with a public constant', () {
      final sources = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      for (final f in sources) {
        expect(f.readAsStringSync(), isNot(contains('NONOGRAM_CONTENT_HMAC_KEY')), reason: f.path);
      }
      expect(RemoteContentConfig.contentReaderSigningKey, 'nonogram-content-reader-public');
    });

    test('disabled: nothing is created, no request is made, bundled puzzles unchanged', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5']));
      final repo = await bundledRepository();
      final before = repo.allPuzzles.map((p) => p.id).toList();
      final service = await startRemoteContent(config: RemoteContentConfig.disabled, repository: repo, storageDirectoryPath: dir.path);
      expect(service, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(backend.requests, isEmpty);
      expect(dir.listSync(), isEmpty, reason: 'no cache or device id file');
      expect(repo.allPuzzles.map((p) => p.id).toList(), before);
    });
  });

  group('enabled', () {
    test('cold start: guest sign-in, catalog, pack registered next to the bundled puzzles; daily unchanged', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5', 'penguin_10x10']));
      final (repo, service) = await launch();
      final bundledCount = repo.allPuzzles.length;
      final daily = repo.getDailyPuzzleForDate(DateTime(2026, 11, 11))!.id;
      expect(backend.requests, isEmpty, reason: 'nothing cached yet, and loadCached never uses the network');

      final report = await service.refresh();
      expect(report.signedIn, isTrue);
      expect(report.catalog, StudioContentRefreshOutcome.updated);
      expect(report.registrations['seasonal']!.registered, ['studio_cat_5x5', 'studio_penguin_10x10']);
      expect(backend.requests, ['POST /v1/auth/guest', 'GET /v1/content/packs', 'GET /v1/content/packs/seasonal']);
      expect(repo.allPuzzles.length, bundledCount + 2);
      expect(repo.getPuzzleById('studio_cat_5x5')!.verifyChecksum(), isTrue);
      expect(repo.getCategories().singleWhere((c) => c.id == 'seasonal').puzzles.map((p) => p.id), ['studio_cat_5x5', 'studio_penguin_10x10']);
      expect(repo.getPuzzleById('cat_5x5'), isNotNull, reason: 'bundled puzzles stay');
      expect(repo.getDailyPuzzleForDate(DateTime(2026, 11, 11))!.id, daily);

      // Second refresh: same session, ETags sent, nothing re-registered.
      final again = await service.refresh();
      expect(again.packs['seasonal'], StudioContentRefreshOutcome.unchanged);
      expect(again.registrations, isEmpty);
      expect(backend.guestCalls, 1);
    });

    test('offline start reuses the last valid cached pack; a failing refresh keeps it', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5']));
      final (_, first) = await launch();
      await first.refresh();

      backend.down = true;
      final (repo, service) = await launch();
      expect(repo.getPuzzleById('studio_cat_5x5'), isNotNull, reason: 'registered from the cache before any request');
      final report = await service.refresh();
      expect(report.signedIn, isFalse);
      expect(repo.getPuzzleById('studio_cat_5x5'), isNotNull);
    });

    test('failed sign-in: bundled puzzles only, nothing thrown', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5']));
      backend.refuseGuest = true;
      final (repo, service) = await launch();
      final report = await service.refresh();
      expect(report.error, 'guest sign-in failed');
      expect(repo.allPuzzles.every((p) => !repo.isRemotePuzzle(p.id)), isTrue);
      expect(backend.requests, ['POST /v1/auth/guest']);
    });

    test('an expired session gets one fresh sign-in', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5']));
      final (repo, service) = await launch();
      await service.refresh();
      backend.publish('seasonal', 2, studioLevels(['cat_5x5', 'duck_5x5']));
      backend.expireNextCalls = 1;
      final report = await service.refresh();
      expect(report.catalog, StudioContentRefreshOutcome.updated);
      expect(backend.guestCalls, 2);
      expect(repo.getPuzzleById('studio_duck_5x5'), isNotNull);
    });

    test('revision changes replace the pack: edited, added and removed puzzles; withdrawn packs leave', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5', 'duck_5x5']));
      backend.publish('winter', 1, studioLevels(['penguin_10x10'], category: 'winter'));
      final (repo, service) = await launch();
      await service.refresh();
      expect(repo.getPuzzleById('studio_duck_5x5'), isNotNull);

      backend.publish('seasonal', 2, studioLevels(['cat_5x5', 'heart_5x5'], titles: {'cat_5x5': 'Kitten'}));
      backend.packs.remove('winter');
      final report = await service.refresh();
      expect(report.packs['seasonal'], StudioContentRefreshOutcome.updated);
      expect(report.withdrawn, ['winter']);
      expect(repo.getPuzzleById('studio_cat_5x5')!.title, 'Kitten');
      expect(repo.getPuzzleById('studio_duck_5x5'), isNull);
      expect(repo.getPuzzleById('studio_heart_5x5'), isNotNull);
      expect(repo.getPuzzleById('studio_penguin_10x10'), isNull);
      expect(repo.getCategories().where((c) => c.id == 'winter'), isEmpty);
      expect(repo.getCategories().singleWhere((c) => c.id == 'seasonal').puzzles.length, 2, reason: 'no duplicate registrations');

      // The next offline start shows revision 2, not the withdrawn pack.
      backend.down = true;
      final (offlineRepo, _) = await launch();
      expect(offlineRepo.getPuzzleById('studio_cat_5x5')!.title, 'Kitten');
      expect(offlineRepo.getPuzzleById('studio_penguin_10x10'), isNull);
    });

    test('malformed payloads, invalid puzzles and unreadable schemas never replace good content', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5']));
      final (repo, service) = await launch();
      await service.refresh();

      // Revision 2 without a levels list: the SDK accepts the envelope, the repository keeps revision 1.
      backend.publish('seasonal', 2, const [], rawLevels: 'not a list');
      final malformed = await service.refresh();
      expect(malformed.registrations['seasonal']!.payloadMalformed, isTrue);
      expect(repo.getPuzzleById('studio_cat_5x5'), isNotNull);

      // A tampered level (wrong checksum) is skipped; the valid one is registered.
      final levels = studioLevels(['cat_5x5', 'duck_5x5']);
      levels[1]['checksum'] = '0' * 64;
      backend.publish('seasonal', 3, levels);
      final tampered = await service.refresh();
      expect(tampered.registrations['seasonal']!.rejected, {'studio_duck_5x5': RemotePuzzleRejection.failedValidation});
      expect(repo.getPuzzleById('studio_duck_5x5'), isNull);

      // A pack of a schema this build cannot read is left out of the catalog entirely.
      backend.publish('future', 1, studioLevels(['tree_5x5']), schema: 2);
      final future = await service.refresh();
      expect(future.packs.containsKey('future'), isFalse);
    });

    test('conflicting ids: bundled puzzles win, then the first pack', () async {
      final bundledCat = (jsonDecode(File('assets/puzzles/animals.json').readAsStringSync()) as List).first as Map<String, dynamic>;
      backend.publish('aaa', 1, [Map<String, Object?>.from(bundledCat)..['title'] = 'Hijacked', ...studioLevels(['duck_5x5'])]);
      backend.publish('bbb', 1, studioLevels(['duck_5x5', 'cat_5x5']));
      final (repo, service) = await launch();
      final original = repo.getPuzzleById('cat_5x5')!;
      final report = await service.refresh();
      expect(report.registrations['aaa']!.rejected, {'cat_5x5': RemotePuzzleRejection.conflictsWithBundled});
      expect(report.registrations['bbb']!.rejected, {'studio_duck_5x5': RemotePuzzleRejection.conflictsWithOtherPack});
      expect(identical(repo.getPuzzleById('cat_5x5'), original), isTrue);
      expect(repo.getPuzzleById('cat_5x5')!.title, 'Cat');
      expect(repo.remotePuzzleIds('bbb'), ['studio_cat_5x5']);
    });

    test('a corrupted cache is ignored: bundled puzzles, then a clean refresh', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5']));
      final (_, first) = await launch();
      await first.refresh();
      for (final f in Directory('${dir.path}/remote_content').listSync().whereType<File>()) {
        if (!f.path.endsWith('device_id')) f.writeAsBytesSync(utf8.encode('garbage'));
      }
      final (repo, service) = await launch();
      expect(repo.allPuzzles.every((p) => !repo.isRemotePuzzle(p.id)), isTrue);
      await service.refresh();
      expect(repo.getPuzzleById('studio_cat_5x5'), isNotNull);
    });

    test('player progress is never erased by refreshes, revisions or a withdrawn pack', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      backend.publish('seasonal', 1, studioLevels(['cat_5x5']));
      final (repo, service) = await launch();
      await service.refresh();
      final now = DateTime(2026, 11, 11);
      for (final id in ['cat_5x5', 'studio_cat_5x5']) {
        await db.saveProgress(PuzzleProgressEntriesCompanion.insert(puzzleId: id, isCompleted: const Value(true), stars: const Value(3), lastPlayed: now));
      }

      backend.publish('seasonal', 2, studioLevels(['cat_5x5'], titles: {'cat_5x5': 'Kitten'}));
      await service.refresh();
      backend.packs.clear();
      await service.refresh();
      expect(repo.getPuzzleById('studio_cat_5x5'), isNull, reason: 'withdrawn from the catalog');
      backend.down = true;
      await service.refresh();

      for (final id in ['cat_5x5', 'studio_cat_5x5']) {
        final row = await db.getProgress(id);
        expect(row!.isCompleted, isTrue, reason: id);
        expect(row.stars, 3, reason: id);
      }
      // Republished: the same id returns and its progress applies again.
      backend.down = false;
      backend.publish('seasonal', 3, studioLevels(['cat_5x5']));
      await service.refresh();
      expect(repo.getPuzzleById('studio_cat_5x5'), isNotNull);
      expect((await db.getProgress('studio_cat_5x5'))!.isCompleted, isTrue);
    });

    test('screens are told when remote puzzles arrive', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5']));
      final (repo, service) = await launch();
      var notified = 0;
      repo.addListener(() => notified++);
      await service.refresh();
      expect(notified, greaterThan(0));
    });
  });

  group('saved boards follow puzzle content', () {
    late AppDatabase db;
    late GameStateVault vault;
    final now = DateTime(2026, 11, 11);

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      vault = GameStateVault.instance;
      await vault.initialize(storageDirectoryPath: (await Directory('${dir.path}/vault').create()).path);
    });
    tearDown(() async {
      await vault.clearAll();
      await db.close();
    });

    /// Plays two moves on [puzzle] and saves the unfinished attempt the way PuzzleScreen does.
    Future<String> saveAttempt(PuzzleDefinition puzzle) async {
      final engine = PuzzleEngine(puzzle: puzzle)
        ..applyTool(0, 0, EditTool.cross)
        ..applyTool(1, 1, EditTool.cross)
        ..restoreSession(encodedBoard: '', mistakes: 1, hintsUsed: 2, elapsedSeconds: 40);
      final cells = engine.serializeBoardState();
      final stored = SavedBoard.encode(puzzle, cells);
      await vault.savePuzzleState(SavedPuzzleState(
        puzzleId: puzzle.id, isCompleted: false, stars: 0, bestTimeSeconds: 0, lastPlayed: now,
        savedBoardState: stored, savedMistakes: 1, savedHintsUsed: 2, savedElapsedSeconds: 40));
      await db.saveProgress(PuzzleProgressEntriesCompanion.insert(
        puzzleId: puzzle.id, lastPlayed: now, savedBoardState: Value(stored),
        savedMistakes: const Value(1), savedHintsUsed: const Value(2), savedElapsedSeconds: const Value(40)));
      return cells;
    }

    Future<ResumableAttempt?> resume(PuzzleRepository repo, String id) async =>
        ResumableAttempt.choose(repo.getPuzzleById(id)!, vault: vault.getPuzzleState(id), database: await db.getProgress(id));

    test('unchanged content, a renamed puzzle and added puzzles keep the attempt', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5']));
      final (repo, service) = await launch();
      await service.refresh();
      final cells = await saveAttempt(repo.getPuzzleById('studio_cat_5x5')!);

      expect((await resume(repo, 'studio_cat_5x5'))!.cells, cells, reason: 'unchanged content');

      backend.publish('seasonal', 2, studioLevels(['cat_5x5', 'duck_5x5'], titles: {'cat_5x5': 'Kitten'}));
      await service.refresh();
      expect(repo.getPuzzleById('studio_cat_5x5')!.title, 'Kitten');
      final attempt = (await resume(repo, 'studio_cat_5x5'))!;
      expect(attempt.cells, cells, reason: 'a new title is not new content');
      expect([attempt.mistakes, attempt.hintsUsed, attempt.elapsedSeconds], [1, 2, 40]);
      expect(await resume(repo, 'studio_duck_5x5'), isNull, reason: 'an added puzzle starts empty');

      final engine = PuzzleEngine(puzzle: repo.getPuzzleById('studio_cat_5x5')!)
        ..restoreSession(encodedBoard: attempt.cells, mistakes: attempt.mistakes, hintsUsed: attempt.hintsUsed, elapsedSeconds: attempt.elapsedSeconds);
      expect(engine.serializeBoardState(), cells);
    });

    test('a changed solution at the same size starts clean; history, stars and wallet stay', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5', 'duck_5x5']));
      final (repo, service) = await launch();
      await service.refresh();
      await saveAttempt(repo.getPuzzleById('studio_cat_5x5')!);
      await db.saveProgress(PuzzleProgressEntriesCompanion.insert(
          puzzleId: 'studio_duck_5x5', isCompleted: const Value(true), stars: const Value(3), bestTimeSeconds: const Value(55), lastPlayed: now));
      await db.saveProgress(PuzzleProgressEntriesCompanion.insert(puzzleId: 'cat_5x5', isCompleted: const Value(true), stars: const Value(2), lastPlayed: now));
      final wallet = await db.getOrCreateEconomy();

      // Revision 2: both ids keep their size, but their pictures are different puzzles now.
      final heart = studioLevels(['heart_5x5']).single;
      final tree = studioLevels(['tree_5x5']).single;
      backend.publish('seasonal', 2, [underId(heart, 'studio_cat_5x5'), underId(tree, 'studio_duck_5x5')]);
      final report = await service.refresh();
      expect(report.registrations['seasonal']!.registered, hasLength(2));
      final changed = repo.getPuzzleById('studio_cat_5x5')!;
      expect(changed.encodedSolution, heart['encodedSolution']);

      expect(await resume(repo, 'studio_cat_5x5'), isNull, reason: 'old marks belong to another picture');
      final fresh = PuzzleEngine(puzzle: changed);
      expect(fresh.serializeBoardState(), '.' * 25);
      expect([fresh.mistakes, fresh.hintsUsed, fresh.elapsedSeconds], [0, 0, 0]);

      // Nothing was deleted: the old attempt is still stored until the player saves a new one.
      expect((await db.getProgress('studio_cat_5x5'))!.savedBoardState, isNotNull);
      expect(vault.getPuzzleState('studio_cat_5x5')!.savedBoardState, isNotNull);
      final duck = (await db.getProgress('studio_duck_5x5'))!;
      expect([duck.isCompleted, duck.stars, duck.bestTimeSeconds], [true, 3, 55], reason: 'completed history stays');
      expect((await db.getProgress('cat_5x5'))!.stars, 2, reason: 'unrelated progress stays');
      final after = await db.getOrCreateEconomy();
      expect([after.coins, after.hintsRemaining], [wallet.coins, wallet.hintsRemaining]);
    });

    test('offline recovery: the attempt resumes from disk on cached content, not on changed content', () async {
      backend.publish('seasonal', 1, studioLevels(['cat_5x5', 'duck_5x5']));
      final (repo, service) = await launch();
      await service.refresh();
      final cells = await saveAttempt(repo.getPuzzleById('studio_cat_5x5')!);

      // Process restart without a backend: vault reopened from disk, content from the cache.
      backend.down = true;
      await vault.initialize(storageDirectoryPath: '${dir.path}/vault');
      final (offline, _) = await launch();
      expect(offline.isRemotePuzzle('studio_cat_5x5'), isTrue);
      final fromDisk = ResumableAttempt.choose(offline.getPuzzleById('studio_cat_5x5')!, vault: vault.getPuzzleState('studio_cat_5x5'));
      expect(fromDisk!.cells, cells);

      // The solution changes online; the next offline start uses the new cache and starts clean.
      backend.down = false;
      backend.publish('seasonal', 2, [underId(studioLevels(['heart_5x5']).single, 'studio_cat_5x5')]);
      await service.refresh();
      backend.down = true;
      final (offline2, _) = await launch();
      expect(await resume(offline2, 'studio_cat_5x5'), isNull);
    });

    test('older saves without a fingerprint resume when they fit; damaged ones never do', () async {
      final repo = await bundledRepository();
      final cat = repo.getPuzzleById('cat_5x5')!;
      final legacy = 'X${'.' * 24}';
      expect(SavedBoard.restorableCells(legacy, cat), legacy);
      expect(SavedBoard.restorableCells('X....', cat), isNull, reason: 'wrong size');
      expect(SavedBoard.restorableCells('fp1:$legacy', cat), isNull, reason: 'damaged prefix');
      expect(SavedBoard.restorableCells(SavedBoard.encode(cat, legacy), cat), legacy);
      expect(SavedBoard.restorableCells(SavedBoard.encode(repo.getPuzzleById('duck_5x5')!, legacy), cat), isNull,
          reason: 'saved on another puzzle');
      expect(ResumableAttempt.choose(cat,
          database: PuzzleProgressEntry(puzzleId: 'cat_5x5', isCompleted: true, stars: 3, bestTimeSeconds: 9, lastPlayed: now,
              savedBoardState: SavedBoard.encode(cat, legacy), savedMistakes: 0, savedHintsUsed: 0, savedElapsedSeconds: 0)), isNull,
          reason: 'a completed puzzle is not resumed');
    });
  });

  test('bundled assets are readable in tests', () async {
    expect(await rootBundle.loadString('assets/puzzles/animals.json'), contains('cat_5x5'));
  });
}
