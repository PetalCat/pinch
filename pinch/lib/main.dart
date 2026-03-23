import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/tva_theme.dart';

void main() {
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PinchApp(),
    ),
  );
}

class PinchApp extends ConsumerWidget {
  const PinchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Pinch',
      theme: TvaTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
