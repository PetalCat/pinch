class Agent {
  final String id;
  final String name;
  final String status; // stopped | starting | running | error | restarting
  final String nodeId;
  final String? systemPrompt;
  final List<String> allowedTools;
  final List<String> disallowedTools;
  final String? configDir;
  final String? projectDir;
  final String? model;
  final String? matrixUserId;
  final bool matrixProvisioned;
  final String? projectosProjectId;
  final bool autoRestart;
  final DateTime createdAt;
  final DateTime? lastStartedAt;

  const Agent({
    required this.id,
    required this.name,
    required this.status,
    required this.nodeId,
    this.systemPrompt,
    this.allowedTools = const [],
    this.disallowedTools = const [],
    this.configDir,
    this.projectDir,
    this.model,
    this.matrixUserId,
    this.matrixProvisioned = false,
    this.projectosProjectId,
    this.autoRestart = true,
    required this.createdAt,
    this.lastStartedAt,
  });

  bool get isRunning => status == 'running';
  bool get isStopped => status == 'stopped';

  factory Agent.fromJson(Map<String, dynamic> json) => Agent(
        id: json['id'] as String,
        name: json['name'] as String,
        status: json['status'] as String? ?? 'stopped',
        nodeId: json['nodeId'] as String? ?? '',
        systemPrompt: json['systemPrompt'] as String?,
        allowedTools: (json['allowedTools'] as List<dynamic>?)?.cast<String>() ?? [],
        disallowedTools: (json['disallowedTools'] as List<dynamic>?)?.cast<String>() ?? [],
        configDir: json['configDir'] as String?,
        projectDir: json['projectDir'] as String?,
        model: json['model'] as String?,
        matrixUserId: json['matrixUserId'] as String?,
        matrixProvisioned: json['matrixProvisioned'] as bool? ?? false,
        projectosProjectId: json['projectosProjectId'] as String?,
        autoRestart: json['autoRestart'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastStartedAt: json['lastStartedAt'] != null
            ? DateTime.parse(json['lastStartedAt'] as String)
            : null,
      );

  Agent copyWith({String? status}) => Agent(
        id: id, name: name, status: status ?? this.status, nodeId: nodeId,
        systemPrompt: systemPrompt, allowedTools: allowedTools,
        disallowedTools: disallowedTools, configDir: configDir,
        projectDir: projectDir, model: model, matrixUserId: matrixUserId,
        matrixProvisioned: matrixProvisioned, projectosProjectId: projectosProjectId,
        autoRestart: autoRestart, createdAt: createdAt, lastStartedAt: lastStartedAt,
      );
}
