import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kit.dart';
import '../widgets/kisa_logo.dart';

/// Qulf ekrani — ilova ochilganda yoki fon'dan qaytganda PIN/biometrik so'raydi.
class LockScreen extends StatefulWidget {
  /// true bo'lsa — overlay (fon'dan qaytishda), unlock pop qiladi.
  /// false bo'lsa — ilk ishga tushish, unlock /home ga o'tadi.
  final bool asOverlay;
  const LockScreen({super.key, this.asOverlay = false});

  /// Hozir qulf ekrani ko'rinib turibdimi (takror ochilmasligi uchun).
  static bool isShowing = false;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = LocalAuthentication();
  String _pin = '';
  bool _error = false;
  bool _checking = false;
  int _shakes = 0; // har xato PIN'da oshadi — silkinish animatsiyasi
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    LockScreen.isShowing = true;
    _startLockTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AppProvider>().biometricEnabled) _biometric();
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    LockScreen.isShowing = false;
    super.dispose();
  }

  /// Bloklangan bo'lsa, qolgan vaqtni har soniyada yangilab turadi.
  void _startLockTimer() {
    _lockTimer?.cancel();
    if (context.read<AppProvider>().pinLockRemaining == null) return;
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {});
      if (context.read<AppProvider>().pinLockRemaining == null) t.cancel();
    });
  }

  Future<void> _biometric() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: context.read<AppProvider>().s('unlock_reason'),
        options: const AuthenticationOptions(
            biometricOnly: true, stickyAuth: true),
      );
      if (ok && mounted) _unlock();
    } catch (_) {}
  }

  void _unlock() {
    if (widget.asOverlay) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _onKey(String key) async {
    final provider = context.read<AppProvider>();
    if (key == 'bio') {
      _biometric();
      return;
    }
    if (_checking || provider.pinLockRemaining != null) return;
    setState(() {
      _error = false;
      if (key == 'back') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 4) {
        _pin += key;
      }
    });
    if (_pin.length < 4) return;

    _checking = true;
    final ok = await provider.verifyPin(_pin);
    _checking = false;
    if (!mounted) return;
    if (ok) {
      _unlock();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = true;
        _pin = '';
        _shakes++;
      });
      _startLockTimer();
    }
  }

  /// PIN unutildi — ro'yxatdan o'tilgan telefon raqami bilan tiklash.
  void _forgotPin(BuildContext context, AppProvider provider) {
    final s = provider.s;
    final ctrl = TextEditingController();
    String? error;
    showKSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          Future<void> submit() async {
            final ok = await provider.resetPinWithPhone('+998${ctrl.text.trim()}');
            if (!ctx.mounted) return;
            if (!ok) {
              setM(() => error = s('login_not_found'));
              return;
            }
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s('pin_reset_done'))));
            _unlock();
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KSheetHandle(),
                    const SizedBox(height: 18),
                    Text(s('forgot_pin'), style: k(17, w: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(s('forgot_pin_hint'),
                        style: k(12.5, c: KColors.sub, height: 1.4)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      onSubmitted: (_) => submit(),
                      style: k(16),
                      decoration: InputDecoration(
                        prefixText: '+998 ',
                        prefixStyle: k(16, w: FontWeight.w600),
                        hintText: '90 123 45 67',
                        errorText: error,
                        filled: true,
                        fillColor: KColors.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(rTile),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    KPrimaryButton(label: s('reset_pin'), onTap: submit),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final bio = provider.biometricEnabled;
    final locked = provider.pinLockRemaining;
    final String title;
    if (locked != null) {
      title = provider
          .s('pin_locked')
          .replaceAll('{s}', '${locked.inSeconds + 1}');
    } else {
      title = _error ? provider.s('wrong_pin') : provider.s('enter_pin');
    }
    final isRed = locked != null || _error;
    // Orqaga tugmasi / iOS surish qulfni yopmasligi kerak — aks holda PIN'siz
    // ilovaga kirib bo'lardi.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const KisaLogo(size: 80),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: k(16,
                        w: FontWeight.w600,
                        c: isRed ? KColors.danger : KColors.ink)),
              ),
              const SizedBox(height: 24),
              // Xato PIN — nuqtalar chapga-o'ngga silkinadi
              TweenAnimationBuilder<double>(
                key: ValueKey(_shakes),
                tween: Tween(begin: _shakes == 0 ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 480),
                builder: (_, t, child) => Transform.translate(
                  offset: Offset(math.sin(t * math.pi * 6) * 12 * (1 - t), 0),
                  child: child,
                ),
                child: PinDots(length: _pin.length, error: isRed),
              ),
              const Spacer(flex: 2),
              PinKeypad(onKey: _onKey, showBiometric: bio),
              const SizedBox(height: 8),
              KPressable(
                onTap: () => _forgotPin(context, provider),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(provider.s('forgot_pin'),
                      style: k(13.5, w: FontWeight.w600, c: KColors.primary)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Yangi PIN o'rnatish (ikki bosqich) ────────────────────────────────────────

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String? _first;
  bool _error = false;

  void _onKey(String key) {
    setState(() {
      _error = false;
      if (key == 'back') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (key != 'bio' && _pin.length < 4) {
        _pin += key;
        if (_pin.length == 4) {
          if (_first == null) {
            _first = _pin;
            _pin = '';
          } else if (_first == _pin) {
            context.read<AppProvider>().setPin(_pin);
            Navigator.of(context).pop(true);
          } else {
            _error = true;
            _first = null;
            _pin = '';
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
                child: IconButton(
                  icon: Icon(Icons.chevron_left_rounded,
                      size: 28, color: KColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            const Spacer(flex: 2),
            Text(
              _error
                  ? s('pin_mismatch')
                  : (_first == null ? s('new_pin') : s('repeat_pin')),
              style: k(17,
                  w: FontWeight.w600,
                  c: _error ? KColors.danger : KColors.ink),
            ),
            const SizedBox(height: 24),
            PinDots(length: _pin.length, error: _error),
            const Spacer(flex: 2),
            PinKeypad(onKey: _onKey, showBiometric: false),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Umumiy: nuqtalar va klaviatura ────────────────────────────────────────────

class PinDots extends StatelessWidget {
  final int length;
  final bool error;
  const PinDots({super.key, required this.length, this.error = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < length;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? (error ? KColors.danger : KColors.primary)
                : Colors.transparent,
            border: Border.all(
              color: error
                  ? KColors.danger
                  : (filled ? KColors.primary : KColors.mut),
              width: 1.6,
            ),
          ),
        );
      }),
    );
  }
}

class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final bool showBiometric;
  const PinKeypad({super.key, required this.onKey, this.showBiometric = false});

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      showBiometric ? 'bio' : '',
      '0', 'back',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.25,
        ),
        itemBuilder: (_, i) {
          final key = keys[i];
          if (key.isEmpty) return const SizedBox();
          final isDigit = key != 'back' && key != 'bio';
          final icon = key == 'back'
              ? Icon(Icons.backspace_outlined, size: 24, color: KColors.ink)
              : key == 'bio'
                  ? const Icon(Icons.fingerprint_rounded,
                      size: 32, color: KColors.primary)
                  : Text(key, style: k(28, w: FontWeight.w500));
          // Raqamlar — iOS uslubidagi shisha doiralar
          return Center(
            child: KPressable(
              onTap: () => onKey(key),
              scale: 0.86,
              child: SizedBox(
                width: 72,
                height: 72,
                child: isDigit
                    ? Glass(
                        borderRadius: BorderRadius.circular(36),
                        child: Center(child: icon),
                      )
                    : Center(child: icon),
              ),
            ),
          );
        },
      ),
    );
  }
}
