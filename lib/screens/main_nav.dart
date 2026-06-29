import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'expenses_screen.dart';
import 'analytics_screen.dart';
import 'reports_screen.dart';
import 'goals_screen.dart';
import 'about_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    ExpensesScreen(),
    AnalyticsScreen(),
    ReportsScreen(),
    GoalsScreen(),
  ];

  static const _items = [
    _NavDef(Icons.home_rounded,           Icons.home_outlined,            'Início'),
    _NavDef(Icons.receipt_long_rounded,   Icons.receipt_long_outlined,    'Histórico'),
    _NavDef(Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Despesas'),
    _NavDef(Icons.insights_rounded,       Icons.insights_outlined,        'Análise'),
    _NavDef(Icons.bar_chart_rounded,      Icons.bar_chart_outlined,       'Relatórios'),
    _NavDef(Icons.flag_rounded,           Icons.flag_outlined,            'Metas'),
  ];

  void _openAbout() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AboutScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _BottomBar(
        currentIndex: _index,
        items: _items,
        onTap: (i) => setState(() => _index = i),
        onLongPressLast: _openAbout,
      ),
    );
  }
}

class _NavDef {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavDef(this.activeIcon, this.icon, this.label);
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavDef> items;
  final void Function(int) onTap;
  final VoidCallback? onLongPressLast;

  const _BottomBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.onLongPressLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final item = items[i];
              final isLast = i == items.length - 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  onLongPress: isLast ? onLongPressLast : null,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: selected ? 20 : 0,
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          color: selected ? AppColors.primary : AppColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: selected ? AppColors.primary : AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            letterSpacing: selected ? 0.2 : 0,
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
