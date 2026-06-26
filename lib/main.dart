import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/app_provider.dart';
import 'services/local_database.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_transaction_screen.dart';

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

class KisaApp extends StatelessWidget {
  const KisaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KiSA',
        theme: ThemeData(
          scaffoldBackgroundColor: KColors.bg,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: KColors.primary,
            primary: KColors.primary,
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/home': (_) => const MainNavigator(),
          '/onboarding': (_) => const OnboardingScreen(),
        },
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

  final _screens = const [
    DashboardScreen(),
    StatisticsScreen(),
    BudgetScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: KColors.bg,
        body: IndexedStack(index: _index, children: _screens),
        floatingActionButton: _Fab(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _KisaNavBar(
          index: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          gradient: kGradient,
          shape: BoxShape.circle,
          boxShadow: kFabShadow,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

// ── Maxsus navigatsiya paneli ─────────────────────────────────────────────────

class _KisaNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _KisaNavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (Icons.home_rounded, 'Asosiy'),
      (Icons.bar_chart_rounded, 'Statistika'),
      (Icons.credit_card_rounded, 'Byudjet'),
      (Icons.person_rounded, 'Profil'),
    ];

    Widget tab(int i) {
      final selected = i == index;
      final color = selected ? KColors.primary : KColors.mut;
      return Expanded(
        child: GestureDetector(
          onTap: () => onTap(i),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 5,
                child: selected
                    ? Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: KColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              Icon(items[i].$1, size: 24, color: color),
              const SizedBox(height: 3),
              Text(items[i].$2,
                  style: k(10,
                      w: selected ? FontWeight.w600 : FontWeight.w500,
                      c: color)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: KColors.card,
        boxShadow: [
          BoxShadow(
              color: Color(0x0D0F172A), offset: Offset(0, -6), blurRadius: 16),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              tab(0),
              tab(1),
              const SizedBox(width: 64), // FAB uchun joy
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}
