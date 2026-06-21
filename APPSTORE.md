# KiSA — App Store'ga chiqarish qo'llanmasi

Bu qo'llanma KiSA'ni **TestFlight'dan App Store'ga** (ommaviy) chiqarishni
tushuntiradi. Kod tomonidagi hamma narsa tayyor (build, imzolash, akkaunt
o'chirish, maxfiylik sahifalari). Quyidagi qadamlar — akkauntlar bilan bog'liq,
ularni faqat siz bajara olasiz.

> TestFlight quvuri uchun: `DEPLOYMENT.md` ga qarang.

---

## 0. Muhim URL'lar

| Maqsad | URL |
|--------|-----|
| Privacy Policy URL | `https://jaloladdin0911.github.io/KiSA/privacy.html` |
| Support URL | `https://jaloladdin0911.github.io/KiSA/` |

Bular `docs/` papkadagi sahifalar. GitHub Pages'ni yoqish:
**Repo → Settings → Pages → Source: `main` / `/docs` → Save** (1-2 daqiqada jonlanadi).

---

## 1. Build'ni tayyorlash

1. Kodni `main` ga push qiling. Codemagic avtomatik build qilib App Store
   Connect'ga yuklaydi (~10 daqiqa).
2. Build **App Store Connect → TestFlight** da paydo bo'lishini kuting
   ("Processing" tugagach tayyor).

> Akkaunt o'chirish funksiyasi (Apple talabi 5.1.1(v)) ilovada bor:
> `Sozlamalar → Akkauntni o'chirish`. Review uchun bu MAJBURIY — yangi buildda
> mavjudligiga ishonch hosil qiling.

---

## 2. Screenshotlar (majburiy)

iPhone'dagi KiSA'dan (TestFlight) ekran rasmlarini oling.

| O'lcham | Piksel | Holat |
|---------|--------|-------|
| 6.7" / 6.9" iPhone | 1290 × 2796 | **Majburiy** (kamida shu) |
| 6.5" iPhone | 1242 × 2688 | Tavsiya etiladi |

- Kamida **3** ta, yaxshisi **5** ta: Dashboard (hamyonlar), Statistika,
  Maqsadlar, Sozlamalar, qo'shish oynasi.
- iPhone'da: tugma + ovoz balandligi tugmasi bilan screenshot olinadi.

---

## 3. App Store versiyasini yaratish

1. **App Store Connect → My Apps → KiSA**
2. Chapda **(+) Version or Platform** → versiya raqami (masalan `1.0`)
3. To'ldiriladigan maydonlar:
   - **Promotional Text** (ixtiyoriy, keyin yangilanadi)
   - **Description** — ilova nima qilishini yozing (pastda namuna)
   - **Keywords** — vergul bilan: `pul,moliya,budjet,xarajat,hamyon,dollar,so'm`
   - **Support URL** = `https://jaloladdin0911.github.io/KiSA/`
   - **Marketing URL** (ixtiyoriy)
   - **App Information → Privacy Policy URL** = `.../privacy.html`
   - **Category**: Primary = **Finance**
   - **Age Rating** anketasini to'ldiring (KiSA uchun hammasi "None" → 4+)

### Tavsif namunasi (Description)
```
KiSA — kirim va xarajatlaringizni oson boshqaradigan shaxsiy moliyaviy ilova.

• Naqd va kartadagi so'm hamda dollar — 4 ta hamyon bir joyda
• Kirim, xarajat, o'tkazma va valyuta ayirboshlash
• Statistika, grafiklar va moliyaviy maqsadlar
• Markaziy bank dollar kursi
• Internetsiz ham ishlaydi, qurilmalar orasida sinxron
• Sodda, tez va chiroyli dizayn

KiSA bilan pulingiz qayerga ketayotganini har doim bilib turing.
```

---

## 4. App Privacy anketasi (← diqqat bilan)

**App Store Connect → KiSA → App Privacy → Edit/Get Started.**

KiSA Firebase orqali email va kiritilgan moliyaviy ma'lumotlarni saqlaydi, lekin
reklama/kuzatuv (tracking) yo'q. Javoblar:

| Ma'lumot turi | Yig'iladimi? | Maqsad | Foydalanuvchiga bog'langanmi? | Tracking? |
|---------------|--------------|--------|-------------------------------|-----------|
| **Email Address** | Ha (faqat ro'yxatdan o'tsa) | App Functionality | Ha | **Yo'q** |
| **Other Financial Info** (kiritilgan summalar) | Ha | App Functionality | Ha | **Yo'q** |
| Name (ko'rsatish ismi) | Ha (ixtiyoriy) | App Functionality | Ha | Yo'q |

- "Do you or your third-party partners use data for **tracking**?" → **No**
- Reklama, joylashuv, kontakt, sog'liq, brauzer tarixi, analitika — **yig'ilmaydi**.

> Agar ilovani **akkauntsiz** (offline) ishlatsa, hech qanday ma'lumot serverga
> yuborilmaydi — lekin anketa "yig'ilishi mumkin bo'lgan" ma'lumotni so'raydi,
> shuning uchun yuqoridagicha belgilang.

---

## 5. Build'ni biriktirish va yuborish

1. Versiya sahifasida **Build** bo'limi → **(+)** → push'dan kelgan buildni
   tanlang.
2. **Export Compliance**: build avtomatik `ITSAppUsesNonExemptEncryption=false`
   bilan keladi, shuning uchun qo'shimcha savol chiqmasligi kerak.
3. **"What's New in This Version"** yozing (birinchi versiyada: "Ilk versiya").
4. Yuqori o'ngda **Add for Review** → **Submit for Review**.

---

## 6. Review va Release

- Apple odatda **24–48 soat**da ko'rib chiqadi. Email orqali xabar keladi.
- **Rejected** bo'lsa: sababini o'qing (Resolution Center) → tuzating → qayta
  Submit. Eng ko'p sabablar: maxfiylik URL ishlamasligi, akkaunt o'chirish yo'qligi,
  noto'g'ri screenshot.
- **Approved** bo'lsa: **Release** (avtomatik yoki "Release This Version"
  tugmasi) → bir necha soatda App Store'da paydo bo'ladi.

---

## 7. Keyingi yangilanishlar (har safar)

1. Kodni o'zgartiring.
2. `pubspec.yaml` da versiyani oshiring (masalan `2.0.0+1` → `2.1.0+1`).
   Build raqami Codemagic'da avtomatik oshadi.
3. `git push` → Codemagic build → App Store Connect.
4. App Store Connect'da **(+) Version** → yangi versiya raqami → build tanlang →
   "What's New" → **Submit for Review**.
5. Tasdiqlangach Release. Foydalanuvchilar App Store'da **Update** oladi.

> Har ommaviy yangilanish review'dan o'tadi (TestFlight internal'dan farqli).
> Kichik tuzatishlar uchun ham xuddi shu jarayon.

---

## Tez-tez uchraydigan rad sabablari (oldini olish)

- **Privacy Policy URL ishlamasa** → GitHub Pages yoqilganini va havola
  ochilishini tekshiring.
- **Akkaunt o'chirish yo'q** → bor (`Sozlamalar → Akkauntni o'chirish`).
- **Login majburiy bo'lsa** → KiSA'da "Kirishsiz davom etish (offline)" bor, shuning
  uchun muammo yo'q.
- **Demo akkaunt so'rasa** → Review eslatmasiga test email/parol yozib qo'ying yoki
  offline rejimni ko'rsating ("Continue without login").
