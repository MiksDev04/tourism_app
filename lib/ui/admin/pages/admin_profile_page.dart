import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';
import 'package:flutter/services.dart';


// ─── Admin Profile Page ───────────────────────────────────────────────────────

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  // Account Info controllers
  final _fullNameCtrl = TextEditingController(text: 'Maria Santos');
  final _usernameCtrl = TextEditingController(text: 'admin_tourism');
  final _emailCtrl    = TextEditingController(text: 'admin@sanpablo.gov.ph');
  final _phoneCtrl    = TextEditingController(text: '09171234567');

  // Password controllers
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl, _usernameCtrl, _emailCtrl, _phoneCtrl,
      _currentPassCtrl, _newPassCtrl, _confirmPassCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }


  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveAccountInfo() {
    // Validate phone number
    final phoneNumber = _phoneCtrl.text.trim();
    final phoneRegex = RegExp(r'^[0-9]+$');
    
    if (!phoneRegex.hasMatch(phoneNumber)) {
      _showSnackbar('Phone number should only contain digits', isError: true);
      return;
    }

    // Save action with effect
    _showSnackbar('Account information saved successfully!');
    // Add actual save logic here
  }

  void _updatePassword() {
    final currentPass = _currentPassCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (currentPass.isEmpty) {
      _showSnackbar('Please enter current password', isError: true);
      return;
    }

    if (newPass.isEmpty) {
      _showSnackbar('Please enter new password', isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showSnackbar('New password must be at least 6 characters', isError: true);
      return;
    }

    if (newPass != confirmPass) {
      _showSnackbar('New passwords do not match', isError: true);
      return;
    }

    // Update password with effect
    _showSnackbar('Password updated successfully!');
    
    // Clear password fields after successful update
    _currentPassCtrl.clear();
    _newPassCtrl.clear();
    _confirmPassCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Profile',
      selectedIndex: 5,
      onNavSelected: (_) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(),
            const SizedBox(height: 20),
            // Constrain cards to match design width
            SizedBox(
              width: 530,
              child: Column(
                children: [
                  _ProfileCard(),
                  const SizedBox(height: 16),
                  _AccountInfoCard(
                    fullNameCtrl: _fullNameCtrl,
                    usernameCtrl: _usernameCtrl,
                    emailCtrl: _emailCtrl,
                    phoneCtrl: _phoneCtrl,
                    onSave: _saveAccountInfo,
                  ),
                  const SizedBox(height: 16),
                  _ChangePasswordCard(
                    currentPassCtrl: _currentPassCtrl,
                    newPassCtrl: _newPassCtrl,
                    confirmPassCtrl: _confirmPassCtrl,
                    obscureCurrent: _obscureCurrent,
                    obscureNew: _obscureNew,
                    obscureConfirm: _obscureConfirm,
                    onToggleCurrent: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    onToggleNew: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    onToggleConfirm: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onUpdate: _updatePassword,
                  ),
                ],
              ),
            ),
          ],
        ),
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
          'Profile Settings',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Manage your account information',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Maria Santos',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'admin@sanpablo.gov.ph',
                style: TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
              const SizedBox(height: 8),
              _RoleBadge(),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryCyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryCyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Tourism Office Admin',
            style: TextStyle(
              color: AppColors.primaryCyan,
              fontSize: 11.5,
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
  });

  final TextEditingController fullNameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final VoidCallback onSave;

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

          // Full Name + Username
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
          const SizedBox(height: 16),

          // Email
          _LabeledField(
            label: 'Email Address',
            icon: Icons.email_outlined,
            child: _InputField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(height: 16),

          // Phone
          _LabeledField(
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            child: _PhoneInputField(
              controller: phoneCtrl,
            ),
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

// ─── Change Password Card ─────────────────────────────────────────────────────

class _ChangePasswordCard extends StatelessWidget {
  const _ChangePasswordCard({
    required this.currentPassCtrl,
    required this.newPassCtrl,
    required this.confirmPassCtrl,
    required this.obscureCurrent,
    required this.obscureNew,
    required this.obscureConfirm,
    required this.onToggleCurrent,
    required this.onToggleNew,
    required this.onToggleConfirm,
    required this.onUpdate,
  });

  final TextEditingController currentPassCtrl;
  final TextEditingController newPassCtrl;
  final TextEditingController confirmPassCtrl;
  final bool obscureCurrent;
  final bool obscureNew;
  final bool obscureConfirm;
  final VoidCallback onToggleCurrent;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConfirm;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  color: AppColors.primaryCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'Change Password',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Current Password
          _LabeledField(
            label: 'Current Password',
            child: _PasswordField(
              controller: currentPassCtrl,
              obscure: obscureCurrent,
              onToggle: onToggleCurrent,
            ),
          ),
          const SizedBox(height: 16),

          // New Password
          _LabeledField(
            label: 'New Password',
            child: _PasswordField(
              controller: newPassCtrl,
              obscure: obscureNew,
              onToggle: onToggleNew,
            ),
          ),
          const SizedBox(height: 16),

          // Confirm New Password
          _LabeledField(
            label: 'Confirm New Password',
            child: _PasswordField(
              controller: confirmPassCtrl,
              obscure: obscureConfirm,
              onToggle: onToggleConfirm,
            ),
          ),
          const SizedBox(height: 22),

          // Update button
          _ActionButton(
            icon: Icons.lock_outline_rounded,
            label: 'Update Password',
            onPressed: onUpdate,
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
        fillColor: AppColors.inputBackground,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
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

// ─── Phone Input Field ────────────────────────────────────────────────────────

class _PhoneInputField extends StatelessWidget {
  const _PhoneInputField({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputBackground,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
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

// ─── Password Field ───────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputBackground,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.textSubtle,
            size: 18,
          ),
          onPressed: onToggle,
        ),
      ),
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

// ─── Extra color constants (mirror app_colors.dart) ──────────────────────────

extension _ProfileColors on AppColors {
  static const inputBackground = Color(0xFF0D1B2E);
  static const inputBorder     = Color(0xFF1C3050);
}