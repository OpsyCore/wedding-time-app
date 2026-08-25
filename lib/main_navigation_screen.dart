import 'package:flutter/material.dart';

import 'core/app_lang.dart';
import 'core/app_theme.dart';
import 'core/app_theme_controller.dart';
import 'screens/budget_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/checklist_screen.dart';
import 'screens/guests_screen.dart';
import 'screens/home_screen.dart';
import 'screens/seating_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String weddingId;

  const MainNavigationScreen({super.key, required this.weddingId});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  void _goToTab(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        // داخل builder ساخته شد تا با تغییر زبان/تم، خود تب‌ها هم آپدیت شوند.
        final pages = [
          HomeScreen(
            weddingId: widget.weddingId,
            onNavigateToTab: _goToTab,
          ),
          ChecklistScreen(weddingId: widget.weddingId),
          BudgetScreen(weddingId: widget.weddingId),
          SeatingScreen(weddingId: widget.weddingId),
          GuestsScreen(weddingId: widget.weddingId),
          CalendarScreen(weddingId: widget.weddingId),
        ];

        final bg = AppTok.background(context);
        final card = AppTok.card(context);
        final border = AppTok.border(context);
        final shadow = AppTok.shadow(context);
        final textSoft = AppTok.textSoft(context);
        final accentDeep = AppTok.accentDeep(context);

        final dark = AppTok.isDark(context);
        final softPill = (dark
                ? AppDarkPalette.brandGreenSoft
                : AppPalette.brandGreenSoft)
            .withValues(alpha: 0.65);

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: bg,
            body: IndexedStack(
              index: currentIndex,
              children: pages,
            ),
            bottomNavigationBar: _buildBottomNav(
              card: card,
              border: border,
              shadow: shadow,
              textSoft: textSoft,
              accentDeep: accentDeep,
              softPill: softPill,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav({
    required Color card,
    required Color border,
    required Color shadow,
    required Color textSoft,
    required Color accentDeep,
    required Color softPill,
  }) {
    final items = [
      {'icon': Icons.home_outlined, 'label': AppLang.tr('nav_home')},
      {
        'icon': Icons.checklist_rtl_outlined,
        'label': AppLang.tr('nav_checklist'),
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': AppLang.tr('nav_budget'),
      },
      {
        'icon': Icons.table_restaurant_outlined,
        'label': AppLang.tr('nav_seating'),
      },
      {'icon': Icons.groups_outlined, 'label': AppLang.tr('nav_guests')},
      {
        'icon': Icons.calendar_today_outlined,
        'label': AppLang.tr('nav_calendar'),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: card,
        border: Border(
          top: BorderSide(
            color: border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isActive = index == currentIndex;
            final item = items[index];

            return GestureDetector(
              onTap: () => _goToTab(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? softPill : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isActive ? accentDeep : textSoft,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isActive ? accentDeep : textSoft,
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}