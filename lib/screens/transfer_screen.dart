import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/app_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// O'tkazma / Ayirboshlash — yangi dizayn (KColors/k).
/// O'tkazma: bir valyuta ichida Naqd↔Karta. Ayirboshlash: so'm↔dollar.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  String _mode = 'transfer'; // transfer | exchange

  // O'tkazma
  String _currency = 'UZS';
  String _from = 'cash';
  String _to = 'card';
  final _amount = TextEditingController();

  // Ayirboshlash
  String _giveCur = 'UZS';
  String _getCur = 'USD';
  String _givePlace = 'cash';
  String _getPlace = 'cash';
  final _give = TextEditingController();
  final _get = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _give.dispose();
    _get.dispose();
    super.dispose();
  }

  AppStrings get s => context.read<AppProvider>().s;

  String _curLabel(String c) => Money.symbols[c] ?? c;

  /// "Berasiz" summasidan CBU kursi bo'yicha "Olasiz"ni hisoblaydi.
  void _applyRate() {
    final give = Money.parse(_give.text);
    final rate = context.read<AppProvider>().usdRate;
    if (give == null || give <= 0 || rate <= 0 || _giveCur == _getCur) return;
    double? got;
    if (_giveCur == 'USD' && _getCur == 'UZS') {
      got = give * rate;
    } else if (_giveCur == 'UZS' && _getCur == 'USD') {
      got = give / rate;
    }
    if (got != null) {
      _get.text = Money.plain(got, currency: _getCur);
    }
  }

  void _save() {
    final provider = context.read<AppProvider>();
    if (_mode == 'transfer') {
      final amount = Money.parse(_amount.text);
      if (amount == null || amount <= 0 || _from == _to) {
        _err(_from == _to ? s('same_wallet_error') : s('enter_amount'));
        return;
      }
      provider.addTransaction(TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: provider.userId,
        type: 'transfer',
        amount: amount,
        category: 'transfer',
        date: DateTime.now(),
        note: '',
        place: _from,
        currency: _currency,
        toPlace: _to,
        toCurrency: _currency,
        toAmount: amount,
      ));
    } else {
      final give = Money.parse(_give.text);
      final get = Money.parse(_get.text);
      if (give == null || give <= 0 || get == null || get <= 0 ||
          _giveCur == _getCur) {
        _err(_giveCur == _getCur
            ? s('other_currency')
            : s('enter_amount'));
        return;
      }
      provider.addTransaction(TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: provider.userId,
        type: 'exchange',
        amount: give,
        category: 'exchange',
        date: DateTime.now(),
        note: '',
        place: _givePlace,
        currency: _giveCur,
        toPlace: _getPlace,
        toCurrency: _getCur,
        toAmount: get,
      ));
    }
    Navigator.pop(context);
  }

  void _err(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: KColors.card,
                        shape: BoxShape.circle,
                        boxShadow: kSoftShadow,
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 22, color: KColors.ink),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                          _mode == 'transfer' ? s('transfer') : s('exchange'),
                          style: k(17, w: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode toggle
            Padding(
              padding: kPad,
              child: _Seg(
                options: [
                  ('transfer', s('transfer')),
                  ('exchange', s('exchange')),
                ],
                value: _mode,
                onChanged: (v) => setState(() => _mode = v),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                children: _mode == 'transfer'
                    ? _transferBody()
                    : _exchangeBody(),
              ),
            ),

            // Save
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: GestureDetector(
                onTap: _save,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    borderRadius: BorderRadius.circular(rBtn),
                    boxShadow: kGreenShadow,
                  ),
                  child: Text(s('save'),
                      style: k(16, w: FontWeight.w600, c: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _transferBody() => [
        _label(s('amount')),
        _amountField(_amount, _curLabel(_currency)),
        const SizedBox(height: 18),
        _label(s('currency')),
        _Seg(
          options: [('UZS', s('som')), ('USD', '\$')],
          value: _currency,
          onChanged: (v) => setState(() => _currency = v),
        ),
        const SizedBox(height: 18),
        _label(s('from_wallet')),
        _Seg(
          options: [('cash', s('wallet_cash')), ('card', s('wallet_card'))],
          value: _from,
          onChanged: (v) => setState(() {
            _from = v;
            if (_to == _from) _to = v == 'cash' ? 'card' : 'cash';
          }),
        ),
        const SizedBox(height: 12),
        _label(s('to_wallet')),
        _Seg(
          options: [('cash', s('wallet_cash')), ('card', s('wallet_card'))],
          value: _to,
          onChanged: (v) => setState(() {
            _to = v;
            if (_from == _to) _from = v == 'cash' ? 'card' : 'cash';
          }),
        ),
      ];

  List<Widget> _exchangeBody() {
    final rate = context.read<AppProvider>().usdRate;
    return [
      _label(s('you_give')),
      _amountField(_give, _curLabel(_giveCur), onChanged: (_) => _applyRate()),
      const SizedBox(height: 8),
      _Seg(
        options: [('UZS', s('som')), ('USD', '\$')],
        value: _giveCur,
        onChanged: (v) {
          setState(() {
            _giveCur = v;
            if (_getCur == _giveCur) _getCur = v == 'UZS' ? 'USD' : 'UZS';
          });
          _applyRate();
        },
      ),
      const SizedBox(height: 6),
      _Seg(
        options: [('cash', s('wallet_cash')), ('card', s('wallet_card'))],
        value: _givePlace,
        onChanged: (v) => setState(() => _givePlace = v),
      ),
      const SizedBox(height: 16),
      Center(child: Icon(Icons.south_rounded, color: KColors.mut)),
      const SizedBox(height: 16),
      _label(s('you_get')),
      _amountField(_get, _curLabel(_getCur)),
      const SizedBox(height: 8),
      _Seg(
        options: [('UZS', s('som')), ('USD', '\$')],
        value: _getCur,
        onChanged: (v) {
          setState(() {
            _getCur = v;
            if (_giveCur == _getCur) _giveCur = v == 'UZS' ? 'USD' : 'UZS';
          });
          _applyRate();
        },
      ),
      const SizedBox(height: 6),
      _Seg(
        options: [('cash', s('wallet_cash')), ('card', s('wallet_card'))],
        value: _getPlace,
        onChanged: (v) => setState(() => _getPlace = v),
      ),
      if (rate > 0) ...[
        const SizedBox(height: 14),
        Center(
          child: Text('${s('cbu_rate')}: 1 \$ = ${Money.format(rate, 'UZS')}',
              style: k(12, c: KColors.mut)),
        ),
      ],
    ];
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: k(13, w: FontWeight.w600, c: KColors.sub)),
      );

  Widget _amountField(TextEditingController c, String suffix,
          {ValueChanged<String>? onChanged}) =>
      TextField(
        controller: c,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: Money.amountFormatters,
        style: k(20, w: FontWeight.w700),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: k(20, w: FontWeight.w700, c: KColors.mut),
          suffixText: suffix,
          filled: true,
          fillColor: KColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(rTile),
            borderSide: BorderSide.none,
          ),
        ),
      );
}

class _Seg extends StatelessWidget {
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;
  const _Seg(
      {required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KColors.isDark ? const Color(0xFF23262F) : const Color(0xFFE6E9EF),
        borderRadius: BorderRadius.circular(rTile),
      ),
      child: Row(
        children: options.map((o) {
          final active = o.$1 == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? KColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(rTile - 3),
                  boxShadow: active ? kSoftShadow : null,
                ),
                child: Text(o.$2,
                    style: k(14,
                        w: active ? FontWeight.w600 : FontWeight.w500,
                        c: active ? KColors.ink : KColors.sub)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
