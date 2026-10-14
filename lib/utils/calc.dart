/// Summa klaviaturasi uchun oddiy kalkulyator: + − × ÷, kasr nuqtasi,
/// amallar tartibi (× ÷ avval). `eval` yoki tashqi kutubxona ishlatilmaydi —
/// faqat raqam va shu 4 belgi qabul qilinadi.
class Calc {
  Calc._();

  static const ops = ['+', '−', '×', '÷'];

  static bool isOp(String ch) => ops.contains(ch);

  /// Ifodada amal belgisi bormi (ya'ni natija ko'rsatish kerakmi).
  static bool hasOp(String expr) => expr.split('').any(isOp);

  /// Ifodani hisoblaydi. Oxirida amal belgisi qolgan bo'lsa, u e'tiborga
  /// olinmaydi ("12+" → 12). Noto'g'ri ifoda yoki 0 ga bo'lish — null.
  static double? evaluate(String expr) {
    var e = expr.trim();
    while (e.isNotEmpty && isOp(e[e.length - 1])) {
      e = e.substring(0, e.length - 1);
    }
    if (e.isEmpty) return null;

    final nums = <double>[];
    final opsList = <String>[];
    var buf = '';
    for (final ch in e.split('')) {
      if (isOp(ch)) {
        final n = double.tryParse(buf);
        if (n == null) return null;
        nums.add(n);
        opsList.add(ch);
        buf = '';
      } else {
        buf += ch;
      }
    }
    final last = double.tryParse(buf);
    if (last == null) return null;
    nums.add(last);

    // 1-bosqich: × va ÷
    final n2 = <double>[nums.first];
    final o2 = <String>[];
    for (var i = 0; i < opsList.length; i++) {
      final op = opsList[i];
      final b = nums[i + 1];
      if (op == '×') {
        n2[n2.length - 1] *= b;
      } else if (op == '÷') {
        if (b == 0) return null;
        n2[n2.length - 1] /= b;
      } else {
        n2.add(b);
        o2.add(op);
      }
    }
    // 2-bosqich: + va −
    var result = n2.first;
    for (var i = 0; i < o2.length; i++) {
      result = o2[i] == '+' ? result + n2[i + 1] : result - n2[i + 1];
    }
    if (result.isNaN || result.isInfinite) return null;
    // Suzuvchi nuqta shovqinini kesish (0.1+0.2 → 0.3)
    return double.parse(result.toStringAsFixed(2));
  }

  /// Oxirgi (hozir yozilayotgan) son.
  static String currentNumber(String expr) {
    var i = expr.length;
    while (i > 0 && !isOp(expr[i - 1])) {
      i--;
    }
    return expr.substring(i);
  }

  /// Kalkulyator tugmasini bosish — yangi ifodani qaytaradi.
  /// [maxDigits] — bitta sondagi raqamlar chegarasi.
  static String press(String expr, String key, {int maxDigits = 12}) {
    if (key == '⌫') {
      return expr.isEmpty ? expr : expr.substring(0, expr.length - 1);
    }
    if (key == '=') {
      final v = evaluate(expr);
      return v == null ? expr : trim(v);
    }
    if (isOp(key)) {
      if (expr.isEmpty) return expr;
      final lastCh = expr[expr.length - 1];
      if (isOp(lastCh)) return expr.substring(0, expr.length - 1) + key;
      if (lastCh == '.') return '${expr.substring(0, expr.length - 1)}$key';
      return expr + key;
    }
    final cur = currentNumber(expr);
    if (key == '.') {
      if (cur.contains('.')) return expr;
      return cur.isEmpty ? '${expr}0.' : '$expr.';
    }
    // Raqam
    if (cur.replaceAll('.', '').length >= maxDigits) return expr;
    final dot = cur.indexOf('.');
    if (dot >= 0 && cur.length - dot > 2) return expr; // 2 xonadan ortiq kasr yo'q
    if (cur == '0') return expr.substring(0, expr.length - 1) + key;
    return expr + key;
  }

  /// 1250000.0 → "1250000", 12.5 → "12.5"
  static String trim(double v) {
    final s = v.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    if (s.endsWith('0')) return s.substring(0, s.length - 1);
    return s;
  }
}
