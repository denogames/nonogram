// Opt-in: the game's remote content path against a REAL local studio-core-backend with
// STUDIO_CONTENT_ENABLED=true and a throwaway PostgreSQL. Run with
//   tool/run_remote_content_live.sh /path/to/studio-core-backend
// The pack is published through the backend's admin API (Content Studio), then read by the
// game's RemoteContentService through the Studio Core SDK.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/core/content/remote_content_config.dart';
import 'package:nonogram/core/content/remote_content_service.dart';
import 'package:nonogram/features/collections/domain/puzzle_repository.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';

final String _url = Platform.environment['NONOGRAM_LIVE_BACKEND_URL'] ?? '';
final String _admin = Platform.environment['NONOGRAM_LIVE_ADMIN_KEY'] ?? '';

Future<Map<String, dynamic>> _adminCall(String method, String path, Object? body, int expected) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, Uri.parse('$_url$path'));
    req.headers.set('x-admin-api-key', _admin);
    req.headers.set('x-admin-actor', 'nonogram-live-test');
    if (body != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));
    }
    final res = await req.close();
    final text = await utf8.decoder.bind(res).join();
    expect(res.statusCode, expected, reason: '$method $path: $text');
    return jsonDecode(text) as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

/// Real puzzles from the game's bundle, re-identified as a studio would publish them. Content
/// Studio computes the checksum and manages puzzleId/revision/contentVersion/publicationStatus.
List<Map<String, Object?>> _entries(List<String> ids, {Map<String, String> titles = const {}}) {
  final all = <Map<String, dynamic>>[];
  for (final f in ['animals', 'nature', 'food', 'objects', 'symbols']) {
    all.addAll((jsonDecode(File('assets/puzzles/$f.json').readAsStringSync()) as List).cast<Map<String, dynamic>>());
  }
  return [
    for (final id in ids)
      () {
        final p = all.firstWhere((x) => x['puzzleId'] == id);
        return <String, Object?>{
          'content_id': 'studio_$id',
          'data': {
            'title': titles[id] ?? p['title'],
            'category': 'seasonal',
            'width': p['width'],
            'height': p['height'],
            'encodedSolution': p['encodedSolution'],
            'difficulty': p['difficulty'],
            'tags': ['studio'],
          },
        };
      }(),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  final bool skip = _url.isEmpty || _admin.isEmpty;

  test('a pack published in Content Studio reaches the game, updates, survives offline', () async {
    final dir = await Directory.systemTemp.createTemp('nonogram_live_');
    addTearDown(() => dir.delete(recursive: true));
    final packId = 'live_${DateTime.now().millisecondsSinceEpoch}';
    const base = '/v1/admin/games/nonogram/content/packs';
    final created = await _adminCall('POST', base, {
      'pack_id': packId,
      'content_type': 'nonogram',
      'document': {'title': 'Seasonal', 'entries': _entries(['cat_5x5', 'penguin_10x10'])},
    }, 201);
    expect((created['draft'] as Map)['validation']['valid'], isTrue, reason: jsonEncode(created['draft']['validation']));
    await _adminCall('POST', '$base/$packId/publish', {'revision': 1, 'expected_version': 1, 'base_published_revision': null}, 200);

    final config = RemoteContentConfig.of(flag: true, backendUrl: _url);
    final repo = PuzzleRepository();
    await repo.loadBundledPuzzles();
    final service = (await startRemoteContent(config: config, repository: repo, storageDirectoryPath: dir.path))!;
    final report = await service.refresh();
    expect(report.signedIn, isTrue, reason: '$report');
    expect(report.registrations[packId]!.registered, ['studio_cat_5x5', 'studio_penguin_10x10'], reason: '$report');
    final cat = repo.getPuzzleById('studio_cat_5x5')!;
    expect(cat.verifyChecksum(), isTrue);
    expect(cat.revision, 1);
    expect(repo.getPuzzleById('cat_5x5'), isNotNull);

    // Revision 2: a title changes; only that puzzle's revision moves.
    final draft = await _adminCall('POST', '$base/$packId/drafts', {}, 201);
    final doc = (draft['revision'] as Map)['document'] as Map<String, dynamic>;
    ((doc['entries'] as List)[0] as Map)['data']['title'] = 'Kitten';
    final saved = await _adminCall('PUT', '$base/$packId/drafts/2', {'document': doc, 'expected_version': 1}, 200);
    await _adminCall('POST', '$base/$packId/publish', {'revision': 2, 'expected_version': (saved['revision'] as Map)['version'], 'base_published_revision': 1}, 200);
    final second = await service.refresh();
    expect(second.packs[packId], StudioContentRefreshOutcome.updated, reason: '$second');
    expect(repo.getPuzzleById('studio_cat_5x5')!.title, 'Kitten');
    expect(repo.getPuzzleById('studio_cat_5x5')!.revision, 2);
    expect(repo.getPuzzleById('studio_penguin_10x10')!.revision, 1);
    expect((await service.refresh()).packs[packId], StudioContentRefreshOutcome.unchanged, reason: 'HTTP 304');

    // Next launch with the backend unreachable: the cached revision 2 is used.
    final offlineRepo = PuzzleRepository();
    await offlineRepo.loadBundledPuzzles();
    final offline = (await startRemoteContent(
      config: RemoteContentConfig.of(flag: true, backendUrl: 'http://127.0.0.1:9'),
      repository: offlineRepo,
      storageDirectoryPath: dir.path,
    ))!;
    expect(offlineRepo.getPuzzleById('studio_cat_5x5')!.title, 'Kitten');
    expect((await offline.refresh()).signedIn, isFalse);
    expect(offlineRepo.getPuzzleById('studio_cat_5x5'), isNotNull);
  }, skip: skip, timeout: const Timeout(Duration(seconds: 60)));
}
