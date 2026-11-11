# Nonogram — Kararlar ve yetkilendirme

Belge teslim tarihi: **19 Ekim 2026**; M0 yürütme onayı: **18 Ekim 2026** (Europe/Istanbul). Bilinmeyen geçmiş kullanıcı kararları bu kayıttan türetilmez. Güncel uygulama durumu [project_status](project_status.md), iş önerileri [roadmap](roadmap.md) içindedir.

## Kaynak kayıtları

| Kimlik | Kaynak ve erişim sınırı |
| --- | --- |
| U1 | Kullanıcının bu Engineering sohbetine ilettiği “M0 — Recovery Baseline & Operating Records” görev metni. İlk aşamada açık onay yoksa salt okunur inceleme ve taslak istiyordu. |
| R0 | 18 Ekim 2026 önceki Engineering raporu: `master`, `0b775ba2afda5a8307b0291f484bac3e130e9f05`, temiz başlangıç/bitiş, tek checkout, sıfır değişiklik, uygulanmamış taslak ve çalıştırılmamış test/analyze/build. Tarihsel rapordur; güncelliği ayrıca kontrol edildi. |
| U2 | Kullanıcının bu sohbete ilettiği “NONOGRAM — M0 BELGE KURULUMU”, bölümler 1 ve 7. 18 Ekim 2026'da ChatGPT HQ'da verilen “onaylıyorum” kararını bildirir ve doğrudan “M0 yürütme onayı verilmiştir. Aynı kapsam için tekrar onay isteme.” der. Tamamlanmış teslimin henüz kabul edilmediğini ayrıca belirtir. Kaynak bu kullanıcı iletimidir; özgün HQ sohbetine erişildiği iddia edilmez. |

## Durum sözlüğü

Durumlar ilgili nesneye ve kapsama bağlanır; birbirinin yerine geçmez.

| Durum | Anlamı |
| --- | --- |
| Proposed | Öneri; yürütme veya öncelik onayı varsayılmaz. |
| Implemented | Belirtilen dosya/kod değişikliği uygulanmış; doğruluk, kullanıcı kabulü veya yayın bundan çıkmaz. |
| Verified | Belirtilen yöntem ve kapsam için gerçekten yapılmış kontrol kanıtı var. Belge kontrolü ürün davranışını doğrulamaz. |
| Accepted | İlgili karar/kabul nesnesi için açık kullanıcı onayı kaynaklandırılmış. Yürütme yetkisinin kabulü, tamamlanmış teslimin kabulü değildir. |
| Released | Belirtilen sürüm/kanal için yayın kanıtı var. |

## D-001 — M0 yürütme yetkisi

