import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/core/monetization/economy/economy_manager.dart';
import 'package:nonogram/core/storage/database/app_database.dart';
import 'package:nonogram/core/storage/vault/game_state_vault.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempVaultDir;
  late HttpServer trapServer;
  late String trapUrl;
  final List<String> capturedHttpCalls = [];

  setUp(() async {
    capturedHttpCalls.clear();
    tempVaultDir = await Directory.systemTemp.createTemp('nonogram_offline_test_');

    // HTTP trap server to guarantee zero network packets are emitted
    trapServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    trapUrl = 'http://${trapServer.address.host}:${trapServer.port}';
    trapServer.listen((HttpRequest request) async {
      capturedHttpCalls.add('${request.method} ${request.uri.path}');
      request.response.statusCode = 500;
      await request.response.close();
    });
  });

  tearDown(() async {
    if (StudioSdk.isInitialized) {
      await StudioSdk.instance.disposeSdk();
    }
    await trapServer.close(force: true);
    if (tempVaultDir.existsSync()) {
      await tempVaultDir.delete(recursive: true);
    }
  });

  group('Hardened Offline-First Integration & Single-Source Wallet Tests', () {
    test(
      'PHASE 3: Offline-first bootstrap emits ZERO network packets & persists UUIDv4 install_id',
      () async {
        final sdk1 = await StudioSdk.initialize(
          gameId: 'nonogram',
          storageDirectoryPath: tempVaultDir.path,
          config: StudioConfig(
            enableCloudSync: false,
            enableDebugOverlay: false,
            cdnBaseUrl: trapUrl,
            initialCurrencies: const {
              StudioCurrencyIds.gold: 100,
              StudioCurrencyIds.hints: 5,
            },
          ),
        );

        // 1. Verify offline backend adapter
        expect(sdk1.backendAdapter, isA<OfflineLocalBackendAdapter>());
        expect(sdk1.hasToken, isFalse);

        // 2. Verify UUIDv4 format of install_id
        final uuidV4Regex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        );
        final initialInstallId = sdk1.installId;
        expect(uuidV4Regex.hasMatch(initialInstallId), isTrue,
            reason: 'Generated install_id must be a cryptographically random UUIDv4');
        expect(sdk1.playerId, equals(initialInstallId));

        // 3. Mutate wallet, outbox, and liveops
        await sdk1.wallet.credit(StudioCurrencyIds.gold, 50, source: 'offline_test');
        await sdk1.wallet.trySpend(StudioCurrencyIds.hints, 1, reason: 'test_hint');
        await sdk1.outboxSync.flushBatch(reason: 'manual_flush');
        await sdk1.liveOps.refreshConfigsFromCdn();

        // 4. Restart SDK in same vault directory — install_id must persist
        await sdk1.disposeSdk();

        final sdk2 = await StudioSdk.initialize(
          gameId: 'nonogram',
          storageDirectoryPath: tempVaultDir.path,
          config: StudioConfig(
            enableCloudSync: false,
            enableDebugOverlay: false,
            cdnBaseUrl: trapUrl,
          ),
        );

        expect(sdk2.installId, equals(initialInstallId),
            reason: 'install_id must be persisted across restarts without server handshake');

        // 5. Zero network requests must have hit trap server
        expect(capturedHttpCalls, isEmpty,
            reason: 'Offline mode must emit zero network packets');
      },
    );

    test(
      'PHASE 4: Single-Source Wallet binds EconomyManager strictly to StudioSdk.wallet',
      () async {
        final sdk = await StudioSdk.initialize(
          gameId: 'nonogram',
          storageDirectoryPath: tempVaultDir.path,
          config: const StudioConfig(
            enableCloudSync: false,
            initialCurrencies: {
              StudioCurrencyIds.gold: 100,
              StudioCurrencyIds.hints: 5,
            },
          ),
        );

        final db = AppDatabase(NativeDatabase.memory());
        final economy = EconomyManager(db: db, wallet: sdk.wallet);
        await economy.initialize();

        // Check initial state
        expect(economy.coins, equals(100));
        expect(economy.hintsRemaining, equals(5));

        // Buying hints: 100 coins -> 3 hints
        final buySuccess = await economy.buyHintWithCoins(cost: 100, hintsToAdd: 3);
        expect(buySuccess, isTrue);
        expect(economy.coins, equals(0));
        expect(economy.hintsRemaining, equals(8));
        expect(sdk.wallet.gold, equals(0));
        expect(sdk.wallet.hints, equals(8));

        // Attempting to buy when insufficient coins
        final failBuy = await economy.buyHintWithCoins(cost: 100, hintsToAdd: 3);
        expect(failBuy, isFalse);

        // Consuming hints
        final hintConsumed = await economy.consumeHint();
        expect(hintConsumed, isTrue);
        expect(economy.hintsRemaining, equals(7));
        expect(sdk.wallet.hints, equals(7));

        // Granting gameplay reward
        await economy.grantReward(addCoins: 45);
        expect(economy.coins, equals(45));
        expect(sdk.wallet.gold, equals(45));

        await db.close();
      },
    );

    test(
      'PHASE 4: Crash-Safe GameStateVault persists and recovers puzzle state without XOR corruption',
      () async {
        final vault = GameStateVault.instance;
        await vault.initialize(storageDirectoryPath: tempVaultDir.path);

        const testPuzzleId = 'animals_cat_01';
        final now = DateTime.now();

        await vault.savePuzzleState(
          SavedPuzzleState(
            puzzleId: testPuzzleId,
            isCompleted: false,
            stars: 0,
            bestTimeSeconds: 0,
            lastPlayed: now,
            savedBoardState: '10101,01010',
            savedMistakes: 1,
            savedHintsUsed: 2,
            savedElapsedSeconds: 42,
          ),
        );

        final restored = vault.getPuzzleState(testPuzzleId);
        expect(restored, isNotNull);
        expect(restored!.puzzleId, equals(testPuzzleId));
        expect(restored.savedBoardState, equals('10101,01010'));
        expect(restored.savedMistakes, equals(1));
        expect(restored.savedHintsUsed, equals(2));
        expect(restored.savedElapsedSeconds, equals(42));
        expect(restored.isCompleted, isFalse);
      },
    );

    test(
      'PHASE 5: resetLocalGameData clears progress and wallet but preserves installId',
      () async {
        final sdk = await StudioSdk.initialize(
          gameId: 'nonogram',
          storageDirectoryPath: tempVaultDir.path,
          config: const StudioConfig(
            enableCloudSync: false,
            initialCurrencies: {
              StudioCurrencyIds.gold: 100,
              StudioCurrencyIds.hints: 5,
            },
          ),
        );

        final initialInstallId = sdk.installId;

        // Mutate wallet and save vault state
        await sdk.wallet.credit(StudioCurrencyIds.gold, 500);
        await sdk.wallet.credit(StudioCurrencyIds.hints, 20);

        final vault = GameStateVault.instance;
        await vault.initialize(storageDirectoryPath: tempVaultDir.path);
        await vault.savePuzzleState(
          SavedPuzzleState(
            puzzleId: 'puzzle_reset_test',
            isCompleted: true,
            stars: 3,
            bestTimeSeconds: 12,
            lastPlayed: DateTime.now(),
          ),
        );

        expect(sdk.wallet.gold, equals(600));
        expect(sdk.wallet.hints, equals(25));
        expect(vault.getPuzzleState('puzzle_reset_test'), isNotNull);

        // Perform local data reset preserving installId
        await sdk.resetLocalGameData(preserveInstallId: true);
        await vault.clearAll();

        // 1. install_id preserved
        expect(sdk.installId, equals(initialInstallId));

        // 2. Wallet reset to starter defaults (100 coins, 5 hints)
        expect(sdk.wallet.gold, equals(100));
        expect(sdk.wallet.hints, equals(5));

        // 3. Vault cleared
        expect(vault.getPuzzleState('puzzle_reset_test'), isNull);
      },
    );
  });
}
