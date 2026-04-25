import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// ─── Admin Header ─────────────────────────────────────────────────────────────

class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  const AdminHeader({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.backgroundMid,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          _NotificationBell(),
        ],
      ),
    );
  }
}

// ─── Notification Bell ────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textGray,
            size: 22,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primaryCyan,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}