import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/wallets/presentation/wallets_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/transactions/presentation/transaction_form_screen.dart';
import 'features/transactions/data/transaction_model.dart';
import 'shared/widgets/main_shell.dart';

GoRouter createRouter(WidgetRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute =
          state.location == '/login' || state.location == '/register';

      if (isLoggedIn && isAuthRoute) return '/';
      if (!isLoggedIn && !isAuthRoute) return '/login';
      return null;
    },
    routes: <RouteBase>[
      // ── Bottom‑nav shell ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallets',
                builder: (context, state) => const WalletsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
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
}