- **Sahip:** Kullanıcı; ChatGPT HQ üzerinden iletilen karar.
- **Tarih / kaynak:** 18 Ekim 2026, U2 bölüm 1.
- **Karar / gerekçe:** Proje bağlamı, durum, kararlar ve çalışma düzenini kalıcı repository belgelerinde kurmak için M0 yürütülebilir. Aynı kapsam yeniden onaya sunulmaz.
- **Durum:** **Accepted — yalnız M0 yürütme yetkisi.** Teslim kabulü bu kayda dahil değildir.
- **Sınır:** Yalnız yedi belge; ayrıntılı güncel görev sınırı [project_status](project_status.md#m0-yürütme-kapsamı) içindedir. Kod, test, bağımlılık, platform, içerik, altyapı ve mağaza değişiklikleri yetkilendirilmedi.

## D-002 — Tamamlanmış M0 tesliminin kabulü

- **Sahip:** Kullanıcı / HQ.
- **Kaynak:** U2 bölüm 1 ve 9, teslim kabulünün henüz verilmediğini açıkça belirtir.
- **Gerekçe:** Yürütme izni ile bitmiş işin kullanıcı kabulünü ayırmak.
- **Durum:** **Bekliyor; Accepted değil.** Belgelerin Implemented veya belge kontrollerinin Verified olması bu durumu değiştirmez.

## D-003 — M1 kapsamı ve önceliği

- **Sahip:** Kullanıcı/HQ; teknik öneriyi Engineering HQ hazırlar.
- **Kaynak:** U2 bölüm 5, Proposed M1 kaydı ister; B2 ve B5 teknik gerekçedir.
- **Gerekçe:** Gerçek startup ve süreçler arası kalıcılık için kanıt eksikliğini gidermek.
- **Durum:** **Proposed.** [M1 önerisi](roadmap.md#proposed-m1--startup--persistence-verification) yürütme onayı değildir.

## D-004 — Günlük seri ürün kuralı

- **Sahip:** Kullanıcı/HQ.
- **Kaynak:** U1/U2 B3 ve statik kod gözlemi; onaylı ürün kuralı bulunmadı.
- **Gerekçe:** Gün atlama, tarih/saat dilimi ve seri devamı beklentisini açıklığa kavuşturmak.
- **Durum:** **Açık karar.** Ardışık gün zorunluluğu veya sıfırlama davranışı seçilmedi.

## D-005 — Üretim monetizasyonu ve tarihsel sürüm fikirleri

- **Sahip:** Kullanıcı/HQ; teknik seçenekler Engineering HQ tarafından sunulabilir.
- **Kaynak:** B1/B6; mevcut monetizasyon belgesi ve roadmap fikirleri.
- **Gerekçe:** Kod veya belge varlığını üretim entegrasyonu, ürün kararı veya sürüm taahhüdü saymamak.
- **Durum:** **Onay durumu bilinmiyor.** Backend/reklam sağlayıcısı, yayın planı veya v1.1/v1.2/v2.0 taahhüdü bu M0 ile kararlaştırılmadı.

## D-006 — Studio Core SDK Offline-First Entegrasyonu (v1 Release)

- **Sahip:** Kullanıcı / Core Hardening Talimatı (28 Ekim 2026).
- **Kaynak:** Kullanıcı promptu: `studio_core_sdk` offline-first entegrasyonu, zero network packets, persistent install_id, crash-safe vault, single-source wallet (`gold`, `hints`), leaf timer optimizasyonu, offline UI gizleme ve yerel veri sıfırlama.
- **Karar / gerekçe:** Sahte monetizasyon ve çift cüzdan ayrışmasını engellemek, oyun durumunu HMAC-SHA256 korumalı disk kasasına taşımak.
- **Durum:** **Implemented & Verified.** `flutter analyze` 0 hata/uyarı, `flutter test` 39/39 test geçti. Working tree manuel inceleme için bekletilmektedir (commit/push yapılmamıştır).

## D-007 — Content Studio uzaktan içerik entegrasyonu (opt-in)

- **Sahip:** Kullanıcı / kurucu; PLATFORM-V1-009 talimatı (11 Kasım 2026).
- **Kaynak:** Kullanıcı onayı: "The founder authorizes the limited Nonogram game-repository changes required for the first real Content Studio integration."
- **Karar:** Oyun, yayınlanmış `nonogram` Content Studio paketlerini `StudioContentPacks` (studio-core-sdk `50f6d2e`) ile yükleyebilir. Özellik **varsayılan olarak kapalıdır** ve yalnız `NONOGRAM_REMOTE_CONTENT=true` + geçerli `NONOGRAM_CONTENT_BACKEND_URL` build define'ları ile açılır (ilk sürümde gereken `NONOGRAM_CONTENT_HMAC_KEY`, [D-008](#d-008--üretim-misafir-kimliği-güvenliği-ve-kayıtlı-tahta-uyumu) ile kaldırıldı). Kapalıyken ağ isteği, misafir oturumu, arka plan işi veya yeni dosya yoktur; SDK `enableCloudSync: false` olarak kalır.
- **Kurallar (Engineering önerisi, bu entegrasyonda uygulandı):** bundled puzzle kimliği her zaman kazanır; paketler arası çakışmada ilk kayıtlı paket kazanır; uzak puzzle'lar günlük puzzle seçimine girmez; katalogdan kalkan paket katalogdan ve önbellekten kaldırılır, oyuncu ilerlemesi hiçbir durumda silinmez.
- **Durum:** **Implemented & Verified (geliştirme).** Kanıt [test_report](test_report.md#content-studio-uzaktan-içerik-entegrasyonu--11-kasım-2026). Üretim backend'i, üretim misafir kimlik bilgisi dağıtımı ve flag açık sürüm kararı verilmedi; bunlar ayrı onay gerektirir.

## D-008 — Üretim misafir kimliği güvenliği ve kayıtlı tahta uyumu

- **Sahip:** Kullanıcı / kurucu; PLATFORM-V1-010 talimatı (11 Kasım 2026).
- **Kaynak (kullanıcı kararı):** "Never ship the backend's shared HMAC secret inside a mobile application." "Do not enable remote content in any production build." Uzak yayında çözümü değişen puzzle'ın yarım tahtası geri yüklenmemeli; tamamlanma, yıldız ve cüzdan korunmalı.
- **Doğrulanan durum (Engineering):** studio-core-backend `POST /v1/auth/guest` ve `GET /v1/content/packs[/:id]` HMAC doğrulaması yapmaz (yalnız durum değiştiren rotalar `verifyHmacAntiCheat` kullanır: sync, satın alma, reklam ödülü, liderlik tablosu, inbox, PvP, hesap bağlama). Global rate limit misafir girişini de kapsar. Bu yüzden içerik okuyucusu sır gerektirmez.
- **Karar / uygulama:** Oyun backend sırrını almaz; `NONOGRAM_CONTENT_HMAC_KEY` kaldırıldı, okuyucu sır olmayan sabit `nonogram-content-reader-public` ile imzalar. Release build'de uzak içerik koşulsuz kapalıdır (`kReleaseMode`). Kayıtlı tahta, puzzle içerik parmak iziyle (checksum) bağlanır; farklı içerikte geri yüklenmez, hiçbir kayıt silinmez. Önemli ölçüde farklı resim yeni `content_id` almalıdır.
- **Üretim için önerilen en küçük yol (Proposed, onay bekliyor):** (1) Mevcut misafir oturumu + içerik okuma, sırsız; backend tarafında bu rotaların HMAC'siz kalması sözleşme olarak belgelenir, misafir girişine ayrı rate limit ve izleme eklenir. (2) Uzun vadede yayınlanan payload'ların oturumsuz, CDN üzerinden herkese açık sunulması (yeni backend yeteneği; bu artımda yok). Hangi yolun seçileceği ve release'te özelliğin açılması kullanıcı kararıdır.
- **Durum:** Sır kaldırma, release kilidi ve tahta uyumu **Implemented & Verified (geliştirme)**; üretim yolu **Proposed**.

## D-009 — Yarım puzzle'ın otomatik kaydı (N-1)

- **Sahip:** Kullanıcı / kurucu; NONOGRAM-FIX-N1 talimatı (11 Kasım 2026), "APPROVED. Fix N-1 now within Nonogram HQ ownership."
- **Kaynak (bulgu):** Android kabul taraması (studio-core-backend `docs/platform/PLATFORM_V1.md` madde 18): yarım tahta yalnız puzzle ekranı kapanırken (`dispose`) kaydediliyordu; ekran açıkken uygulama öldürülünce deneme kayboluyordu. Platforma özgü değil.
- **Karar / uygulama (Engineering, kullanıcı onaylı kapsam):** Her tahta değişikliğinden (hücre, temizleme, sürükleme, geri al/yinele, ipucu, yeniden başlatma) sonra mevcut kasa + SQLite kaydı yazılır (`PuzzleAutosave`). Yazmalar sıralı ve tek tektir; biri sürerken yalnız en yeni durum bekler. Başarısız yazma bir sonraki değişiklikte veya flush'ta yeniden denenir, döngüye girmez. Uygulama ön plandan çıkınca (`AppLifecycleListener`) güncel süreyle flush edilir. Tamamlanınca bekleyen yarım durum düşürülür ve süren yazma beklenir; tamamlanma kaydından sonra yarım kayıt yazılamaz. Daha önce tamamlanmış puzzle'ın tekrar oynanışı yarım kayıt yazmaz, böylece tamamlanma/yıldız korunur (önceki sürüm ekrandan çıkarken bunu ezebiliyordu). İçerik parmak izi kuralı (D-008) aynen geçerlidir.
- **Durum:** **Implemented & Verified (geliştirme)**.

