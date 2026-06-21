import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kisa_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_error != null) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _validEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  Future<void> _login() async {
    final s = context.read<AppProvider>().s;
    if (_loginEmailCtrl.text.trim().isEmpty || _loginPassCtrl.text.isEmpty) {
      setState(() => _error = s('fill_fields'));
      return;
    }
    if (!_validEmail(_loginEmailCtrl.text.trim())) {
      setState(() => _error = s('invalid_email'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signIn(
        email: _loginEmailCtrl.text.trim(),
        password: _loginPassCtrl.text,
      );
      if (mounted) await context.read<AppProvider>().init();
      _goHome();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final s = context.read<AppProvider>().s;
    if (_regNameCtrl.text.trim().isEmpty ||
        _regEmailCtrl.text.trim().isEmpty ||
        _regPassCtrl.text.isEmpty) {
      setState(() => _error = s('fill_fields'));
      return;
    }
    if (!_validEmail(_regEmailCtrl.text.trim())) {
      setState(() => _error = s('invalid_email'));
      return;
    }
    if (_regPassCtrl.text.length < 6) {
      setState(() => _error = s('password_short'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signUp(
        email: _regEmailCtrl.text.trim(),
        password: _regPassCtrl.text,
      );
      await _authService.updateDisplayName(_regNameCtrl.text.trim());
      if (mounted) await context.read<AppProvider>().init();
      _goHome();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppProvider>().s;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              const SizedBox(height: 28),
              const KisaLogo(size: 84),
              const SizedBox(height: 20),
              Text('KiSA', style: context.t.headlineMedium),
              const SizedBox(height: 4),
              Text(s('financial_manager'), style: context.t.bodyMedium),
              const SizedBox(height: 32),

              // Tab almashtirgich
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: c.textPrimary,
                  unselectedLabelColor: c.textSecondary,
                  labelStyle: context.t.titleSmall,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  splashBorderRadius: BorderRadius.circular(AppRadius.sm),
                  indicator: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: AppShadows.card(context.isDark),
                  ),
                  tabs: [
                    Tab(text: s('login')),
                    Tab(text: s('register')),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.expense.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.expense, size: 19),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: context.t.bodySmall
                                ?.copyWith(color: AppColors.expense)),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                height: 312,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Login
                    Column(
                      children: [
                        _InputField(
                          controller: _loginEmailCtrl,
                          label: s('email'),
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _InputField(
                          controller: _loginPassCtrl,
                          label: s('password'),
                          icon: Icons.lock_outline,
                          obscure: _obscurePass,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: c.textTertiary,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              if (_loginEmailCtrl.text.isNotEmpty) {
                                _authService
                                    .resetPassword(_loginEmailCtrl.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(s('email_sent'))),
                                );
                              }
                            },
                            child: Text(s('forgot_password'),
                                style: const TextStyle(
                                    color: AppColors.brand,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _AuthButton(
                            label: s('login'),
                            loading: _loading,
                            onPressed: _login),
                      ],
                    ),

                    // Register
                    Column(
                      children: [
                        _InputField(
                          controller: _regNameCtrl,
                          label: s('your_name_field'),
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _InputField(
                          controller: _regEmailCtrl,
                          label: s('email'),
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _InputField(
                          controller: _regPassCtrl,
                          label: s('min_6_chars'),
                          icon: Icons.lock_outline,
                          obscure: _obscurePass,
                        ),
                        const SizedBox(height: 20),
                        _AuthButton(
                            label: s('register'),
                            loading: _loading,
                            onPressed: _register),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await context.read<AppProvider>().init();
                  _goHome();
                },
                child: Text(s('continue_offline'),
                    style: TextStyle(color: c.textSecondary, fontSize: 13.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.4),
              )
            : Text(label),
      ),
    );
  }
}
