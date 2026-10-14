import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../l10n/app_strings.dart';
import '../services/app_provider.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kit.dart';
import 'accounts_screen.dart';
import 'security_screen.dart';
import 'recurring_screen.dart';
import 'categories_screen.dart';

/// Profil — KISA_DESIGN_SPEC.md, Section 10.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _mln(double v) {
    final a = v.abs();
    if (a >= 1e6) {
      return '${(v / 1e6).toStringAsFixed(1).replaceAll('.', ',')} mln';
    }
    if (a >= 1e3) return '${(v / 1e3).toStringAsFixed(0)} ming';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
            children: [
              Text(s('nav_profile'), style: k(22, w: FontWeight.w700)),
              const SizedBox(height: 18),

              // Profil header
              KCard(
                radius: rCardLg,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                          color: Color(0xFFE2E8F0), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(_initials(provider.userName),
                          style:
                              k(20, w: FontWeight.w700, c: const Color(0xFF475569))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(provider.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: k(16, w: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(provider.phone ?? s('local_account'),
                              style: k(12.5, c: KColors.sub)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _profileDialog(context, provider),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: KColors.greenBg, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_outlined,
                            size: 17, color: KColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Stats
              KCard(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    _stat(_mln(provider.currencyBalance('UZS')),
                        s('balance_label')),
                    _vline(),
                    _stat('2', s('cards_label')),
                    _vline(),
                    _stat('${provider.goals.length}', s('goals')),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              _label(s('section_account')),
              KCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _row(Icons.person_outline_rounded, KColors.blue,
                        s('personal_info'),
                        onTap: () => _profileDialog(context, provider)),
                    _divider(),
                    _row(Icons.credit_card_rounded, KColors.primary,
                        s('my_cards'),
                        value: '2',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AccountsScreen()))),
                    _divider(),
                    _row(Icons.shield_outlined, KColors.purple, s('security'),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SecurityScreen()))),
                    _divider(),
                    _row(Icons.event_repeat_rounded, KColors.orange,
                        s('recurring'),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RecurringScreen()))),
                    _divider(),
                    _row(Icons.category_rounded, KColors.pink,
                        s('categories'),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CategoriesScreen()))),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              _label(s('section_settings')),
              KCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _toggleRow(Icons.notifications_none_rounded, KColors.orange,
                        s('notifications'), provider.notificationsEnabled,
                        (v) => _toggleNotif(context, provider, v)),
                    _divider(),
                    _row(Icons.language_rounded, KColors.blue, s('language'),
                        value: kLanguageNames[provider.language] ?? "O'zbek",
                        onTap: () => _languageSheet(context, provider, s)),
                    _divider(),
                    _row(Icons.contrast_rounded, KColors.indigo, s('theme'),
                        value: s('theme_${provider.themeMode}'),
                        onTap: () => _themeSheet(context, provider)),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              _label(s('section_data')),
              KCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _row(Icons.backup_outlined, KColors.blue,
                        s('backup_create'),
                        value: 'JSON',
                        onTap: () => BackupService.share(provider.toBackup())),
                    _divider(),
                    _row(Icons.settings_backup_restore_rounded, KColors.purple,
                        s('backup_restore'),
                        onTap: () => _restore(context, provider)),
                    _divider(),
                    _row(Icons.ios_share_rounded, KColors.primary,
                        s('export_data'),
                        value: 'CSV', onTap: () => _export(context, provider)),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              _label(s('about_app').toUpperCase()),
              KCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _row(Icons.privacy_tip_outlined, KColors.indigo,
                        s('privacy_policy'),
                        onTap: () => _openPrivacy(context, provider)),
                    _divider(),
                    _row(Icons.info_outline_rounded, KColors.mut,
                        s('version'),
                        value: kAppVersion),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(s('offline_promise'),
                    textAlign: TextAlign.center,
                    style: k(11.5, c: KColors.mut, height: 1.4)),
              ),
              const SizedBox(height: 22),

              // Chiqish — sessiyani yopadi, ma'lumotlar saqlanib qoladi
              KCard(
                padding: EdgeInsets.zero,
                onTap: () => _logoutDialog(context, provider),
                child: _row(Icons.logout_rounded, KColors.danger, s('logout'),
                    labelColor: KColors.danger),
              ),
              const SizedBox(height: 12),

              // Barcha ma'lumotlarni o'chirish — qaytarib bo'lmaydi
              KCard(
                padding: EdgeInsets.zero,
                onTap: () => _clearDialog(context, provider),
                child: _row(Icons.delete_outline_rounded, KColors.danger,
                    s('clear_all'),
                    labelColor: KColors.danger),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value, style: k(16, w: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: k(11, c: KColors.mut)),
          ],
        ),
      );

  Widget _vline() =>
      Container(width: 1, height: 30, color: KColors.line);

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text,
            style: k(11, w: FontWeight.w600, c: KColors.mut, ls: 0.6)),
      );

  Widget _divider() => Padding(
        padding: const EdgeInsets.only(left: 60),
        child: Divider(height: 1, thickness: 1, color: KColors.line),
      );

  Widget _row(IconData icon, Color color, String label,
      {String? value, VoidCallback? onTap, Color? labelColor}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            KTintedIcon(icon: icon, color: color, size: 32, circle: false),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      k(14, w: FontWeight.w500, c: labelColor ?? KColors.ink)),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k(12.5, c: KColors.mut)),
              ),
              const SizedBox(width: 6),
            ],
            if (labelColor == null && onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: KColors.mut),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(IconData icon, Color color, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          KTintedIcon(icon: icon, color: color, size: 32, circle: false),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k(14, w: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          _KToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'K';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.elementAt(1).characters.first)
        .toUpperCase();
  }

  void _profileDialog(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController(text: provider.userName);
    final phoneCtrl = TextEditingController(
        text: (provider.phone ?? '').replaceFirst('+998', ''));
    showKDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(provider.s('personal_info'),
            style: k(16, w: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: k(15),
              decoration: InputDecoration(
                labelText: provider.s('name_label'),
                filled: true,
                fillColor: KColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(rTile),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              style: k(15),
              decoration: InputDecoration(
                prefixText: '+998 ',
                labelText: provider.s('phone_number'),
                filled: true,
                fillColor: KColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(rTile),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(provider.s('cancel'), style: k(14, c: KColors.sub))),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                provider.setUserName(nameCtrl.text.trim());
              }
              if (phoneCtrl.text.trim().length == 9) {
                provider.setPhone('+998${phoneCtrl.text.trim()}');
              }
              Navigator.pop(ctx);
            },
            child: Text(provider.s('save'),
                style: k(14, w: FontWeight.w600, c: KColors.primary)),
          ),
        ],
      ),
    );
  }

  void _logoutDialog(BuildContext context, AppProvider provider) {
    showKDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(provider.s('logout'), style: k(16, w: FontWeight.w700)),
        content: Text(provider.s('logout_confirm'),
            style: k(13.5, c: KColors.sub, height: 1.4)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(provider.s('cancel'), style: k(14, c: KColors.sub))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: Text(provider.s('logout'),
                style: k(14, w: FontWeight.w600, c: KColors.danger)),
          ),
        ],
      ),
    );
  }

  void _languageSheet(
      BuildContext context, AppProvider provider, AppStrings s) {
    showKSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(s('language'), style: k(18, w: FontWeight.w700)),
            const SizedBox(height: 10),
            ...kLanguageNames.entries.map((e) {
              final sel = e.key == provider.language;
              return GestureDetector(
                onTap: () {
                  provider.setLanguage(e.key);
                  Navigator.pop(ctx);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Text(e.value,
                          style: k(15,
                              w: sel ? FontWeight.w600 : FontWeight.w500,
                              c: sel ? KColors.primary : KColors.ink)),
                      const Spacer(),
                      if (sel)
                        const Icon(Icons.check_rounded,
                            color: KColors.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _clearDialog(BuildContext context, AppProvider provider) {
    showKDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(provider.s('clear_all'),
            style: k(16, w: FontWeight.w700, c: KColors.danger)),
        content: Text(provider.s('clear_confirm'),
            style: k(13.5, c: KColors.sub, height: 1.4)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(provider.s('cancel'), style: k(14, c: KColors.sub))),
          TextButton(
            onPressed: () {
              provider.clearAllData();
              Navigator.pop(ctx);
            },
            child: Text(provider.s('delete'),
                style: k(14, w: FontWeight.w600, c: KColors.danger)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotif(
      BuildContext context, AppProvider provider, bool v) async {
    if (v) {
      final t = await showTimePicker(
          context: context, initialTime: provider.reminderTime);
      if (t == null) return;
      final ok =
          await provider.setNotifications(true, hour: t.hour, minute: t.minute);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(provider.s('notif_denied'))));
      } else if (ok && context.mounted) {
        final hh = t.hour.toString().padLeft(2, '0');
        final mm = t.minute.toString().padLeft(2, '0');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${provider.s('reminder_set')} · $hh:$mm')));
      }
    } else {
      provider.setNotifications(false);
    }
  }

  void _export(BuildContext context, AppProvider provider) {
    if (provider.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.s('export_empty'))));
      return;
    }
    ExportService.exportTransactions(provider.transactions, provider.s);
  }

  Future<void> _openPrivacy(BuildContext context, AppProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(kPrivacyPolicyUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) {
      messenger.showSnackBar(
          const SnackBar(content: Text(kPrivacyPolicyUrl)));
    }
  }

  /// Tema tanlash: Tizim / Yorug' / To'q — har biri kichik "oyna" ko'rinishida.
  void _themeSheet(BuildContext context, AppProvider provider) {
    final s = provider.s;
    const modes = [
      ('system', Icons.brightness_auto_rounded),
      ('light', Icons.light_mode_rounded),
      ('dark', Icons.dark_mode_rounded),
    ];
    showKSheet(
      context: context,
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KSheetHandle(),
              const SizedBox(height: 18),
              Text(s('theme'), style: k(18, w: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var i = 0; i < modes.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeOption(
                        icon: modes[i].$2,
                        label: s('theme_${modes[i].$1}'),
                        selected: provider.themeMode == modes[i].$1,
                        onTap: () {
                          provider.setThemeMode(modes[i].$1);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Zaxira faylni tanlash → tasdiqlash → joriy ma'lumotlarni almashtirish.
  Future<void> _restore(BuildContext context, AppProvider provider) async {
    final s = provider.s;
    void snack(String m) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(m)));
      }
    }

    final Map<String, dynamic>? data;
    try {
      data = await BackupService.pick();
    } catch (_) {
      snack(s('backup_invalid'));
      return;
    }
    if (data == null || !context.mounted) return;

    final ok = await showKDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('backup_restore'), style: k(16, w: FontWeight.w700)),
        content: Text(s('backup_restore_confirm'),
            style: k(13.5, c: KColors.sub, height: 1.4)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s('cancel'), style: k(14, c: KColors.sub))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s('restore'),
                style: k(14, w: FontWeight.w600, c: KColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final n = await provider.restoreBackup(data);
      snack(provider.s('backup_restored').replaceAll('{n}', '$n'));
    } on FormatException {
      snack(s('backup_invalid'));
    }
  }

}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: KMotion.medium,
        curve: KMotion.spring,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? KColors.primary.withValues(alpha: 0.14)
              : KColors.bg,
          borderRadius: BorderRadius.circular(rCard),
          border: Border.all(
              color: selected ? KColors.primary : Colors.transparent,
              width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 26, color: selected ? KColors.primary : KColors.sub),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k(13,
                    w: selected ? FontWeight.w700 : FontWeight.w500,
                    c: selected ? KColors.primary : KColors.ink)),
          ],
        ),
      ),
    );
  }
}

/// 44×26 toggle.
class _KToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _KToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? KColors.primary : KColors.mut.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Color(0x1A000000),
                  offset: Offset(0, 1),
                  blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }
}
