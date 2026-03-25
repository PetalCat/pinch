import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/docs_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/session_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              key: ValueKey('home'),
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/session/:sessionId',
            pageBuilder: (context, state) {
              final isHistorical =
                  state.uri.queryParameters['historical'] == 'true';
              return NoTransitionPage(
                key: ValueKey('session-${state.pathParameters['sessionId']}'),
                child: SessionScreen(
                  sessionId: state.pathParameters['sessionId']!,
                  isHistorical: isHistorical,
                ),
              );
            },
          ),
          GoRoute(
            path: '/projects',
            pageBuilder: (context, state) => const NoTransitionPage(
              key: ValueKey('projects'),
              child: ProjectsScreen(),
            ),
          ),
          GoRoute(
            path: '/docs',
            pageBuilder: (context, state) => const NoTransitionPage(
              key: ValueKey('docs'),
              child: DocsScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => const NoTransitionPage(
              key: ValueKey('history'),
              child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              key: ValueKey('settings'),
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
