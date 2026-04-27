import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';

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
      child: // REPLACE the Row children in build() with:
      Row(
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
          // REPLACE the right-side Row with:
          Row(
            children: [
              _NotificationBell(),
              const SizedBox(width: 4),
              Container(width: 1, height: 24, color: AppColors.cardBorder),
              const SizedBox(width: 12),
              _ProfileButton(),
            ],
          ),
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

class _ProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Make background transparent
      child: InkWell(
        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.adminProfile),
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.cardBorder.withOpacity(0.3),
        splashColor: AppColors.primaryCyan.withOpacity(0.2),
        highlightColor: AppColors.textGray.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.primaryCyan,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tourism Office',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}