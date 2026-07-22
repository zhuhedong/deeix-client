import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/password_reset_page.dart';
import '../features/auth/presentation/profile_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/sessions_page.dart';
import '../features/auth/presentation/two_factor_page.dart';
import '../features/billing/presentation/billing_page.dart';
import '../features/chat/presentation/chat_page.dart';
import '../features/file/presentation/files_page.dart';
import '../features/project/presentation/projects_page.dart';
import '../features/search/presentation/search_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../shared/widgets/loading_view.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final status = auth.status;
      final loc = state.matchedLocation;
      final publicAuth =
          loc == '/login' ||
          loc == '/register' ||
          loc == '/password-reset' ||
          loc == '/two-factor';

      if (status == AuthStatus.unknown) {
        return null;
      }

      if (status == AuthStatus.twoFactor) {
        return loc == '/two-factor' ? null : '/two-factor';
      }

      if (status == AuthStatus.unauthenticated) {
        return publicAuth ? null : '/login';
      }

      // authenticated
      if (loc == '/login' ||
          loc == '/register' ||
          loc == '/two-factor' ||
          loc == '/password-reset') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetPage(),
      ),
      GoRoute(
        path: '/two-factor',
        builder: (context, state) => const TwoFactorPage(),
      ),
      GoRoute(
        path: '/',
        // Watch (not read) auth status: on cold-start restore we stay at '/'
        // while status flips unknown → authenticated, and go_router does NOT
        // re-run a builder when the location is unchanged. A Consumer that
        // watches the status rebuilds the home from the spinner into the chat.
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final status = ref.watch(
              authControllerProvider.select((s) => s.status),
            );
            if (status == AuthStatus.authenticated) {
              // Home opens straight into a fresh draft chat ('' = new session).
              return const ChatPage(conversationId: '');
            }
            // unknown → restoring; unauthenticated/twoFactor → redirect will
            // move us to /login or /two-factor momentarily.
            return const Scaffold(body: LoadingView(message: '正在恢复登录状态…'));
          },
        ),
        routes: [
          GoRoute(
            path: 'chat/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ChatPage(conversationId: id);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: 'billing',
            builder: (context, state) => const BillingPage(),
          ),
          GoRoute(
            path: 'files',
            builder: (context, state) => const FilesPage(),
          ),
          GoRoute(
            path: 'sessions',
            builder: (context, state) => const SessionsPage(),
          ),
          GoRoute(
            path: 'projects',
            builder: (context, state) => const ProjectsPage(),
          ),
          GoRoute(
            path: 'search',
            builder: (context, state) => const SearchPage(),
          ),
        ],
      ),
    ],
  );
});
