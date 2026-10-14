import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kisa_logo.dart';
import '../widgets/kit.dart';

/// Ro'yxatdan o'tish — ism va telefon raqamni lokal saqlaydi. Backend/SMS
/// yo'q (to'liq offline ilova) — raqam faqat qurilmada "Kirish" uchun
/// taqqoslanadi.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _err(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    final provider = context.read<AppProvider>();
    final s = provider.s;
    final name = _name.text.trim();
    final digits = _phone.text.trim();
    if (name.isEmpty) {
      _err(s('fill_fields'));
      return;
    }
    if (digits.length != 9) {
      _err(s('invalid_phone'));
      return;
    }
    await provider.register(name, '+998$digits');
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const KisaLogo(size: 84),
                const SizedBox(height: 24),
                Text(s('register'), style: k(24, w: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(s('app_tagline'), style: k(14, c: KColors.sub)),
                const SizedBox(height: 32),
                _AuthField(
                  controller: _name,
                  label: s('name_label'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                _PhoneField(controller: _phone),
                const SizedBox(height: 26),
                _AuthButton(label: s('register'), onTap: _submit),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  child: Text.rich(
                    TextSpan(
                      text: s('have_account'),
                      style: k(14, c: KColors.sub),
                      children: [
                        TextSpan(
                          text: s('login'),
                          style: k(14, w: FontWeight.w600, c: KColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kirish — saqlangan telefon raqamga taqqoslaydi (haqiqiy SMS tasdiqlovsiz).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _err(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    final provider = context.read<AppProvider>();
    final s = provider.s;
    final digits = _phone.text.trim();
    if (digits.length != 9) {
      _err(s('invalid_phone'));
      return;
    }
    final ok = await provider.login('+998$digits');
    if (!mounted) return;
    if (!ok) {
      _err(s('login_not_found'));
      return;
    }
    final target = provider.pinEnabled ? '/lock' : '/home';
    Navigator.of(context).pushNamedAndRemoveUntil(target, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const KisaLogo(size: 84),
                const SizedBox(height: 24),
                Text(s('login'), style: k(24, w: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(s('app_tagline'), style: k(14, c: KColors.sub)),
                const SizedBox(height: 32),
                _PhoneField(controller: _phone),
                const SizedBox(height: 26),
                _AuthButton(label: s('login'), onTap: _submit),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/register'),
                  child: Text.rich(
                    TextSpan(
                      text: s('no_account'),
                      style: k(14, c: KColors.sub),
                      children: [
                        TextSpan(
                          text: s('register'),
                          style: k(14, w: FontWeight.w600, c: KColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Umumiy: maydonlar va tugma ────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextCapitalization textCapitalization;
  const _AuthField({
    required this.controller,
    required this.label,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: k(15),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: KColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rTile),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      style: k(15),
      decoration: InputDecoration(
        prefixText: '+998 ',
        prefixStyle: k(15, w: FontWeight.w600),
        labelText: s('phone_number'),
        hintText: '90 123 45 67',
        filled: true,
        fillColor: KColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rTile),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AuthButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) =>
      KPrimaryButton(label: label, onTap: onTap);
}
