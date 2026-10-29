# Nonogram — Proje bağlamı

Başlangıç kaynak incelemesi: **18 Ekim 2026**; M0 belge teslimi: **19 Ekim 2026** (Europe/Istanbul). Kod tabanı: `master`, HEAD `0b775ba2afda5a8307b0291f484bac3e130e9f05`. Bu kayıt kaynak incelemesidir; ürün kabulü veya çalışma zamanı doğrulaması değildir.

## Ürün ve mevcut kapsam

Kullanıcının M0 görev tanımı ve [README](../README.md) Nonogram'ı Android/iOS hedefli, çevrimdışı öncelikli Flutter Picross oyunu olarak tanımlar. Repository'de koleksiyon, günlük bulmaca, öğretici, oyun, undo/redo, ipucu, tercihler, istatistik ve yerel ekonomiyle ilgili kod bulunur. Özellik envanteri, bütün akışların çalıştığı veya kullanıcı tarafından kabul edildiği anlamına gelmez.

[Pubspec](../pubspec.yaml) paket sürümünü `1.0.0+1`, Dart constraint'ini `^3.13.4` olarak tanımlar. Flutter, Riverpod, go_router, Drift SQLite, SharedPreferences ve in_app_purchase bağımlılıkları kayıtlıdır. Bunlar kurulu SDK veya çözümlenen bağımlılıkların çalışırlık kanıtı değildir.

## Bileşen ve veri haritası

| Alan | Gözlenen sorumluluk / kaynak |
| --- | --- |
| [lib/engine](../lib/engine) | Oyun oturumu, solver, generator, validator ve modeller |
| [lib/core](../lib/core) | Provider, yönlendirme, tema, depolama, analitik, haptik ve monetizasyon |
| [lib/features](../lib/features) | Özellik ekranları, oyun etkileşimi ve koleksiyon repository'si |
| [Veritabanı](../lib/core/storage/database/app_database.dart) | Drift şema sürümü `1`; ilerleme, günlük kayıtlar, ekonomi ve entitlement tabloları |
| [Tercihler](../lib/core/storage/preferences/app_preferences.dart) | SharedPreferences üzerinden tema, oyun ve erişilebilirlik tercihleri |
| [İçerik](../assets/puzzles) | Beş normal paket ve tutorial; statik JSON sayımı 18 normal + 2 öğretici kaydı |
| [Test kaynakları](../test) | Sekiz Dart dosyasında 35 `test`/`testWidgets` bildirimi; çalıştırılmış sonuç değildir |

Ayrıntılı mevcut tasarım [architecture](architecture.md), [content_format](content_format.md) ve [monetization](monetization.md) belgelerinde korunur. Tasarım iddiaları ile kod arasındaki açık farklar [durum kaydında](project_status.md#teknik-bulgular-b1b7) izlenir.

## Roller ve ortamlar

| Rol / ortam | Sorumluluk ve erişim sınırı |
| --- | --- |
| Kullanıcı / ChatGPT HQ — `00 — HQ \| Project Director` | Ürün yönü, öncelikler ve kabul; görev metni üzerinden bildirilen yönetim rolü |
| Codex / mevcut Nonogram - PMO — `00 — Engineering HQ \| Technical Lead` | Yerel teknik inceleme, yetkili uygulama ve kanıt üretimi |
| Yerel checkout | `C:\Users\burak\Documents\Projects\nonogram`; Windows/PowerShell çalışma ortamı; tek checkout gözlendi |
| Hedef cihazlar / mağazalar | Android ve iOS ürün hedefleri; mevcut platform klasörleri cihaz veya mağaza doğrulaması değildir |

Rol ve onay kaynağı [U2 kullanıcı iletimi](decisions.md#kaynak-kayıtları) olup diğer sohbet doğrudan okunmamıştır. Devir kullanıcı aracılığıyla yapılır.

## Kaynaklar ve bilinmeyenler

- Önceki Recovery raporu [R0](decisions.md#kaynak-kayıtları), aynı tarih/branch/HEAD'de temiz tek checkout ve uygulanmamış taslak bildiriyordu. M0 başlangıcında bu Git durumu yeniden gözlendi.
- Güncel kaynaklar: README, pubspec, mevcut teknik belgeler, ilgili uygulama/test dosyaları ve salt okunur Git incelemesi. Ayrıntılı kaynaklar B1–B7 altında tutulur.
- SDK sürümü, platform araçları, gerçek startup, süreçler arası disk kalıcılığı ve bütün içeriğin kalite kapısı doğrulanmadı.
- Üretim receipt backend'i incelenen repository'de görülmedi. Haricî servisler/mağaza hesapları, mağaza yayını, iOS sonuçları ve geçmiş ürün kabulü bilinmiyor.
- Günlük seri kuralı ve geçmiş roadmap fikirlerinin kullanıcı onayı bilinmiyor. [Karar kayıtları](decisions.md) bu boşlukları ayrı tutar.

## Kanonik belge haritası

| Bilgi türü | Kanonik yer |
| --- | --- |
| Ürün bağlamı, kapsam, roller, ortam ve kaynak haritası | Bu belge |
| Güncel durum, B1–B7, riskler, engeller, Continuity Checkpoint | [project_status](project_status.md) |
| Kullanıcı kararları, onay kaynakları, açık kararlar ve durum sözlüğü | [decisions](decisions.md) |
| Kalıcı çalışma ve devir ilkeleri | [AGENTS](../AGENTS.md) |
| Belge giriş noktası ve çalıştırma örnekleri | [README](../README.md) |
| Önerilen iş sırası ve tarihsel sürüm fikirleri | [roadmap](roadmap.md) |
| Tarihsel test iddiaları, kanıt sınırları ve yapılan belge kontrolleri | [test_report](test_report.md) |
| Mevcut mimari, içerik formatı ve monetizasyon tasarımı | [architecture](architecture.md), [content_format](content_format.md), [monetization](monetization.md) |
