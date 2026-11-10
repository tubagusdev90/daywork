import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/wages/pages/wages_page.dart';
import '../../features/attendance/pages/attendance_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/attendance/pages/worker_attendance_page.dart';
import '../../features/pay_periods/pages/pay_periods_page.dart';



class AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription _subscription;

  AuthRefreshNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter(AuthRefreshNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loggedIn =
          Supabase.instance.client.auth.currentSession != null;

      final isLoginPage = state.matchedLocation == '/login';

      if (!loggedIn && !isLoginPage) return '/login';
      if (loggedIn && isLoginPage) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/wages',
        builder: (context, state) => const WagesPage(),
      ),
      GoRoute(
        path: '/payment-periods',
        builder: (context, state) => const PayPeriodsPage(),
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendancePage(),
      ),
      GoRoute(
        path: '/attendance/worker',
        builder: (context, state) =>
            const WorkerAttendancePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Terjadi kesalahan navigasi:\n${state.error ?? state.uri}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}