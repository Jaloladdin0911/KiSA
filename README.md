# KiSA v2.0 — shaxsiy moliya (to'liq offline)

Barcha ma'lumotlar faqat qurilmada (Hive) saqlanadi — server, hisob yoki
bulut yo'q. Internet faqat USD kursini (cbu.uz) olish uchun ishlatiladi va
kurs keshlanadi, shuning uchun ilova offline'da ham to'liq ishlaydi.

## ✨ Imkoniyatlar

- **Hamyonlar:** naqd/karta × so'm/dollar, o'tkazma va ayirboshlash (CBU kursi
  avtomatik yoki qo'lda), umumiy boylik so'mda.
- **Qoldiqni tuzatish:** boshlang'ich qoldiq yoki haqiqiy summaga moslash —
  balansni o'zgartiradi, kirim/chiqim statistikasiga kirmaydi.
- **Amallar:** kalkulyatorli klaviatura (12 000 + 3 500), izoh, o'z
  kategoriyalaringiz (nom, ikonka, rang), surib o'chirish va "Bekor qilish".
- **Statistika:** chiqim/kirim donut, avvalgi davr bilan solishtirish, kunlik
  o'rtacha, 6 oylik dinamika, kategoriya bo'yicha amallar.
- **Byudjet:** kategoriya limitlari, 80%/100% ogohlantirish, "kuniga sarflash
  mumkin" va oy oxiri prognozi.
- **Maqsadlar va takroriy to'lovlar** (oylik sana 31 → 28/29 → 31 to'g'ri).
- **Xavfsizlik:** PIN (5 xatodan keyin blok), biometrika, ilovalar
  almashtirgichida xiralashtirish, PIN unutilsa telefon raqam bilan tiklash.
- **Ma'lumot:** JSON zaxira/tiklash, CSV eksport — hammasi faqat qurilmada.
- **Dizayn:** "Liquid Glass" — aurora fon, shisha yuzalar, prujinali
  animatsiyalar; yorug'/to'q/tizim mavzusi; uz/ru/en.

## 📁 Loyiha strukturasi

```
lib/
├── main.dart                    # App, routing, fon'dan qaytganda PIN qulfi
├── models/                      # Tranzaksiya, maqsad, takroriy to'lov
├── services/
│   ├── app_provider.dart        # Global holat (Provider) va biznes mantiq
│   ├── local_database.dart      # Hive (tranzaksiyalar, maqsadlar)
│   ├── rate_service.dart        # CBU USD kursi
│   ├── export_service.dart      # CSV eksport
│   └── notification_service.dart# Kunlik lokal eslatma
├── screens/                     # Ekranlar
├── widgets/                     # Umumiy UI komponentlar (kit.dart)
├── theme/app_theme.dart         # Dizayn tokenlari (KColors, k(), radiuslar)
├── l10n/app_strings.dart        # uz / ru / en matnlar
└── utils/                       # Pul formatlash, kategoriyalar
```

Sozlamalar, byudjetlar, takroriy to'lovlar va PIN xeshi
`shared_preferences` da saqlanadi.

**Zaxira nusxa:** Profil → Ma'lumotlar → "Zaxira nusxa yaratish" barcha
ma'lumotni JSON faylga yozadi, "Zaxiradan tiklash" uni boshqa qurilmada
qaytaradi. PIN va telefon raqam zaxiraga ataylab kiritilmaydi.

## 🚀 Ishga tushirish

```bash
flutter pub get
flutter run -d chrome     # brauzerda
flutter run               # ulangan telefon/emulyatorda
flutter test              # unit testlar
```

Brauzerda biometrik qulf va kunlik eslatma ishlamaydi (platforma
cheklovi), qolgan hamma narsa ishlaydi.

## 📦 Asosiy paketlar

| Paket | Vazifasi |
|-------|---------|
| `hive_flutter` | Lokal ma'lumotlar bazasi |
| `provider` | Holat boshqaruvi |
| `shared_preferences` | Sozlamalar |
| `fl_chart`, `percent_indicator` | Grafiklar |
| `local_auth`, `crypto` | Biometrik qulf, PIN xeshi |
| `flutter_local_notifications` | Kunlik eslatma |
| `http` | CBU valyuta kursi |
| `share_plus`, `path_provider` | CSV eksport |

## 🏗️ Release

- **iOS:** Codemagic orqali TestFlight'ga — [codemagic.yaml](codemagic.yaml)
  va [DEPLOYMENT.md](DEPLOYMENT.md).
- **Android:** `android/key.properties` yarating (git'ga qo'shilmaydi):

  ```properties
  storePassword=...
  keyPassword=...
  keyAlias=upload
  storeFile=C:/yo'l/upload-keystore.jks
  ```

  Fayl bo'lmasa release build debug kalit bilan imzolanadi (faqat sinov uchun).
