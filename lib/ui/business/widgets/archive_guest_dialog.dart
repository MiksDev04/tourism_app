import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// ─── Archive Guest Dialog ─────────────────────────────────────────────────────

/// Shows the archive confirmation dialog and returns `true` if the user
/// confirmed, or `null`/`false` if they cancelled.
Future<bool?> showArchiveGuestDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => const _ArchiveGuestDialog(),
  );
}

class _ArchiveGuestDialog extends StatelessWidget {
  const _ArchiveGuestDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        // Keeps dialog compact on wide screens, full-width on narrow ones.
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.40),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──────────────────────────────────────────────────────
              const Text(
                'Archive Record?',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),

              // ── Body ───────────────────────────────────────────────────────
              const Text(
                'This record will be marked as archived. You can still view it in the Archived tab.',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // ── Actions ────────────────────────────────────────────────────
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: _DialogButton(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(false),
                      style: _ButtonStyle.outline,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Archive button
                  Expanded(
                    child: _DialogButton(
                      label: 'Archive',
                      icon: Icons.archive_outlined,
                      onTap: () => Navigator.of(context).pop(true),
                      style: _ButtonStyle.accent,
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

// ─── Shared Button Widget ─────────────────────────────────────────────────────

enum _ButtonStyle { outline, accent }

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.style,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final _ButtonStyle style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isAccent = style == _ButtonStyle.accent;

    // Amber/gold accent — matches the archive icon colour in the screenshot.
    const accentColor = Color(0xFFD4A017);

    final borderColor = isAccent
        ? accentColor.withOpacity(0.60)
        : AppColors.cardBorder;
    final foreground = isAccent ? accentColor : AppColors.textGray;
    final background = isAccent
        ? accentColor.withOpacity(0.08)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground, size: 15),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}