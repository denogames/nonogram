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
