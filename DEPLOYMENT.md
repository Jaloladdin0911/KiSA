# KiSA — iPhone'ga o'rnatish (GitHub → Codemagic → TestFlight)

Bu qo'llanma KiSA ilovasini Mac'siz, Codemagic bulutli serverlari orqali
build qilib, TestFlight orqali iPhone'ingizga o'rnatishni tushuntiradi.

Kod tomonidagi hamma narsa tayyor (`codemagic.yaml`, bundle ID, ikonkalar).
Quyidagi qadamlar — akkauntlar bilan bog'liq, ularni faqat siz bajara olasiz.

---

## 0. Nima kerak (oldindan)

| Talab | Izoh |
|-------|------|
| **Apple Developer Program** | $99/yil. TestFlight uchun MAJBURIY. https://developer.apple.com/programs/ |
| GitHub akkaunti | Bepul |
| Codemagic akkaunti | Bepul reja oyiga 500 daqiqa beradi |
| iPhone'da TestFlight ilovasi | App Store'dan bepul |

> ⚠️ Apple Developer Program a'zoligisiz TestFlight ishlamaydi — bu Apple talabi, uni aylanib o'tib bo'lmaydi.

---

## 1. Loyihani GitHub'ga yuklash

Git repo allaqachon tayyor va commit qilingan. Endi GitHub'ga jo'natish kerak.

### Variant A — GitHub Desktop (eng oson, sizda o'rnatilgan)
1. GitHub Desktop'ni oching → **File → Add Local Repository**
2. `C:\Users\jaloladdin.yoldashov\Desktop\kisa` papkasini tanlang
3. **Publish repository** tugmasini bosing → nom: `kisa` → **Private** belgilang → Publish

### Variant B — Buyruq qatori
GitHub'da bo'sh repo yarating (`kisa`), so'ng:
```bash
git remote add origin https://github.com/<FOYDALANUVCHI>/kisa.git
git push -u origin main
```

---

## 2. App Store Connect'da ilova yaratish

1. https://appstoreconnect.apple.com → **My Apps → +  → New App**
2. To'ldiring:
   - Platforms: **iOS**
   - Name: **KiSA**
   - Bundle ID: **com.kisa.finance** (avval https://developer.apple.com/account → Identifiers da ro'yxatdan o'tkazing)
   - SKU: `kisa` (ixtiyoriy noyob matn)
3. Yaratgach, **App Information** sahifasida **Apple ID** raqamini ko'chiring (masalan `6740000000`).
4. `codemagic.yaml` ichidagi `APP_STORE_APPLE_ID: 0000000000` ni shu raqamga almashtiring, commit qilib push qiling.

---

## 3. App Store Connect API key yaratish

Codemagic shu kalit orqali avtomatik imzolaydi va TestFlight'ga yuklaydi.

1. App Store Connect → **Users and Access → Integrations → App Store Connect API**
2. **Generate API Key** → Access: **App Manager** → nom bering
3. Quyidagilarni saqlang:
   - **Issuer ID** (sahifa tepasida)
   - **Key ID**
   - **.p8 fayl** (faqat bir marta yuklab olinadi!)

---

## 4. Codemagic'ni sozlash

1. https://codemagic.io → GitHub bilan kiring → `kisa` repozitoriysini ulang.
2. **Teams → Integrations → App Store Connect → Manage keys → Add key**:
   - Name: **KisaAscApiKey**  ← (`codemagic.yaml` dagi nom bilan AYNAN bir xil bo'lsin)
   - Issuer ID, Key ID, .p8 faylni kiriting.
3. Codemagic repo'dagi `codemagic.yaml` ni avtomatik topadi.
4. **Start new build** → workflow: **KiSA iOS — TestFlight** → Start.

Codemagic o'zi: kodni klonlaydi → `flutter build ipa` → imzolaydi → TestFlight'ga yuklaydi.
Birinchi build ~10–15 daqiqa.

---

## 5. iPhone'ga o'rnatish (TestFlight)

1. Build muvaffaqiyatli tugagach, App Store Connect → **TestFlight** bo'limiga o'tadi.
2. **Internal Testing → +** → o'zingizni (Apple ID email) tester sifatida qo'shing.
3. iPhone'da **TestFlight** ilovasini App Store'dan o'rnating.
4. Email'dagi taklifni qabul qiling yoki TestFlight ilovasida KiSA paydo bo'ladi → **Install**.

Tayyor! Endi har push'da yangi build avtomatik TestFlight'ga chiqadi.

---

## Yangilanish berish (har safargi jarayon)

Birinchi sozlash tugagach, yangilanish berish juda oddiy:

1. Kodga o'zgartirish kiriting.
2. Commit qilib `main` branchга push qiling (GitHub Desktop yoki `git push`).
3. Codemagic **avtomatik** build qiladi (push trigger yoqilgan) va TestFlight'ga yuklaydi.
   - Build raqami avtomatik +1 oshadi.
   - Export compliance avtomatik (Info.plist'da sozlangan).
4. ~10–15 daqiqada iPhone'dagi **TestFlight** ilovasida yangi build paydo bo'ladi → **Update**.

**Versiya raqamini o'zgartirish** (masalan 2.0.0 → 2.1.0): `pubspec.yaml` dagi
`version: 2.0.0+1` ni tahrirlang (masalan `2.1.0+1`). Build raqami baribir avtomatik oshadi.

> Codemagic bepul rejasi oyiga ~500 daqiqa beradi; har iOS build ~6–9 daqiqa.
> Agar har push'da build qilishni xohlamasangiz, `codemagic.yaml` dagi `triggering`
> blokini o'chiring va qo'lda "Start new build" bosing.

## Eslatmalar

- **Bundle ID** hozir `com.kisa.finance`. Agar boshqasini xohlasangiz, aytishingiz bilan
  iOS loyihasi va `codemagic.yaml` da almashtiraman (App Store Connect'da ham shu bo'lishi shart).
- **Build raqami** TestFlight'dan avtomatik +1 oshiriladi (`codemagic.yaml` da sozlangan).
- **android/app/google-services.json** repozitoriyga kiritilgan — bu Firebase mijoz konfiguratsiyasi,
  maxfiy emas, lekin xohlasangiz repo'ni Private qiling.
- macOS/Windows/web build uchun ham alohida workflow qo'shib bera olaman.
