import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/accommodation_models.dart';

// ─── Business Details Data Model ─────────────────────────────────────────────

class BusinessDetails {
  const BusinessDetails({
    required this.name,
    required this.type,
    required this.rooms,
    required this.status,
    required this.owner,
    required this.permitNumber,
    required this.registrationNumber,
    required this.registeredDate,
    required this.address,
    required this.phone,
    required this.email,
    this.documents = const ['Business Permit', 'Valid ID'],
  });

  final String name;
  final String type;
  final int rooms;
  final AccommodationStatus status;
  final String owner;
  final String permitNumber;
  final String registrationNumber;
  final String registeredDate;
  final String address;
  final String phone;
  final String email;
  final List<String> documents;
}

// ─── Show Helper ──────────────────────────────────────────────────────────────

Future<void> showBusinessDetailsModal(
  BuildContext context,
  BusinessDetails details, {
  VoidCallback? onApprove,
  VoidCallback? onReject,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => BusinessDetailsModal(
      details: details,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}

// ─── Modal Widget ─────────────────────────────────────────────────────────────

class BusinessDetailsModal extends StatelessWidget {
  const BusinessDetailsModal({
    super.key,
    required this.details,
    this.onApprove,
    this.onReject,
  });

  final BusinessDetails details;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  static const _modalMaxWidth = 460.0;

  @override
  Widget build(BuildContext context) {
    final showActions = details.status == AccommodationStatus.pending;

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
                _ModalHeader(onClose: () => Navigator.of(context).pop()),
                const Divider(color: AppColors.cardBorder, height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BusinessIdentity(details: details),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.cardBorder, height: 1),
                        const SizedBox(height: 20),
                        _DetailsGrid(details: details),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.cardBorder, height: 1),
                        const SizedBox(height: 20),
                        _ContactInfo(details: details),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.cardBorder, height: 1),
                        const SizedBox(height: 20),
                        _DocumentsSection(documents: details.documents),
                      ],
                    ),
                  ),
                ),
                if (showActions) ...[
                  const Divider(color: AppColors.cardBorder, height: 1),
                  _ActionRow(
                    onApprove: () {
                      Navigator.of(context).pop();
                      onApprove?.call();
                    },
                    onReject: () {
                      Navigator.of(context).pop();
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
            'Business Details',
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

// ─── Business Identity ────────────────────────────────────────────────────────

class _BusinessIdentity extends StatelessWidget {
  const _BusinessIdentity({required this.details});

  final BusinessDetails details;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryCyan.withOpacity(0.25)),
          ),
          child: const Icon(
            Icons.apartment_rounded,
            color: AppColors.primaryCyan,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.name,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${details.type} • ${details.rooms} Rooms',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              _StatusBadge(status: details.status),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Details Grid ────────────────────────────────────────────────────────────

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.details});

  final BusinessDetails details;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 300;
        if (isNarrow) {
          return Column(
            children: [
              _DetailField(label: 'Owner', value: details.owner),
              const SizedBox(height: 14),
              _DetailField(label: 'Permit #', value: details.permitNumber),
              const SizedBox(height: 14),
              _DetailField(
                label: 'Registration #',
                value: details.registrationNumber,
              ),
              const SizedBox(height: 14),
              _DetailField(label: 'Registered', value: details.registeredDate),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailField(label: 'Owner', value: details.owner),
                  const SizedBox(height: 16),
                  _DetailField(
                    label: 'Registration #',
                    value: details.registrationNumber,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailField(label: 'Permit #', value: details.permitNumber),
                  const SizedBox(height: 16),
                  _DetailField(
                    label: 'Registered',
                    value: details.registeredDate,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

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
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Contact Info ─────────────────────────────────────────────────────────────

class _ContactInfo extends StatelessWidget {
  const _ContactInfo({required this.details});

  final BusinessDetails details;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ContactRow(
          icon: Icons.location_on_outlined,
          text: details.address,
        ),
        const SizedBox(height: 10),
        _ContactRow(icon: Icons.phone_outlined, text: details.phone),
        const SizedBox(height: 10),
        _ContactRow(icon: Icons.email_outlined, text: details.email),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSubtle, size: 15),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Documents Section ────────────────────────────────────────────────────────

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({required this.documents});

  final List<String> documents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Documents',
          style: TextStyle(
            color: AppColors.textSubtle,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: documents
              .map((doc) => _DocumentChip(label: doc))
              .toList(),
        ),
      ],
    );
  }
}

class _DocumentChip extends StatelessWidget {
  const _DocumentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: AppColors.textGray,
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Row (NO CONFIRMATION - immediate actions) ────────────────────────

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
              onTap: onReject,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModalButton(
              label: 'Approve',
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF00C48C),
              onTap: onApprove,
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

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AccommodationStatus status;

  static ({String label, Color color}) _styleFor(AccommodationStatus s) {
    switch (s) {
      case AccommodationStatus.approved:
        return (label: 'Approved', color: const Color(0xFF00C48C));
      case AccommodationStatus.pending:
        return (label: 'Pending', color: const Color(0xFFFFB020));
      case AccommodationStatus.rejected:
        return (label: 'Rejected', color: const Color(0xFFFF4D6A));
      case AccommodationStatus.warning:
        return (label: 'Warning', color: const Color(0xFFFFB020));
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}