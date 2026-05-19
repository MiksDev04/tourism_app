import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tourism_app/api/register_api.dart';
import 'package:tourism_app/core/enums/business_enums.dart';
import 'package:tourism_app/router/app_router.dart';
import 'package:tourism_app/core/constants/app_colors.dart';



class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: RegisterScreen());
  }
}

// ─── Colors ───────────────────────────────────────────────────────────────────

class RegisterColors {
  RegisterColors._();
  static const textRed = Color(0xFFFF4D6A);
}

// ─── Validators ───────────────────────────────────────────────────────────────

class _V {
  _V._();

  static final _emailRe = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  static final _phoneRe = RegExp(r'^(09|\+639)\d{9}$');

  static String? fullName(String v) =>
      v.trim().isEmpty ? 'Full name is required' : null;

  static String? email(String v) {
    v = v.trim();
    if (v.isEmpty) return 'Email is required';
    if (!_emailRe.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String v) {
    final stripped = v.trim().replaceAll(RegExp(r'[-\s]'), '');
    if (stripped.isEmpty) return 'Phone number is required';
    if (!_phoneRe.hasMatch(stripped)) {
      return 'Use format 09XX-XXX-XXXX or +639XXXXXXXXX';
    }
    return null;
  }

  static String? password(String v) {
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }

  static String? confirmPassword(String v, String password) {
    if (v.isEmpty) return 'Please confirm your password';
    if (v != password) return 'Passwords do not match';
    return null;
  }

  static String? businessName(String v) =>
      v.trim().isEmpty ? 'Business name is required' : null;

  static String? ownerName(String v) =>
      v.trim().isEmpty ? 'Owner name is required' : null;

  static String? totalRooms(String v) {
    final n = int.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Must be at least 1';
    return null;
  }

  static String? permitNumber(String v) =>
      v.trim().isEmpty ? 'Permit number is required' : null;

  static String? registrationNumber(String v) =>
      v.trim().isEmpty ? 'Registration number is required' : null;

    static String? street(String v) =>
      v.trim().isEmpty ? 'Street is required' : null;

    static String? barangay(String v) =>
      v.trim().isEmpty ? 'Barangay is required' : null;

    static String? cityMunicipality(String v) =>
      v.trim().isEmpty ? 'City / Municipality is required' : null;

    static String? province(String v) =>
      v.trim().isEmpty ? 'Province is required' : null;

    static String? region(String v) =>
      v.trim().isEmpty ? 'Region is required' : null;
  static String? file(File? f) =>
      f == null ? 'Please upload the required file' : null;
}

// ─── Register Screen ──────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ── Connectivity ───────────────────────────────────────────────────────────
  bool _isOnline = true;
  bool _checkingConnection = true;
  Timer? _connectivityTimer;

  // ── Form state ─────────────────────────────────────────────────────────────
  int _step = 1;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Step 2
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _totalRoomsCtrl = TextEditingController();
  final _permitNumberCtrl = TextEditingController();
  final _registrationCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _barangayCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  String _businessType = 'Hotel';

  File? _permitFile;
  File? _validIdFile;
  bool _showErrors = false;

