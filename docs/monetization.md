# Monetization Architecture & Store Setup

## Overview

The monetization subsystem is designed around player respect, sustainable monetization, and compliance with Google Play Billing and Apple App Store Review Guidelines.

It encompasses:
1. **In-App Purchase (IAP)**: Non-consumable `ads_free` entitlement.
2. **Advertising**: Non-intrusive interstitials with frequency caps and optional rewarded ads for hints.
3. **Earned Economy**: Soft currency (`coins`) and daily reward streak bonuses.

---

## 1. In-App Purchase Architecture (`ads_free`)

### Product Identifier
- **ID**: `com.antigravity.nonogram.ads_free`
- **Type**: Non-consumable (permanent unlock)

### Entitlement Lifecycle & Persistence
```
[User Taps Buy] 
      │
      ▼
[InAppPurchase Platform SDK / StoreKit / Play Billing]
      │
      ▼
[Receipt Validation Boundary]
      │
      ▼
[Drift SQLite Entitlement Table] ──► Cached Offline
      │
      ▼
[IapManager.adsFreeStream] ──► Disables all Interstitial Ads
```

### Verification Boundary (`ReceiptValidator`)
- An abstract `ReceiptValidator` contract separates purchase capture from backend cryptographic validation.
- In production, forward `purchase.verificationData.serverVerificationData` to your secure backend (e.g., Cloud Function or server) validating with:
  - **Google Play Developer API**: `purchases.products.get`
  - **Apple App Store Server API**: `verifyReceipt` or App Store Server API JWT endpoint
- In sandbox / development mode, `LocalReceiptValidator` validates non-empty tokens.

### Store Configuration Steps

#### Google Play Console
1. Navigate to **Monetize > Products > In-app products**.
2. Click **Create product**.
3. Product ID: `com.antigravity.nonogram.ads_free`
4. Name: `Remove Ads`
5. Description: `Removes all interstitial advertisements permanently.`
6. Status: **Active**.

#### Apple App Store Connect
1. Navigate to **Apps > [Your App] > In-App Purchases**.
2. Click **+** and choose **Non-Consumable**.
3. Reference Name: `Remove Ads`
4. Product ID: `com.antigravity.nonogram.ads_free`
5. Pricing: Tier 3 ($2.99 USD or equivalent).
6. Provide App Store review screenshot and description.

#### Restore Purchases Requirement
Per Apple App Store Review Guideline 3.1.1, a **Restore Purchases** button is prominent on both the **Shop Screen** and the **Settings Screen**. It queries `InAppPurchase.instance.restorePurchases()`, re-populates the local Drift `EntitlementEntries` table, and immediately updates the UI without double charging.

---

## 2. Advertising Architecture

### Placements
- **`interstitialCompletion`**: Natural break after completing a puzzle.
- **`rewardedHint`**: Optional rewarded video granting a free gameplay hint.
- **`rewardedCoins`**: Optional rewarded video granting +50 bonus coins.

### Policies & Frequency Capping
- **No Forced Ads During Active Play**: Ads NEVER interrupt an active puzzle.
- **Frequency Cap**: Configured in `AdManager`:
  - Minimum 2 completed puzzles between interstitials.
  - Minimum 90 seconds elapsed between interstitials.
- **Ads Free Protection**: When `iap.isAdsFree == true`, the interstitial logic immediately short-circuits to `false`.

### Development Mock Provider
- For local testing, desktop runs, and headless CI, `MockAdProvider` simulates deterministic ad impressions and rewarded completions without needing AdMob native dependencies.

---

## 3. Player Economy & Daily Rewards

- **Initial Balance**: 100 coins, 5 hints.
- **Daily Streak Bonus**:
  - Streak day 1–7 gives $+10$ extra coins per consecutive day.
  - Every 3 days gives $+2$ bonus hints.
- **Hint Shop**:
  - 3 Hints = 100 Coins
  - 10 Hints = 300 Coins
- **Offline Resilience**: State is stored directly in SQLite (`PlayerEconomyEntries`).
