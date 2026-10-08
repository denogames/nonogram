import 'dart:async';
import 'dart:developer' as dev;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../analytics/analytics_service.dart';
import '../../storage/database/app_database.dart';

class IapProductConfig {
  static const adsFreeId = 'com.antigravity.nonogram.ads_free';
  static const Set<String> allProductIds = {adsFreeId};
}

enum PurchaseVerificationStatus {
  verified,
  pending,
  failed,
  restored,
}

/// Boundary for server-side or cryptographically validated in-app receipts.
abstract class ReceiptValidator {
  Future<bool> validateReceipt({
    required String productId,
    required String verificationData,
    required String source,
  });
}

/// Default local offline/sandbox receipt validator.
class LocalReceiptValidator implements ReceiptValidator {
  @override
  Future<bool> validateReceipt({
    required String productId,
    required String verificationData,
    required String source,
  }) async {
    // In production, send transaction receipt payload to your secure backend endpoint
    // (e.g. Google Play Developer API / Apple App Store Server API) for cryptographic verification.
    // In offline/sandbox local mode, verify non-empty token integrity.
    return verificationData.isNotEmpty && IapProductConfig.allProductIds.contains(productId);
  }
}

class IapManager {
  final InAppPurchase? _iapInstance;
  final AppDatabase db;
  final AnalyticsService _analytics;
  final ReceiptValidator _receiptValidator;
  final bool isMockMode;

  InAppPurchase get _iap => _iapInstance ?? InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAdsFreeCached = false;
  final StreamController<bool> _adsFreeStreamController = StreamController<bool>.broadcast();

  IapManager({
    InAppPurchase? iap,
    required this.db,
    AnalyticsService? analytics,
    ReceiptValidator? receiptValidator,
    this.isMockMode = false,
  })  : _iapInstance = iap,
        _analytics = analytics ?? AnalyticsService.instance,
        _receiptValidator = receiptValidator ?? LocalReceiptValidator();

  bool get isAdsFree => _isAdsFreeCached;
  Stream<bool> get adsFreeStream => _adsFreeStreamController.stream;

  Future<void> initialize() async {
    // 1. Read cached entitlement from offline SQLite DB
    _isAdsFreeCached = await db.hasActiveEntitlement(IapProductConfig.adsFreeId);
    _adsFreeStreamController.add(_isAdsFreeCached);

    if (isMockMode) {
      dev.log('IAP Manager running in Mock Mode', name: 'IapManager');
      return;
    }

    // 2. Listen to platform purchase stream
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (err) => dev.log('IAP stream error: $err', name: 'IapManager'),
    );
  }

  void dispose() {
    _subscription?.cancel();
    _adsFreeStreamController.close();
  }

  /// Purchase non-consumable ads_free product.
  Future<bool> buyAdsFree() async {
    if (isMockMode) {
      dev.log('[MockIAP] Simulating purchase of ads_free', name: 'IapManager');
      await _activateAdsFree(source: 'mock_sandbox', transactionId: 'mock_tx_${DateTime.now().millisecondsSinceEpoch}');
      return true;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      dev.log('In-app purchase not available on this device', name: 'IapManager');
      return false;
    }

    final response = await _iap.queryProductDetails({IapProductConfig.adsFreeId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      dev.log('Product ${IapProductConfig.adsFreeId} not found in store catalog', name: 'IapManager');
      return false;
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore previous purchases (required by App Store and Google Play).
  Future<void> restorePurchases() async {
    if (isMockMode) {
      dev.log('[MockIAP] Restoring mock purchases', name: 'IapManager');
      await _activateAdsFree(source: 'mock_restore', transactionId: 'restored_mock_tx');
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) return;

    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final isValid = await _receiptValidator.validateReceipt(
          productId: purchase.productID,
          verificationData: purchase.verificationData.serverVerificationData,
          source: purchase.verificationData.source,
        );

        if (isValid && purchase.productID == IapProductConfig.adsFreeId) {
          await _activateAdsFree(
            source: purchase.verificationData.source,
            transactionId: purchase.purchaseID ?? 'unknown_tx',
          );
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        dev.log('Purchase error: ${purchase.error}', name: 'IapManager');
      }
    }
  }

  Future<void> _activateAdsFree({
    required String source,
    required String transactionId,
  }) async {
    _isAdsFreeCached = true;
    _adsFreeStreamController.add(true);

    // Persist verified entitlement to SQLite Drift database
    await db.setEntitlement(
      entitlementId: IapProductConfig.adsFreeId,
      isActive: true,
      source: source,
      signature: transactionId,
    );

    await _analytics.logPurchaseVerified(
      productId: IapProductConfig.adsFreeId,
      transactionId: transactionId,
    );
    await _analytics.logAdsFreeActivated(source: source);
  }

  /// Revoke entitlement (e.g., refund notification from backend).
  Future<void> revokeAdsFree() async {
    _isAdsFreeCached = false;
    _adsFreeStreamController.add(false);
    await db.setEntitlement(
      entitlementId: IapProductConfig.adsFreeId,
      isActive: false,
      source: 'revocation',
    );
  }
}
