import 'package:flutter/material.dart';

// Replace these with your actual page imports
import '../ui/shared/pages/login_page.dart';
import '../ui/shared/pages/register_page.dart';
import '../ui/admin/pages/admin_dashboard_page.dart';
import '../ui/admin/pages/admin_accommodations_page.dart';
import '../ui/admin/pages/admin_reports_page.dart';
import '../ui/admin/pages/admin_messages_page.dart';
import '../ui/admin/pages/admin_compliance_page.dart';
import '../ui/admin/pages/admin_profile_page.dart';
import '../ui/business/pages/business_dashboard_page.dart';
import '../ui/business/pages/business_guest_entry_page.dart';
import '../ui/business/pages/business_guest_records_page.dart';
import '../ui/business/pages/business_reports_page.dart';
import '../ui/business/pages/business_messages_page.dart';
import '../ui/business/pages/business_profile_page.dart';

// ─── Route Names ──────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const login        = '/login';
  static const register     = '/register';
  static const adminDashboard    = '/admin/dashboard';
  static const adminAccommodations = '/admin/accommodations';
  static const adminMessages     = '/admin/messages';
  static const adminReports      = '/admin/reports';
  static const adminCompliance    = '/admin/compliance';
  static const adminProfile      = '/admin/profile';
  static const businessDashboard = '/business/dashboard'; 
  static const businessGuestEntry = '/business/guest-entry';
  static const businessGuestRecord = '/business/guest-records';
  static const businessReports = '/business/reports';
  static const businessMessages = '/business/messages';
  static const businessProfile = '/business/profile';
}

// ─── Router ───────────────────────────────────────────────────────────────────

abstract final class AppRouter {
  /// The initial route when the app launches.
  static const initialRoute = AppRoutes.login;

  /// Named-route factory used by [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {

      // Admin Pages
      AppRoutes.login         => _fade(const LoginPage(),        settings),
      AppRoutes.register      => _fade(const RegisterPage(),     settings),
      AppRoutes.adminDashboard     => _fade(const AdminDashboardPage(),    settings),
      AppRoutes.adminAccommodations=> _fade(const AdminAccommodationsPage(), settings),
      AppRoutes.adminMessages      => _fade(const AdminMessagesPage(),     settings),
      AppRoutes.adminReports       => _fade(const AdminReportsPage(),      settings),
      AppRoutes.adminProfile       => _fade(const AdminProfilePage(),     settings),
      AppRoutes.adminCompliance    => _fade(const AdminCompliancePage(),   settings),

      // Business Pages
      AppRoutes.businessDashboard     => _fade(const BusinessDashboardPage(),    settings),
      AppRoutes.businessGuestEntry    => _fade(const BusinessGuestEntryPage(),   settings),
      AppRoutes.businessGuestRecord   => _fade(const BusinessGuestRecordsPage(), settings),
      AppRoutes.businessMessages      => _fade(const BusinessMessagesPage(),     settings),
      AppRoutes.businessReports       => _fade(const BusinessReportsPage(),      settings),
      AppRoutes.businessProfile       => _fade(const BusinessProfilePage(),      settings),

      // ── Placeholders (remove once real pages are wired) ──────────────────
      // AppRoutes.adminAccommodations=> _fade(const AdminAccommodationsPage(), settings),
      // AppRoutes.adminMessages      => _fade(const AdminMessagesPage(),     settings),
      // AppRoutes.adminReports       => _fade(const AdminReportsPage(),      settings),
      // AppRoutes.adminProfile       => _fade(const AdminProfilePage(),     settings),
      // AppRoutes.adminCompliance    => _fade(const AdminCompliancePage(),   settings),
      // ── Placeholders (remove once real pages are wired) ──────────────────
      // AppRoutes.dashboard      => _fade(_PlaceholderPage(title: 'Dashboard'),    settings),
      // AppRoutes.accommodations => _fade(_PlaceholderPage(title: 'Accommodations'), settings),
      // AppRoutes.tourists       => _fade(_PlaceholderPage(title: 'Tourists'),     settings),
      // AppRoutes.reports        => _fade(_PlaceholderPage(title: 'Reports'),      settings),
      // AppRoutes.settings_      => _fade(_PlaceholderPage(title: 'Settings'),     settings),

      _ => _notFound(settings),
    };
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Smooth fade transition — feels cleaner than the default slide on desktop.
  static PageRouteBuilder<dynamic> _fade(
    Widget page,
    RouteSettings settings,
  ) =>
      PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 180),
      );

  static Route<dynamic> _notFound(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => _NotFoundPage(routeName: settings.name ?? '?'),
    );
  }
}

// ─── Dev-only Placeholder Page ────────────────────────────────────────────────
// Remove this whole section once every page is implemented.

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      body: Center(
        child: Text(
          '$title\n(coming soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8A9BB5),
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

// ─── 404 Page ─────────────────────────────────────────────────────────────────

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage({required this.routeName});
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF4D6A), size: 48),
            const SizedBox(height: 16),
            Text(
              'Route not found: $routeName',
              style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.adminDashboard,
              ),
              child: const Text(
                'Go to Dashboard',
                style: TextStyle(color: Color(0xFF00D4FF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}