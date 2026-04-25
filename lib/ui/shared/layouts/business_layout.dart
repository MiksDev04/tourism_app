import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/business_sidebar.dart';
import '../widgets/business_header.dart';

// ─── Business Layout ──────────────────────────────────────────────────────────
//
// Usage:
//   BusinessLayout(
//     title: 'Dashboard',
//     selectedIndex: 0,
//     onNavSelected: (i) { ... },
//     child: YourPageContent(),
//   )

class BusinessLayout extends StatelessWidget {
  const BusinessLayout({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onNavSelected,
    required this.child,
    this.hasNotification = true,
  });

  final String title;
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final Widget child;
  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Row(
        children: [
          BusinessSidebar(
            selectedIndex: selectedIndex,
            onItemSelected: onNavSelected,
          ),
          Expanded(
            child: Column(
              children: [
                BusinessHeader(
                  title: title,
                  hasNotification: hasNotification,
                ),
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