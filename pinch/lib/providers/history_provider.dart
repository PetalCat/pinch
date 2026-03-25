import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connection_provider.dart';

final sessionHistoryListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final conn = ref.watch(connectionServiceProvider);
  return conn.getHistoricalSessions();
});
