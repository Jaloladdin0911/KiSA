import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/app_provider.dart';
import 'services/local_database.dart';
import 'theme/app_theme.dart';
import 'widgets/glass.dart';
import 'widgets/kisa_logo.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/transfer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive — barcha ma'lumotlar qurilmada lokal saqlanadi (offline)
  await LocalDatabase.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const KisaApp(),
    ),
  );
}

class KisaApp extends StatefulWidget {
  const KisaApp({super.key});

  @override
  State<KisaApp> createState() => _KisaAppState();
}

class _KisaAppState extends State<KisaApp> with WidgetsBindingObserver {
  final _navKey = GlobalKey<NavigatorState>();
  bool _wasPaused = false;

  /// Ilova faol emas (ilovalar almashtirgichi, bildirishnoma pardasi) — PIN
  /// yoqilgan bo'lsa ekran xiralashtiriladi, balanslar ko'rinib qolmaydi.
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _navKey.currentContext?.read<AppProvider>().onPlatformBrightnessChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final obscure = state != AppLifecycleState.resumed;
    if (obscure != _obscured) setState(() => _obscured = obscure);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      final ctx = _navKey.currentContext;
      if (ctx == null) return;
      final provider = ctx.read<AppProvider>();
      if (provider.pinEnabled && !LockScreen.isShowing) {
        _navKey.currentState?.push(MaterialPageRoute(
            builder: (_) => const LockScreen(asOverlay: true)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Joriy temani global tokenga uzatamiz — butun ilova avtomatik moslashadi
        KColors.isDark = provider.isDarkMode;
        return MaterialApp(
          navigatorKey: _navKey,
          debugShowCheckedModeBanner: false,
          title: 'KiSA',
          theme: kTheme(provider.isDarkMode),
          // Barcha sahifalar shaffof — ortida bitta umumiy aurora fon
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            // Tizimdagi katta shrift qo'llab-quvvatlanadi, lekin 130% dan
            // oshganda kartalar va panel tartibi buzilmasligi uchun cheklanadi
            maxScaleFactor: 1.3,
            child: Stack(
              children: [
                const Positioned.fill(child: KAuroraBackground()),
                if (child != null) child,
                if (_obscured && provider.pinEnabled)
                  const Positioned.fill(child: _PrivacyShield()),
              ],
            ),
          ),
          home: const SplashScreen(),
          routes: {
            '/home': (_) => const MainNavigator(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/register': (_) => const RegisterScreen(),
            '/login': (_) => const LoginScreen(),
            '/lock': (_) => const LockScreen(),
          },
        );
      },
    );
  }
}

/// Fonda ko'rinadigan maxfiylik qalqoni — kuchli xiralashtirish va logo.
class _PrivacyShield extends StatelessWidget {
  const _PrivacyShield();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: ColoredBox(
        color: KColors.base.withValues(alpha: 0.55),
        child: const Center(child: KisaLogo(size: 88)),
      ),
    );
  }
}

// ── Asosiy navigator ────────────────────────────────────────────────────────

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    StatisticsScreen(),
    BudgetScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            KColors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            KColors.isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Kontent suzuvchi panel ostidan ham o'tadi — shisha uni xiralashtiradi
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _screens.length; i++)
              _TabReveal(active: i == _index, child: _screens[i]),
          ],
        ),
        bottomNavigationBar: _KisaNavBar(
          index: _index,
          onTap: (i) => setState(() => _index = i),
          onAdd: () => _showActionSheet(context),
        ),
      ),
    );
  }
}

/// Tab almashganda yangi ekran xiralikdan biroz kattalashib chiqadi.
/// IndexedStack ichida — ekran holati (scroll, filtr) saqlanib qoladi.
class _TabReveal extends StatefulWidget {
  final bool active;
  final Widget child;
  const _TabReveal({required this.active, required this.child});

  @override
  State<_TabReveal> createState() => _TabRevealState();
}

class _TabRevealState extends State<_TabReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: KMotion.medium, value: 1);
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: KMotion.emphasized);

  @override
  void didUpdateWidget(_TabReveal old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: ScaleTransition(
        scale: Tween(begin: 0.97, end: 1.0).animate(_a),
        child: widget.child,
      ),
    );
  }
}

// ── "+" bosilganda amal turini tanlash menyusi ────────────────────────────

