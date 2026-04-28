import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';


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
          Row(
            children: [
              _NotificationBell(hasNotification: hasNotification),
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

class _ProfileButton extends StatefulWidget {
  const _ProfileButton({
    this.displayName = 'Juan Dela Cruz',
    this.businessName = 'grandhotel',
    this.initials = 'A',
  });

  final String displayName;
  final String businessName;
  final String initials;

  @override
  State<_ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<_ProfileButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushReplacementNamed(context, AppRoutes.businessProfile),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _isHovered 
                ? AppColors.cardBorder.withOpacity(0.3)
                : Colors.transparent,
          ),
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
                child: Text(
                  widget.initials,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.displayName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.businessName,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 9,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}