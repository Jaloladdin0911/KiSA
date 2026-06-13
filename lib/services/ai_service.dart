import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../l10n/app_strings.dart';

class AiInsight {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const AiInsight({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

class AiService {
  static List<AiInsight> generate(
    List<TransactionModel> transactions,
    double monthlyBudget,
    AppStrings s,
    String currency,
  ) {
    if (transactions.isEmpty) return [];

    final insights = <AiInsight>[];
    final now = DateTime.now();
    final prevMonth = now.month == 1
        ? DateTime(now.year - 1, 12)
        : DateTime(now.year, now.month - 1);

    final thisMonthTx = transactions
        .where((t) => t.date.month == now.month && t.date.year == now.year)
        .toList();
    final prevMonthTx = transactions
        .where((t) =>
            t.date.month == prevMonth.month &&
            t.date.year == prevMonth.year)
        .toList();

    final thisExp = _sum(thisMonthTx, 'expense');
    final prevExp = _sum(prevMonthTx, 'expense');
    final thisInc = _sum(thisMonthTx, 'income');

    // 1. Budget exceeded / warning
    if (monthlyBudget > 0) {
      final pct = thisExp / monthlyBudget;
      if (pct >= 1.0) {
        insights.add(AiInsight(
          icon: Icons.warning_amber_rounded,
          title: _budgetExceededTitle(s),
          body: _budgetExceededBody(s, thisExp, monthlyBudget, currency),
          color: Colors.red,
        ));
      } else if (pct >= 0.8) {
        insights.add(AiInsight(
          icon: Icons.error_outline_rounded,
          title: _budgetWarningTitle(s),
          body: _budgetWarningBody(s, pct, monthlyBudget, thisExp, currency),
          color: Colors.orange,
        ));
      }
    }

    // 2. Month-over-month expense comparison
    if (prevExp > 0 && thisExp > 0) {
      final diff = (thisExp - prevExp) / prevExp * 100;
      if (diff > 20) {
        insights.add(AiInsight(
          icon: Icons.trending_up_rounded,
          title: _expUpTitle(s),
          body: _expUpBody(s, diff),
          color: Colors.red.shade400,
        ));
      } else if (diff < -10) {
        insights.add(AiInsight(
          icon: Icons.trending_down_rounded,
          title: _expDownTitle(s),
          body: _expDownBody(s, diff.abs()),
          color: const Color(0xFF2F9E44),
        ));
      }
    }

    // 3. Top expense category this month
    if (thisMonthTx.isNotEmpty) {
      final catMap = <String, double>{};
      for (final t in thisMonthTx.where((t) => t.type == 'expense')) {
        catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
      }
      if (catMap.isNotEmpty) {
        final topCat = catMap.entries.reduce((a, b) => a.value > b.value ? a : b);
        final total = catMap.values.fold(0.0, (a, b) => a + b);
        final pct = (topCat.value / total * 100).toStringAsFixed(0);
        insights.add(AiInsight(
          icon: Icons.pie_chart_outline_rounded,
          title: _topCatTitle(s),
          body: _topCatBody(s, s.cat(topCat.key), pct, topCat.value, currency),
          color: const Color(0xFF3B82F6),
        ));
      }
    }

    // 4. Savings rate
    if (thisInc > 0) {
      final saved = thisInc - thisExp;
      final rate = saved / thisInc * 100;
      if (rate >= 20) {
        insights.add(AiInsight(
          icon: Icons.savings_rounded,
          title: _savingsGoodTitle(s),
          body: _savingsGoodBody(s, rate),
          color: const Color(0xFF2F9E44),
        ));
      } else if (rate < 0) {
        insights.add(AiInsight(
          icon: Icons.money_off_rounded,
          title: _savingsBadTitle(s),
          body: _savingsBadBody(s, saved.abs(), currency),
          color: Colors.red,
        ));
      }
    }

    // 5. No income this month but has expenses
    if (thisInc == 0 && thisExp > 0) {
      insights.add(AiInsight(
        icon: Icons.priority_high_rounded,
        title: _noIncomeTitle(s),
        body: _noIncomeBody(s),
        color: Colors.orange,
      ));
    }

    // 6. Category overspend compared to last month
    if (prevMonthTx.isNotEmpty && thisMonthTx.isNotEmpty) {
      final thisCat = _catMap(thisMonthTx);
      final prevCat = _catMap(prevMonthTx);
      AiInsight? biggest;
      double biggestDiff = 0;
      for (final cat in thisCat.keys) {
        final prev = prevCat[cat] ?? 0;
        if (prev > 0) {
          final diff = (thisCat[cat]! - prev) / prev * 100;
          if (diff > 30 && diff > biggestDiff) {
            biggestDiff = diff;
            biggest = AiInsight(
              icon: Icons.bar_chart_rounded,
              title: _catIncTitle(s),
              body: _catIncBody(s, s.cat(cat), diff),
              color: Colors.orange.shade700,
            );
          }
        }
      }
      if (biggest != null) insights.add(biggest);
    }

    return insights;
  }

  static double _sum(List<TransactionModel> list, String type) =>
      list.where((t) => t.type == type).fold(0.0, (s, t) => s + t.amount);

  static Map<String, double> _catMap(List<TransactionModel> list) {
    final map = <String, double>{};
    for (final t in list.where((t) => t.type == 'expense')) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  // ─── Localized text builders ───────────────────────────────────────────────

  static String _fmt(double v, String cur) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} mln $cur';
    final s = v.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return '$s $cur';
  }

  static String _budgetExceededTitle(AppStrings s) => {
        'uz': 'Budget oshib ketdi!',
        'ru': 'Бюджет превышен!',
        'en': 'Budget Exceeded!',
      }[s.language] ??
      'Budget Exceeded!';

  static String _budgetExceededBody(
      AppStrings s, double exp, double budget, String cur) {
    final over = _fmt(exp - budget, cur);
    return {
          'uz': 'Xarajatingiz budgetdan $over ga oshdi. Tejashga harakat qiling.',
          'ru': 'Ваши расходы превысили бюджет на $over. Постарайтесь сократить траты.',
          'en': 'Your expenses exceeded the budget by $over. Try to cut back.',
        }[s.language] ??
        '';
  }

  static String _budgetWarningTitle(AppStrings s) => {
        'uz': 'Budget chegarasiga yaqinlashyapsiz',
        'ru': 'Вы близки к лимиту бюджета',
        'en': 'Approaching Budget Limit',
      }[s.language] ??
      '';

  static String _budgetWarningBody(
      AppStrings s, double pct, double budget, double exp, String cur) {
    final p = (pct * 100).toStringAsFixed(0);
    final rem = _fmt(budget - exp, cur);
    return {
          'uz': 'Budgetning $p% sarflandi. Qolgan: $rem',
          'ru': 'Использовано $p% бюджета. Остаток: $rem',
          'en': '$p% of budget used. Remaining: $rem',
        }[s.language] ??
        '';
  }

  static String _expUpTitle(AppStrings s) => {
        'uz': "Xarajatlar o'sdi",
        'ru': 'Расходы выросли',
        'en': 'Expenses Increased',
      }[s.language] ??
      '';

  static String _expUpBody(AppStrings s, double diff) {
    final d = diff.toStringAsFixed(0);
    return {
          'uz': "O'tgan oyga nisbatan xarajatlaringiz $d% oshdi. Kategoriyalarni tekshiring.",
          'ru': 'По сравнению с прошлым месяцем расходы выросли на $d%. Проверьте категории.',
          'en': 'Expenses increased by $d% compared to last month. Review your categories.',
        }[s.language] ??
        '';
  }

  static String _expDownTitle(AppStrings s) => {
        'uz': 'Xarajatlar kamaydi',
        'ru': 'Расходы снизились',
        'en': 'Expenses Decreased',
      }[s.language] ??
      '';

  static String _expDownBody(AppStrings s, double diff) {
    final d = diff.toStringAsFixed(0);
    return {
          'uz': "Ajoyib! O'tgan oyga nisbatan $d% kam xarajat qildingiz.",
          'ru': 'Отлично! Расходы снизились на $d% по сравнению с прошлым месяцем.',
          'en': 'Great! Expenses decreased by $d% compared to last month.',
        }[s.language] ??
        '';
  }

  static String _topCatTitle(AppStrings s) => {
        'uz': 'Eng katta xarajat',
        'ru': 'Основная статья расходов',
        'en': 'Top Expense Category',
      }[s.language] ??
      '';

  static String _topCatBody(
      AppStrings s, String cat, String pct, double amount, String cur) {
    final a = _fmt(amount, cur);
    return {
          'uz': '$cat — jami xarajatning $pct% ($a).',
          'ru': '$cat — $pct% от общих расходов ($a).',
          'en': '$cat — $pct% of total expenses ($a).',
        }[s.language] ??
        '';
  }

  static String _savingsGoodTitle(AppStrings s) => {
        'uz': "Yaxshi tejash sur'ati!",
        'ru': 'Хороший уровень сбережений!',
        'en': 'Great Savings Rate!',
      }[s.language] ??
      '';

  static String _savingsGoodBody(AppStrings s, double rate) {
    final r = rate.toStringAsFixed(0);
    return {
          'uz': "Bu oy daromadingizning $r% ni tejadingiz. Davom eting!",
          'ru': 'В этом месяце вы сэкономили $r% дохода. Продолжайте!',
          'en': 'You saved $r% of your income this month. Keep it up!',
        }[s.language] ??
        '';
  }

  static String _savingsBadTitle(AppStrings s) => {
        'uz': 'Xarajatlar daromaddan oshdi',
        'ru': 'Расходы превысили доходы',
        'en': 'Expenses Exceed Income',
      }[s.language] ??
      '';

  static String _savingsBadBody(AppStrings s, double over, String cur) {
    final o = _fmt(over, cur);
    return {
          'uz': "Bu oy daromaddan $o ko'p sarfladingiz. Xarajatlarni kamaytiring.",
          'ru': 'В этом месяце расходы превысили доходы на $o. Сократите траты.',
          'en': 'This month you spent $o more than you earned. Cut back on expenses.',
        }[s.language] ??
        '';
  }

  static String _noIncomeTitle(AppStrings s) => {
        'uz': "Bu oy daromad yo'q",
        'ru': 'В этом месяце нет доходов',
        'en': 'No Income This Month',
      }[s.language] ??
      '';

  static String _noIncomeBody(AppStrings s) => {
        'uz': "Bu oy hech qanday daromad kiritilmagan, lekin xarajatlar bor. Daromadlarni qo'shishni unutmang.",
        'ru': 'В этом месяце не записан ни один доход, но расходы есть. Не забудьте добавить доходы.',
        'en': "No income recorded this month, but you have expenses. Don't forget to log your income.",
      }[s.language] ??
      '';

  static String _catIncTitle(AppStrings s) => {
        'uz': 'Kategoriya xarajati oshdi',
        'ru': 'Расход по категории вырос',
        'en': 'Category Spending Up',
      }[s.language] ??
      '';

  static String _catIncBody(AppStrings s, String cat, double diff) {
    final d = diff.toStringAsFixed(0);
    return {
          'uz': "$cat xarajatingiz o'tgan oyga nisbatan $d% oshdi.",
          'ru': 'Расходы на $cat выросли на $d% по сравнению с прошлым месяцем.',
          'en': '$cat spending increased by $d% compared to last month.',
        }[s.language] ??
        '';
  }
}
