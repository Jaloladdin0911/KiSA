# KiSA v2.0 — SQLite + Firebase

## 📁 Loyiha strukturasi

```
lib/
├── main.dart                      # App + routing + Firebase init
├── models/
│   ├── transaction_model.dart     # SQLite + Firebase modeli
│   └── goal_model.dart
├── services/
│   ├── local_database.dart        # SQLite (sqflite)
│   ├── sync_service.dart          # Firebase sync logikasi
│   ├── auth_service.dart          # Firebase Auth
│   └── app_provider.dart          # Global state
├── screens/
│   ├── auth_screen.dart           # Login / Register
│   ├── dashboard_screen.dart
│   ├── statistics_screen.dart
│   ├── goals_screen.dart
│   └── settings_screen.dart
└── widgets/
    └── transaction_card.dart
```

---

## 🔥 Firebase sozlash (MUHIM)

### 1. Firebase Console
1. https://console.firebase.google.com ga kiring
2. "Add project" → loyiha nomi: `kisa-app`
3. Google Analytics → "Enable" (ixtiyoriy)

### 2. Android uchun
1. Firebase Console → "Add app" → Android icon
2. Package name: `com.example.kisa`
3. `google-services.json` ni yuklab oling
4. Faylni `android/app/` papkasiga qo'ying

### 3. FlutterFire CLI (avtomatik sozlash)
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=kisa-app
```
Bu buyruq `lib/firebase_options.dart` faylini avtomatik yaratadi.

### 4. main.dart ga qo'shish
```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 5. Firebase Console → Authentication
- "Get started" → Email/Password → Enable

### 6. Firebase Console → Firestore
- "Create database" → "Start in test mode"

---

## 🚀 Ishga tushirish

```bash
flutter pub get
flutter run
```

---

## 🏗️ Arxitektura

```
Telefon                          Firebase (bulut)
┌─────────────┐                 ┌─────────────────┐
│  Flutter UI │                 │  Firestore DB   │
│     ↕       │                 │                 │
│  Provider   │ ←── sync ──→   │  Authentication │
│     ↕       │  (internet      │                 │
│   SQLite    │   bo'lganda)    └─────────────────┘
└─────────────┘

✅ Internet bo'lmasa: SQLite dan ishlaydi
✅ Internet bo'lsa: Firebase ga avtomatik sync
✅ Boshqa qurilma: Firebase orqali ma'lumotlar saqlanadi
```

---

## 📦 Paketlar

| Paket | Vazifasi |
|-------|---------|
| `sqflite` | Lokal SQLite bazasi |
| `firebase_core` | Firebase asosi |
| `firebase_auth` | Login / Register |
| `cloud_firestore` | Bulut bazasi |
| `connectivity_plus` | Internet holati |
| `provider` | State management |
| `fl_chart` | Grafiklar |
| `shared_preferences` | Sozlamalar |
