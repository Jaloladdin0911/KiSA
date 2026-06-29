import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../widgets/kit.dart';

/// Amal qo'shish / tahrirlash — KISA_DESIGN_SPEC.md, Section 7.
/// To'liq ekran: Chiqim/Kirim, summa display, kategoriya, raqamli klaviatura.
class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? existing;
  final String? initialType; // 'income' | 'expense'

  const AddTransactionScreen({super.key, this.existing, this.initialType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late String _type; // 'income' | 'expense'
  String _amount = '';
  late String _category;
  late String _place; // 'cash' | 'card'
  late String _currency; // 'UZS' | 'USD'
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.initialType ?? 'expense';
    if (_type != 'income' && _type != 'expense') _type = 'expense';
    _amount = e != null ? _trimAmount(e.amount) : '';
    _place = e?.place ?? 'card';
    _currency = e?.currency ?? 'UZS';
    _date = e?.date ?? DateTime.now();
    final keys = _catKeys();
    _category = (e != null && keys.contains(e.category)) ? e.category : keys.first;
  }

  String _trimAmount(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  List<String> _catKeys() {
    final s = context.read<AppProvider>().s;
    return _type == 'income' ? s.incomeCategoryKeys : s.expenseCategoryKeys;
  }

  Color get _accent => _type == 'expense' ? KColors.danger : KColors.primary;

  String _fmt(String raw) {
    if (raw.isEmpty) return '0';
    final parts = raw.split('.');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final grouped = intPart.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
    return parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
  }

  void _tap(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (key == '.') {
        if (!_amount.contains('.') && _amount.isNotEmpty) _amount += '.';
      } else {
        if (_amount.replaceAll('.', '').length >= 12) return;
        if (_amount == '0') {
          _amount = key;
        } else {
          _amount += key;
        }
      }
    });
  }

  void _save() {
    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) return;
    final provider = context.read<AppProvider>();
    final tx = TransactionModel(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      userId: provider.userId,
      type: _type,
      amount: amount,
      category: _category,
      date: _date,
      note: widget.existing?.note ?? '',
      place: _place,
      currency: _currency,
    );
    if (widget.existing != null) {
      provider.updateTransaction(tx);
    } else {
      provider.addTransaction(tx);
    }
    Navigator.of(context).pop();
  }

  void _delete() {
    final existing = widget.existing;
    if (existing == null) return;
    final s = context.read<AppProvider>().s;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text(s('delete_transaction'), style: k(16, w: FontWeight.w700)),
        content: Text(s('delete_transaction_confirm'),
            style: k(13.5, c: KColors.sub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s('cancel'), style: k(14, c: KColors.sub)),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteTransaction(existing.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(s('delete'),
                style: k(14, w: FontWeight.w600, c: KColors.danger)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String get _dateLabel {
    final s = context.read<AppProvider>().s;
    final now = DateTime.now();
    final label = '${_date.day} ${s.months[_date.month - 1]}';
    if (_date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day) {
      return '${s('today')}, $label';
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    final keys = _catKeys();
    if (!keys.contains(_category)) _category = keys.first;

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
                          widget.existing != null
                              ? s('edit_transaction')
                              : s('new_transaction'),
                          style: k(17, w: FontWeight.w600)),
                    ),
                  ),
                  if (widget.existing != null)
                    GestureDetector(
                      onTap: _delete,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: KColors.dangerBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 22, color: KColors.danger),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Type toggle
            Padding(
              padding: kPad,
              child: _TypeToggle(
                type: _type,
                onChanged: (t) => setState(() {
                  _type = t;
                  _category = _catKeys().first;
                }),
              ),
            ),

            // Scrollable middle
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 18),
                  // Amount display
                  Center(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: kPad,
                            child: Text(
                              '${_type == 'expense' ? '-' : '+'} ${_fmt(_amount)}',
                              style: k(40, w: FontWeight.w700, c: _accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Valyuta tanlash (so'm / $)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final cur in const ['UZS', 'USD'])
                              GestureDetector(
                                onTap: () => setState(() => _currency = cur),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _currency == cur
                                        ? _accent.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: _currency == cur
                                            ? _accent
                                            : KColors.line,
                                        width: 1.2),
                                  ),
                                  child: Text(
                                    cur == 'USD' ? '\$' : s('som'),
                                    style: k(13,
                                        w: FontWeight.w600,
                                        c: _currency == cur
                                            ? _accent
                                            : KColors.mut),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Category
                  Padding(
                    padding: kPad,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(s('category'),
                          style: k(13, w: FontWeight.w600, c: KColors.sub)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: kPad,
                      itemCount: keys.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => _CatChip(
                        catKey: keys[i],
                        label: s.cat(keys[i]),
                        selected: keys[i] == _category,
                        onTap: () => setState(() => _category = keys[i]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Detail card (Hisob / Sana)
                  Padding(
                    padding: kPad,
                    child: KCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.credit_card_rounded,
                            iconColor: KColors.primary,
                            label: s('account'),
                            value: _place == 'card'
                                ? s('wallet_card')
                                : s('wallet_cash'),
                            onTap: () => setState(
                                () => _place = _place == 'card' ? 'cash' : 'card'),
                          ),
                          Divider(
                              height: 1, thickness: 1, color: KColors.line),
                          _DetailRow(
                            icon: Icons.calendar_today_rounded,
                            iconColor: KColors.blue,
                            label: s('date'),
                            value: _dateLabel,
                            onTap: _pickDate,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Keypad
                  _Keypad(onTap: _tap),
                  const SizedBox(height: 8),
                ],
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
}

class _TypeToggle extends StatelessWidget {
  final String type;
  final ValueChanged<String> onChanged;
  const _TypeToggle({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    Widget seg(String value, String label, Color activeColor) {
      final active = type == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? KColors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(rTile - 3),
              boxShadow: active ? kSoftShadow : null,
            ),
            child: Text(label,
                style: k(15,
                    w: active ? FontWeight.w600 : FontWeight.w500,
                    c: active ? activeColor : KColors.sub)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KColors.isDark
            ? const Color(0xFF23262F)
            : const Color(0xFFE6E9EF),
        borderRadius: BorderRadius.circular(rTile),
      ),
      child: Row(
        children: [
          seg('expense', s('chiqim'), KColors.danger),
          seg('income', s('kirim'), KColors.primary),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String catKey, label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({
    required this.catKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoryMeta.color(catKey);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? color : color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(16),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            offset: const Offset(0, 6),
                            blurRadius: 14)
                      ]
                    : null,
              ),
              child: Icon(CategoryMeta.icon(catKey),
                  size: 24, color: selected ? Colors.white : color),
            ),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k(11.5,
                    w: selected ? FontWeight.w600 : FontWeight.w500,
                    c: selected ? color : KColors.mut)),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  final VoidCallback onTap;
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            KTintedIcon(icon: icon, color: iconColor, size: 36, circle: false),
            const SizedBox(width: 12),
            Text(label, style: k(14, w: FontWeight.w500)),
            const Spacer(),
            Text(value, style: k(13, c: KColors.sub)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: KColors.mut),
          ],
        ),
      ),
    );
  }
}

// ── Hamyonlar orasi o'tkazma (Naqd ↔ Karta) ───────────────────────────────────

void showTransferSheet(BuildContext context, AppProvider provider) {
  String from = 'cash';
  String to = 'card';
  final amountCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: KColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setM) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                      color: KColors.line,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),
              Text(provider.s('transfer'), style: k(18, w: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: Money.amountFormatters,
                style: k(16),
                decoration: InputDecoration(
                  labelText: provider.s('amount'),
                  suffixText: provider.s('som'),
                  filled: true,
                  fillColor: KColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(rTile),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(provider.s('from_wallet'),
                  style: k(13, w: FontWeight.w600, c: KColors.sub)),
              const SizedBox(height: 8),
              _PlaceSeg(
                value: from,
                onChanged: (v) => setM(() {
                  from = v;
                  if (to == from) to = v == 'cash' ? 'card' : 'cash';
                }),
              ),
              const SizedBox(height: 12),
              Text(provider.s('to_wallet'),
                  style: k(13, w: FontWeight.w600, c: KColors.sub)),
              const SizedBox(height: 8),
              _PlaceSeg(
                value: to,
                onChanged: (v) => setM(() {
                  to = v;
                  if (from == to) from = v == 'cash' ? 'card' : 'cash';
                }),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  final amount = Money.parse(amountCtrl.text);
                  if (amount == null || amount <= 0 || from == to) return;
                  provider.addTransaction(TransactionModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: provider.userId,
                    type: 'transfer',
                    amount: amount,
                    category: 'transfer',
                    date: DateTime.now(),
                    note: '',
                    place: from,
                    currency: 'UZS',
                    toPlace: to,
                    toCurrency: 'UZS',
                    toAmount: amount,
                  ));
                  Navigator.pop(ctx);
                },
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    borderRadius: BorderRadius.circular(rBtn),
                  ),
                  child: Text(provider.s('save'),
                      style: k(16, w: FontWeight.w600, c: Colors.white)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      );
    },
  );
}

class _PlaceSeg extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _PlaceSeg({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    Widget seg(String v, String label, IconData icon) {
      final active = v == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(v),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? KColors.primary.withValues(alpha: 0.13)
                  : KColors.bg,
              borderRadius: BorderRadius.circular(rTile),
              border: Border.all(
                  color: active ? KColors.primary : Colors.transparent,
                  width: 1.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: active ? KColors.primary : KColors.sub),
                const SizedBox(width: 6),
                Text(label,
                    style: k(13.5,
                        w: active ? FontWeight.w600 : FontWeight.w500,
                        c: active ? KColors.primary : KColors.sub)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg('cash', s('wallet_cash'), Icons.payments_rounded),
        seg('card', s('wallet_card'), Icons.credit_card_rounded),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _Keypad({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '.', '0', '⌫',
    ];
    return Padding(
      padding: kPad,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.9,
        ),
        itemBuilder: (_, i) {
          final key = keys[i];
          return GestureDetector(
            onTap: () => onTap(key),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: key == '⌫'
                  ? Icon(Icons.backspace_outlined,
                      size: 24, color: KColors.ink)
                  : Text(key, style: k(26, w: FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }
}
