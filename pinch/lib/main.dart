import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/connection_provider.dart';
import 'router.dart';
import 'services/settings_service.dart';
import 'theme/tva_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final settings = await SettingsService().load();
  final container = ProviderContainer();

  final conn = container.read(connectionServiceProvider);
  conn.connect(settings.serverHost, settings.serverPort);

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
