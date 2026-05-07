import 'package:flutter/material.dart';
import '../../../router/app_router.dart';
import '../../../core/constants/app_colors.dart';

// void main() {
//   runApp(const RegisterPage());
// }

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: RegisterScreen(),
    );
  }
}

// ─── Colors ───────────────────────────────────────────────────────────────────

class RegisterColors {
  RegisterColors._();


  static const textRed = Color(0xFFFF4D6A);
  static const warningBg = Color(0xFF1A1200);
  static const warningText = Color(0xFFFFB020);
}

// ─── Register Screen ──────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 1; // 1 = Account Info, 2 = Business Details

  // Step 1 controllers
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Step 2 controllers
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _totalRoomsCtrl = TextEditingController();
  final _permitNumberCtrl = TextEditingController();
  final _registrationCtrl = TextEditingController();
  final _businessAddrCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();
  String _businessType = 'Hotel';

  // Validation errors (step 2)
  bool _showErrors = false;

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl,
      _usernameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passwordCtrl,
      _confirmPassCtrl,
      _businessNameCtrl,
      _ownerNameCtrl,
      _totalRoomsCtrl,
      _permitNumberCtrl,
      _registrationCtrl,
      _businessAddrCtrl,
      _contactNumberCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goNext() => setState(() {
    _step = 2;
    _showErrors = false;
  });
  void _goBack() => setState(() {
    _step = 1;
    _showErrors = false;
  });

  void _submit() {
    setState(() => _showErrors = true);
    final valid =
        _businessNameCtrl.text.isNotEmpty &&
        _ownerNameCtrl.text.isNotEmpty &&
        int.tryParse(_totalRoomsCtrl.text) != null &&
        _permitNumberCtrl.text.isNotEmpty &&
        _registrationCtrl.text.isNotEmpty &&
        _businessAddrCtrl.text.isNotEmpty &&
        _contactNumberCtrl.text.isNotEmpty;
    if (valid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration submitted!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3),
            radius: 1.2,
            colors: [AppColors.activeNavBg, AppColors.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        const _AppHeader(),
                        const SizedBox(height: 28),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: _FormCard(
                            step: _step,
                            showErrors: _showErrors,
                            // Step 1
                            fullNameCtrl: _fullNameCtrl,
                            usernameCtrl: _usernameCtrl,
                            emailCtrl: _emailCtrl,
                            phoneCtrl: _phoneCtrl,
                            passwordCtrl: _passwordCtrl,
                            confirmPassCtrl: _confirmPassCtrl,
                            onNext: _goNext,
                            // Step 2
                            businessNameCtrl: _businessNameCtrl,
                            businessType: _businessType,
                            onBusinessTypeChanged: (v) =>
                                setState(() => _businessType = v!),
                            ownerNameCtrl: _ownerNameCtrl,
                            totalRoomsCtrl: _totalRoomsCtrl,
                            permitNumberCtrl: _permitNumberCtrl,
                            registrationCtrl: _registrationCtrl,
                            businessAddrCtrl: _businessAddrCtrl,
                            contactNumberCtrl: _contactNumberCtrl,
                            onBack: _goBack,
                            onSubmit: _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── App Header ───────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.assignment_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Register Accommodation',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'San Pablo City Tourism System',
          style: TextStyle(color: AppColors.textGray, fontSize: 13.5),
        ),
      ],
    );
  }
}

