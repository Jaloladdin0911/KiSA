import 'package:flutter_test/flutter_test.dart';
import 'package:kisa/utils/calc.dart';

String typeAll(String keys) {
  var e = '';
  for (final k in keys.split('')) {
    e = Calc.press(e, k);
  }
  return e;
}

void main() {
  group('Calc.evaluate', () {
    test('oddiy son va amallar tartibi', () {
      expect(Calc.evaluate('12000'), 12000);
      expect(Calc.evaluate('12000+3500'), 15500);
      expect(Calc.evaluate('2+3×4'), 14);
      expect(Calc.evaluate('100−20÷4'), 95);
      expect(Calc.evaluate('0.1+0.2'), 0.3);
    });

    test('oxirgi amal belgisi e\'tiborsiz', () {
      expect(Calc.evaluate('12+'), 12);
      expect(Calc.evaluate('12×−'), 12);
    });

    test('noto\'g\'ri ifoda va nolga bo\'lish', () {
      expect(Calc.evaluate(''), isNull);
      expect(Calc.evaluate('5÷0'), isNull);
      expect(Calc.evaluate('+5'), isNull);
    });
  });

  group('Calc.press', () {
    test('amal belgisini almashtirish', () {
      expect(typeAll('12+×3'), '12×3');
      expect(typeAll('+5'), '5'); // bo'sh ifodaga amal yo'q
    });

    test('nuqta va kasr chegarasi', () {
      expect(typeAll('.5'), '0.5');
      expect(typeAll('1..2'), '1.2');
      expect(typeAll('1.234'), '1.23');
      expect(typeAll('5+.'), '5+0.');
    });

    test('boshidagi nol almashtiriladi, raqamlar chegarasi', () {
      expect(typeAll('05'), '5');
      expect(typeAll('1234567890123'), '123456789012');
    });

    test('= natijani qo\'yadi, ⌫ o\'chiradi', () {
      expect(typeAll('2+3='), '5');
      expect(typeAll('10÷4='), '2.5');
      expect(typeAll('12+⌫'), '12');
    });
  });
}
