# Nonogram — Güncel durum

Güncel kayıt / teslim tarihi: **19 Ekim 2026**; başlangıç incelemesi ve yürütme onayı: **18 Ekim 2026** (Europe/Istanbul). Kanonik bağlam [project_context](project_context.md), onaylar ve durum tanımları [decisions](decisions.md) içindedir.

## M0 durumu

**M0 — Recovery Baseline & Operating Records: Implemented.** Yedi belge kurulmuş veya uzlaştırılmıştır. Yürütme yetkisi [D-001](decisions.md#d-001--m0-yürütme-yetkisi) ile verilmiştir; aynı yetki için yeniden onay gerekmiyor. Tamamlanmış teslimin kullanıcı kabulü [D-002](decisions.md#d-002--tamamlanmış-m0-tesliminin-kabulü) kapsamında bekliyor. Ürün kabulü veya release kanıtı yoktur.

**Verified yalnız gerçekleştirilen belge kontrollerinin kapsamındadır**; yöntem, sonuç ve sınırlar [test_report](test_report.md#m0-belge-kontrolleri) içinde tutulur. Uygulama/test çalıştırma doğrulaması yapılmadı.

## M0 yürütme kapsamı

U2 ile izin verilen dosyalar: `docs/project_context.md`, `docs/project_status.md`, `docs/decisions.md`, `AGENTS.md`, `README.md`, `docs/roadmap.md`, `docs/test_report.md`.

Bu M0 sırasında uygulama/test kodu, dependency/lockfile, platform config, içerik varlıkları, altyapı ve mağaza işlemleri kapsam dışıdır. Test, analyze, build, uygulama, generator, kurulum veya migration çalıştırılmaz. Branch/worktree, commit veya push yapılmaz. Bu sınırlar M0'a aittir; gelecekte ayrıca yetkilendirilen işleri genel olarak engellemez.

## Baseline karşılaştırması

| Alan | R0 tarihsel kayıt | M0 güncel gözlemi |
| --- | --- | --- |
| Repository | `C:\Users\burak\Documents\Projects\nonogram` | Aynı gerçek Git kökü |
| Branch / HEAD | `master` / `0b775ba2afda5a8307b0291f484bac3e130e9f05` | Değişmedi |
| Worktree / geçmiş / etiket | Tek checkout; görünen tek commit; release etiketi görülmedi | Aynı; Git etiketi yok |
| Başlangıç çalışma ağacı | Temiz | Temiz; kullanıcı değişikliği görülmedi |
| İş bitişi | Sıfır değişiklik, taslak uygulanmamış | Dört yeni ve üç düzenlenmiş belge; staged değişiklik yok |
| Talimat / onay | AGENTS yok; M0 taslağı onay bekliyordu | Kalıcı AGENTS eklendi; U2 yürütme onayı geçerli; teslim kabulü bekliyor |
| Kod gözlemleri / sayımlar | B1–B7; 8 test dosyası / 35 bildirim; 18+2 içerik | Statik kaynaklarla uyumlu; yeni çalışma zamanı sonucu yok |

## Teknik bulgular B1–B7

Tüm kayıtlar **açık**. “Statik gözlem” kaynakta görülen durumu, “olası etki” çıkarımı belirtir. Önerilen doğrulamalar bu M0 içinde çalıştırılmadı ve yürütme yetkisi oluşturmaz.

### B1 — Mock monetizasyon ve sınırlı receipt kontrolü

- **Başlangıç iddiası:** IAP/reklamlar mock; yerel receipt kontrolü üretim doğrulama kanıtı değil.
- **Güncel kaynak / kanıt düzeyi:** [app_providers](../lib/core/providers/app_providers.dart#L35) `isMockMode: true`; [AdManager](../lib/core/monetization/ads/ad_manager.dart#L24) varsayılan `MockAdProvider`; [LocalReceiptValidator](../lib/core/monetization/iap/iap_manager.dart#L29) boş olmayan veri ve ürün kimliğini kontrol ediyor. Statik kod gözlemi; incelenen repository'de gerçek receipt backend'i görülmedi. [Monetizasyon belgesi](monetization.md) tasarım/kurulum kaynağıdır.
- **Olası etki:** Gerçek satın alma, restore, reklam ve üretim doğrulaması hazır kabul edilemez. Haricî backend'in kesinlikle bulunmadığı çıkarılmaz.
- **Önerilen doğrulama:** Ayrı yetkiyle provider seçimi, backend sınırı, mağaza sandbox purchase/restore/revoke ve gerçek reklam sağlayıcısı kanıtlanmalı.

### B2 — Başlangıç nesneleri ve kalıcı durumun yüklenmesi

- **Başlangıç iddiası:** main ile Riverpod ayrı ekonomi nesneleri kuruyor; IAP/reklam initialization bağlantısı belirsiz.
- **Güncel kaynak / kanıt düzeyi:** [main](../lib/main.dart#L26) EconomyManager oluşturup initialize ediyor, ProviderScope overrides listesine aktarmıyor. [Provider](../lib/core/providers/app_providers.dart#L49) ayrı nesne oluşturuyor. `lib` kapsamındaki initialization aramasında IAP/AdManager çağrısı bulunmadı; tanımları [IAP](../lib/core/monetization/iap/iap_manager.dart#L69) ve [AdManager](../lib/core/monetization/ads/ad_manager.dart#L27) içinde mevcut. Statik gözlem.
- **Olası etki:** Ekranlar kayıtlı bakiye/ipucu/günlük ödül/ads-free yerine yüklenmemiş cache değerleri görebilir. Veri kaybı veya kullanıcıda gerçekleşmiş hata kanıtlanmadı.
- **Önerilen doğrulama:** Proposed M1'de gerçek main/ProviderScope hattı, disk DB ve süreç yeniden başlatma senaryoları incelenmeli.

### B3 — Günlük seri kuralı

- **Başlangıç iddiası:** Gün atlama kontrolü yok; beklenen davranış kullanıcı kararı gerektiriyor.
- **Güncel kaynak / kanıt düzeyi:** [EconomyManager](../lib/core/monetization/economy/economy_manager.dart#L38) aynı gün tekrarını kontrol ediyor; `claimDailyReward` içinde `streakDays + 1` var. Dün/gün atlama karşılaştırması görünmüyor. Statik gözlem; ardışıklık iddiası [monetizasyon belgesinde](monetization.md) yer alıyor.
- **Olası etki:** “Seri” davranışı ürün beklentisiyle farklı olabilir; onaylı beklenti olmadan ürün hatası hükmü verilmez.
- **Önerilen doğrulama:** [D-004](decisions.md#d-004--günlük-seri-ürün-kuralı) kararı sonrası aynı gün, ertesi gün, atlanan gün ve tarih sınırı senaryoları.

### B4 — Bundled ve haricî içerik kalite yolları

- **Başlangıç iddiası:** Checksum ve tam validator yolları farklı; yükleme hataları sessiz; 18 normal + 2 öğretici kaydı var.
- **Güncel kaynak / kanıt düzeyi:** [PuzzleRepository](../lib/features/collections/domain/puzzle_repository.dart#L28) beş normal kategoriyi yüklüyor; bundled yolda checksum kontrolü ve boş catch var, tutorial katalog listesinde değil. Haricî import [PuzzleValidator](../lib/engine/validator/puzzle_validator.dart) kullanıyor. JSON okuma/sayımı: animals 4, nature 4, food 3, objects 3, symbols 4, tutorial 2. Statik kod ve kayıt sayımı; kalite kapısı çalıştırılmadı.
- **Olası etki:** Katalog eksik yüklenebilir; checksum tek çözüm kanıtı değildir. Tutorial dosyasının varlığı katalog veya öğretici akışında kullanıldığını kanıtlamaz.
- **Önerilen doğrulama:** Ayrı yetkiyle altı dosya için schema/checksum/çözülebilirlik/tek çözüm çıktısı ve bozuk/eksik paket yükleme davranışı kaydedilmeli.

### B5 — Tarihsel başarılar ve kanıt kapsamı

- **Başlangıç iddiası:** Sekiz dosyada 35 bildirim var; eski başarılar güncel startup/kalıcılık kanıtı değil.
- **Güncel kaynak / kanıt düzeyi:** [Tarihsel rapor](test_report.md) başarı iddia ediyor; ortam, test edilen commit ve ham çıktı bağlantısı görülmedi. `test` altında sekiz Dart dosyasında 35 bildirim sayıldı. [IAP testi](../test/monetization/entitlement_test.dart#L13) mock/bellek içi DB kullanıyor; ikinci manager aynı DB nesnesini kullanıyor. [Widget testi](../test/widget_test.dart#L41) doğrudan NonogramApp kuruyor, main çağırmıyor. [Günlük seçim testi](../test/daily/daily_consistency_test.dart#L33) aynı test çalıştırmasında karşılaştırma yapıyor. Statik inceleme ve tarihsel belge iddiası ayrı kanıt türleridir.
- **Olası etki:** Bildirim sayısı başarılı test sayısı değildir; gerçek startup, süreçler arası disk kalıcılığı veya cihazlar arası günlük seçim kanıtlanmış sayılamaz. [Seçim kodu](../lib/features/collections/domain/puzzle_repository.dart#L95) tarih hash'i ve kayıt sırasını kullanıyor; cihaz uyumsuzluğu çalıştırılarak gösterilmedi.
- **Önerilen doğrulama:** Yetkili sonraki çalışmada ortam/commit/komut/exit code/ham çıktı kaydı; M1'de startup ve gerçek süreç yeniden açılışı. Cihazlar arası günlük seçim ayrıca karşılaştırılmalı. 18/18 ile toplam 20 kapsam ayrımı test_report içinde açıklanır.

### B6 — Yayın hazırlığı

- **Başlangıç iddiası:** Android release debug imzalı; mağaza/iOS/kabul bilinmiyor.
- **Güncel kaynak / kanıt düzeyi:** [Android yapılandırması](../android/app/build.gradle.kts#L32) release için debug signingConfig seçiyor. Takip edilen repository envanterinde CI/CD yapılandırması görülmedi; Git etiket listesi boş. Statik/yerel Git gözlemi; mağazalara erişilmedi.
- **Olası etki:** Üretim imzası, mağaza yayını, iOS doğrulaması ve ürün kabulü varsayılamaz. Haricî CI/CD veya geçmiş yayın olmadığı kanıtlanmış değildir.
- **Önerilen doğrulama:** Ayrı yetkiyle imzalama, platform/mağaza kanıtları ve kullanıcı kabul kayıtları incelenmeli. Debug build başarısı release kanıtı değildir.

### B7 — Belge doğruluğu ve Reduced Motion

- **Başlangıç iddiası:** README `cd prj2`, pubspec varsayılan açıklama; reveal tercihi okumadan başlıyor.
- **Güncel kaynak / kanıt düzeyi:** M0 öncesi [README](../README.md) yanlış klasör adı ve `file:///docs/` bağlantıları içeriyordu; bu belge hataları M0'da düzeltildi. [Pubspec](../pubspec.yaml) açıklaması hâlâ `A new Flutter project.`. [Tercih](../lib/core/storage/preferences/app_preferences.dart#L45) ve ayarlar mevcut; [reveal initState](../lib/features/puzzle_game/presentation/widgets/artwork_reveal_widget.dart#L39) tercihi okumadan `_animController.forward()` çağırıyor. Statik gözlem; davranış çalıştırılmadı.
- **Olası etki:** Başlangıç yönergeleri yanıltıcıydı; varsayılan metadata ve Reduced Motion ile animasyon arasında olası uyumsuzluk sürüyor. B7 bütünü kapanmış değildir.
- **Önerilen doğrulama:** README bağlantıları/klasör düzeltmesi belge kontrolüyle incelenir. Ayrı yetkiyle Reduced Motion açık/kapalı tamamlanma akışı gözlenmeli; pubspec değişikliği ayrıca kapsama alınmalı.

## Riskler, engeller ve sonraki iş

- M0 belge uygulaması için erişim veya kullanıcı değişikliği çakışması engeli görülmedi; yürütme onayı beklenmiyor.
- B1–B7 çalışma zamanı ve ürün hazırlığı bakımından açıktır. En yakın teknik kanıt ihtiyacı B2/B5 startup ve kalıcılık akışıdır; bu Engineering önerisidir, kullanıcı öncelik kararı değildir.
- Teslim kabulü D-002, M1 kapsam/önceliği D-003, günlük seri D-004 ve üretim/yol haritası kararları D-005 içinde izlenir.
- Sonraki iş **[Proposed M1 — Startup & Persistence Verification](roadmap.md#proposed-m1--startup--persistence-verification)**; henüz yürütülmedi.

## Continuity Checkpoint (28 Ekim 2026)

- **Tarih:** 28 Ekim 2026, Europe/Istanbul.
- **Yer / Git:** `C:\Users\burak\Documents\Projects\denogames\nonogram`; branch `master`; HEAD `0b775ba2afda5a8307b0291f484bac3e130e9f05`.
- **Başlangıç / Bitiş:** Çalışma ağacı modified/untracked durumda tutuldu. `git commit` veya `git push` **yapılmadı**; değişiklikler manuel kullanıcı incelemesi için çalışma kopyasında bırakıldı.
- **Uygulanan:**
  - `studio_core_sdk` offline-first entegrasyonu (`gameId: 'nonogram'`, `enableCloudSync: false`, `storageDirectoryPath: appSupportDir.path`).
  - Crash-safe `GameStateVault` (`nonogram_game_state` EncryptedStorageBox) kalıcı kasa servisi.
  - `EconomyManager` tek kaynaklı cüzdana (`StudioSdk.instance.wallet`) bağlandı (`StudioCurrencyIds.gold` ve `StudioCurrencyIds.hints`).
  - `puzzle_screen.dart` içinde kök seviyedeki saniyelik `setState` timer yeniden çizim döngüsü kaldırıldı, leaf widget seviyesine (`ValueNotifier<int> _timerNotifier`) izole edildi.
  - `settings_screen.dart` içerisine yerel verileri sıfırlama (`StudioSdk.instance.resetLocalGameData(preserveInstallId: true)`, `GameStateVault.clearAll()`, default starter wallet) aksiyonu eklendi.
  - Sahte reklam ödül dağıtımı (`MockAdProvider`) kapatıldı, gerçek mağaza IAP kartları ve bağlanmamış VPS LiveOps özellikleri (turnuva paneli, hediye kutusu) offline v1 için gizlendi.
  - `android/app/src/main/AndroidManifest.xml` içerisine `android.permission.INTERNET` eklendi.
- **Doğrulama:**
  - `flutter analyze`: 0 error, 0 warning (temiz).
  - `flutter test ..\studio-core-sdk`: 26/26 geçti.
  - `flutter test`: 39/39 geçti (ağ tuzağı ile sıfır paket testi, UUIDv4 installId kalıcılığı, single-source wallet ve vault sıfırlama dahil).

## Continuity Checkpoint (19 Ekim 2026)

- **Tarih:** 19 Ekim 2026, Europe/Istanbul; başlangıç incelemesi ve yürütme onayı 18 Ekim 2026.
- **Yer / Git:** `C:\Users\burak\Documents\Projects\nonogram`; `master`; HEAD `0b775ba2afda5a8307b0291f484bac3e130e9f05`; tek checkout ve değişmeyen commit.
- **Başlangıç / bitiş:** Başlangıç temiz. Bitişte yalnız izinli yedi belge: dört yeni untracked, üç tracked modified; staged diff yok. Commit/push yapılmadı.
- **Durum:** M0 Implemented; belge kontrol kanıtı test_report'ta; tamamlanmış teslim kabulü bekliyor; ürün/release doğrulanmadı.
- **Yapılmayanlar:** Test/analyze/build, uygulama, generator, kurulum, migration; SDK sürümü ve mağaza/iOS doğrulaması. Branch/worktree oluşturulmadı.
- **Devam:** Kullanıcı/HQ teslimi değerlendirir; M1 için ayrıca kapsam ve yürütme yetkisi belirlenir. Yeni oturum Git ve talimatları yeniden kontrol ederek B2/B5 üzerinden ilerler. HQ raporu kullanıcı aracılığıyla taşınır.
