import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PinchApp(),
    ),
  );
}

class PinchApp extends StatelessWidget {
  const PinchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pinch',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(child: Text('PINCH')),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
