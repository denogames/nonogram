import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';

import '../../features/collections/domain/puzzle_repository.dart';
import 'remote_content_config.dart';

/// What one load or refresh did. For logs and tests; nothing here is shown to players.
class RemoteContentReport {
  final bool signedIn;
  final StudioContentRefreshOutcome? catalog;
  final Map<String, StudioContentRefreshOutcome> packs;
  final Map<String, RemotePackRegistration> registrations;
  final List<String> withdrawn;
  final String? error;

  const RemoteContentReport({
    this.signedIn = false,
    this.catalog,
    this.packs = const {},
    this.registrations = const {},
    this.withdrawn = const [],
    this.error,
  });

  int get registeredPuzzles => registrations.values.fold(0, (n, r) => n + r.registered.length);

  @override
  String toString() =>
      'RemoteContentReport(signedIn: $signedIn, catalog: ${catalog?.name}, packs: ${packs.map((k, v) => MapEntry(k, v.name))}, '
      'puzzles: $registeredPuzzles, withdrawn: $withdrawn${error == null ? '' : ', error: $error'})';
}

/// Reads Nonogram packs published in Studio Content Studio and registers them in the game's
/// [PuzzleRepository], next to the bundled puzzles. Created only when remote content is enabled.
///
/// - [loadCached] reads the last good catalog and packs from disk. No network.
/// - [refresh] signs in as a guest (the SDK's `POST /v1/auth/guest`), reads the backend's
///   content catalog, fetches each pack (sending the stored ETag), and registers what changed.
///   On any failure what is registered stays: cached packs, else bundled puzzles only.
///   An expired session (HTTP 401) gets one fresh sign-in.
///
/// The rest of the SDK stays offline: this uses its own adapter, not the SDK's cloud sync.
class RemoteContentService {
  RemoteContentService({
    required this.repository,
    required this.config,
    required String storageDirectoryPath,
    StudioVpsAdapter? adapter,
  })  : _directory = '$storageDirectoryPath${Platform.pathSeparator}remote_content',
        _adapter = adapter ??
            StudioVpsAdapter(
              endpointUrl: config.backendUrl,
              hmacSigningKey: config.hmacKey,
              requestTimeout: const Duration(seconds: 8),
            ) {
    _packs = StudioContentPacks(
      backend: _adapter,
      gameId: gameId,
      supportedSchemas: const {
        RemoteContentConfig.contentType: {1},
      },
      storeFor: (packId) => FileStudioRemoteConfigStore(
        directory: _directory,
        gameId: gameId,
        scope: 'content:$packId',
        maxBytes: 4 * 1024 * 1024,
      ),
      catalogStore: FileStudioRemoteConfigStore(directory: _directory, gameId: gameId, scope: 'content-catalog'),
    );
  }

  static const String gameId = 'nonogram';

  final PuzzleRepository repository;
  final RemoteContentConfig config;
  final String _directory;
  final StudioVpsAdapter _adapter;
  late final StudioContentPacks _packs;
  bool _signedIn = false;
  Future<RemoteContentReport>? _running;

  /// Registers the cached packs of the cached catalog. Never touches the network.
  Future<RemoteContentReport> loadCached() async {
    final registrations = <String, RemotePackRegistration>{};
    for (final entry in await _packs.loadCachedCatalog()) {
      if (await _packs.loadCached(entry.packId)) {
        registrations[entry.packId] = repository.registerRemotePack(entry.packId, _packs.packOf(entry.packId)!.payload);
      }
    }
    final report = RemoteContentReport(registrations: registrations);
    debugPrint('[remote content] cached: $report');
    return report;
  }

  /// Fetches the published catalog and packs. Concurrent calls share one run. Never throws.
  Future<RemoteContentReport> refresh() => _running ??= _refresh().whenComplete(() => _running = null);

  Future<RemoteContentReport> _refresh() async {
    try {
      if (!_signedIn && !await _signIn()) {
        return _log(const RemoteContentReport(error: 'guest sign-in failed'));
      }
      var catalog = await _packs.refreshCatalog(contentType: RemoteContentConfig.contentType);
      if (catalog == StudioContentRefreshOutcome.notAuthenticated && await _signIn()) {
        catalog = await _packs.refreshCatalog(contentType: RemoteContentConfig.contentType);
      }
      if (catalog != StudioContentRefreshOutcome.updated && catalog != StudioContentRefreshOutcome.unchanged) {
        return _log(RemoteContentReport(signedIn: _signedIn, catalog: catalog));
      }

      final outcomes = <String, StudioContentRefreshOutcome>{};
      final registrations = <String, RemotePackRegistration>{};
      final listed = <String>{};
      for (final entry in _packs.catalog) {
        listed.add(entry.packId);
        var result = await _packs.refresh(entry.packId);
        if (result.outcome == StudioContentRefreshOutcome.notAuthenticated && await _signIn()) {
          result = await _packs.refresh(entry.packId);
        }
        outcomes[entry.packId] = result.outcome;
        final held = _packs.packOf(entry.packId);
        final alreadyRegistered = repository.remotePuzzleIds(entry.packId).isNotEmpty;
        if (held != null && (result.outcome == StudioContentRefreshOutcome.updated || !alreadyRegistered)) {
          registrations[entry.packId] = repository.registerRemotePack(entry.packId, held.payload);
        }
      }
      // Packs the server no longer lists leave the catalog; progress stored by puzzle id stays.
      final withdrawn = repository.remotePackIds.where((id) => !listed.contains(id)).toList();
      for (final id in withdrawn) {
        repository.removeRemotePack(id);
        await _packs.clear(id);
      }
      return _log(RemoteContentReport(
        signedIn: true,
        catalog: catalog,
        packs: outcomes,
        registrations: registrations,
        withdrawn: withdrawn,
      ));
    } catch (e) {
      return _log(RemoteContentReport(signedIn: _signedIn, error: '$e'));
    }
  }

  Future<bool> _signIn() async {
    try {
      await _adapter.authenticateAndHandshake(gameId: gameId, deviceId: await _deviceId(), hmacSigningKey: config.hmacKey);
      _signedIn = true;
    } catch (e) {
      debugPrint('[remote content] guest sign-in failed: $e');
      _signedIn = false;
    }
    return _signedIn;
  }

  /// A random id kept next to the content cache, so the guest account is the same across launches.
  Future<String> _deviceId() async {
    final file = File('$_directory${Platform.pathSeparator}device_id');
    try {
      final existing = (await file.readAsString()).trim();
      if (RegExp(r'^[a-f0-9]{32}$').hasMatch(existing)) return existing;
    } catch (_) {}
    final random = Random.secure();
    final id = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await file.parent.create(recursive: true);
    await file.writeAsString(id, flush: true);
    return id;
  }

  RemoteContentReport _log(RemoteContentReport report) {
    debugPrint('[remote content] refresh: $report');
    return report;
  }
}

/// Creates the service and registers cached content when [config] is enabled; otherwise
/// returns null without creating anything (no adapter, no file, no request).
Future<RemoteContentService?> startRemoteContent({
  required RemoteContentConfig config,
  required PuzzleRepository repository,
  required String storageDirectoryPath,
}) async {
  if (!config.enabled) return null;
  final service = RemoteContentService(repository: repository, config: config, storageDirectoryPath: storageDirectoryPath);
  await service.loadCached();
  return service;
}
