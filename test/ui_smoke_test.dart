import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kisa/main.dart';
import 'package:kisa/screens/onboarding_screen.dart';
import 'package:kisa/models/transaction_model.dart';
import 'package:kisa/services/app_provider.dart';
import 'package:kisa/theme/app_theme.dart';
import 'package:kisa/widgets/glass.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asosiy ekranlarni ochib, render xatolari (overflow, assert) yo'qligini
/// tekshiradi. Animatsiyalar cheksiz (aurora, nafas olish) bo'lgani uchun
/// pumpAndSettle o'rniga aniq vaqt bilan pump qilinadi.
/// Bir nechta kadr aylantiradi — route/oyna animatsiyalari oxiriga yetadi.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late Directory dir;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    kUseGoogleFonts = false; // testda shrift fayli/tarmoq yo'q
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kisa_ui');
    Hive.init(dir.path);
    await Hive.openBox('transactions');
    await Hive.openBox('goals');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  Future<void> run(WidgetTester tester, {required bool dark}) async {
    tester.view.physicalSize = const Size(1170, 2532); // iPhone 13
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    late AppProvider p;
    await tester.runAsync(() async {
      p = AppProvider();
      await p.init();
      await p.setDarkMode(dark);
      for (var i = 0; i < 6; i++) {
        await p.addTransaction(TransactionModel(
          id: 't$i',
          userId: p.userId,
          type: i.isEven ? 'expense' : 'income',
          amount: 125000.0 * (i + 1),
          category: i.isEven ? 'Oziq-ovqat' : 'Ish haqi',
          date: DateTime.now().subtract(Duration(hours: i * 5)),
          note: i == 0 ? 'Juda uzun izoh matni sinov uchun yozildi' : '',
          place: i % 3 == 0 ? 'card' : 'cash',
        ));
      }
    });

    KColors.isDark = dark;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: p,
      child: MaterialApp(
        theme: kTheme(dark),
        builder: (context, child) => Stack(children: [
          const Positioned.fill(child: KAuroraBackground()),
          child!,
        ]),
        home: const MainNavigator(),
      ),
    ));
    await settle(tester);
    expect(find.byType(MainNavigator), findsOneWidget);

    // Har bir tabni ochamiz
    for (final label in [p.s('nav_stats'), p.s('nav_budget'),
        p.s('nav_profile'), p.s('nav_home')]) {
      await tester.tap(find.text(label).last);
      await settle(tester);
    }

    // Statistika: kirim turiga o'tish va donut/trend chizilishi
    await tester.tap(find.text(p.s('nav_stats')).last);
    await settle(tester);
    await tester.tap(find.text(p.s('kirim')).first);
    await settle(tester);
    expect(find.text(p.s('trend_6m')), findsOneWidget);
    await tester.tap(find.text(p.s('nav_home')).last);
    await settle(tester);

    // "+" → amal tanlash oynasi → Chiqim ekrani
    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await settle(tester);
    expect(find.text(p.s('choose_action')), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(BottomSheet), matching: find.text(p.s('chiqim'))));
    await settle(tester);
    // Kalkulyator: 5 + 3 → natija ko'rinadi, saqlanganda 8 yoziladi
    for (final key in ['5', '+', '3']) {
      await tester.tap(find.text(key).last);
      await settle(tester);
    }
    expect(find.text('= 8'), findsOneWidget);

    // Hive diskka yozishi soxta vaqt (fakeAsync) zonasida tugamaydi — shuning
    // uchun ma'lumot yozadigan amallar haqiqiy asinxron zonada bajariladi
    Future<void> real(Future<void> Function() action) async {
      await tester.runAsync(() async {
        await action();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await settle(tester);
    }

    // Saqlash → bosh sahifaga qaytadi, amal qo'shiladi
    final before = p.transactions.length;
    await real(() => tester.tap(find.text(p.s('save')).last));
    expect(p.transactions.length, before + 1);
    expect(p.transactions.first.amount, 8);

    // Barcha amallar → chapga surib o'chirish → "Bekor qilish"
    await tester.tap(find.text(p.s('see_all')));
    await settle(tester);
    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await settle(tester); // surish animatsiyasi → onDismissed
    await real(() async {});
    expect(p.transactions.length, before);
    expect(find.text(p.s('tx_deleted')), findsOneWidget);
    // TextButton bosilishi runAsync ichida yetib bormaydi, soxta zonada esa Hive
    // yozuvi tugamaydi — shuning uchun tugma callback'ini to'g'ridan-to'g'ri
    // haqiqiy zonada chaqiramiz (gesture → onPressed — Flutter'ning o'z mantiqi)
    await real(() async =>
        tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed());
    expect(p.transactions.length, before + 1);

    // Hisoblar ekrani: umumiy boylik, kurs kartasi, hamyonlar
    await tester.tap(find.byIcon(Icons.chevron_left_rounded).first); // ro'yxatdan orqaga
    await settle(tester);
    await tester.tap(find.text(p.s('total_balance')));
    await settle(tester);
    expect(find.text(p.s('net_worth')), findsOneWidget);
    expect(find.text(p.s('cbu_rate')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
    await settle(tester);

    // Profil → Kategoriyalar → yaratish oynasi ochiladi
    await tester.tap(find.text(p.s('nav_profile')).last);
    await settle(tester);
    await tester.scrollUntilVisible(find.text(p.s('categories')), 200,
        scrollable: find.byType(Scrollable).last);
    // Suzuvchi panel ostidan chiqarish uchun qatorni ekran o'rtasiga olib kelamiz
    Scrollable.ensureVisible(tester.element(find.text(p.s('categories'))),
        alignment: 0.5);
    await settle(tester);
    await tester.tap(find.text(p.s('categories')));
    await settle(tester);
    expect(find.text(p.s('my_categories')), findsOneWidget);
    await tester.tap(find.text(p.s('no_custom_categories')));
    await settle(tester);
    expect(find.text(p.s('new_expense_category')), findsOneWidget);

    // Unmount — taymer va cheksiz animatsiyalar to'xtaydi
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('onboarding: sahifalar varaqlanadi, oxirida Boshlash', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    late AppProvider p;
    await tester.runAsync(() async {
      p = AppProvider();
      await p.init();
    });
    KColors.isDark = false;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: p,
      child: MaterialApp(
        theme: kTheme(false),
        home: const OnboardingScreen(),
        routes: {'/register': (_) => const Scaffold(body: Text('REG'))},
      ),
    ));
    await settle(tester);
    expect(find.text(p.s('next')), findsOneWidget);
    await tester.tap(find.text(p.s('next')));
    await settle(tester);
    await tester.tap(find.text(p.s('next')));
    await settle(tester);
    expect(find.text(p.s('start')), findsOneWidget);
    await tester.tap(find.text(p.s('start')));
    await settle(tester);
    expect(find.text('REG'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('yorug\' tema: asosiy ekranlar xatosiz chiziladi',
      (tester) => run(tester, dark: false));

  testWidgets('quyuq tema: asosiy ekranlar xatosiz chiziladi',
      (tester) => run(tester, dark: true));
}
