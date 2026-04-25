import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// ─── Business Header ──────────────────────────────────────────────────────────

class BusinessHeader extends StatelessWidget implements PreferredSizeWidget {
  const BusinessHeader({
    super.key,
    required this.title,
    this.hasNotification = true,
  });

  final String title;
  final bool hasNotification;

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
          _NotificationBell(hasNotification: hasNotification),
        ],
      ),
    );
  }
}

// ─── Notification Bell ────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.hasNotification});

  final bool hasNotification;

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
        if (hasNotification)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.accentPurple,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}