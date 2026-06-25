import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/app_provider.dart';
import 'services/local_database.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/transaction_card.dart';

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
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreen(),
        routes: {
          '/home': (_) => const MainNavigator(),
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
    GoalsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle(context.isDark),
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              showAddActionSheet(context, context.read<AppProvider>()),
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 30),
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

// ── Maxsus navigatsiya paneli ─────────────────────────────────────────────────

class _KisaNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _KisaNavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final provider = context.watch<AppProvider>();
    final s = provider.s;

    final items = [
      (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, s('nav_home')),
      (Icons.insights_outlined, Icons.insights, s('nav_stats')),
      (Icons.flag_outlined, Icons.flag, s('nav_goals')),
      (Icons.person_outline, Icons.person, s('nav_settings')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == index;
              final item = items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 5),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.brand.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Icon(
                            selected ? item.$2 : item.$1,
                            size: 23,
                            color: selected ? AppColors.brand : c.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? AppColors.brand : c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
