import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/business_layout.dart';

// ─── Business Profile Page ────────────────────────────────────────────────────

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  // Account Info controllers
  final _fullNameCtrl = TextEditingController(text: 'Juan dela Cruz');
  final _usernameCtrl = TextEditingController(text: 'grandhotel');
  final _emailCtrl    = TextEditingController(text: 'grandhotel@sanpablo.com');
  final _phoneCtrl    = TextEditingController(text: '09281234567');

  // Business Info controllers
  final _businessNameCtrl  = TextEditingController(text: 'Grand Hotel San Pablo');
  final _ownerNameCtrl     = TextEditingController(text: 'Juan dela Cruz');
  final _totalRoomsCtrl    = TextEditingController(text: '45');
  final _addressCtrl       = TextEditingController(text: 'Maharlika Highway, San Pablo City, Laguna');
  final _descriptionCtrl   = TextEditingController(
    text: 'A premier hotel located along Maharlika Highway offering comfortable accommodations and excellent service.',
  );

  String _selectedBusinessType = 'Hotel';

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl, _usernameCtrl, _emailCtrl, _phoneCtrl,
      _businessNameCtrl, _ownerNameCtrl, _totalRoomsCtrl,
      _addressCtrl, _descriptionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusinessLayout(
      title: 'Profile',
      selectedIndex: 5,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      _BusinessCard(),
                      const SizedBox(height: 16),
                      _AccountInfoCard(
                        fullNameCtrl: _fullNameCtrl,
                        usernameCtrl: _usernameCtrl,
                        emailCtrl: _emailCtrl,
                        phoneCtrl: _phoneCtrl,
                        onSave: () {},
                        isNarrow: isNarrow,
                      ),
                      const SizedBox(height: 16),
                      _BusinessInfoCard(
                        businessNameCtrl: _businessNameCtrl,
                        ownerNameCtrl: _ownerNameCtrl,
                        totalRoomsCtrl: _totalRoomsCtrl,
                        addressCtrl: _addressCtrl,
                        descriptionCtrl: _descriptionCtrl,
                        selectedBusinessType: _selectedBusinessType,
                        onBusinessTypeChanged: (val) =>
                            setState(() => _selectedBusinessType = val ?? 'Hotel'),
                        onSave: () {},
                        isNarrow: isNarrow,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile & Settings',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Manage your account and business information',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Business Card (top identity card) ────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          // Icon container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.business_center_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name & type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grand Hotel San Pablo',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Hotel  •  Maharlika Highway',
                  style: TextStyle(color: AppColors.textGray, fontSize: 12.5),
                ),
              ],
            ),
          ),
          // Approved badge
          _StatusBadge(),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D3B26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A5C3A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF34D399),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Approved',
            style: TextStyle(
              color: Color(0xFF34D399),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Account Info Card ────────────────────────────────────────────────────────

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({
    required this.fullNameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.onSave,
    required this.isNarrow,
  });

  final TextEditingController fullNameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final VoidCallback onSave;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  color: AppColors.primaryCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'Account Information',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Full Name + Username (side-by-side on wide, stacked on narrow)
          if (isNarrow) ...[
            _LabeledField(
              label: 'Full Name',
              child: _InputField(controller: fullNameCtrl),
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Username',
              child: _InputField(controller: usernameCtrl),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Full Name',
                    child: _InputField(controller: fullNameCtrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _LabeledField(
                    label: 'Username',
                    child: _InputField(controller: usernameCtrl),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),

          // Email
          _LabeledField(
            label: 'Email',
            icon: Icons.mail_outline_rounded,
            child: _InputField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(height: 14),

          // Phone
          _LabeledField(
            label: 'Phone',
            icon: Icons.phone_outlined,
            child: _InputField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 22),

          // Save button
          _ActionButton(
            icon: Icons.save_outlined,
            label: 'Save',
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

// ─── Business Info Card ───────────────────────────────────────────────────────

class _BusinessInfoCard extends StatelessWidget {
  const _BusinessInfoCard({
    required this.businessNameCtrl,
    required this.ownerNameCtrl,
    required this.totalRoomsCtrl,
    required this.addressCtrl,
    required this.descriptionCtrl,
    required this.selectedBusinessType,
    required this.onBusinessTypeChanged,
    required this.onSave,
    required this.isNarrow,
  });

  final TextEditingController businessNameCtrl;
  final TextEditingController ownerNameCtrl;
  final TextEditingController totalRoomsCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController descriptionCtrl;
  final String selectedBusinessType;
  final ValueChanged<String?> onBusinessTypeChanged;
  final VoidCallback onSave;
  final bool isNarrow;

  static const _businessTypes = [
    'Hotel',
    'Resort',
    'Restaurant',
    'Café',
    'Pension House',
    'Inn',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Row(
            children: [
              Icon(Icons.store_outlined,
                  color: AppColors.primaryCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'Business Information',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Business Name + Business Type
          if (isNarrow) ...[
            _LabeledField(
              label: 'Business Name',
              child: _InputField(controller: businessNameCtrl),
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Business Type',
              child: _DropdownField(
                value: selectedBusinessType,
                items: _businessTypes,
                onChanged: onBusinessTypeChanged,
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Business Name',
                    child: _InputField(controller: businessNameCtrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _LabeledField(
                    label: 'Business Type',
                    child: _DropdownField(
                      value: selectedBusinessType,
                      items: _businessTypes,
                      onChanged: onBusinessTypeChanged,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),

          // Owner Name + Total Rooms/Units
          if (isNarrow) ...[
            _LabeledField(
              label: 'Owner Name',
              child: _InputField(controller: ownerNameCtrl),
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Total Rooms/Units',
              icon: Icons.bed_outlined,
              child: _InputField(
                controller: totalRoomsCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Owner Name',
                    child: _InputField(controller: ownerNameCtrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _LabeledField(
                    label: 'Total Rooms/Units',
                    icon: Icons.bed_outlined,
                    child: _InputField(
                      controller: totalRoomsCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),

          // Address
          _LabeledField(
            label: 'Address',
            icon: Icons.location_on_outlined,
            child: _InputField(controller: addressCtrl),
          ),
          const SizedBox(height: 14),

          // Description
          _LabeledField(
            label: 'Description',
            child: _MultilineField(controller: descriptionCtrl),
          ),
          const SizedBox(height: 22),

          // Save button
          _ActionButton(
            icon: Icons.save_outlined,
            label: 'Save Changes',
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

// ─── Shared Section Card ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

// ─── Labeled Field ────────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.icon,
  });

  final String label;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textGray, size: 14),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

// ─── Input Field ──────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: _ProfileColors.inputBackground,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _ProfileColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _ProfileColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Multiline Field ──────────────────────────────────────────────────────────

class _MultilineField extends StatelessWidget {
  const _MultilineField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: _ProfileColors.inputBackground,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _ProfileColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _ProfileColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Dropdown Field ───────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: AppColors.cardBackground,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textGray, size: 20),
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: _ProfileColors.inputBackground,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _ProfileColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _ProfileColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
      ),
      items: items
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(t),
            ),
          )
          .toList(),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Local color constants (mirror app_colors.dart) ──────────────────────────

class _ProfileColors {
  static const inputBackground = Color(0xFF0D1B2E);
  static const inputBorder     = Color(0xFF1C3050);
}