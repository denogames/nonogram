# Test Verification Report

## N-1 otomatik kayıt — 11 Kasım 2026

- **Kapsam:** [D-009](decisions.md#d-009--yarım-puzzleın-otomatik-kaydı-n-1). Başlangıç HEAD `a4209d4`.
- **Ortam:** macOS, Flutter 3.47.5; Android emülatörü Pixel 10 AVD, Android 17 (API 37), arm64. Uzak içerik için yerel tek kullanımlık studio-core-backend `f22eb2e` (`adb reverse` + istek sayan proxy). Hiçbir şey deploy edilmedi.

| Komut | Sonuç |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 70 passed, 1 skipped (önceki 57) |
| `flutter test test/storage/puzzle_autosave_test.dart` | 10/10 |
| `flutter test test/widget/puzzle_autosave_screen_test.dart` | 3/3 (gerçek `PuzzleScreen`, parmak hareketiyle) |

Regresyon testleri:

- **Tek hamle:** ekran açıkken kasa ve SQLite'ta (ekrandan çıkmadan). Bu kayıt kaldırıldığında test başarısız olur (kontrol edildi).
- **Hızlı hamleler:** aynı anda tek yazma, ara durumlar atlanır, en yeni tahta en son yazılır.
- **Yeniden açılış:** dosya veritabanı + kasa yeniden açılınca son tahta, süre, hata ve ipucu; kasa kaybolursa SQLite'tan.
- **Arka plan:** `inactive → hidden → paused` geçişi hamlesiz geçen süreyi kaydeder.
- **Başarısız yazma:** saklanır, flush'ta yeniden denenir, döngü yok; daha yeni hamle eskisinin yerine geçer.
- **Tamamlanma sırasında bekleyen yazma:** bekleyen düşer, süren yazma beklenir; sonrasında kayıt yazılmaz; ekranda tamamlanma, 3 yıldız, coin 100 → 145 korunur, yarım tahta geri gelmez.
- **Tamamlanmış puzzle'ın tekrar oynanışı:** tamamlanma ve yıldız ezilmez.
- **İçerik revizyonu (aynı id ve boyut, farklı çözüm):** eski tahta geri yüklenmez.
- **Varsayılan (uzak içerik kapalı):** ekran testi boyunca `HttpClient` oluşturulmadı.

### Gerçek uygulama (Android emülatörü)

| Adım | Gözlem |
| --- | --- |
| Food → Coffee Mug (10×10), 8 hamle, ekranda `am force-stop` | Yeniden açılışta 8 hücre geri geldi, süre son hamleden (≈00:15) devam etti (00:16) |
| Bulmaca tamamlandı (3 yıldız), tamamlanma ekranında `force-stop` | Food 1/3 ★3; coin 145; yeniden açılışta tahta boş (yarım kayıt yok) |
| Tamamlanmış puzzle'da 1 hamle, `force-stop` | Food 1/3 ★3 korundu |
| Animals → Cat: 1 hamle, ≈12 sn bekleme, Home tuşu, `force-stop` | Süre 00:16'dan devam etti (hamle anı ≈00:02): ön plandan çıkış kaydı çalıştı |
| Uzak içerik açık build: tam 3 istek (misafir, katalog, `seasonal_picks`); Studio Tree'de 9 hücre, `force-stop`, backend kesik yeniden açılış | 9 hücre ve süre geri geldi (çevrimdışı, 0 istek); tamamlandı: Seasonal 1/3 ★3, coin 190 |

---

## Entegrasyon stabilizasyonu — 11 Kasım 2026

- **Kapsam:** PLATFORM-V1-010, [D-008](decisions.md#d-008--üretim-misafir-kimliği-güvenliği-ve-kayıtlı-tahta-uyumu). Repository `denogames/nonogram`, branch `master`, başlangıç HEAD `bdeff1de2acf6f9ed1ae519a56e779202046c1c1`.
- **Ortam:** macOS, Flutter 3.47.5 stable; yerel tek kullanımlık studio-core-backend `71185a1` (geçici PostgreSQL, rastgele `HMAC_SHARED_SECRET`). Hiçbir şey deploy edilmedi.

| Komut | Sonuç |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 57 passed, 1 skipped (canlı test env olmadan atlanır). Önceki: 52 passed |
| `flutter test test/content/remote_content_test.dart` | 18/18 passed |
| `tool/run_remote_content_live.sh <studio-core-backend>` | passed; oyuna backend sırrı **verilmeden** misafir girişi, katalog, paket, revizyon 2, 304 ve çevrimdışı önbellek çalıştı |

Yeni regresyon testleri (`saved boards follow puzzle content` grubu ve bayrak testleri):

- **Değişmeyen içerik:** kaydedilen tahta, hata, ipucu ve süre aynen geri gelir; motor aynı tahtayı üretir.
- **Yeniden adlandırma ve eklenen puzzle'lar:** başlık değişimi tahtayı korur; yeni puzzle boş başlar.
- **Aynı boyutta değişen çözüm:** eski işaretler geri yüklenmez, yeni oturum boş (0 hata/ipucu/süre); eski kayıt silinmez; başka puzzle'ın tamamlanma/yıldız/en iyi süre kaydı, bundled ilerleme ve cüzdan satırı değişmez.
- **Çevrimdışı kurtarma:** kasa diskten yeniden açılır, içerik önbellekten gelir, tahta devam eder; çözüm çevrimiçi değiştikten sonraki çevrimdışı açılışta tahta geri yüklenmez.
- **Eski biçim:** parmak izsiz eski kayıt boyutu uyarsa geri yüklenir; bozuk önek, yanlış boyut, başka puzzle'ın parmak izi ve tamamlanmış puzzle geri yüklenmez.
- **Güvenlik:** bayrak varsayılan kapalı, release build'de her koşulda kapalı; `lib/` içinde `NONOGRAM_CONTENT_HMAC_KEY` yok.

CI: `.github/workflows/ci.yml` (push → master, elle çalıştırma; pull request tetikleyicisi yok). İlk başarılı GitHub Actions çalıştırması: [42987227258](https://github.com/denogames/nonogram/actions/runs/42987227258) (`10dbfe5`; analyze temiz, 57 passed, 1 skipped). Ayrıntı [project_status](project_status.md#continuity-checkpoint-11-kasım-2026--entegrasyon-stabilizasyonu) içinde.

---

## Content Studio uzaktan içerik entegrasyonu — 11 Kasım 2026

- **Kapsam:** PLATFORM-V1-009, [D-007](decisions.md#d-007--content-studio-uzaktan-içerik-entegrasyonu-opt-in). Repository `denogames/nonogram`, branch `master`, başlangıç HEAD `1222e309c5f0fa55db8fe4f01f6fc07eff3c32a8`; değişiklikler bu kayıtla aynı commit'tedir.
- **Ortam:** macOS, Flutter 3.47.5 stable, iOS Simulator iPhone 17. studio-core-sdk `50f6d2e` (SDK CI: [run 42927746766](https://github.com/denogames/studio-core-sdk/actions/runs/42927746766) başarılı). Yerel, tek kullanımlık studio-core-backend `9321704` (`STUDIO_CONTENT_ENABLED=true`, geçici PostgreSQL). Hiçbir şey deploy edilmedi.
- **Bu repository'de GitHub Actions workflow'u yoktur;** aşağıdaki sonuçlar yerel çalıştırmalardır, CI kanıtı değildir.

### Komutlar

| Komut | Sonuç |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 52 passed, 1 skipped (skip: canlı backend testi env olmadan atlanır). Değişiklik öncesi taban: 39 passed |
| `flutter test test/content/remote_content_test.dart` | 13/13 passed |
| `tool/run_remote_content_live.sh <studio-core-backend>` | passed (backend `9321704`) |

### Otomatik senaryolar (`test/content/remote_content_test.dart`, loopback sahte backend)

Flag ayrıştırma; flag kapalı (servis yok, 0 istek, dosya yok); soğuk başlangıç (tam istek sırası, günlük puzzle değişmez); çevrimdışı açılışta önbellek kullanımı; misafir oturumu reddi (bundled + önbellek kalır); süresi dolmuş oturum (401 → tek yeniden giriş); revizyon değişimi ve paketin yayından kalkması; bozuk payload, checksum'ı değiştirilmiş giriş ve desteklenmeyen şema 2; bundled ve paketler arası id çakışması; bozuk önbellek dosyası; drift ilerlemesinin korunması; repository dinleyici bildirimi.

### Canlı backend testi (`test/content/remote_content_live_test.dart`)

Admin API ile gerçek taslak → yayın; oyun servisi misafir girişi + katalog + paket çekti; revizyon 2 yayınlandı ve yalnız değişen puzzle'ın revizyonu arttı; ikinci yenilemede 304; backend'siz yeniden açılışta önbellek kullanıldı.

### Gerçek uygulama (iOS Simulator, iPhone 17)

Yayınlanan paket: `seasonal_picks`, kategori `seasonal` (revizyon 1: Studio Heart 5×5, Studio Tree 5×5, Studio Penguin 10×10). İstekler backend önündeki sayaçlı bir proxy ile kaydedildi.

| Adım | Gözlem |
| --- | --- |
| Flag kapalı build | Proxy **0 istek**; uygulama kapsayıcısında `remote_content` dizini yok. Bundled Food/"Apple" 3 yıldızla çözüldü (coin 100 → 145). |
| Aynı veriler üzerine flag açık build | Proxy tam olarak `POST /v1/auth/guest`, `GET /v1/content/packs?content_type=nonogram`, `GET /v1/content/packs/seasonal_picks`. Collections'ta yeni "Seasonal" (0/3); Food & Drinks 1/3 ve 3 yıldız korundu; günlük puzzle ("Key") ve 145 coin değişmedi. |
| Uzak puzzle oynandı | Seasonal → "Studio Heart" normal puzzle ekranında Content Studio ipuçlarıyla açıldı ve 3 yıldızla çözüldü (coin 190). |
| Çevrimdışı yeniden açılış | Proxy durduruldu, uygulama kapatılıp açıldı: Seasonal 1/3 + 3 yıldız ve Food & Drinks 1/3 + 3 yıldız önbellekten gösterildi; 190 coin. |
| Revizyon 2 | Studio Tree → "Studio Pine" ve yeni "Studio Star" 5×5 yayınlandı; yeniden açılışta aynı 3 istek, Seasonal **1/4**, Studio Heart 3 yıldızını korudu, yeni 5×5 puzzle listede. |

### Sınırlar

- İlk çevrimiçi açılışta uzak içerik ilk kareden sonra gelir; sonraki açılışlarda önbellekten hemen görünür. Yenileme açılış başına bir kezdir.
- Aynı boyutta içeriği değişen bir uzak puzzle'ın yarım kalmış tahtası eski işaretlerle geri yüklenebilir (mevcut uzunluk koruması çökmeyi engeller).
- Uzak puzzle başlıkları mevcut UI davranışı gereği çözülene kadar "Level N" olarak görünür; ana ekran alt başlığı statik metindir.
- Android'de gerçek cihaz/emülatör çalıştırması yapılmadı; doğrulama iOS Simulator'dadır.

---

## Studio Core SDK Offline-First Hardening Doğrulama Kaydı — 28 Ekim 2026

- **Tarih:** 28 Ekim 2026 (Europe/Istanbul)
- **Kapsam:** `studio_core_sdk` offline-first entegrasyonu, single-source wallet (`gold`, `hints`), crash-safe `GameStateVault` (`nonogram_game_state`), leaf timer optimizasyonu, offline UI temizliği ve yerel veri sıfırlama (`resetLocalGameData`).
- **Komut ve Çıktılar:**
  - `flutter analyze`: **No issues found!** (0 errors, 0 warnings, ran in 14.2s).
  - `flutter test ..\studio-core-sdk`: **26 passed, 0 failed** (SDK core unit testleri).
  - `flutter test`: **39 passed, 0 failed** (35 orijinal test + 4 yeni offline-first SDK integration testi).
- **Ağ İzolasyonu Testi:** `test/studio_sdk_integration_test.dart` içinde loopback HTTP trap server ile bootstrap ve işlem akışlarında **sıfır ağ paketi (0 packets)** yayımlandığı kanıtlanmıştır.
- **install_id Kalıcılığı:** Kriptografik rastgele UUIDv4 `install_id` ilk açılışta üretilip `nonogram_identity` kasasında saklanmakta; yerel veri sıfırlamasında korunmaktadır.
- **Çift Cüzdan Tasfiyesi:** `EconomyManager`, `StudioSdk.instance.wallet`'a bağlanarak drift DB cüzdan kopyalama ayrışması giderilmiştir.

---

## Recovery kanıt sınırları — 18–19 Ekim 2026

Aşağıdaki eski Summary, PASSED listeleri ve CLI sonuçları **tarihsel belge iddiaları olarak korunmuştur**. Bu M0 sırasında yeniden çalıştırılmış veya güncel başarı olarak doğrulanmış değildir.

- İncelenen kod tabanı: `master`, HEAD `0b775ba2afda5a8307b0291f484bac3e130e9f05`. Raporun bu commit içinde bulunması, sonuçların bu commit üzerinde üretildiğini kanıtlamaz.
- Eski raporda yeniden üretilebilir SDK/işletim sistemi/cihaz ortamı, test edilen commit ve ham çıktı bağlantısı görülmedi. Orijinal çalıştırma tarihi doğrulanmadı.
- M0 sırasında test, analyze, build, uygulama, generator, kurulum, migration veya içerik validator çalıştırılmadı. Kurulu SDK sürümü kontrol edilmedi. Yeni uygulama başarısı eklenmedi.
- Salt okunur sayım: sekiz Dart test dosyasında 35 bildirim. Bu, 35 testin geçtiği anlamına gelmez.
- IAP testleri mock/bellek içi DB kullanır; ikinci oturum aynı DB nesnesi üzerinde yeni manager kurar. Gerçek mağaza veya süreçler arası disk kalıcılığı kanıtı değildir.
- Widget smoke testi main başlangıcını çağırmaz; kendi ProviderScope'u ile NonogramApp kurar. Günlük seçim testleri farklı cihaz/süreçlerde karşılaştırma yapmaz. Kaynaklar ve doğrulama ihtiyaçları [B5](project_status.md#b5--tarihsel-başarılar-ve-kanıt-kapsamı) içindedir.

### İçerik sayımı ve tarihsel kapsam

JSON dosyalarının salt okunur kayıt sayımı:

| Dosya | Normal katalog kaydı | Öğretici kaydı |
| --- | --- | --- |
| animals.json | 4 | 0 |
| nature.json | 4 | 0 |
| food.json | 3 | 0 |
| objects.json | 3 | 0 |
| symbols.json | 4 | 0 |
| tutorial.json | 0 | 2 |
| Toplam | 18 | 2 |

Eski Summary içindeki **18/18**, beş normal paketin toplamıyla; CLI bölümündeki **20**, tutorial dahil altı dosyayla örtüşür. Bu kapsam açıklaması yeniden doğrulama değildir. JSON okuma/sayımı; checksum, şema uygunluğu, çözülebilirlik, tek çözüm veya uygulamada yüklenme kanıtı değildir. [B4](project_status.md#b4--bundled-ve-haricî-içerik-kalite-yolları) açık kalır.

## M0 belge kontrolleri

**Verified — yalnız belge kontrolleri; 19 Ekim 2026 (Europe/Istanbul).** Kod tabanı HEAD'i değişmedi; kontrol edilen belge değişiklikleri henüz commit edilmedi. Yöntemler salt okunur yerel dosya/Git kontrolleri ve içerik incelemesidir.

| Kontrol | Yöntem ve sonuç |
| --- | --- |
| İzinli dosya sınırı | Tracked diff, staged diff ve untracked dosya listesi yedi dosyalık izin listesiyle karşılaştırıldı: dört yeni, üç düzenlenmiş belge; kapsam dışı değişiklik ve staged değişiklik yok. |
| Yerel belge bağlantıları | Yedi belgedeki 88 yerel Markdown hedefi dosya/dizin varlığıyla kontrol edildi; 17 başlık fragment'i başlıklarla, 16 kaynak satır bağı dosya satır aralığıyla karşılaştırıldı. Kırık hedef/başlık veya aralık dışı satır bulunmadı. |
| Tarihsel sonuçların korunması | HEAD'deki raporun `## Summary` başlangıcından sonraki gövdesi güncel gövdeyle karşılaştırıldı; satır sonu normalizasyonu dışında içerik aynı. Yeni uygulama test başarısı eklenmedi. |
| Roadmap fikirlerinin korunması | HEAD'deki dokuz v1.1/v1.2/v2.0 fikir maddesi güncel metinle karşılaştırıldı; aynı. Başlık hiyerarşisi düzenlendi, fikirler taahhüde dönüştürülmedi. |
| Diff ve metin temizliği | `git diff --check` başarılı; yeni belgeler dahil yedi dosyada satır sonu boşluk ve Unicode replacement karakteri taramasında sorun bulunmadı. README klasör örneği ve gerçek Markdown bağlantı hedefleri kontrol edildi. |
| Anlam ve yetki tutarlılığı | B1–B7'nin kaynak/kanıt/etki/doğrulama alanları, kanonik belge haritası, M0 Implemented, yalnız belge kapsamında Verified, Accepted yürütme yetkisi ile bekleyen teslim kabulü ve Proposed M1 ayrımı gözden geçirildi. AGENTS görevden bağımsız; M0 sınırları durum kaydında. |

Sınırlar: Bağlantılar yerel hedef/başlık/satır düzeyinde kontrol edildi; Markdown tarayıcı render'ı ve dış web hedefleri incelenmedi. Satır bağının geçerli olması çalışma zamanı kanıtı değildir. Uygulama, test, analyzer, build, içerik kalite kapısı, SDK, cihaz, mağaza, iOS ve kullanıcı kabulü bu Verified kapsamının dışındadır. Bu kontroller ürün doğrulaması veya Released durumu oluşturmaz.

## Tarihsel sonuçlar

Bu noktadan sonraki özgün sonuç metni korunmuştur; güncel çalışma kanıtı olarak kullanılmamalıdır.

## Summary

- **Total Automated Tests**: 35 Passed, 0 Failed.
- **Flutter Analyze Status**: 0 Errors, 0 Warnings, Clean (`flutter analyze` exit code 0).
- **Platform Build Status**: Android APK compiled cleanly (`flutter build apk --debug` exit code 0), bundle assembled cleanly (`flutter build bundle` exit code 0).
- **Starter Content Validation**: 18/18 Puzzles Verified Unique & Solvable via CLI tool.

---

## Detailed Test Breakdown

### 1. Pure Dart Engine & 1D Line Solver (`test/engine/line_solver_test.dart`)
- `Empty clue on line of 5 means all cells are crossed`: PASSED
- `Full line clue [5] on line of 5 means all cells are filled`: PASSED
- `Overlap clue [3] on line of 5 deduces center cell is filled`: PASSED
- `Exact fit clue [2, 2] on line of 5 determines entire line`: PASSED
- `Detects contradiction when clue cannot fit given crossed cells`: PASSED

### 2. Dual-Phase Nonogram Solver & Uniqueness Verification (`test/engine/solver_test.dart`)
- `Solves a 5x5 heart puzzle with unique solution`: PASSED
- `Solves a 10x10 cup puzzle with verified unique solution`: PASSED
- `Detects ambiguous puzzle with multiple solutions (rejects ambiguity)`: PASSED
- `Detects contradiction with no solutions (rejects invalid puzzles)`: PASSED
- `Validates quality gate through PuzzleValidator`: PASSED

### 3. Interactive Gameplay Engine (`test/engine/puzzle_engine_test.dart`)
- `Initial board state is all empty`: PASSED
- `Applying tools modifies cells correctly (fill, cross, erase)`: PASSED
- `Undo and redo restores states accurately`: PASSED
- `Batch drag stroke applies and undoes in single step`: PASSED
- `Hints never contradict solution and fix mistakes`: PASSED
- `Completing puzzle transitions game status to completed`: PASSED
- `Strict mistake policy counts mistakes and corrects error`: PASSED
- `Serializing and restoring board state works deterministically`: PASSED

### 4. Touch Coordinate Mapping & Zoom Transformation (`test/interaction/touch_mapping_test.dart`)
- `Coordinates within clue areas return null`: PASSED
- `Coordinates inside grid map to exact cell (0, 0)`: PASSED
- `Coordinates map accurately to interior cells`: PASSED
- `Coordinates outside grid boundary return null`: PASSED
- `Zoom scale factor transforms coordinates linearly`: PASSED

### 5. Daily Puzzle Consistency (`test/daily/daily_consistency_test.dart`)
- `Same date always yields identical daily puzzle (deterministic idempotency)`: PASSED
- `Consecutive dates select valid puzzles from pack`: PASSED

### 6. Persistence & SQLite Drift Database (`test/storage/database_test.dart`)
- `Saves and reads puzzle progress`: PASSED
- `Daily puzzle tracking works`: PASSED
- `Player economy defaults and updates`: PASSED
- `Entitlements store and check ads_free`: PASSED

### 7. Monetization & Entitlements (`test/monetization/entitlement_test.dart`)
- `Initial entitlement state defaults to not ads-free`: PASSED
- `Purchasing ads-free transitions entitlement and persists to DB`: PASSED
- `New app session restores cached verified entitlement offline`: PASSED
- `Revocation turns entitlement off and updates DB`: PASSED

### 8. Widget UI Smoke & Control Bar (`test/widget_test.dart`)
- `App mounts and displays Home Screen with categories`: PASSED
- `ControlBarWidget handles tool switching, undo, redo, and hints`: PASSED

---

## Content Tool CLI Verification

Command:
```bash
dart run bin/content_tool.dart validate assets/puzzles/<pack>.json
```

Results:
- `animals.json` (4 puzzles: Cat 5x5, Duck 5x5, Penguin 10x10, Elephant 15x15): **4 Passed, 0 Failed**
- `nature.json` (4 puzzles: Pine Tree 5x5, Mushroom 5x5, Tulip 10x10, Mountain 15x15): **4 Passed, 0 Failed**
- `food.json` (3 puzzles: Apple 5x5, Mug 10x10, Ice Cream 15x15): **3 Passed, 0 Failed**
- `objects.json` (3 puzzles: Key 5x5, Sword 10x10, Castle 15x15): **3 Passed, 0 Failed**
- `symbols.json` (4 puzzles: Heart 5x5, Star 5x5, Music Note 10x10, Moon 15x15): **4 Passed, 0 Failed**
- `tutorial.json` (2 practice puzzles): **2 Passed, 0 Failed**

**Total Curated Puzzles**: 20 Puzzles (5x5, 10x10, 15x15) validated with unique solutions and balanced clues.
