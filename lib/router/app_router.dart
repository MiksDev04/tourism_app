import 'package:flutter/material.dart';
import 'package:tourism_app/core/services/session_service.dart';

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
  static const login                = '/login';
  static const register             = '/register';
  static const adminDashboard       = '/admin/dashboard';
  static const adminAccommodations  = '/admin/accommodations';
  static const adminMessages        = '/admin/messages';
  static const adminReports         = '/admin/reports';
  static const adminCompliance      = '/admin/compliance';
  static const adminProfile         = '/admin/profile';
  static const businessDashboard    = '/business/dashboard';
  static const businessGuestEntry   = '/business/guest-entry';
  static const businessGuestRecord  = '/business/guest-records';
  static const businessReports      = '/business/reports';
  static const businessMessages     = '/business/messages';
  static const businessProfile      = '/business/profile';
}

// ─── Route Permissions ────────────────────────────────────────────────────────
//
// Empty set  = public (no login required).
// Non-empty  = the roles that may visit this route.

abstract final class _RoutePermissions {
  static const Map<String, Set<String>> _map = {
    AppRoutes.login:               {},           // public
    AppRoutes.register:            {},           // public
    AppRoutes.adminDashboard:      {'admin'},
    AppRoutes.adminAccommodations: {'admin'},
    AppRoutes.adminMessages:       {'admin'},
    AppRoutes.adminReports:        {'admin'},
    AppRoutes.adminCompliance:     {'admin'},
    AppRoutes.adminProfile:        {'admin'},
    AppRoutes.businessDashboard:   {'business'},
    AppRoutes.businessGuestEntry:  {'business'},
    AppRoutes.businessGuestRecord: {'business'},
    AppRoutes.businessReports:     {'business'},
    AppRoutes.businessMessages:    {'business'},
    AppRoutes.businessProfile:     {'business'},
  };

  /// Returns null if the route is allowed, or a redirect route if blocked.
  /// - Not logged in           → login
  /// - Wrong role              → access-denied page (returned as a widget)
  /// - Public or matching role → null (proceed normally)
  static String? guard(String routeName) {
    final allowed = _map[routeName];
    if (allowed == null) return null;          // unknown route — let _notFound handle it

    // Public route — always allowed
    if (allowed.isEmpty) return null;

    final session = SessionService.instance.current;

    // Not logged in
    if (session == null) return AppRoutes.login;

    // Role mismatch — caller will show AccessDeniedPage
    if (!allowed.contains(session.role)) return '__denied__';

    return null; // all good
  }
}

// ─── Router ───────────────────────────────────────────────────────────────────

abstract final class AppRouter {
  /// Computed at runtime — skips login if a session is already cached.
  static String get initialRoute {
    final session = SessionService.instance.current;
    if (session == null) return AppRoutes.login;
    return session.role == 'admin'
        ? AppRoutes.adminDashboard
        : AppRoutes.businessDashboard;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // ── Auth guard ───────────────────────────────────────────────────────────
    final guardResult = _RoutePermissions.guard(routeName);
    if (guardResult == AppRoutes.login) {
      return _fade(const LoginPage(), const RouteSettings(name: AppRoutes.login));
    }
    if (guardResult == '__denied__') {
      return _fade(
        AccessDeniedPage(attemptedRoute: routeName),
        settings,
      );
    }

    // ── Normal routing ───────────────────────────────────────────────────────
    return switch (routeName) {
      AppRoutes.login                => _fade(const LoginPage(),                settings),
      AppRoutes.register             => _fade(const RegisterPage(),             settings),
      AppRoutes.adminDashboard       => _fade(const AdminDashboardPage(),       settings),
      AppRoutes.adminAccommodations  => _fade(const AdminAccommodationsPage(),  settings),
      AppRoutes.adminMessages        => _fade(const AdminMessagesPage(),        settings),
      AppRoutes.adminReports         => _fade(const AdminReportsPage(),         settings),
      AppRoutes.adminProfile         => _fade(const AdminProfilePage(),         settings),
      AppRoutes.adminCompliance      => _fade(const AdminCompliancePage(),      settings),
      AppRoutes.businessDashboard    => _fade(const BusinessDashboardPage(),    settings),
      AppRoutes.businessGuestEntry   => _fade(const BusinessGuestEntryPage(),   settings),
      AppRoutes.businessGuestRecord  => _fade(const BusinessGuestRecordsPage(), settings),
      AppRoutes.businessMessages     => _fade(const BusinessMessagesPage(),     settings),
      AppRoutes.businessReports      => _fade(const BusinessReportsPage(),      settings),
      AppRoutes.businessProfile      => _fade(const BusinessProfilePage(),      settings),
      _                              => _notFound(settings),
    };
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  static PageRouteBuilder<dynamic> _fade(Widget page, RouteSettings settings) =>
      PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 180),
      );

  static Route<dynamic> _notFound(RouteSettings settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => _NotFoundPage(routeName: settings.name ?? '?'),
      );
}

// ─── Access Denied Page ───────────────────────────────────────────────────────

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key, required this.attemptedRoute});
  final String attemptedRoute;

  String get _homeRoute {
    final role = SessionService.instance.current?.role;
    return role == 'admin' ? AppRoutes.adminDashboard : AppRoutes.businessDashboard;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded,
                color: Color(0xFFFF4D6A), size: 52),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have permission to view "$attemptedRoute".',
              style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, _homeRoute),
              child: const Text(
                'Go to my Dashboard',
                style: TextStyle(color: Color(0xFF00D4FF)),
              ),
            ),
          ],
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
            const Icon(Icons.error_outline,
                color: Color(0xFFFF4D6A), size: 48),
            const SizedBox(height: 16),
            Text(
              'Route not found: $routeName',
              style: const TextStyle(
                  color: Color(0xFF8A9BB5), fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRouter.initialRoute,
              ),
              child: const Text('Go to Dashboard',
                  style: TextStyle(color: Color(0xFF00D4FF))),
            ),
          ],
        ),
      ),
    );
  }
}