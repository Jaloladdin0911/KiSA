import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    LockScreen.isShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AppProvider>().biometricEnabled) _biometric();
    });
  }

  @override
  void dispose() {
    LockScreen.isShowing = false;
    super.dispose();
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

  void _onKey(String key) {
    final provider = context.read<AppProvider>();
    setState(() {
      _error = false;
      if (key == 'back') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (key == 'bio') {
        _biometric();
      } else if (_pin.length < 4) {
        _pin += key;
        if (_pin.length == 4) {
          if (provider.verifyPin(_pin)) {
            _unlock();
          } else {
            _error = true;
            _pin = '';
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final bio = provider.biometricEnabled;
    return Scaffold(
      backgroundColor: KColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            const KisaLogo(size: 80),
            const SizedBox(height: 24),
            Text(_error ? provider.s('wrong_pin') : provider.s('enter_pin'),
                style: k(16,
                    w: FontWeight.w600,
                    c: _error ? KColors.danger : KColors.ink)),
            const SizedBox(height: 24),
            PinDots(length: _pin.length, error: _error),
            const Spacer(flex: 2),
            PinKeypad(onKey: _onKey, showBiometric: bio),
            const SizedBox(height: 20),
          ],
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
      backgroundColor: KColors.bg,
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
          childAspectRatio: 1.4,
        ),
        itemBuilder: (_, i) {
          final key = keys[i];
          if (key.isEmpty) return const SizedBox();
          return GestureDetector(
            onTap: () => onKey(key),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: key == 'back'
                  ? Icon(Icons.backspace_outlined, size: 24, color: KColors.ink)
                  : key == 'bio'
                      ? const Icon(Icons.fingerprint_rounded,
                          size: 30, color: KColors.primary)
                      : Text(key, style: k(28, w: FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }
}
