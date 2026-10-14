import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../widgets/kit.dart';

/// Kategoriyalar — o'rnatilganlar va foydalanuvchi yaratganlari.
/// O'zinikini qo'shish/o'chirish mumkin (o'chirish = arxivlash, "Bekor qilish").
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _type = 'expense';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final s = p.s;
    final custom = p.customCategories(_type);
    final builtIn = (_type == 'income' ? s.incomeCategoryKeys : s.expenseCategoryKeys)
        .where((k) => !CategoryMeta.custom.containsKey(k))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  const KBackButton(),
                  Expanded(
                    child: Center(
                      child: Text(s('categories'),
                          style: k(17, w: FontWeight.w600)),
                    ),
                  ),
                  KAddButton(
                      onTap: () => showCategoryCreator(context, _type)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: kPad,
              child: KSegmented(
                options: [('expense', s('chiqim')), ('income', s('kirim'))],
                colors: const [KColors.danger, KColors.primary],
                value: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  Text(s('my_categories'), style: k(15, w: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (custom.isEmpty)
                    KCard(
                      onTap: () => showCategoryCreator(context, _type),
                      child: Row(
                        children: [
                          const KTintedIcon(
                              icon: Icons.add_rounded, color: KColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(s('no_custom_categories'),
                                style: k(13, c: KColors.sub, height: 1.4)),
                          ),
                        ],
                      ),
                    )
                  else
                    KCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          for (var i = 0; i < custom.length; i++) ...[
                            _CustomRow(cat: custom[i]),
                            if (i != custom.length - 1)
                              Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: KColors.line),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  Text(s('builtin_categories'),
                      style: k(15, w: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in builtIn)
                        Glass(
                          shadow: const [],
                          borderRadius: BorderRadius.circular(rTile),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CategoryMeta.icon(key),
                                  size: 16, color: CategoryMeta.color(key)),
                              const SizedBox(width: 6),
                              Text(s.cat(key),
                                  style: k(13, w: FontWeight.w500)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomRow extends StatelessWidget {
  final CustomCategory cat;
  const _CustomRow({required this.cat});

  @override
  Widget build(BuildContext context) {
    final p = context.read<AppProvider>();
    final s = p.s;
    return Dismissible(
      key: ValueKey(cat.key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded, color: KColors.danger),
      ),
      onDismissed: (_) => _archive(context, p),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            KTintedIcon(icon: cat.iconData, color: cat.color, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(cat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: k(14.5, w: FontWeight.w600)),
            ),
            KPressable(
              onTap: () => _archive(context, p),
              semanticLabel: s('delete'),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.delete_outline_rounded,
                    size: 20, color: KColors.mut),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _archive(BuildContext context, AppProvider p) {
    final s = p.s;
    p.archiveCategory(cat.key);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(s('category_deleted')),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: s('undo'),
          textColor: const Color(0xFF6EE7B7),
          onPressed: () => p.archiveCategory(cat.key, restore: true),
        ),
      ));
  }
}

/// Yangi kategoriya yaratish oynasi. Yaratilsa — yangi kalitni qaytaradi.
Future<String?> showCategoryCreator(BuildContext context, String type) {
  final p = context.read<AppProvider>();
  final s = p.s;
  final nameCtrl = TextEditingController();
  var icon = CategoryMeta.pickerIcons.keys.first;
  var color = CategoryMeta.pickerColors.first;

  return showKSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setM) {
        Future<void> save() async {
          final name = nameCtrl.text.trim();
          if (name.isEmpty) return;
          final key = await p.addCategory(
              name: name, type: type, icon: icon, color: color.toARGB32());
          if (ctx.mounted) Navigator.pop(ctx, key);
        }

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KSheetHandle(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      // Jonli ko'rinish — tanlangan ikonka va rang
                      AnimatedContainer(
                        duration: KMotion.medium,
                        curve: KMotion.spring,
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: KMotion.fast,
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: Icon(CategoryMeta.pickerIcons[icon],
                              key: ValueKey(icon),
                              color: Colors.white,
                              size: 26),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                            type == 'income'
                                ? s('new_income_category')
                                : s('new_expense_category'),
                            style: k(17, w: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    maxLength: 24,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => save(),
                    style: k(15),
                    decoration: InputDecoration(
                      hintText: s('category_name'),
                      hintStyle: k(15, c: KColors.mut),
                      counterText: '',
                      filled: true,
                      fillColor: KColors.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(rTile),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(s('color'),
                      style: k(13, w: FontWeight.w600, c: KColors.sub)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in CategoryMeta.pickerColors)
                        KPressable(
                          onTap: () => setM(() => color = c),
                          scale: 0.85,
                          child: AnimatedContainer(
                            duration: KMotion.fast,
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: c == color
                                      ? KColors.ink
                                      : Colors.transparent,
                                  width: 2.5),
                            ),
                            child: c == color
                                ? const Icon(Icons.check_rounded,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(s('icon'),
                      style: k(13, w: FontWeight.w600, c: KColors.sub)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (final e in CategoryMeta.pickerIcons.entries)
                        KPressable(
                          onTap: () => setM(() => icon = e.key),
                          scale: 0.85,
                          child: AnimatedContainer(
                            duration: KMotion.fast,
                            decoration: BoxDecoration(
                              color: e.key == icon
                                  ? color.withValues(alpha: 0.18)
                                  : KColors.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: e.key == icon
                                      ? color
                                      : Colors.transparent,
                                  width: 1.5),
                            ),
                            child: Icon(e.value,
                                size: 20,
                                color: e.key == icon ? color : KColors.sub),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  KPrimaryButton(label: s('create'), onTap: save),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
