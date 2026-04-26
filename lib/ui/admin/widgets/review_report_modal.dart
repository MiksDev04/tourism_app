import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/report_models.dart';

// ─── ReportStatus (mirror from reports page) ──────────────────────────────────

// ─── Review Report Data Model ─────────────────────────────────────────────────

class ReviewReportData {
  const ReviewReportData({
    required this.business,
    required this.period,
    required this.totalGuests,
    required this.checkIns,
    this.submitted,
    required this.status,
  });

  final String business;
  final String period;
  final int totalGuests;
  final int checkIns;
  final String? submitted;
  final ReportStatus status;
}

// ─── Show Helper ──────────────────────────────────────────────────────────────

Future<void> showReviewReportModal(
  BuildContext context,
  ReviewReportData report, {
  VoidCallback? onApprove,
  VoidCallback? onReject,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => ReviewReportModal(
      report: report,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}

// ─── Modal Widget ─────────────────────────────────────────────────────────────

class ReviewReportModal extends StatelessWidget {
  const ReviewReportModal({
    super.key,
    required this.report,
    this.onApprove,
    this.onReject,
  });

  final ReviewReportData report;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  static const _modalMaxWidth = 420.0;

  bool get _showActions => report.status == ReportStatus.submitted;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _modalMaxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1923),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                _ModalHeader(onClose: () => Navigator.of(context).pop()),

                // ── Divider ──
                const Divider(color: AppColors.cardBorder, height: 1),

                // ── Body ──
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business + Period row
                      _DetailsGrid(
                        topLeft: _DetailField(
                          label: 'Business',
                          value: report.business,
                        ),
                        topRight: _DetailField(
                          label: 'Period',
                          value: report.period,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Total Guests + Check-ins row
                      _DetailsGrid(
                        topLeft: _DetailField(
                          label: 'Total Guests',
                          value: '${report.totalGuests}',
                          valueLarge: true,
                        ),
                        topRight: _DetailField(
                          label: 'Check-ins',
                          value: '${report.checkIns}',
                          valueLarge: true,
                        ),
                      ),
                      if (report.submitted != null) ...[
                        const SizedBox(height: 16),
                        _SubmittedChip(date: report.submitted!),
                      ],
                    ],
                  ),
                ),

                // ── Action Buttons ──
                if (_showActions) ...[
                  const Divider(color: AppColors.cardBorder, height: 1),
                  _ActionRow(
                    onApprove: () {
                      onApprove?.call();
                    },
                    onReject: () {
                      onReject?.call();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Modal Header ─────────────────────────────────────────────────────────────

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          const Text(
            'Review Report',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textGray,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Details Grid (2-column layout) ──────────────────────────────────────────

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.topLeft, required this.topRight});

  final Widget topLeft;
  final Widget topRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: topLeft),
        const SizedBox(width: 24),
        Expanded(child: topRight),
      ],
    );
  }
}

// ─── Detail Field ─────────────────────────────────────────────────────────────

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.valueLarge = false,
  });

  final String label;
  final String value;
  final bool valueLarge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSubtle,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: valueLarge ? 22 : 13.5,
            fontWeight: valueLarge ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: valueLarge ? -0.5 : 0,
          ),
        ),
      ],
    );
  }
}

// ─── Submitted Date Chip ──────────────────────────────────────────────────────

class _SubmittedChip extends StatelessWidget {
  const _SubmittedChip({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        'Submitted: $date',
        style: const TextStyle(color: AppColors.textSubtle, fontSize: 12.5),
      ),
    );
  }
}

// ─── Action Row (Reject / Approve - NO CONFIRMATION) ────────────────────────────

// ─── Action Row (Reject / Approve - NO CONFIRMATION) ────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onApprove, required this.onReject});

  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _ModalButton(
              label: 'Reject',
              icon: Icons.cancel_outlined,
              color: const Color(0xFFFF4D6A),
              onTap: () {
                Navigator.of(context).pop(); // Close modal first
                onReject(); // Then execute callback
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ModalButton(
              label: 'Approve',
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF00C48C),
              onTap: () {
                Navigator.of(context).pop(); // Close modal first
                onApprove(); // Then execute callback
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalButton extends StatelessWidget {
  const _ModalButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
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
