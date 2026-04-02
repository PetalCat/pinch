import 'package:flutter/material.dart';

import '../models/session_options.dart';
import '../theme/tva_colors.dart';

Future<SessionOptions?> showSessionCreateDialog(
  BuildContext context, {
  String? projectDir,
}) async {
  return showModalBottomSheet<SessionOptions>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TvaColors.bgPanel,
    shape: const RoundedRectangleBorder(),
    builder: (context) => SessionCreateSheet(initialProjectDir: projectDir),
  );
}

class SessionCreateSheet extends StatefulWidget {
  const SessionCreateSheet({super.key, this.initialProjectDir});

  final String? initialProjectDir;

  @override
  State<SessionCreateSheet> createState() => _SessionCreateSheetState();
}

class _SessionCreateSheetState extends State<SessionCreateSheet> {
  late final TextEditingController _projectDirController;
  late final TextEditingController _customModelController;
  late final TextEditingController _sessionNameController;
  late final TextEditingController _maxBudgetController;
  late final TextEditingController _systemPromptController;
  late final TextEditingController _appendSystemPromptController;
  late final TextEditingController _allowedToolsController;
  late final TextEditingController _disallowedToolsController;
  late final TextEditingController _addDirsController;
  late final TextEditingController _mcpConfigController;

  String _model = 'auto';
  String _permissionMode = 'default';
  String _effort = 'high';
  bool _dangerouslySkipPermissions = false;
  bool _allowDangerouslySkipPermissions = false;
  bool _worktree = false;

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
    _projectDirController =
        TextEditingController(text: widget.initialProjectDir ?? '');
    _customModelController = TextEditingController();
    _sessionNameController = TextEditingController();
    _maxBudgetController = TextEditingController();
    _systemPromptController = TextEditingController();
    _appendSystemPromptController = TextEditingController();
    _allowedToolsController = TextEditingController();
    _disallowedToolsController = TextEditingController();
    _addDirsController = TextEditingController();
    _mcpConfigController = TextEditingController();
  }

  @override
  void dispose() {
    _projectDirController.dispose();
    _customModelController.dispose();
    _sessionNameController.dispose();
    _maxBudgetController.dispose();
    _systemPromptController.dispose();
    _appendSystemPromptController.dispose();
    _allowedToolsController.dispose();
    _disallowedToolsController.dispose();
    _addDirsController.dispose();
    _mcpConfigController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _mono.copyWith(fontSize: 11, color: TvaColors.txt3),
      filled: true,
      fillColor: TvaColors.bgInset,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: TvaColors.brd),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: TvaColors.brd2),
      ),
    );
  }

  TextStyle get _inputTextStyle =>
      _mono.copyWith(fontSize: 12, color: TvaColors.txt);

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(), style: _labelStyle),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: TvaColors.bgInset,
        border: Border.all(color: TvaColors.brd),
      ),
      child: TextField(
        controller: controller,
        style: _inputTextStyle,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _inputDecoration(hint: hint),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
        style: _mono.copyWith(fontSize: 12, color: TvaColors.txt2),
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  Widget _buildSwitch({
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
              color: labelColor ?? TvaColors.txt3,
            ),
          ),
        ),
        SizedBox(
          height: 24,
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

  Future<void> _onDangerouslySkipToggle(bool val) async {
    if (val) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: TvaColors.bgPanel,
          shape: const RoundedRectangleBorder(),
          title: Text(
            'CONFIRM',
            style: _mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TvaColors.rust,
              letterSpacing: 2,
            ),
          ),
          content: Text(
            'This will skip ALL permission checks. Are you sure?',
            style: _mono.copyWith(fontSize: 11, color: TvaColors.txt2),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('CANCEL',
                  style: _mono.copyWith(fontSize: 10, color: TvaColors.txt3)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('CONFIRM',
                  style: _mono.copyWith(fontSize: 10, color: TvaColors.rust)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        setState(() => _dangerouslySkipPermissions = true);
      }
    } else {
      setState(() => _dangerouslySkipPermissions = false);
    }
  }

  void _submit() {
    final projectDir = _projectDirController.text.trim();
    if (projectDir.isEmpty) return;

    final model = _model == 'custom' ? _customModelController.text.trim() : _model == 'auto' ? null : _model;

    final allowedTools = _allowedToolsController.text.trim().isEmpty
        ? <String>[]
        : _allowedToolsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final disallowedTools = _disallowedToolsController.text.trim().isEmpty
        ? <String>[]
        : _disallowedToolsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final addDirs = _addDirsController.text.trim().isEmpty
        ? <String>[]
        : _addDirsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final budgetText = _maxBudgetController.text.trim();
    final maxBudget = budgetText.isEmpty ? null : double.tryParse(budgetText);

    final options = SessionOptions(
      projectDir: projectDir,
      model: (model == null || model.isEmpty) ? null : model,
      permissionMode:
          _permissionMode == 'default' ? null : _permissionMode,
      dangerouslySkipPermissions: _dangerouslySkipPermissions,
      allowDangerouslySkipPermissions: _allowDangerouslySkipPermissions,
      allowedTools: allowedTools,
      disallowedTools: disallowedTools,
      systemPrompt: _systemPromptController.text.trim().isEmpty
          ? null
          : _systemPromptController.text.trim(),
      appendSystemPrompt: _appendSystemPromptController.text.trim().isEmpty
          ? null
          : _appendSystemPromptController.text.trim(),
      effort: _effort,
      maxBudget: maxBudget,
      addDirs: addDirs,
      mcpConfig: _mcpConfigController.text.trim().isEmpty
          ? null
          : _mcpConfigController.text.trim(),
      worktree: _worktree,
      sessionName: _sessionNameController.text.trim().isEmpty
          ? null
          : _sessionNameController.text.trim(),
    );

    Navigator.of(context).pop(options);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'NEW SESSION',
              style: _mono.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TvaColors.amber,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),

            // Scrollable content
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Project Directory
                  _buildLabel('PROJECT DIRECTORY'),
                  _buildTextField(_projectDirController,
                      hint: '/path/to/project'),
                  const SizedBox(height: 16),

                  // Model
                  _buildLabel('MODEL'),
                  _buildDropdown<String>(
                    value: _model,
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('auto (default)')),
                      DropdownMenuItem(value: 'opus', child: Text('opus')),
                      DropdownMenuItem(value: 'sonnet', child: Text('sonnet')),
                      DropdownMenuItem(value: 'haiku', child: Text('haiku')),
                      DropdownMenuItem(value: 'custom', child: Text('custom')),
                    ],
                    onChanged: (v) => setState(() => _model = v ?? 'auto'),
                  ),
                  if (_model == 'custom') ...[
                    const SizedBox(height: 8),
                    _buildTextField(_customModelController,
                        hint: 'model identifier'),
                  ],
                  const SizedBox(height: 16),

                  // Permission Mode
                  _buildLabel('PERMISSION MODE'),
                  _buildDropdown<String>(
                    value: _permissionMode,
                    items: const [
                      DropdownMenuItem(
                          value: 'default', child: Text('default')),
                      DropdownMenuItem(
                          value: 'acceptEdits', child: Text('acceptEdits')),
                      DropdownMenuItem(value: 'plan', child: Text('plan')),
                      DropdownMenuItem(value: 'auto', child: Text('auto')),
                      DropdownMenuItem(
                          value: 'dontAsk', child: Text('dontAsk')),
                      DropdownMenuItem(
                          value: 'bypassPermissions',
                          child: Text('bypassPermissions')),
                    ],
                    onChanged: (v) =>
                        setState(() => _permissionMode = v ?? 'default'),
                  ),
                  const SizedBox(height: 16),

                  // Dangerous Permissions
                  _buildSwitch(
                    label: 'Dangerously Skip Permissions',
                    value: _dangerouslySkipPermissions,
                    onChanged: _onDangerouslySkipToggle,
                    labelColor: TvaColors.rust,
                  ),
                  const SizedBox(height: 8),
                  _buildSwitch(
                    label: 'Allow Dangerously Skip Permissions',
                    value: _allowDangerouslySkipPermissions,
                    onChanged: (v) =>
                        setState(() => _allowDangerouslySkipPermissions = v),
                  ),
                  const SizedBox(height: 16),

                  // Advanced
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: TvaColors.brd),
                      color: TvaColors.bgInset,
                    ),
                    child: ExpansionTile(
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      title: Text('ADVANCED',
                          style: _labelStyle.copyWith(fontSize: 10)),
                      iconColor: TvaColors.txt3,
                      collapsedIconColor: TvaColors.txt3,
                      shape: const RoundedRectangleBorder(),
                      collapsedShape: const RoundedRectangleBorder(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('SESSION NAME'),
                              _buildTextField(_sessionNameController,
                                  hint: 'optional name'),
                              const SizedBox(height: 12),

                              _buildLabel('EFFORT'),
                              _buildDropdown<String>(
                                value: _effort,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'low', child: Text('low')),
                                  DropdownMenuItem(
                                      value: 'medium', child: Text('medium')),
                                  DropdownMenuItem(
                                      value: 'high', child: Text('high')),
                                  DropdownMenuItem(
                                      value: 'max', child: Text('max')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _effort = v ?? 'high'),
                              ),
                              const SizedBox(height: 12),

                              _buildLabel('MAX BUDGET USD'),
                              _buildTextField(_maxBudgetController,
                                  hint: '0.00',
                                  keyboardType: TextInputType.number),
                              const SizedBox(height: 12),

                              _buildLabel('SYSTEM PROMPT'),
                              _buildTextField(_systemPromptController,
                                  hint: 'custom system prompt',
                                  maxLines: 3),
                              const SizedBox(height: 12),

                              _buildLabel('APPEND SYSTEM PROMPT'),
                              _buildTextField(_appendSystemPromptController,
                                  hint: 'appended to default prompt',
                                  maxLines: 3),
                              const SizedBox(height: 12),

                              _buildLabel('ALLOWED TOOLS'),
                              _buildTextField(_allowedToolsController,
                                  hint: 'tool1, tool2'),
                              const SizedBox(height: 12),

                              _buildLabel('DISALLOWED TOOLS'),
                              _buildTextField(_disallowedToolsController,
                                  hint: 'tool1, tool2'),
                              const SizedBox(height: 12),

                              _buildLabel('ADDITIONAL DIRECTORIES'),
                              _buildTextField(_addDirsController,
                                  hint: '/path1, /path2'),
                              const SizedBox(height: 12),

                              _buildLabel('MCP CONFIG'),
                              _buildTextField(_mcpConfigController,
                                  hint: 'mcp config path'),
                              const SizedBox(height: 12),

                              _buildSwitch(
                                label: 'Git Worktree',
                                value: _worktree,
                                onChanged: (v) =>
                                    setState(() => _worktree = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create button
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: TvaColors.orange,
                        border: Border.all(color: TvaColors.orangeBr),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'CREATE SESSION',
                        style: _mono.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TvaColors.parch,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
