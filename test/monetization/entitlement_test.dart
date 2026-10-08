import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/core/monetization/iap/iap_manager.dart';
import 'package:nonogram/core/storage/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Entitlement and Purchase Transitions tests', () {
    late AppDatabase db;
    late IapManager iapManager;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      iapManager = IapManager(db: db, isMockMode: true);
      await iapManager.initialize();
    });

    tearDown(() async {
      iapManager.dispose();
      await db.close();
    });

    test('Initial entitlement state defaults to not ads-free', () {
      expect(iapManager.isAdsFree, isFalse);
    });

    test('Purchasing ads-free transitions entitlement and persists to DB', () async {
      final success = await iapManager.buyAdsFree();
      expect(success, isTrue);
      expect(iapManager.isAdsFree, isTrue);

      // Verify offline DB persistence
      final isEntitledInDb = await db.hasActiveEntitlement(IapProductConfig.adsFreeId);
      expect(isEntitledInDb, isTrue);
    });

    test('New app session restores cached verified entitlement offline', () async {
      // First session: buy
      await iapManager.buyAdsFree();
      expect(iapManager.isAdsFree, isTrue);

      // Second session (e.g. app restarted offline)
      final secondSessionIap = IapManager(db: db, isMockMode: true);
      await secondSessionIap.initialize();

      expect(secondSessionIap.isAdsFree, isTrue);
      secondSessionIap.dispose();
    });

    test('Revocation turns entitlement off and updates DB', () async {
      await iapManager.buyAdsFree();
      expect(iapManager.isAdsFree, isTrue);

      // Simulate backend refund revocation
      await iapManager.revokeAdsFree();
      expect(iapManager.isAdsFree, isFalse);

      final inDb = await db.hasActiveEntitlement(IapProductConfig.adsFreeId);
      expect(inDb, isFalse);
    });
  });
}
