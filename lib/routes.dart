import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/providers/auth_providers.dart';

// Placeholder for dashboard - will be replaced later
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finova')),
      body: const Center(child: Text('Home - Dashboard placeholder')),
    );
  }
}

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
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
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
    ],
  );
}