// ─── Form Card ────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.step,
    required this.showErrors,
    required this.fullNameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.confirmPassCtrl,
    required this.onNext,
    required this.businessNameCtrl,
    required this.businessType,
    required this.onBusinessTypeChanged,
    required this.ownerNameCtrl,
    required this.totalRoomsCtrl,
    required this.permitNumberCtrl,
    required this.registrationCtrl,
    required this.businessAddrCtrl,
    required this.contactNumberCtrl,
    required this.onBack,
    required this.onSubmit,
  });

  final int step;
  final bool showErrors;

  // Step 1
  final TextEditingController fullNameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPassCtrl;
  final VoidCallback onNext;

  // Step 2
  final TextEditingController businessNameCtrl;
  final String businessType;
  final ValueChanged<String?> onBusinessTypeChanged;
  final TextEditingController ownerNameCtrl;
  final TextEditingController totalRoomsCtrl;
  final TextEditingController permitNumberCtrl;
  final TextEditingController registrationCtrl;
  final TextEditingController businessAddrCtrl;
  final TextEditingController contactNumberCtrl;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(currentStep: step),
          const SizedBox(height: 24),
          if (step == 1)
            _Step1Form(
              fullNameCtrl: fullNameCtrl,
              usernameCtrl: usernameCtrl,
              emailCtrl: emailCtrl,
              phoneCtrl: phoneCtrl,
              passwordCtrl: passwordCtrl,
              confirmPassCtrl: confirmPassCtrl,
              onNext: onNext,
            )
          else
            _Step2Form(
              showErrors: showErrors,
              businessNameCtrl: businessNameCtrl,
              businessType: businessType,
              onBusinessTypeChanged: onBusinessTypeChanged,
              ownerNameCtrl: ownerNameCtrl,
              totalRoomsCtrl: totalRoomsCtrl,
              permitNumberCtrl: permitNumberCtrl,
              registrationCtrl: registrationCtrl,
              businessAddrCtrl: businessAddrCtrl,
              contactNumberCtrl: contactNumberCtrl,
              onBack: onBack,
              onSubmit: onSubmit,
            ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.login),
              child: RichText(
                text: const TextSpan(
                  text: 'Already registered? ',
                  style: TextStyle(color: AppColors.textSubtle, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: TextStyle(
                        color: AppColors.primaryCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBadge(
          number: 1,
          label: 'Account Info',
          isActive: currentStep == 1,
          isComplete: currentStep > 1,
        ),
        Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: currentStep > 1
                ? AppColors.primaryCyan
                : AppColors.cardBorder,
          ),
        ),
        _StepBadge(
          number: 2,
          label: 'Business Details',
          isActive: currentStep == 2,
          isComplete: false,
        ),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  final int number;
  final String label;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = (isActive || isComplete)
        ? AppColors.primaryCyan
        : AppColors.cardBorder;
    final Color textColor = (isActive || isComplete)
        ? AppColors.textWhite
        : AppColors.textSubtle;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
            color: (isActive || isComplete)
                ? Colors.transparent
                : Colors.transparent,
          ),
          child: Center(
            child: isComplete
                ? const Icon(
                    Icons.check,
                    color: AppColors.primaryCyan,
                    size: 16,
                  )
                : Text(
                    '$number',
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Step 1 Form ──────────────────────────────────────────────────────────────

class _Step1Form extends StatelessWidget {
  const _Step1Form({
    required this.fullNameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.confirmPassCtrl,
    required this.onNext,
  });

  final TextEditingController fullNameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPassCtrl;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Full Name',
                child: _Input(controller: fullNameCtrl, hint: 'Maria Santos'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Username',
                child: _Input(controller: usernameCtrl, hint: 'maria_santos'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Email Address',
          child: _Input(
            controller: emailCtrl,
            hint: 'email@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Phone Number',
          child: _Input(
            controller: phoneCtrl,
            hint: '09XX-XXX-XXXX',
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Password',
                child: _Input(
                  controller: passwordCtrl,
                  hint: 'Min 6 characters',
                  obscure: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Confirm Password',
                child: _Input(
                  controller: confirmPassCtrl,
                  hint: 'Repeat password',
                  obscure: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _GradientButton(label: 'Next: Business Details →', onPressed: onNext),
      ],
    );
  }
}

// ─── Step 2 Form ──────────────────────────────────────────────────────────────

class _Step2Form extends StatelessWidget {
  const _Step2Form({
    required this.showErrors,
    required this.businessNameCtrl,
    required this.businessType,
    required this.onBusinessTypeChanged,
    required this.ownerNameCtrl,
    required this.totalRoomsCtrl,
    required this.permitNumberCtrl,
    required this.registrationCtrl,
    required this.businessAddrCtrl,
    required this.contactNumberCtrl,
    required this.onBack,
    required this.onSubmit,
  });

  final bool showErrors;
  final TextEditingController businessNameCtrl;
  final String businessType;
  final ValueChanged<String?> onBusinessTypeChanged;
  final TextEditingController ownerNameCtrl;
  final TextEditingController totalRoomsCtrl;
  final TextEditingController permitNumberCtrl;
  final TextEditingController registrationCtrl;
  final TextEditingController businessAddrCtrl;
  final TextEditingController contactNumberCtrl;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  bool _isEmpty(TextEditingController c) => showErrors && c.text.isEmpty;
  bool get _invalidRooms =>
      showErrors && int.tryParse(totalRoomsCtrl.text) == null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Business Name',
                error: _isEmpty(businessNameCtrl) ? 'Required' : null,
                child: _Input(
                  controller: businessNameCtrl,
                  hint: 'Hotel / Resort Name',
                  hasError: _isEmpty(businessNameCtrl),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Business Type',
                child: _DropdownField(
                  value: businessType,
                  items: const [
                    'Hotel',
                    'Resort',
                    'Inn',
                    'Pension House',
                    'Other',
                  ],
                  onChanged: onBusinessTypeChanged,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Owner Name',
                error: _isEmpty(ownerNameCtrl) ? 'Required' : null,
                child: _Input(
                  controller: ownerNameCtrl,
                  hint: 'Full name of owner',
                  hasError: _isEmpty(ownerNameCtrl),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Total Rooms/Units',
                error: _invalidRooms ? 'Valid number required' : null,
                child: _Input(
                  controller: totalRoomsCtrl,
                  hint: 'e.g. 30',
                  keyboardType: TextInputType.number,
                  hasError: _invalidRooms,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Permit Number',
                error: _isEmpty(permitNumberCtrl) ? 'Required' : null,
                child: _Input(
                  controller: permitNumberCtrl,
                  hint: 'SP-HTL-2024-XXX',
                  hasError: _isEmpty(permitNumberCtrl),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Registration Number',
                error: _isEmpty(registrationCtrl) ? 'Required' : null,
                child: _Input(
                  controller: registrationCtrl,
                  hint: 'BIR-2024-XXXXX',
                  hasError: _isEmpty(registrationCtrl),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Business Address',
          error: _isEmpty(businessAddrCtrl) ? 'Required' : null,
          child: _Input(
            controller: businessAddrCtrl,
            hint: 'Complete address in San Pablo City',
            hasError: _isEmpty(businessAddrCtrl),
          ),
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Contact Number',
          error: _isEmpty(contactNumberCtrl) ? 'Required' : null,
          child: _Input(
            controller: contactNumberCtrl,
            hint: '049-XXX-XXXX',
            keyboardType: TextInputType.phone,
            hasError: _isEmpty(contactNumberCtrl),
          ),
        ),
        const SizedBox(height: 16),
        _WarningBanner(),
        const SizedBox(height: 20),
        Row(
          children: [
            _BackButton(onPressed: onBack),
            const SizedBox(width: 12),
            Expanded(
              child: _GradientButton(
                label: 'Submit Registration',
                onPressed: onSubmit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Warning Banner ───────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RegisterColors.warningBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RegisterColors.warningText.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.info_outline_rounded,
            color: RegisterColors.warningText,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Business documents (permit, valid ID) should be uploaded after account approval. Please prepare these documents.',
              style: TextStyle(
                color: RegisterColors.warningText,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.error});

  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: const TextStyle(color: RegisterColors.textRed, fontSize: 11.5),
          ),
        ],
      ],
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? RegisterColors.textRed : AppColors.inputBorder;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
        filled: true,
        fillColor: AppColors.inputBackground,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primaryCyan,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          iconEnabledColor: AppColors.textGray,
          style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.textGray),
        label: const Text(
          'Back',
          style: TextStyle(color: AppColors.textGray, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );
  }
}
