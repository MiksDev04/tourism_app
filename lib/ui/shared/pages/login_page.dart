import 'package:flutter/material.dart';
import '../../../router/app_router.dart';
import '../../../core/constants/app_colors.dart'; // Import your actual AppColors file

// REMOVE the entire LoginPage class that wraps MaterialApp:
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoginScreen(),
    );
  }
}

// ─── Login Screen ─────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(
    text: 'grandhotel@sanpablo.com',
  );
  final _passwordController = TextEditingController(text: '••••••••••');
  final bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillTourismOffice() {
    setState(() {
      _emailController.text = 'admin@tourism.sanpablo.gov';
      _passwordController.text = 'admin123';
    });
  }

  void _fillGrandHotel() {
    setState(() {
      _emailController.text = 'grandhotel@sanpablo.com';
      _passwordController.text = 'hotel123';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.3),
              radius: 1.2,
              colors: [Color(0xFF0D2040), AppColors.backgroundDark],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _AppLogo(),
                    const SizedBox(height: 16),
                    const _AppTitle(),
                    const SizedBox(height: 40),
                    const _LoginCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Logo ─────────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}

// ─── Title ────────────────────────────────────────────────────────────────────

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'San Pablo City',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Tourism Demographics System',
          style: TextStyle(
            color: AppColors.primaryCyan,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Login Card ───────────────────────────────────────────────────────────────

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _emailController = TextEditingController(
    text: 'grandhotel@sanpablo.com',
  );
  final _passwordController = TextEditingController(text: '••••••••••');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillTourismOffice() {
    setState(() {
      _emailController.text = 'admin@tourism.sanpablo.gov';
      _passwordController.text = 'admin123';
      _obscurePassword = true;
    });
  }

  void _fillGrandHotel() {
    setState(() {
      _emailController.text = 'grandhotel@sanpablo.com';
      _passwordController.text = 'hotel123';
      _obscurePassword = true;
    });
  }

  void _handleSignIn() {
    final email = _emailController.text;

    if (email == 'admin@tourism.sanpablo.gov') {
      // Admin goes to admin dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else if (email == 'grandhotel@sanpablo.com') {
      // Business goes to business dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.businessDashboard);
    } else {
      // Default or show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sign In heading
          const Text(
            'Sign In',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // Email field
          const _FieldLabel(label: 'Email Address'),
          const SizedBox(height: 8),
          _InputField(
            controller: _emailController,
            hintText: 'Enter email address',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),

          // Password field
          const _FieldLabel(label: 'Password'),
          const SizedBox(height: 8),
          _PasswordField(
            controller: _passwordController,
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 22),

          // Sign In button
          _SignInButton(onPressed: _handleSignIn),
          const SizedBox(height: 16),

          // Register link
          Center(
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.register),
              child: const Text(
                'Register your accommodation establishment →',
                style: TextStyle(
                  color: AppColors.primaryCyan,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Divider
          const Divider(color: AppColors.cardBorder, thickness: 1),
          const SizedBox(height: 16),

          // Demo credentials label
          const Center(
            child: Text(
              'Demo Credentials',
              style: TextStyle(color: AppColors.textSubtle, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 12),

          // Demo credential buttons
          Row(
            children: [
              Expanded(
                child: _DemoButton(
                  label: 'Tourism Office (Admin)',
                  borderColor: AppColors.inputBorder,
                  textColor: AppColors.textWhite,
                  onPressed: _fillTourismOffice,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DemoButton(
                  label: 'Grand Hotel (Business)',
                  borderColor: AppColors.accentPurple.withOpacity(0.5),
                  textColor: AppColors.accentPurple,
                  onPressed: _fillGrandHotel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textGray,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─── Input Field ──────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textSubtle),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primaryCyan,
            width: 1.5,
          ),
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
      style: const TextStyle(color: AppColors.textWhite, fontSize: 14.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primaryCyan,
            width: 1.5,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSubtle,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ─── Sign In Button ───────────────────────────────────────────────────────────

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.login_rounded, size: 18, color: Colors.white),
          label: const Text(
            'Sign In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Demo Button ──────────────────────────────────────────────────────────────

class _DemoButton extends StatelessWidget {
  const _DemoButton({
    required this.label,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        side: BorderSide(color: borderColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.transparent,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}