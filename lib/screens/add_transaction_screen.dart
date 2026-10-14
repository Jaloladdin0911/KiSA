import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/calc.dart';
import '../utils/categories.dart';
import '../widgets/kit.dart';
import '../widgets/movement_sheet.dart';
import 'categories_screen.dart';

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
  late final TextEditingController _note;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _note = TextEditingController(text: e?.note ?? '');
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
    final base =
        _type == 'income' ? s.incomeCategoryKeys : s.expenseCategoryKeys;
    // Tahrirlanayotgan amal kategoriyasi ro'yxatda bo'lmasa (masalan
    // arxivlangan) — uni qo'shib qo'yamiz, aks holda jimgina almashib qolardi
    final e = widget.existing;
    if (e != null && e.type == _type && !base.contains(e.category)) {
      return [...base, e.category];
    }
    return base;
  }

  Color get _accent => _type == 'expense' ? KColors.danger : KColors.primary;

  /// Bitta sonni minglik bo'shliqlar bilan: "1250000.5" → "1 250 000.5"
  String _fmtNum(String raw) {
    final parts = raw.split('.');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final grouped = intPart.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
    return parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
  }

  /// Butun ifodani chiroyli ko'rsatish: "12000+3500" → "12 000 + 3 500"
  String _fmt(String expr) {
    if (expr.isEmpty) return '0';
    final out = StringBuffer();
    var buf = '';
    for (final ch in expr.split('')) {
      if (Calc.isOp(ch)) {
        out.write('${_fmtNum(buf)} $ch ');
        buf = '';
      } else {
        buf += ch;
      }
    }
    if (buf.isNotEmpty) out.write(_fmtNum(buf));
    return out.toString().trimRight();
  }

  void _tap(String key) {
    setState(() => _amount = Calc.press(_amount, key));
  }
  void _save() {
    // Ifoda bo'lsa (12000+3500) — natija saqlanadi
    final amount = Calc.evaluate(_amount);
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
      note: _note.text.trim(),
      place: _place,
      currency: _currency,
    );
    final alert = widget.existing == null ? _budgetAlert(provider, tx) : null;
    if (widget.existing != null) {
      provider.updateTransaction(tx);
    } else {
      provider.addTransaction(tx);
    }
    if (alert != null) {
      // Root messenger — xabar oldingi ekranda ko'rinadi
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Row(
            children: [
              Icon(alert.$2 ? Icons.error_rounded : Icons.warning_amber_rounded,
                  color: alert.$2 ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D),
                  size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(alert.$1)),
            ],
          ),
        ));
    }
    Navigator.of(context).pop();
  }

  /// Yangi chiqim shu oydagi kategoriya byudjetini 80% yoki 100% chegaradan
  /// o'tkazsa — ogohlantirish matni va "oshib ketdimi" belgisi.
  (String, bool)? _budgetAlert(AppProvider p, TransactionModel tx) {
    if (tx.type != 'expense') return null;
    final limit = p.categoryBudgets[tx.category];
    final now = DateTime.now();
    if (limit == null || limit <= 0) return null;
    if (tx.date.year != now.year || tx.date.month != now.month) return null;
    final before = p.categorySpentThisMonth(tx.category);
    final after = before + p.toUzs(tx.amount, tx.currency);
    final s = p.s;
    final name = s.cat(tx.category);
    if (before < limit && after >= limit) {
      return (s('budget_over').replaceAll('{cat}', name), true);
    }
    if (before < limit * 0.8 && after >= limit * 0.8) {
      final pct = (after / limit * 100).round();
      return (
        s('budget_warn').replaceAll('{cat}', name).replaceAll('{p}', '$pct'),
        false
      );
    }
    return null;
  }

  void _delete() {
    final existing = widget.existing;
    if (existing == null) return;
    // Tasdiq o'rniga — darhol o'chirish va "Bekor qilish" imkoniyati
    deleteWithUndo(context, existing);
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _date.year < 2020 ? DateTime(_date.year) : DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    // Faqat kunni almashtiramiz — vaqt (soat:daqiqa) saqlanadi, aks holda
    // amal 00:00 ga tushib, kun ichidagi tartib buzilardi
    setState(() => _date = DateTime(picked.year, picked.month, picked.day,
        _date.hour, _date.minute, _date.second));
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  KCircleButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
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
                    KCircleButton(
                      icon: Icons.delete_outline_rounded,
                      color: KColors.danger,
                      bg: KColors.dangerBg,
                      label: s('delete'),
                      onTap: _delete,
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
                            // Har bir raqam kiritilganda summa yengil "sakraydi",
                            // tur almashganda rang silliq o'zgaradi
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(_amount),
                              tween: Tween(begin: 1.06, end: 1.0),
                              duration: KMotion.medium,
                              curve: KMotion.spring,
                              builder: (_, sc, child) =>
                                  Transform.scale(scale: sc, child: child),
                              child: AnimatedDefaultTextStyle(
                                duration: KMotion.medium,
                                // Ifoda yozilayotganda kichrayadi, natija pastda
                                style: k(Calc.hasOp(_amount) ? 30 : 44,
                                    w: FontWeight.w700, c: _accent),
                                child: Text(
                                  '${_type == 'expense' ? '-' : '+'} ${_fmt(_amount)}',
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Kalkulyator natijasi — bosilsa ifoda natija bilan almashadi
                        AnimatedSize(
                          duration: KMotion.medium,
                          curve: KMotion.emphasized,
                          child: Calc.hasOp(_amount) &&
                                  Calc.evaluate(_amount) != null
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: KPressable(
                                    onTap: () => _tap('='),
                                    child: Glass(
                                      color: _accent.withValues(alpha: 0.12),
                                      shadow: const [],
                                      borderRadius:
                                          BorderRadius.circular(rCard),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      child: Text(
                                        '= ${_fmtNum(Calc.trim(Calc.evaluate(_amount)!))}',
                                        style: k(16,
                                            w: FontWeight.w700, c: _accent),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
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
                  const SizedBox(height: 18),

                  // Keypad — summadan darhol keyin, kalkulyator uslubida
                  _Keypad(onTap: _tap, accent: _accent),
                  const SizedBox(height: 22),
                  Divider(height: 1, thickness: 1, color: KColors.line),
                  const SizedBox(height: 20),

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
                      itemCount: keys.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => i == keys.length
                          // Oxirida — o'z kategoriyasini yaratish
                          ? _NewCatChip(
                              label: s('new_category'),
                              onTap: () async {
                                final key =
                                    await showCategoryCreator(context, _type);
                                if (key != null && mounted) {
                                  setState(() => _category = key);
                                }
                              },
                            )
                          : _CatChip(
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
                          Divider(
                              height: 1, thickness: 1, color: KColors.line),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            child: Row(
                              children: [
                                const KTintedIcon(
                                    icon: Icons.notes_rounded,
                                    color: KColors.orange,
                                    size: 36,
                                    circle: false),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _note,
                                    maxLength: 80,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: k(14),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      counterText: '',
                                      hintText: s('note_optional'),
                                      hintStyle: k(14, c: KColors.mut),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Save
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: KPrimaryButton(label: s('save'), onTap: _save),
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
    return KSegmented(
      options: [('expense', s('chiqim')), ('income', s('kirim'))],
      colors: const [KColors.danger, KColors.primary],
      value: type,
      onChanged: onChanged,
      height: 44,
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
    return KPressable(
      onTap: onTap,
      scale: 0.88,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            AnimatedContainer(
              duration: KMotion.medium,
              curve: KMotion.spring,
              width: 56,
              height: 56,
              transform: Matrix4.translationValues(0, selected ? -3 : 0, 0),
              decoration: BoxDecoration(
                color: selected ? color : color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(selected ? 20 : 16),
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

class _NewCatChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NewCatChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return KPressable(
      onTap: onTap,
      scale: 0.88,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: KColors.mut.withValues(alpha: 0.5), width: 1.4),
              ),
              child: Icon(Icons.add_rounded, size: 24, color: KColors.sub),
            ),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k(11.5, w: FontWeight.w500, c: KColors.mut)),
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
            const SizedBox(width: 10),
            Expanded(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: k(13, c: KColors.sub)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: KColors.mut),
          ],
        ),
      ),
    );
  }
}

/// Kalkulyatorli klaviatura: 4 ustun — raqamlar va + − × ÷ amallari.
/// Amal tugmalari tur rangida (chiqim — qizil, kirim — yashil) ajralib turadi.
class _Keypad extends StatelessWidget {
  final ValueChanged<String> onTap;
  final Color accent;
  const _Keypad({required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    const keys = [
      '1', '2', '3', '÷',
      '4', '5', '6', '×',
      '7', '8', '9', '−',
      '.', '0', '⌫', '+',
    ];
    return Padding(
      padding: kPad,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.7,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (_, i) {
          final key = keys[i];
          final isOp = Calc.isOp(key);
          // Har tugma — kichik shisha plitka, bosilganda prujina bilan siqiladi
          return KPressable(
            onTap: () => onTap(key),
            scale: 0.9,
            semanticLabel: key == '⌫'
                ? MaterialLocalizations.of(context).deleteButtonTooltip
                : null,
            child: Glass(
              shadow: const [],
              color: isOp ? accent.withValues(alpha: 0.12) : null,
              borderRadius: BorderRadius.circular(rTile),
              child: Center(
                child: AnimatedSwitcher(
                  duration: KMotion.fast,
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: key == '⌫'
                      ? Icon(Icons.backspace_outlined,
                          key: const ValueKey('del'),
                          size: 22,
                          color: KColors.ink)
                      : Text(key,
                          key: ValueKey(key),
                          style: k(isOp ? 26 : 24,
                              w: isOp ? FontWeight.w600 : FontWeight.w500,
                              c: isOp ? accent : null)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}