import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_header.dart';

// ─── Admin Layout ─────────────────────────────────────────────────────────────
//
// Usage:
//   AdminLayout(
//     title: 'Dashboard',
//     selectedIndex: 0,
//     onNavSelected: (i) { ... },
//     child: YourPageContent(),
//   )

class AdminLayout extends StatelessWidget {
  const AdminLayout({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onNavSelected,
    required this.child,
  });

  final String title;
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: selectedIndex,
            onItemSelected: onNavSelected,
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(title: title),
                Expanded(
                  child: Container(
                    color: AppColors.backgroundDark,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}