import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document.dart';
import '../providers/connection_provider.dart';
import '../theme/tva_colors.dart';
import '../widgets/docs/doc_viewer.dart';
import '../widgets/docs/doc_toc.dart';

final _docsProvider = FutureProvider<List<Document>>((ref) async {
  final conn = ref.watch(connectionServiceProvider);
  return conn.getDocs('current');
});

final _selectedDocPathProvider = StateProvider<String?>((ref) => null);

final _docContentProvider = FutureProvider.family<String, String>((ref, path) async {
  final conn = ref.watch(connectionServiceProvider);
  return conn.readDocument('current', path);
});

class DocsScreen extends ConsumerWidget {
  const DocsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPath = ref.watch(_selectedDocPathProvider);

    if (selectedPath != null) {
      return _DocDetail(docPath: selectedPath);
    }
    return _DocList();
  }
}

class _DocList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(_docsProvider);

    return Container(
      color: TvaColors.bg,
      child: docsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: TvaColors.amber)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: TvaColors.clawd))),
        data: (docs) => ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(
            color: TvaColors.brd,
            height: 1,
          ),
          itemBuilder: (context, i) {
            final doc = docs[i];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              title: Text(
                doc.title,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TvaColors.txt,
                ),
              ),
              subtitle: Text(
                doc.path,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  color: TvaColors.txt3,
                ),
              ),
              trailing: _CategoryChip(category: doc.category),
              onTap: () {
                ref.read(_selectedDocPathProvider.notifier).state = doc.path;
              },
            );
          },
        ),
      ),
    );
  }
}

class _DocDetail extends ConsumerWidget {
  final String docPath;
  const _DocDetail({required this.docPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(_docContentProvider(docPath));
    final wide = MediaQuery.of(context).size.width > 1100;

    return Container(
      color: TvaColors.bg,
      child: Column(
        children: [
          // Back bar
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: TvaColors.brd)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 16,
                      color: TvaColors.txt2),
                  onPressed: () {
                    ref.read(_selectedDocPathProvider.notifier).state = null;
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  docPath,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
                    color: TvaColors.txt2,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: contentAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: TvaColors.amber)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: TvaColors.clawd))),
              data: (md) => Row(
                children: [
                  Expanded(child: DocViewer(markdown: md)),
                  if (wide) DocToc(markdown: md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final DocCategory category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (category) {
      DocCategory.spec => ('SPEC', TvaColors.tealBr),
      DocCategory.plan => ('PLAN', TvaColors.amber),
      DocCategory.finding => ('FIND', TvaColors.greenBr),
      DocCategory.brainstorm => ('IDEA', TvaColors.purple),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