  final _api = RegisterApi();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Re-check every 3 seconds so the overlay auto-dismisses when reconnected
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkConnectivity(),
    );
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    for (final c in [
      _fullNameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passwordCtrl,
      _confirmPassCtrl,
      _businessNameCtrl,
      _ownerNameCtrl,
      _totalRoomsCtrl,
      _permitNumberCtrl,
      _registrationCtrl,
      _streetCtrl,
      _barangayCtrl,
      _cityCtrl,
      _provinceCtrl,
      _regionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (mounted) {
        setState(() {
          _isOnline = online;
          _checkingConnection = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isOnline = false;
          _checkingConnection = false;
        });
      }
    }
  }

  // ── Step 1 ─────────────────────────────────────────────────────────────────

  bool get _step1Valid =>
      _V.fullName(_fullNameCtrl.text) == null &&
      _V.email(_emailCtrl.text) == null &&
      _V.phone(_phoneCtrl.text) == null &&
      _V.password(_passwordCtrl.text) == null &&
      _V.confirmPassword(_confirmPassCtrl.text, _passwordCtrl.text) == null;

  void _goNext() {
    setState(() => _showErrors = true);
    if (!_step1Valid) return;
    setState(() {
      _step = 2;
      _showErrors = false;
      _errorMessage = null;
    });
  }

  void _goBack() => setState(() {
    _step = 1;
    _showErrors = false;
    _errorMessage = null;
  });

  // ── Step 2 ─────────────────────────────────────────────────────────────────

  bool get _step2Valid =>
      _V.businessName(_businessNameCtrl.text) == null &&
      _V.ownerName(_ownerNameCtrl.text) == null &&
      _V.totalRooms(_totalRoomsCtrl.text) == null &&
      _V.permitNumber(_permitNumberCtrl.text) == null &&
      _V.registrationNumber(_registrationCtrl.text) == null &&
      _V.street(_streetCtrl.text) == null &&
      _V.barangay(_barangayCtrl.text) == null &&
      _V.cityMunicipality(_cityCtrl.text) == null &&
      _V.province(_provinceCtrl.text) == null &&
      _V.region(_regionCtrl.text) == null &&
      _V.file(_permitFile) == null &&
      _V.file(_validIdFile) == null;

  Future<void> _pickPermitFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _permitFile = File(result.files.single.path!));
    }
  }

  Future<void> _pickValidId() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _validIdFile = File(result.files.single.path!));
    }
  }

  Future<void> _submit() async {
    setState(() {
      _showErrors = true;
      _errorMessage = null;
    });
    if (!_step2Valid) return;

    setState(() => _isLoading = true);

    final result = await _api.register(
      fullName: _fullNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phoneNumber: _phoneCtrl.text.trim(),
      businessName: _businessNameCtrl.text.trim(),
      businessType: _mapBusinessType(_businessType),
      ownerName: _ownerNameCtrl.text.trim(),
      totalRooms: int.parse(_totalRoomsCtrl.text.trim()),
      permitNumber: _permitNumberCtrl.text.trim(),
      registrationNumber: _registrationCtrl.text.trim(),
      street: _streetCtrl.text.trim(),
      barangay: _barangayCtrl.text.trim(),
      cityMunicipality: _cityCtrl.text.trim(),
      province: _provinceCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
      permitFile: _permitFile!,
      validIdFile: _validIdFile!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration submitted! Awaiting admin approval.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  BusinessType _mapBusinessType(String type) {
    switch (type.toLowerCase()) {
      case 'resort':
        return BusinessType.resort;
      case 'inn':
        return BusinessType.inn;
      case 'pension house':
      case 'other':
        return BusinessType.other;
      case 'hotel':
      default:
        return BusinessType.hotel;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Show a plain spinner on the very first connectivity check
    if (_checkingConnection) {
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3),
            radius: 1.2,
            colors: [AppColors.activeNavBg, AppColors.backgroundDark],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    return Stack(
      children: [
        // ── The actual page (always rendered) ─────────────────────────────
        _buildPage(),

        // ── Offline blocking overlay ───────────────────────────────────────
        if (!_isOnline) _buildOfflineOverlay(),
      ],
    );
  }

  Widget _buildPage() {
    return Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                          isLoading: _isLoading,
                          errorMessage: _errorMessage,
                          fullNameCtrl: _fullNameCtrl,
                          emailCtrl: _emailCtrl,
                          phoneCtrl: _phoneCtrl,
                          passwordCtrl: _passwordCtrl,
                          confirmPassCtrl: _confirmPassCtrl,
                          onNext: _goNext,
                          businessNameCtrl: _businessNameCtrl,
                          businessType: _businessType,
                          onBusinessTypeChanged: (v) =>
                              setState(() => _businessType = v!),
                          ownerNameCtrl: _ownerNameCtrl,
                          totalRoomsCtrl: _totalRoomsCtrl,
                          permitNumberCtrl: _permitNumberCtrl,
                          registrationCtrl: _registrationCtrl,
                          streetCtrl: _streetCtrl,
                          barangayCtrl: _barangayCtrl,
                          cityCtrl: _cityCtrl,
                          provinceCtrl: _provinceCtrl,
                          regionCtrl: _regionCtrl,
                          permitFile: _permitFile,
                          validIdFile: _validIdFile,
                          onPickPermitFile: _pickPermitFile,
                          onPickValidId: _pickValidId,
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
    );
  }

  Widget _buildOfflineOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: RegisterColors.textRed.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 28,
                    color: RegisterColors.textRed,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'An internet connection is required to register your accommodation establishment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _HoverButton(
                  label: 'Try Again',
                  icon: Icons.refresh_rounded,
                  onPressed: _checkConnectivity,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: const Text(
                    'Back to Sign In',
                    style: TextStyle(
                      color: AppColors.primaryCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
    required this.isLoading,
    this.errorMessage,
    required this.fullNameCtrl,
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
    required this.streetCtrl,
    required this.barangayCtrl,
    required this.cityCtrl,
    required this.provinceCtrl,
    required this.regionCtrl,
    required this.permitFile,
    required this.validIdFile,
    required this.onPickPermitFile,
    required this.onPickValidId,
    required this.onBack,
    required this.onSubmit,
  });

  final int step;
  final bool showErrors;
  final bool isLoading;
  final String? errorMessage;
  final TextEditingController fullNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPassCtrl;
  final VoidCallback onNext;
  final TextEditingController businessNameCtrl;
  final String businessType;
  final ValueChanged<String?> onBusinessTypeChanged;
  final TextEditingController ownerNameCtrl;
  final TextEditingController totalRoomsCtrl;
  final TextEditingController permitNumberCtrl;
  final TextEditingController registrationCtrl;
  final TextEditingController streetCtrl;
  final TextEditingController barangayCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController provinceCtrl;
  final TextEditingController regionCtrl;
  final File? permitFile;
  final File? validIdFile;
  final VoidCallback onPickPermitFile;
  final VoidCallback onPickValidId;
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
              emailCtrl: emailCtrl,
              phoneCtrl: phoneCtrl,
              passwordCtrl: passwordCtrl,
              confirmPassCtrl: confirmPassCtrl,
              showErrors: showErrors,
              onNext: onNext,
            )
          else
            _Step2Form(
              showErrors: showErrors,
              isLoading: isLoading,
              errorMessage: errorMessage,
              businessNameCtrl: businessNameCtrl,
              businessType: businessType,
              onBusinessTypeChanged: onBusinessTypeChanged,
              ownerNameCtrl: ownerNameCtrl,
              totalRoomsCtrl: totalRoomsCtrl,
              permitNumberCtrl: permitNumberCtrl,
              registrationCtrl: registrationCtrl,
              streetCtrl: streetCtrl,
              barangayCtrl: barangayCtrl,
              cityCtrl: cityCtrl,
              provinceCtrl: provinceCtrl,
              regionCtrl: regionCtrl,
              permitFile: permitFile,
              validIdFile: validIdFile,
              onPickPermitFile: onPickPermitFile,
              onPickValidId: onPickValidId,
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
    final borderColor = (isActive || isComplete)
        ? AppColors.primaryCyan
        : AppColors.cardBorder;
    final textColor = (isActive || isComplete)
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

class _Step1Form extends StatefulWidget {
  const _Step1Form({
    required this.fullNameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.confirmPassCtrl,
    required this.showErrors,
    required this.onNext,
  });

  final TextEditingController fullNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPassCtrl;
  final bool showErrors;
  final VoidCallback onNext;

  @override
  State<_Step1Form> createState() => _Step1FormState();
}

class _Step1FormState extends State<_Step1Form> {
  final _touched = <String>{};

  void _touch(String field) => setState(() => _touched.add(field));
  bool _show(String f) => _touched.contains(f) || widget.showErrors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabeledField(
          label: 'Full Name',
          error: _show('fullName')
              ? _V.fullName(widget.fullNameCtrl.text)
              : null,
          child: _Input(
            controller: widget.fullNameCtrl,
            hint: 'Maria Santos',
            hasError:
                _show('fullName') &&
                _V.fullName(widget.fullNameCtrl.text) != null,
            onChanged: (_) => _touch('fullName'),
          ),
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Email Address',
          error: _show('email') ? _V.email(widget.emailCtrl.text) : null,
          child: _Input(
            controller: widget.emailCtrl,
            hint: 'email@example.com',
            keyboardType: TextInputType.emailAddress,
            hasError: _show('email') && _V.email(widget.emailCtrl.text) != null,
            onChanged: (_) => _touch('email'),
          ),
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Phone Number',
          error: _show('phone') ? _V.phone(widget.phoneCtrl.text) : null,
          child: _Input(
            controller: widget.phoneCtrl,
            hint: '09XX-XXX-XXXX',
            keyboardType: TextInputType.phone,
            hasError: _show('phone') && _V.phone(widget.phoneCtrl.text) != null,
            onChanged: (_) => _touch('phone'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Password',
                error: _show('password')
                    ? _V.password(widget.passwordCtrl.text)
                    : null,
                child: _Input(
                  controller: widget.passwordCtrl,
                  hint: 'Min 6 characters',
                  obscure: true,
                  hasError:
                      _show('password') &&
                      _V.password(widget.passwordCtrl.text) != null,
                  onChanged: (_) => _touch('password'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Confirm Password',
                error: _show('confirmPass')
                    ? _V.confirmPassword(
                        widget.confirmPassCtrl.text,
                        widget.passwordCtrl.text,
                      )
                    : null,
                child: _Input(
                  controller: widget.confirmPassCtrl,
                  hint: 'Repeat password',
                  obscure: true,
                  hasError:
                      _show('confirmPass') &&
                      _V.confirmPassword(
                            widget.confirmPassCtrl.text,
                            widget.passwordCtrl.text,
                          ) !=
                          null,
                  onChanged: (_) => _touch('confirmPass'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _GradientButton(
          label: 'Next: Business Details →',
          onPressed: widget.onNext,
        ),
      ],
    );
  }
}

// ─── Step 2 Form ──────────────────────────────────────────────────────────────

class _Step2Form extends StatefulWidget {
  const _Step2Form({
    required this.showErrors,
    required this.isLoading,
    this.errorMessage,
    required this.businessNameCtrl,
    required this.businessType,
    required this.onBusinessTypeChanged,
    required this.ownerNameCtrl,
    required this.totalRoomsCtrl,
    required this.permitNumberCtrl,
    required this.registrationCtrl,
    required this.streetCtrl,
    required this.barangayCtrl,
    required this.cityCtrl,
    required this.provinceCtrl,
    required this.regionCtrl,
    required this.permitFile,
    required this.validIdFile,
    required this.onPickPermitFile,
    required this.onPickValidId,
    required this.onBack,
    required this.onSubmit,
  });

  final bool showErrors;
  final bool isLoading;
  final String? errorMessage;
  final TextEditingController businessNameCtrl;
  final String businessType;
  final ValueChanged<String?> onBusinessTypeChanged;
  final TextEditingController ownerNameCtrl;
  final TextEditingController totalRoomsCtrl;
  final TextEditingController permitNumberCtrl;
  final TextEditingController registrationCtrl;
  final TextEditingController streetCtrl;
  final TextEditingController barangayCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController provinceCtrl;
  final TextEditingController regionCtrl;
  final File? permitFile;
  final File? validIdFile;
  final VoidCallback onPickPermitFile;
  final VoidCallback onPickValidId;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  State<_Step2Form> createState() => _Step2FormState();
}

class _Step2FormState extends State<_Step2Form> {
  final _touched = <String>{};

  void _touch(String field) => setState(() => _touched.add(field));
  bool _show(String f) => _touched.contains(f) || widget.showErrors;

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
                error: _show('businessName')
                    ? _V.businessName(widget.businessNameCtrl.text)
                    : null,
                child: _Input(
                  controller: widget.businessNameCtrl,
                  hint: 'Hotel / Resort Name',
                  hasError:
                      _show('businessName') &&
                      _V.businessName(widget.businessNameCtrl.text) != null,
                  onChanged: (_) => _touch('businessName'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Business Type',
                child: _DropdownField(
                  value: widget.businessType,
                  items: const [
                    'Hotel',
                    'Resort',
                    'Inn',
                    'Pension House',
                    'Other',
                  ],
                  onChanged: widget.onBusinessTypeChanged,
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
                error: _show('ownerName')
                    ? _V.ownerName(widget.ownerNameCtrl.text)
                    : null,
                child: _Input(
                  controller: widget.ownerNameCtrl,
                  hint: 'Full name of owner',
                  hasError:
                      _show('ownerName') &&
                      _V.ownerName(widget.ownerNameCtrl.text) != null,
                  onChanged: (_) => _touch('ownerName'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Total Rooms / Units',
                error: _show('totalRooms')
                    ? _V.totalRooms(widget.totalRoomsCtrl.text)
                    : null,
                child: _Input(
                  controller: widget.totalRoomsCtrl,
                  hint: 'e.g. 30',
                  keyboardType: TextInputType.number,
                  hasError:
                      _show('totalRooms') &&
                      _V.totalRooms(widget.totalRoomsCtrl.text) != null,
                  onChanged: (_) => _touch('totalRooms'),
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
                error: _show('permitNumber')
                    ? _V.permitNumber(widget.permitNumberCtrl.text)
                    : null,
                child: _Input(
                  controller: widget.permitNumberCtrl,
                  hint: 'SP-HTL-2024-XXX',
                  hasError:
                      _show('permitNumber') &&
                      _V.permitNumber(widget.permitNumberCtrl.text) != null,
                  onChanged: (_) => _touch('permitNumber'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Registration Number',
                error: _show('registration')
                    ? _V.registrationNumber(widget.registrationCtrl.text)
                    : null,
                child: _Input(
                  controller: widget.registrationCtrl,
                  hint: 'BIR-2024-XXXXX',
                  hasError:
                      _show('registration') &&
                      _V.registrationNumber(widget.registrationCtrl.text) !=
                          null,
                  onChanged: (_) => _touch('registration'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Street',
          error: _show('street') ? _V.street(widget.streetCtrl.text) : null,
          child: _Input(
            controller: widget.streetCtrl,
            hint: 'House number, street',
            hasError: _show('street') && _V.street(widget.streetCtrl.text) != null,
            onChanged: (_) => _touch('street'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Barangay',
                error: _show('barangay') ? _V.barangay(widget.barangayCtrl.text) : null,
                child: _Input(
                  controller: widget.barangayCtrl,
                  hint: 'Barangay',
                  hasError: _show('barangay') && _V.barangay(widget.barangayCtrl.text) != null,
                  onChanged: (_) => _touch('barangay'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'City / Municipality',
                error: _show('city') ? _V.cityMunicipality(widget.cityCtrl.text) : null,
                child: _Input(
                  controller: widget.cityCtrl,
                  hint: 'City / Municipality',
                  hasError: _show('city') && _V.cityMunicipality(widget.cityCtrl.text) != null,
                  onChanged: (_) => _touch('city'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Province',
                error: _show('province') ? _V.province(widget.provinceCtrl.text) : null,
                child: _Input(
                  controller: widget.provinceCtrl,
                  hint: 'Province',
                  hasError: _show('province') && _V.province(widget.provinceCtrl.text) != null,
                  onChanged: (_) => _touch('province'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Region',
                error: _show('region') ? _V.region(widget.regionCtrl.text) : null,
                child: _Input(
                  controller: widget.regionCtrl,
                  hint: 'Region',
                  hasError: _show('region') && _V.region(widget.regionCtrl.text) != null,
                  onChanged: (_) => _touch('region'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        _LabeledField(
          label: 'Business Permit',
          error: widget.showErrors ? _V.file(widget.permitFile) : null,
          child: _FilePicker(
            label: 'Upload Permit (PDF / Image)',
            file: widget.permitFile,
            hasError: widget.showErrors && _V.file(widget.permitFile) != null,
            onPick: widget.onPickPermitFile,
          ),
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: "Owner's Valid ID",
          error: widget.showErrors ? _V.file(widget.validIdFile) : null,
          child: _FilePicker(
            label: "Upload Owner's Valid ID (PDF / Image)",
            file: widget.validIdFile,
            hasError: widget.showErrors && _V.file(widget.validIdFile) != null,
            onPick: widget.onPickValidId,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RegisterColors.textRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: RegisterColors.textRed.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: RegisterColors.textRed,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.errorMessage!,
                    style: const TextStyle(
                      color: RegisterColors.textRed,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            _BackButton(onPressed: widget.isLoading ? () {} : widget.onBack),
            const SizedBox(width: 12),
            Expanded(
              child: widget.isLoading
                  ? const _LoadingButton()
                  : _GradientButton(
                      label: 'Submit Registration',
                      onPressed: widget.onSubmit,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _FilePicker extends StatelessWidget {
  const _FilePicker({
    required this.label,
    required this.file,
    required this.hasError,
    required this.onPick,
  });

  final String label;
  final File? file;
  final bool hasError;
  final VoidCallback onPick;

  String get _fileName => file!.path.split('/').last;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? RegisterColors.textRed
        : AppColors.inputBorder;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              file != null ? Icons.check_circle : Icons.upload_file_rounded,
              color: file != null ? AppColors.primaryCyan : AppColors.textGray,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file != null ? _fileName : label,
                style: TextStyle(
                  color: file != null
                      ? AppColors.textWhite
                      : AppColors.textSubtle,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              file != null ? 'Change' : 'Browse',
              style: const TextStyle(
                color: AppColors.primaryCyan,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingButton extends StatelessWidget {
  const _LoadingButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      ),
    );
  }
}

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
            style: const TextStyle(
              color: RegisterColors.textRed,
              fontSize: 11.5,
            ),
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
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? RegisterColors.textRed
        : AppColors.inputBorder;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
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

class _GradientButton extends StatefulWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedOpacity(
            opacity: _hovered && !_pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
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
                      color: AppColors.primaryBlue.withOpacity(
                        _hovered ? 0.5 : 0.3,
                      ),
                      blurRadius: _hovered ? 20 : 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  const _BackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.cardBorder.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered ? AppColors.textGray : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back,
                  size: 16,
                  color: _hovered ? AppColors.textWhite : AppColors.textGray,
                ),
                const SizedBox(width: 8),
                Text(
                  'Back',
                  style: TextStyle(
                    color: _hovered ? AppColors.textWhite : AppColors.textGray,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  const _HoverButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedOpacity(
            opacity: _hovered && !_pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(
                      _hovered ? 0.55 : 0.3,
                    ),
                    blurRadius: _hovered ? 22 : 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}