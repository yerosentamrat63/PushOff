import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum NavTab { home, groups, board, profile }

class BottomNav extends StatelessWidget {
  final NavTab currentTab;
  final ValueChanged<NavTab> onSelectTab;

  const BottomNav({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildNavItem(
                tab: NavTab.home,
                label: 'Home',
                icon: Icons.home_rounded,
              ),
              _buildNavItem(
                tab: NavTab.groups,
                label: 'Groups',
                icon: Icons.group_rounded,
              ),
              _buildNavItem(
                tab: NavTab.board,
                label: 'Board',
                icon: Icons.bar_chart_rounded,
              ),
              _buildNavItem(
                tab: NavTab.profile,
                label: 'Profile',
                icon: Icons.person_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required NavTab tab,
    required String label,
    required IconData icon,
  }) {
    final isSelected = currentTab == tab;
    final color = isSelected ? AppColors.accentLime : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => onSelectTab(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption(color: color).copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