void _showActionSheet(BuildContext context) {
  final s = context.read<AppProvider>().s;
  void open(Widget screen) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  final actions = [
    (Icons.north_east_rounded, KColors.danger, s('chiqim'),
        const AddTransactionScreen(initialType: 'expense')),
    (Icons.south_west_rounded, KColors.primary, s('kirim'),
        const AddTransactionScreen(initialType: 'income')),
    (Icons.swap_horiz_rounded, KColors.blue, s('transfer'),
        const TransferScreen()),
    (Icons.currency_exchange_rounded, KColors.purple, s('exchange'),
        const TransferScreen(initialMode: 'exchange')),
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
            Text(s('choose_action'), style: k(18, w: FontWeight.w700)),
            const SizedBox(height: 16),
            // 2×2 shisha plitkalar, navbatma-navbat paydo bo'ladi
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                for (var i = 0; i < actions.length; i++)
                  KFadeSlideIn.stagger(
                    i,
                    child: _ActionTile(
                      icon: actions[i].$1,
                      color: actions[i].$2,
                      label: actions[i].$3,
                      onTap: () => open(actions[i].$4),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KPressable(
      onTap: onTap,
      child: Glass(
        color: color.withValues(alpha: KColors.isDark ? 0.14 : 0.10),
        shadow: const [],
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k(14.5, w: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Suzuvchi shisha navigatsiya paneli ────────────────────────────────────────
//
// Tanlangan tab ortida "suyuq tomchi" turadi: tab almashganda u yangi joyga
// siljiydi va yo'lda cho'ziladi, joyiga yetganda prujina bilan siqiladi.

class _KisaNavBar extends StatefulWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  const _KisaNavBar(
      {required this.index, required this.onTap, required this.onAdd});

  @override
  State<_KisaNavBar> createState() => _KisaNavBarState();
}

class _KisaNavBarState extends State<_KisaNavBar>
    with SingleTickerProviderStateMixin {
  // 5 ta joy: tab0, tab1, [+], tab2, tab3
  static int _slot(int tab) => tab < 2 ? tab : tab + 1;

  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late double _from = _slot(widget.index).toDouble();
  late double _to = _from;

  @override
  void didUpdateWidget(_KisaNavBar old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _from = _current;
      _to = _slot(widget.index).toDouble();
      _c.forward(from: 0);
    }
  }

  double get _current {
    final t = KMotion.spring.transform(_c.value);
    return _from + (_to - _from) * t;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    final items = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home_rounded, s('nav_home')),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, s('nav_stats')),
      (Icons.account_balance_wallet_outlined,
          Icons.account_balance_wallet_rounded, s('nav_budget')),
      (Icons.person_outline_rounded, Icons.person_rounded, s('nav_profile')),
    ];

    Widget tab(int i) {
      final selected = i == widget.index;
      final color = selected ? KColors.primary : KColors.sub;
      return Expanded(
        child: KPressable(
          onTap: () => widget.onTap(i),
          scale: 0.85,
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: KMotion.fast,
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Icon(selected ? items[i].$2 : items[i].$1,
                      key: ValueKey(selected), size: 24, color: color),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: KMotion.fast,
                  style: k(10.5,
                      w: selected ? FontWeight.w700 : FontWeight.w500,
                      c: color),
                  child: Text(items[i].$3,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Glass(
          blur: true,
          sigma: 28,
          color: KColors.sheet.withValues(alpha: KColors.isDark ? 0.62 : 0.55),
          shadow: kCardShadow,
          borderRadius: BorderRadius.circular(34),
          child: SizedBox(
            height: 68,
            child: LayoutBuilder(
              builder: (context, box) {
                final slotW = box.maxWidth / 5;
                return Stack(
                  children: [
                    // Suyuq tomchi
                    AnimatedBuilder(
                      animation: _c,
                      builder: (_, __) {
                        // Harakat o'rtasida cho'ziladi (sin), oxirida asl holi
                        final stretch = math.sin(math.pi * _c.value).abs();
                        final w = slotW - 10 + stretch * slotW * 0.45;
                        final h = 52 - stretch * 6;
                        final cx = (_current + 0.5) * slotW;
                        return Positioned(
                          left: cx - w / 2,
                          top: (68 - h) / 2,
                          width: w,
                          height: h,
                          child: Container(
                            decoration: BoxDecoration(
                              color: KColors.primary.withValues(
                                  alpha: KColors.isDark ? 0.20 : 0.13),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                  color: KColors.primary
                                      .withValues(alpha: 0.18)),
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        tab(0),
                        tab(1),
                        Expanded(child: Center(child: _AddOrb(onTap: widget.onAdd, label: s('choose_action')))),
                        tab(2),
                        tab(3),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Markazdagi "+" — gradient shisha shar, sekin "nafas oladi".
class _AddOrb extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  const _AddOrb({required this.onTap, required this.label});

  @override
  State<_AddOrb> createState() => _AddOrbState();
}

class _AddOrbState extends State<_AddOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KPressable(
      onTap: widget.onTap,
      scale: 0.86,
      semanticLabel: widget.label,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) => Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: KColors.gradStart
                    .withValues(alpha: 0.30 + 0.18 * _glow.value),
                blurRadius: 14 + 8 * _glow.value,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
        child: Glass(
          tint: kGradient,
          shadow: const [],
          borderRadius: BorderRadius.circular(26),
          child: const SizedBox.expand(
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
