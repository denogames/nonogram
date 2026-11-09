# Repository çalışma ilkeleri

## Okuma sırası

1. [Proje bağlamı ve kanonik belge haritası](docs/project_context.md).
2. [Güncel durum, bulgular ve Continuity Checkpoint](docs/project_status.md).
3. [Kararlar, onay kaynakları ve durum sözlüğü](docs/decisions.md).
4. Göreve göre [mimari](docs/architecture.md), [içerik](docs/content_format.md), [monetizasyon](docs/monetization.md), [roadmap](docs/roadmap.md) ve [doğrulama kayıtları](docs/test_report.md).

## Yetki ve çalışma düzeni

- İşe başlarken gerçek repository kökünü, geçerli yönergeleri, branch/HEAD, worktree ve çalışma ağacı durumunu kontrol et. Kullanıcı değişikliklerini koru; ilgisiz değişiklikleri geri alma.
- Geçerli kullanıcı onayını iletildiği kaynaktan tanı ve yetkili kapsamda ilerle. Aynı yetki için tekrar onay isteme. Önceki sohbetlere otomatik erişim veya aktarım varsayma.
- Göreve özgü dosya, komut ve işlem sınırlarını güncel kullanıcı talimatından ve durum kaydından oku. Bir görevin sınırlarını gelecekte ayrıca yetkilendirilmiş işlere genel yasak olarak taşıma.
- Kullanıcı/HQ ürün yönü, öncelik ve kabulü; Engineering HQ teknik inceleme, uygulama ve kanıt üretimini yönetir. Açık kullanıcı kararı olmadan ürün kuralı, mimari karar veya roadmap taahhüdü oluşturma.
- Kullanıcı kararı, AI önerisi, tarihsel belge iddiası, statik kod gözlemi ve gerçekten çalıştırılmış sonucu ayrı yaz. Kaynak, tarih ve ilgili commit'i belirt; statik bulguyu çalışma zamanında doğrulanmış hata olarak sunma.
- Uygulama yetkisi, uygulanmış değişiklik, kapsamı belirtilmiş doğrulama, teslim kabulü ve yayın ayrı kayıtlardır. [Durum sözlüğünü](docs/decisions.md#durum-sözlüğü) kullan; eksik kanıtı başarı olarak yorumlama.
- Doğrulama yöntemini görevin yetkisine ve değişikliğin kapsamına göre seç. Yapılan kontrolleri, sonuçlarını ve yapılmayan doğrulamaları açıkça bildir.

## Kayıt ve devir

- Her bilginin kanonik belgesini güncelle; diğer belgelerden bağlantı ver. Mevcut kaynakları uzlaştır, tarihsel sonuçları yeni kanıt gibi sunma.
- Devirde repository/branch/HEAD, başlangıç-bitiş Git durumu, değişen dosyalar, kontroller ve sınırları, açık kararlar/engeller ile Continuity Checkpoint'i bildir.
- Başka sohbete mesaj göndermek için kullanıcı yetkisi gerekir. Kullanıcı aracılığıyla aktarılması istenen raporu taşınabilir biçimde hazırla.

## Asset'ler (DenoGames Mühendislik Standartları)

- Kanonik standart: game-asset-toolkit `docs/standards/denogames-asset-standard.md`
  (ADR 0021). Bu repository standarda yalnız referans verir; içeriğini kopyalamaz.
- Bu oyun henüz toolkit asset manifesti (`asset_manifest.yaml`) kullanmıyor.
  Görsel/ses asset'i eklenecekse önce standarttaki akışla benimse
  (`game-assets init`, `manifest add`, `runtime export`, `tool/verify_assets.sh`);
  ikinci bir asset kaydı, JSON listesi veya Dart yol haritası kurma.
- Widget'larda asset yolu sabitleme; kararlı semantik id ile çöz
  (studio_core_sdk `StudioAssetResolver`).
- Eksik asset hata değildir: bildirilen fallback gösterilir. Asset onaylanıp
  yayınlanana kadar prosedürel fallback'leri koru.
- Asset onaylama/reddetme, sağlayıcı etkinleştirme, `--live` veya ücretli üretim
  kendi kararınla yapılmaz; aday, journal ve review kayıtları silinmez.
- Offline doğrula: `enableCloudSync: false` ve ağ yokken oyun açılıp çizilmeli.
