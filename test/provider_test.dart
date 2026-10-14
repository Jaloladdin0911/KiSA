import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kisa/models/goal_model.dart';
import 'package:kisa/models/recurring_model.dart';
import 'package:kisa/models/transaction_model.dart';
import 'package:kisa/services/app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _id = 0;

TransactionModel _tx(
  String type,
  double amount, {
  String place = 'cash',
  String currency = 'UZS',
  String? toPlace,
  String? toCurrency,
  double? toAmount,
  String category = 'Oziq-ovqat',
  DateTime? date,
}) =>
    TransactionModel(
      id: 't${_id++}',
      userId: 'local_user',
      type: type,
      amount: amount,
      category: category,
      date: date ?? DateTime.now(),
      note: '',
      place: place,
      currency: currency,
      toPlace: toPlace,
      toCurrency: toCurrency,
      toAmount: toAmount,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // HTTP so'rovlarni bloklaydi
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kisa_test');
    Hive.init(dir.path);
    await Hive.openBox('transactions');
    await Hive.openBox('goals');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  Future<AppProvider> provider() async {
    final p = AppProvider();
    await p.init();
    return p;
  }

  test('hamyon balanslari: kirim, chiqim, o\'tkazma, ayirboshlash', () async {
    final p = await provider();
    await p.addTransaction(_tx('income', 1000000));
    await p.addTransaction(_tx('expense', 200000));
    await p.addTransaction(_tx('transfer', 300000,
        toPlace: 'card', toCurrency: 'UZS', toAmount: 300000));
    await p.addTransaction(_tx('exchange', 127000,
        place: 'card', toPlace: 'cash', toCurrency: 'USD', toAmount: 10));

    expect(p.balanceOf('cash', 'UZS'), 500000);
    expect(p.balanceOf('card', 'UZS'), 173000);
    expect(p.balanceOf('cash', 'USD'), 10);
    expect(p.currencyBalance('UZS'), 673000);
  });

  test('byudjet: USD xarajat kurs bo\'yicha so\'mga qo\'shiladi', () async {
    final p = await provider();
    await p.setUsdRate(12700);
    await p.addTransaction(_tx('expense', 50000));
    await p.addTransaction(_tx('expense', 2, currency: 'USD'));
    expect(p.categorySpentThisMonth('Oziq-ovqat'), 50000 + 2 * 12700);
    expect(p.expenseThisMonthInUzs(), 75400);
  });

  test('zaxira: eksport → tozalash → tiklash bir xil holatni qaytaradi',
      () async {
    final p = await provider();
    await p.addTransaction(_tx('income', 500));
    await p.addTransaction(_tx('expense', 120));
    await p.addGoal(GoalModel(
        id: 'g1',
        userId: 'local_user',
        title: 'Telefon',
        targetAmount: 1000,
        currentAmount: 100,
        deadline: DateTime(2030),
        icon: 'target'));
    await p.setCategoryBudget('Oziq-ovqat', 900);
    final backup = p.toBackup();

    await p.clearAllData();
    expect(p.transactions, isEmpty);
    expect(p.categoryBudgets, isEmpty);

    final n = await p.restoreBackup(backup);
    expect(n, 2);
    expect(p.currencyBalance('UZS'), 380);
    expect(p.goals.single.title, 'Telefon');
    expect(p.categoryBudgets['Oziq-ovqat'], 900);

    // Qayta ochilganda ham saqlangan bo'lishi kerak
    final again = await provider();
    expect(again.transactions.length, 2);
  });

  test('zaxira: yaroqsiz fayl hech narsani o\'zgartirmaydi', () async {
    final p = await provider();
    await p.addTransaction(_tx('income', 500));

    await expectLater(p.restoreBackup({'format': 'other'}),
        throwsA(isA<FormatException>()));
    await expectLater(
        p.restoreBackup({
          'format': AppProvider.backupFormat,
          'version': 1,
          'transactions': [
            {'id': 'x'} // amount/date yo'q
          ],
        }),
        throwsA(isA<FormatException>()));
    expect(p.transactions.length, 1);
  });

  test('PIN: 5 xatodan keyin bloklanadi, to\'g\'risi ham qabul qilinmaydi',
      () async {
    final p = await provider();
    await p.setPin('1234');
    for (var i = 0; i < 4; i++) {
      expect(await p.verifyPin('0000'), isFalse);
    }
    expect(p.pinLockRemaining, isNull);
    expect(await p.verifyPin('0000'), isFalse);
    expect(p.pinLockRemaining, isNotNull);
    expect(await p.verifyPin('1234'), isFalse); // blok davomida
  });

  test('PIN unutildi: faqat ro\'yxatdagi telefon bilan tiklanadi', () async {
    final p = await provider();
    await p.register('Ali', '+998901234567');
    await p.setPin('1234');
    for (var i = 0; i < 5; i++) {
      await p.verifyPin('0000');
    }
    expect(p.pinLockRemaining, isNotNull);
    expect(await p.resetPinWithPhone('+998900000000'), isFalse);
    expect(p.pinEnabled, isTrue);
    expect(await p.resetPinWithPhone('+998901234567'), isTrue);
    expect(p.pinEnabled, isFalse);
    expect(p.pinLockRemaining, isNull);
  });

  test('PIN: to\'g\'ri kiritilsa xatolar hisobi nolga tushadi', () async {
    final p = await provider();
    await p.setPin('1234');
    for (var i = 0; i < 4; i++) {
      await p.verifyPin('0000');
    }
    expect(await p.verifyPin('1234'), isTrue);
    for (var i = 0; i < 4; i++) {
      await p.verifyPin('0000');
    }
    expect(p.pinLockRemaining, isNull);
  });

  test('statistika: davr va kategoriya bo\'yicha jami, 6 oylik dinamika',
      () async {
    final p = await provider();
    await p.setUsdRate(12000);
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1, 12);
    final lastMonth = DateTime(now.year, now.month - 1, 15);
    await p.addTransaction(_tx('expense', 100, date: thisMonth));
    await p.addTransaction(
        _tx('expense', 1, currency: 'USD', category: 'Transport', date: thisMonth));
    await p.addTransaction(_tx('expense', 50, date: lastMonth));
    await p.addTransaction(
        _tx('income', 900, category: 'Ish haqi', date: thisMonth));

    final from = DateTime(now.year, now.month);
    final to = DateTime(now.year, now.month + 1);
    final totals = p.categoryTotals('expense', from, to);
    expect(totals['Oziq-ovqat'], 100);
    expect(totals['Transport'], 12000); // USD → so'm
    expect(p.inRange('expense', from, to).length, 2);

    final months = p.monthlyTotals();
    expect(months.length, 6);
    expect(months.last.expense, 12100);
    expect(months.last.income, 900);
    expect(months[4].expense, 50);
  });

  test('qoldiq tuzatish: balansni moslaydi, statistikaga kirmaydi', () async {
    final p = await provider();
    await p.addTransaction(_tx('income', 1000));
    await p.addTransaction(_tx('expense', 300));
    expect(p.balanceOf('cash', 'UZS'), 700);

    // Haqiqatda hamyonda 500 bor — farq −200 "adjust" bo'lib yoziladi
    expect(await p.setActualBalance('cash', 'UZS', 500), isTrue);
    expect(p.balanceOf('cash', 'UZS'), 500);
    final adj = p.transactions.firstWhere((t) => t.isAdjust);
    expect(adj.amount, -200);
    expect(adj.isSystem, isTrue);

    // Statistika o'zgarmaydi
    expect(p.incomeThisMonth('UZS'), 1000);
    expect(p.expenseThisMonth('UZS'), 300);

    // Farq yo'q bo'lsa — yangi amal yaratilmaydi
    expect(await p.setActualBalance('cash', 'UZS', 500), isFalse);
    expect(p.transactions.where((t) => t.isAdjust).length, 1);

    // Boshlang'ich qoldiq bo'sh hamyonda
    await p.setActualBalance('card', 'USD', 250.5);
    expect(p.balanceOf('card', 'USD'), 250.5);
  });

  test('kategoriyalar: yaratish, ro\'yxatda chiqish, arxivlash, zaxira',
      () async {
    final p = await provider();
    final key = await p.addCategory(
        name: 'Kitoblar', type: 'expense', icon: 'book', color: 0xFF4C8DFF);
    expect(p.s.expenseCategoryKeys, contains(key));
    expect(p.s.expenseCategoryKeys.last, 'Boshqa'); // "Boshqa" oxirida qoladi
    expect(p.s.incomeCategoryKeys, isNot(contains(key)));
    expect(p.s.cat(key), 'Kitoblar');

    await p.addTransaction(_tx('expense', 50, category: key));
    final backup = p.toBackup();

    // Arxivlash: tanlovdan yo'qoladi, lekin nomi saqlanadi
    await p.archiveCategory(key);
    expect(p.s.expenseCategoryKeys, isNot(contains(key)));
    expect(p.s.cat(key), 'Kitoblar');
    await p.archiveCategory(key, restore: true);
    expect(p.s.expenseCategoryKeys, contains(key));

    // Qayta ochilganda saqlangan
    final again = await provider();
    expect(again.customCategories('expense').single.name, 'Kitoblar');

    // Zaxiradan tiklash kategoriyani qaytaradi
    await again.archiveCategory(key);
    SharedPreferences.setMockInitialValues({});
    final fresh = await provider();
    expect(fresh.customCategories('expense'), isEmpty);
    await fresh.restoreBackup(backup);
    expect(fresh.s.cat(key), 'Kitoblar');
    expect(fresh.s.expenseCategoryKeys, contains(key));
  });

  test('umumiy boylik: USD kurs bo\'yicha so\'mga qo\'shiladi', () async {
    final p = await provider();
    await p.addTransaction(_tx('income', 1000000));
    await p.addTransaction(_tx('income', 100, currency: 'USD', place: 'card'));
    expect(p.netWorthUzs, 1000000); // kurs noma'lum — USD qo'shilmaydi
    await p.setUsdRate(12500);
    expect(p.netWorthUzs, 1000000 + 100 * 12500);
  });

  test('tema: eski dark_mode sozlamasi yangi rejimga o\'tadi', () async {
    SharedPreferences.setMockInitialValues({'dark_mode': true});
    final p = await provider();
    expect(p.themeMode, 'dark');
    expect(p.isDarkMode, isTrue);
    await p.setThemeMode('light');
    expect(p.isDarkMode, isFalse);
    expect((await provider()).themeMode, 'light'); // saqlangan
  });

  test('o\'chirilgan amal updateTransaction bilan o\'z joyiga qaytadi',
      () async {
    final p = await provider();
    final old = _tx('expense', 10, date: DateTime(2025, 1, 1));
    await p.addTransaction(_tx('expense', 20));
    await p.addTransaction(old);
    await p.addTransaction(_tx('expense', 30));
    await p.deleteTransaction(old.id);
    expect(p.transactions.length, 2);
    await p.updateTransaction(old); // "Bekor qilish"
    expect(p.transactions.length, 3);
    expect(p.transactions.last.id, old.id); // eng eski — oxirida
  });

  test('takroriy to\'lov: o\'tib ketgan sanalar uchun amallar yaratiladi',
      () async {
    final p = await provider();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day - 2);
    await p.addRecurring(RecurringModel(
      id: 'r1',
      type: 'expense',
      amount: 10,
      category: 'Transport',
      place: 'card',
      currency: 'UZS',
      note: 'Metro',
      frequency: 'daily',
      nextDate: start,
    ));
    expect(p.transactions.where((t) => t.note == 'Metro').length, 3);
    expect(p.recurring.single.nextDate.isAfter(today), isTrue);
    expect(p.upcomingRecurring(days: 1).length, 1);
  });
}
