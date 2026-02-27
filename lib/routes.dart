import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/wallets/presentation/wallets_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/transactions/presentation/transaction_form_screen.dart';
import 'features/transactions/data/transaction_model.dart';
import 'shared/widgets/main_shell.dart';

/// Listenable that notifies when Firebase auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

final _authChangeNotifier = _AuthChangeNotifier();

/// Riverpod provider so the router is created once and stays stable.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _authChangeNotifier,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isAuthRoute =
          state.location == '/login' || state.location == '/register';

      if (isLoggedIn && isAuthRoute) return '/';
      if (!isLoggedIn && !isAuthRoute) return '/login';
      return null;
    },
    routes: <RouteBase>[
      // ── Bottom‑nav shell ──
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child, location: state.location);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/wallets',
            builder: (context, state) => const WalletsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Auth routes ──
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          onSignUpTap: () => GoRouter.of(context).go('/register'),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegisterScreen(onLogInTap: () => GoRouter.of(context).go('/login')),
      ),

      // ── Transaction routes ──
      GoRoute(
        path: '/transaction/add',
        builder: (context, state) => const TransactionFormScreen(),
      ),
      GoRoute(
        path: '/transaction/edit',
        builder: (context, state) {
          final tx = state.extra as TransactionModel;
          return TransactionFormScreen(transaction: tx);
        },
      ),
    ],
  );
});
