import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/login_screen.dart';

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

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/login',
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
            const Scaffold(body: Center(child: Text('Register - coming soon'))),
      ),
    ],
  );
}
