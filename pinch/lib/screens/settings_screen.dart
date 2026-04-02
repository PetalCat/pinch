import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../theme/tva_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _projectDirController;
  late TextEditingController _systemPromptController;
  String _model = 'auto';
  String _permissionMode = 'default';
  String _effort = 'high';
  bool _dangerouslySkipPermissions = false;
  bool _worktree = false;
  bool _initialized = false;
  bool _dirty = false;

  static const _mono = TextStyle(fontFamily: 'IBMPlexMono');

  static const _labelStyle = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: 9,
    color: TvaColors.txt3,
    letterSpacing: 2,
  );

  @override
  void initState() {
    super.initState();
    _projectDirController = TextEditingController();
    _systemPromptController = TextEditingController();
  }

  @override
  void dispose() {
    _projectDirController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _loadFrom(UserSettings s) {
    _projectDirController.text = s.defaultProjectDir ?? '';
    _model = s.model;
    _permissionMode = s.permissionMode;
    _effort = s.effort;
    _dangerouslySkipPermissions = s.dangerouslySkipPermissions;
    _worktree = s.worktree;
    _initialized = true;
    _dirty = false;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    final settings = UserSettings(
      defaultProjectDir: _projectDirController.text.trim().isEmpty
          ? null
          : _projectDirController.text.trim(),
      model: _model,
      permissionMode: _permissionMode,
      effort: _effort,
      dangerouslySkipPermissions: _dangerouslySkipPermissions,
      worktree: _worktree,
    );
    await ref.read(settingsProvider.notifier).save(settings);
    setState(() => _dirty = false);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: TvaColors.bg,
      body: settingsAsync.when(
        loading: () => const Center(
          child: Text('LOADING...', style: TextStyle(color: TvaColors.txt3)),
        ),
        error: (e, _) => Center(
          child:
              Text('Error: $e', style: const TextStyle(color: TvaColors.rust)),
        ),
        data: (settings) {
          if (!_initialized) _loadFrom(settings);

          return Column(
            children: [
              // Top bar
              Container(
                height: 52,
                color: TvaColors.bgInset,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/home'),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back,
                              size: 16, color: TvaColors.txt3),
                          const SizedBox(width: 8),
                          Text(
                            'BACK',
                            style: _mono.copyWith(
                              fontSize: 10,
                              color: TvaColors.txt3,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      'SETTINGS',
                      style: _mono.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TvaColors.txt,
                        letterSpacing: 3,
                      ),
                    ),
                    const Spacer(),
                    if (_dirty)
                      GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: TvaColors.amber,
                            border: Border.all(color: TvaColors.amberBr),
                          ),
                          child: Text(
                            'SAVE',
                            style: _mono.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: TvaColors.bgInset,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    if (!_dirty)
                      Text(
                        'SAVED',
                        style: _mono.copyWith(
                          fontSize: 10,
                          color: TvaColors.txt3,
                          letterSpacing: 2,
                        ),
                      ),
                  ],
                ),
              ),
              Container(height: 1, color: TvaColors.brd),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Session Defaults
                            Text(
                              'QUICK SESSION DEFAULTS',
                              style: _mono.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TvaColors.amber,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'These settings are used when you tap + QUICK SESSION.',
                              style: _mono.copyWith(
                                  fontSize: 10, color: TvaColors.txt3),
                            ),
                            const SizedBox(height: 24),

                            // Project Directory
                            _label('DEFAULT PROJECT DIRECTORY'),
                            _textField(
                              _projectDirController,
                              hint: '~/Developer/my-project',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Directory will be created if it doesn\'t exist. Supports ~ for home.',
                              style:
                                  _mono.copyWith(fontSize: 8, color: TvaColors.txt3),
                            ),
                            const SizedBox(height: 24),

                            // Model
                            _label('MODEL'),
                            _dropdown<String>(
                              value: _model,
                              items: const [
                                DropdownMenuItem(
                                    value: 'auto',
                                    child: Text('auto (use Claude\'s default)')),
                                DropdownMenuItem(
                                    value: 'opus', child: Text('opus')),
                                DropdownMenuItem(
                                    value: 'sonnet', child: Text('sonnet')),
                                DropdownMenuItem(
                                    value: 'haiku', child: Text('haiku')),
                              ],
                              onChanged: (v) {
                                setState(() => _model = v ?? 'auto');
                                _markDirty();
                              },
                            ),
                            const SizedBox(height: 24),

                            // Permission Mode
                            _label('PERMISSION MODE'),
                            _dropdown<String>(
                              value: _permissionMode,
                              items: const [
                                DropdownMenuItem(
                                    value: 'default',
                                    child: Text('default (ask for each)')),
                                DropdownMenuItem(
                                    value: 'acceptEdits',
                                    child: Text('acceptEdits')),
                                DropdownMenuItem(
                                    value: 'plan', child: Text('plan')),
                                DropdownMenuItem(
                                    value: 'auto', child: Text('auto')),
                                DropdownMenuItem(
                                    value: 'dontAsk',
                                    child: Text('dontAsk')),
                                DropdownMenuItem(
                                    value: 'bypassPermissions',
                                    child: Text('bypassPermissions')),
                              ],
                              onChanged: (v) {
                                setState(
                                    () => _permissionMode = v ?? 'default');
                                _markDirty();
                              },
                            ),
                            const SizedBox(height: 24),

                            // Effort
                            _label('EFFORT'),
                            _dropdown<String>(
                              value: _effort,
                              items: const [
                                DropdownMenuItem(
                                    value: 'low', child: Text('low')),
                                DropdownMenuItem(
                                    value: 'medium', child: Text('medium')),
                                DropdownMenuItem(
                                    value: 'high',
                                    child: Text('high (default)')),
                                DropdownMenuItem(
                                    value: 'max', child: Text('max')),
                              ],
                              onChanged: (v) {
                                setState(() => _effort = v ?? 'high');
                                _markDirty();
                              },
                            ),
                            const SizedBox(height: 24),

                            Container(height: 1, color: TvaColors.brd),
                            const SizedBox(height: 24),

                            Text(
                              'DANGEROUS',
                              style: _mono.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TvaColors.rust,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Switches
                            _switch(
                              label: 'Skip All Permissions',
                              value: _dangerouslySkipPermissions,
                              onChanged: (v) {
                                setState(
                                    () => _dangerouslySkipPermissions = v);
                                _markDirty();
                              },
                              labelColor: TvaColors.rust,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bypasses ALL permission checks. Use only in sandboxed environments.',
                              style:
                                  _mono.copyWith(fontSize: 8, color: TvaColors.txt3),
                            ),
                            const SizedBox(height: 16),
                            _switch(
                              label: 'Git Worktree',
                              value: _worktree,
                              onChanged: (v) {
                                setState(() => _worktree = v);
                                _markDirty();
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Run sessions in an isolated git worktree. Requires a git repository.',
                              style:
                                  _mono.copyWith(fontSize: 8, color: TvaColors.txt3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: _labelStyle),
      );

  Widget _textField(TextEditingController controller, {String? hint}) {
    return TextField(
      controller: controller,
      style: _mono.copyWith(fontSize: 13, color: TvaColors.txt),
      onChanged: (_) => _markDirty(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _mono.copyWith(fontSize: 12, color: TvaColors.txt3),
        filled: true,
        fillColor: TvaColors.bgInset,
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: TvaColors.brd),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: TvaColors.amber),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: TvaColors.bgInset,
        border: Border.all(color: TvaColors.brd),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: TvaColors.bgPanel,
        style: _mono.copyWith(fontSize: 13, color: TvaColors.txt2),
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  Widget _switch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? labelColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: _labelStyle.copyWith(
                color: labelColor ?? TvaColors.txt3, fontSize: 10),
          ),
        ),
        SizedBox(
          height: 28,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: TvaColors.amber,
            activeTrackColor: TvaColors.amberDm,
            inactiveThumbColor: TvaColors.txt3,
            inactiveTrackColor: TvaColors.bgInset,
          ),
        ),
      ],
    );
  }
}
