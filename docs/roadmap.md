# Project Roadmap

## M0 — Recovery Baseline & Operating Records

**Implemented — 19 Ekim 2026.** Yedi repository belgesi kurulmuş/uzlaştırılmıştır. 18 Ekim yürütme yetkisi [D-001](decisions.md#d-001--m0-yürütme-yetkisi) ile verilmiştir; tamamlanmış teslimin kabulü [D-002](decisions.md#d-002--tamamlanmış-m0-tesliminin-kabulü) kapsamında bekliyor. Güncel durum ve checkpoint [project_status](project_status.md), yapılan belge kontrolleri [test_report](test_report.md) içindedir. Ürün doğrulaması veya release bu durumdan çıkarılmaz.

## Proposed M1 — Startup & Persistence Verification

**Proposed; yürütme ve öncelik onayı yok.** Kaynak: [B2/B5](project_status.md#teknik-bulgular-b1b7) ve [D-003](decisions.md#d-003--m1-kapsamı-ve-önceliği).

- Önce yetkili doğrulama kapsamı ve ortamı belirle; SDK/cihaz, commit, senaryo, komut, exit code ve ham çıktı konumunu kaydet.
- Gerçek `main`/ProviderScope hattında ekonomi, IAP ve reklam nesnelerinin kurulma/yüklenme sırasını izle; ekranların hangi nesneyi kullandığını göster.
- Diskte kayıtlı bakiye/ipucu, günlük ödül tarihi ve ads-free durumunu süreç kapatılıp yeniden açıldığında, çevrimdışı başlangıç dahil karşılaştır. Aynı bellek içi DB üzerinde ikinci manager oluşturmayı süreç yeniden başlatma kanıtı sayma.
- Beklenen/mevcut sonucu ve gerekirse düzeltme önerisini raporla. Kod/test düzeltmesi için yetki kapsamını ayrıca doğrula; M0 onayını kod değişikliği izni sayma.

Günlük seri ürün kuralı, üretim monetizasyon entegrasyonu, mağaza işlemleri, içerik üretimi ve yeni özellikler bu öneriyle onaylanmaz. B1–B7'nin diğer doğrulama ihtiyaçları durum kaydında korunur.

## Historical Post-MVP Ideas

The v1.1/v1.2/v2.0 ideas below are preserved from the existing roadmap. Their user approval, priority and delivery dates are unknown. They are not active commitments or evidence that MVP acceptance or release occurred.

### Phase 1: Near-Term Enhancements (v1.1)
- **Sound Effects & Audio**: Add audio effects for cell placement, pencil crosses, line completion chimes, and victory music.
- **Color Nonograms**: Support multi-color Picross puzzles where clues have associated color chips and numbers indicate runs of identical colors.
- **Large Boards (20x20 & 25x25)**: Expand the level catalog to include master-tier large canvas art with multi-tile viewport navigation.

### Phase 2: Live Content & Downloadable Level Packs (v1.2)
- **Remote DLC Packs**: Remote content delivery system using compressed asset bundles with signature verification.
- **Seasonal Event Calendars**: Time-limited puzzle journeys (Halloween, Winter Festival, Spring Bloom) with unique reveal badges.
- **Cloud Progress Sync**: Google Play Games and Apple Game Center / iCloud sync for cross-device gameplay continuity.

### Phase 3: Competitive & Social Gameplay (v2.0)
- **Time Attack Mode**: Race against the clock with progressive clue reveals and mistake time penalties.
- **User-Generated Content & Puzzle Creator**: In-game pixel-art canvas allowing players to draw art, verify uniqueness with the built-in solver, and share levels via QR codes.
- **Global Leaderboards**: Best times and speedrun records for daily nonograms.
