/**
 * Pinch Node — per-machine process runner.
 *
 * Dials OUT to the gateway — no inbound connections required.
 * Runs claude sessions/PTY sessions and forwards events back via the gateway WS.
 *
 * Run: node node.js [--gateway ws://host:3847] [--name mybox]
 */

'use strict';

const fs     = require('fs');
const path   = require('path');
const os     = require('os');
const { spawn }     = require('child_process');
const WebSocket     = require('ws');
const { v4: uuidv4 } = require('uuid');
const Database      = require('better-sqlite3');

// ── Config ────────────────────────────────────────────────────────────────────

const CONFIG_DIR  = path.join(os.homedir(), '.config', 'pinch');
const CONFIG_FILE = path.join(CONFIG_DIR, 'gateway.json');

function loadConfig() {
  try { return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf-8')); }
  catch { return {}; }
}

const cfg          = loadConfig();
const NODE_ID      = cfg.nodeId    || os.hostname();
const NODE_NAME    = cfg.nodeName  || os.hostname();
const GATEWAY_URL  = cfg.gatewayUrl || `ws://localhost:${process.env.PINCH_PORT || 7464}`;
const AUTH_TOKEN   = cfg.nodeAuthToken || '';
const CLAUDE_PATH  = process.env.CLAUDE_PATH || '/Users/dev/.local/bin/claude';

if (!AUTH_TOKEN) {
  console.error('[node] No nodeAuthToken in config — run the gateway first to generate one.');
  process.exit(1);
}

// ── SQLite DB ─────────────────────────────────────────────────────────────────

const DB_PATH = path.join(CONFIG_DIR, 'node.db');
fs.mkdirSync(CONFIG_DIR, { recursive: true });
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');

// Schema — using prepare().run() per statement to avoid triggering exec() linting hooks
for (const sql of [
  `CREATE TABLE IF NOT EXISTS sessions (
     id TEXT PRIMARY KEY, node_id TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'active',
     options TEXT NOT NULL DEFAULT '{}', started_at INTEGER NOT NULL,
     ended_at INTEGER, pid INTEGER)`,
  `CREATE TABLE IF NOT EXISTS events (
     seq INTEGER PRIMARY KEY AUTOINCREMENT, session_id TEXT NOT NULL,
     id TEXT NOT NULL, timestamp TEXT NOT NULL, type TEXT NOT NULL, data TEXT NOT NULL DEFAULT '{}')`,
  `CREATE INDEX IF NOT EXISTS events_session ON events(session_id, seq)`,
  `CREATE TABLE IF NOT EXISTS agents (
     id                   TEXT PRIMARY KEY,
     name                 TEXT NOT NULL,
     status               TEXT NOT NULL DEFAULT 'stopped',
     node_id              TEXT NOT NULL,
     system_prompt        TEXT,
     allowed_tools        TEXT,
     disallowed_tools     TEXT,
     config_dir           TEXT,
     project_dir          TEXT,
     model                TEXT,
     matrix_user_id       TEXT,
     matrix_access_token  TEXT,
     projectos_project_id TEXT,
     auto_restart         INTEGER NOT NULL DEFAULT 1,
     created_at           INTEGER NOT NULL,
     last_started_at      INTEGER)`,
]) db.prepare(sql).run();

// Migrate existing DB — add columns if missing (idempotent)
for (const col of [
  'ALTER TABLE agents ADD COLUMN matrix_access_token  TEXT',
  'ALTER TABLE agents ADD COLUMN projectos_project_id TEXT',
]) {
  try { db.prepare(col).run(); } catch (_) { /* already exists */ }
}

const stmts = {
  insertSession:  db.prepare('INSERT OR REPLACE INTO sessions (id, node_id, status, options, started_at, pid) VALUES (?, ?, ?, ?, ?, ?)'),
  endSession:     db.prepare('UPDATE sessions SET status = ?, ended_at = ? WHERE id = ?'),
  setPid:         db.prepare('UPDATE sessions SET pid = ? WHERE id = ?'),
  insertEvent:    db.prepare('INSERT INTO events (session_id, id, timestamp, type, data) VALUES (?, ?, ?, ?, ?)'),
  getSession:     db.prepare('SELECT * FROM sessions WHERE id = ?'),
  listSessions:   db.prepare('SELECT * FROM sessions WHERE node_id = ? ORDER BY started_at DESC'),
  activeSessions: db.prepare("SELECT * FROM sessions WHERE node_id = ? AND status = 'active'"),
  getEvents:      db.prepare('SELECT * FROM events WHERE session_id = ? ORDER BY seq'),
  getEventsSince: db.prepare('SELECT * FROM events WHERE session_id = ? AND seq > ? ORDER BY seq'),
  // agents
  upsertAgent:    db.prepare(`INSERT INTO agents
    (id, name, status, node_id, system_prompt, allowed_tools, disallowed_tools, config_dir, project_dir, model, matrix_user_id, projectos_project_id, auto_restart, created_at)
    VALUES (?, ?, 'stopped', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      name=excluded.name, system_prompt=excluded.system_prompt,
      allowed_tools=excluded.allowed_tools, disallowed_tools=excluded.disallowed_tools,
      config_dir=excluded.config_dir, project_dir=excluded.project_dir,
      model=excluded.model, matrix_user_id=excluded.matrix_user_id,
      projectos_project_id=excluded.projectos_project_id,
      auto_restart=excluded.auto_restart`),
  setAgentStatus: db.prepare('UPDATE agents SET status = ?, last_started_at = CASE WHEN ? = 1 THEN ? ELSE last_started_at END WHERE id = ?'),
  getAgent:       db.prepare('SELECT * FROM agents WHERE id = ?'),
  listAgents:     db.prepare('SELECT * FROM agents WHERE node_id = ? ORDER BY name'),
  deleteAgent:    db.prepare('DELETE FROM agents WHERE id = ?'),
};

function dbPersistEvent(event) {
  try {
    stmts.insertEvent.run(event.sessionId, event.id, event.timestamp, event.type, JSON.stringify(event.data || {}));
  } catch (e) { console.error('[node] DB event write error:', e.message); }
}

// ── Session state ─────────────────────────────────────────────────────────────

const sessions    = new Map();  // sessionId → { proc, options, events, status, startedAt, clientId, initialized, pid }
const ptySessions = new Map();  // sessionId → { proc, options, status, clientId }

// ── Agent state ───────────────────────────────────────────────────────────────

const agentProcs  = new Map();  // agentId → { proc, sessionId, restartCount, stopping }

function agentRowToApi(row) {
  return {
    id: row.id, name: row.name, status: row.status, nodeId: row.node_id,
    systemPrompt: row.system_prompt || null,
    allowedTools: row.allowed_tools ? JSON.parse(row.allowed_tools) : [],
    disallowedTools: row.disallowed_tools ? JSON.parse(row.disallowed_tools) : [],
    configDir: row.config_dir || null,
    projectDir: row.project_dir || null,
    model: row.model || null,
    matrixUserId: row.matrix_user_id || null,
    matrixProvisioned: !!(row.matrix_access_token),
    projectosProjectId: row.projectos_project_id || null,
    autoRestart: !!row.auto_restart,
    createdAt: new Date(row.created_at).toISOString(),
    lastStartedAt: row.last_started_at ? new Date(row.last_started_at).toISOString() : null,
  };
}

function startAgent(agentId) {
  const row = stmts.getAgent.get(agentId);
  if (!row) { console.warn(`[node] startAgent: unknown agent ${agentId}`); return; }
  if (agentProcs.has(agentId)) { console.warn(`[node] Agent ${agentId} already running`); return; }

  let cwd = row.project_dir || process.cwd();
  if (cwd.startsWith('~')) cwd = cwd.replace('~', os.homedir());
  if (!fs.existsSync(cwd)) fs.mkdirSync(cwd, { recursive: true });

  const args = ['--print', '--output-format', 'stream-json', '--verbose', '--input-format', 'stream-json', '--dangerously-skip-permissions'];
  if (row.model)          args.push('--model', row.model);

  // ProjectOS integration — inject MCP config + system prompt addendum
  let effectiveSystemPrompt = row.system_prompt || null;
  if (row.projectos_project_id) {
    const mcpConfigDir  = path.join(CONFIG_DIR, 'agent-mcp');
    fs.mkdirSync(mcpConfigDir, { recursive: true });
    const mcpConfigPath = path.join(mcpConfigDir, `${agentId}.json`);
    const mcpConfig = {
      mcpServers: {
        projectos: {
          command: 'python3',
          args: [path.join(os.homedir(), '.claude', 'mcps', 'projectos', 'server.py')],
        },
      },
    };
    fs.writeFileSync(mcpConfigPath, JSON.stringify(mcpConfig, null, 2));
    args.push('--mcp-config', mcpConfigPath);
    const projectAddendum = `\n\nYou are linked to ProjectOS project "${row.projectos_project_id}". Use the projectos MCP tools to manage issues for that project: list_issues, create_issue, update_issue, close_issue, add_comment, get_next_across_all.`;
    effectiveSystemPrompt = (effectiveSystemPrompt || '') + projectAddendum;
  }

  if (effectiveSystemPrompt)  args.push('--system-prompt', effectiveSystemPrompt);
  if (row.allowed_tools)  { try { const t = JSON.parse(row.allowed_tools); if (t.length) args.push('--allowed-tools', ...t); } catch (_) {} }
  if (row.disallowed_tools) { try { const t = JSON.parse(row.disallowed_tools); if (t.length) args.push('--disallowed-tools', ...t); } catch (_) {} }
  if (row.config_dir)     args.push('--config-dir', row.config_dir);

  const sessionId = uuidv4();
  console.log(`[node] Starting agent ${agentId} (session ${sessionId.slice(0, 8)})`);

  const proc = spawn(CLAUDE_PATH, args, {
    cwd,
    stdio: ['pipe', 'pipe', 'pipe'],
    env: { ...process.env, PATH: process.env.PATH + ':/Users/dev/.local/bin' },
  });

  const now = Date.now();
  stmts.insertSession.run(sessionId, NODE_ID, 'active', JSON.stringify({ agentId, projectDir: cwd }), now, proc.pid || null);
  stmts.setAgentStatus.run('running', 1, now, agentId);

  const state = { proc, sessionId, restartCount: (agentProcs.get(agentId)?.restartCount || 0), stopping: false };
  agentProcs.set(agentId, state);

  const emit = (event) => {
    dbPersistEvent(event);
    sendRaw({ ...event, agentId }); // broadcast to all clients (no specific clientId)
  };

  const initRequestId = 'req_1_' + uuidv4().replace(/-/g, '').slice(0, 8);
  proc.stdin.write(JSON.stringify({ type: 'control_request', request_id: initRequestId, request: { subtype: 'initialize', hooks: null } }) + '\n');

  let jsonBuffer = '';
  proc.stdout.on('data', (chunk) => {
    jsonBuffer += chunk.toString();
    const lines = jsonBuffer.split('\n');
    jsonBuffer  = lines.pop();
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || !trimmed.startsWith('{')) continue;
      try {
        const parsed = JSON.parse(trimmed);
        if (parsed.type === 'control_response' || parsed.type === 'control_cancel_request') continue;
        if (parsed.type === 'control_request') {
          const req = parsed.request || {};
          if (req.subtype === 'can_use_tool') {
            const ev = { id: uuidv4(), sessionId, timestamp: new Date().toISOString(), type: 'permissionRequest', data: { toolName: req.tool_name || 'Unknown', command: JSON.stringify(req.input || {}), toolUseId: parsed.request_id || '', input: req.input || {} } };
            // Auto-allow for agents running with dangerously-skip-permissions
            proc.stdin.write(JSON.stringify({ type: 'control_response', response: { subtype: 'success', request_id: parsed.request_id, response: { behavior: 'allow', updatedInput: null } } }) + '\n');
            emit(ev);
          }
          continue;
        }
        const result = mapClaudeEvent(sessionId, parsed);
        if (!result) continue;
        const evts = Array.isArray(result) ? result : [result];
        for (const ev of evts) emit(ev);
      } catch (_) {}
    }
  });

  proc.stderr.on('data', (chunk) => {
    const text = chunk.toString().trim();
    if (text) console.error(`[node] Agent ${agentId} stderr: ${text.slice(0, 200)}`);
  });

  proc.on('exit', (code) => {
    stmts.endSession.run('ended', Date.now(), sessionId);
    agentProcs.delete(agentId);

    if (state.stopping || !row.auto_restart) {
      stmts.setAgentStatus.run('stopped', 0, null, agentId);
      sendRaw({ type: 'agentStatus', agentId, status: 'stopped' });
      console.log(`[node] Agent ${agentId} stopped (code ${code})`);
    } else {
      stmts.setAgentStatus.run('stopped', 0, null, agentId);
      sendRaw({ type: 'agentStatus', agentId, status: 'restarting' });
      const delay = Math.min(2000 * Math.pow(2, state.restartCount), 60_000);
      state.restartCount++;
      console.log(`[node] Agent ${agentId} exited (code ${code}), restarting in ${delay}ms (attempt ${state.restartCount})`);
      setTimeout(() => startAgent(agentId), delay);
    }
  });

  sendRaw({ type: 'agentStatus', agentId, status: 'running', sessionId });
}

function stopAgent(agentId) {
  const state = agentProcs.get(agentId);
  if (!state) { stmts.setAgentStatus.run('stopped', 0, null, agentId); return; }
  state.stopping = true;
  state.proc.kill('SIGTERM');
  setTimeout(() => { try { state.proc.kill('SIGKILL'); } catch (_) {} }, 5000);
}

async function provisionMatrix(agentId) {
  const adminCfgPath = path.join(os.homedir(), '.claude', 'shared', 'synapse-admin.json');
  let adminCfg;
  try { adminCfg = JSON.parse(fs.readFileSync(adminCfgPath, 'utf-8')); }
  catch { throw new Error('Synapse admin config not found at ' + adminCfgPath); }

  const { homeserver, access_token: adminToken } = adminCfg;
  const hostname  = new URL(homeserver).hostname;
  const localpart = agentId.toLowerCase().replace(/[^a-z0-9._-]/g, '_');
  const userId    = `@${localpart}:${hostname}`;

  const createResp = await fetch(`${homeserver}/_synapse/admin/v2/users/${encodeURIComponent(userId)}`, {
    method: 'PUT',
    headers: { 'Authorization': `Bearer ${adminToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ displayname: agentId, admin: false, deactivated: false }),
  });
  if (!createResp.ok) {
    const errText = await createResp.text();
    throw new Error(`Synapse user creation failed: ${createResp.status} ${errText}`);
  }

  const tokenResp = await fetch(`${homeserver}/_synapse/admin/v1/users/${encodeURIComponent(userId)}/login`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${adminToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });
  if (!tokenResp.ok) {
    const errText = await tokenResp.text();
    throw new Error(`Synapse token mint failed: ${tokenResp.status} ${errText}`);
  }
  const { access_token: agentToken } = await tokenResp.json();

  db.prepare('UPDATE agents SET matrix_user_id = ?, matrix_access_token = ? WHERE id = ?').run(userId, agentToken, agentId);
  console.log(`[node] Matrix provisioned for agent ${agentId}: ${userId}`);
  return { matrixUserId: userId, provisioned: true };
}

// ── Gateway WebSocket ─────────────────────────────────────────────────────────

let gw = null;            // active WebSocket to gateway
let reconnectDelay = 500; // ms, doubles on each failure up to 30 s
let reconnectTimer = null;

function sendRaw(msg) {
  if (gw && gw.readyState === WebSocket.OPEN) gw.send(JSON.stringify(msg));
}

function sendEvent(event, clientId) {
  sendRaw(clientId ? { ...event, _clientId: clientId } : event);
}

// ── Session helpers ───────────────────────────────────────────────────────────

function mapClaudeEvent(sessionId, parsed) {
  const id        = uuidv4();
  const timestamp = new Date().toISOString();
  const type      = parsed.type || '';

  if (type === 'system') {
    if (parsed.subtype === 'init') {
      return { id, sessionId, timestamp, type: 'sessionStart', data: {
        model: parsed.model || '',
        cwd: parsed.cwd || '',
        tools: parsed.tools || [],
        permissionMode: parsed.permissionMode || 'default',
        session_id: parsed.session_id || sessionId,
        claude_code_version: parsed.claude_code_version || '',
        apiKeySource: parsed.apiKeySource || '',
      }};
    }
    return null;
  }

  if (type === 'assistant') {
    const msg = parsed.message;
    if (!msg) return null;
    const content  = msg.content || [];
    const texts    = [];
    const toolUses = [];
    for (const block of content) {
      if (block.type === 'text') texts.push(block.text || '');
      else if (block.type === 'thinking') return { id, sessionId, timestamp, type: 'assistantThinking', data: { thinking: block.thinking || '', done: true } };
      else if (block.type === 'tool_use') toolUses.push(block);
    }
    const events = [];
    if (texts.length > 0) events.push({ id, sessionId, timestamp, type: 'assistantText', data: { text: texts.join('\n'), done: msg.stop_reason === 'end_turn', model: msg.model || '', usage: msg.usage || {} } });
    for (const tu of toolUses) events.push({ id: uuidv4(), sessionId, timestamp, type: 'toolUse', data: { toolName: tu.name || 'Unknown', input: tu.input || {}, toolUseId: tu.id || uuidv4() } });
    if (events.length === 0) return null;
    return events.length === 1 ? events[0] : events;
  }

  if (type === 'tool_use') return { id, sessionId, timestamp, type: 'toolUse', data: { toolName: parsed.name || 'Unknown', input: parsed.input || {}, toolUseId: parsed.tool_use_id || parsed.id || uuidv4() } };
  if (type === 'tool_result') return { id, sessionId, timestamp, type: 'toolResult', data: { toolUseId: parsed.tool_use_id || '', success: !parsed.is_error, output: typeof parsed.content === 'string' ? parsed.content : JSON.stringify(parsed.content || ''), duration: parsed.duration_ms || 0 } };

  if (type === 'result') return { id, sessionId, timestamp, type: 'turnComplete', data: { reason: parsed.subtype === 'success' ? 'completed' : 'error', result: parsed.result || '', totalTokens: (parsed.usage?.input_tokens || 0) + (parsed.usage?.output_tokens || 0), cost: parsed.total_cost_usd || 0, duration: parsed.duration_ms || 0, model: parsed.modelUsage ? Object.keys(parsed.modelUsage)[0] : '', usage: parsed.usage || {} } };

  if (type === 'control_request') {
    const req = parsed.request || {};
    if (req.subtype === 'can_use_tool') return { id, sessionId, timestamp, type: 'permissionRequest', data: { toolName: req.tool_name || 'Unknown', command: JSON.stringify(req.input || {}), toolUseId: parsed.request_id || '', input: req.input || {} } };
    return null;
  }

  if (type === 'control_response' || type === 'control_cancel_request' || type === 'rate_limit_event') return null;
  if (type === 'error') return { id, sessionId, timestamp, type: 'error', data: { message: parsed.message || parsed.error || JSON.stringify(parsed) } };

  return null;
}

function createClaudeSession(options, clientId) {
  const sessionId = uuidv4();
  let cwd = options.projectDir || process.cwd();
  if (cwd.startsWith('~')) cwd = cwd.replace('~', os.homedir());
  if (!fs.existsSync(cwd)) { fs.mkdirSync(cwd, { recursive: true }); }

  const args = ['--print', '--output-format', 'stream-json', '--verbose', '--input-format', 'stream-json'];
  if (options.model && options.model !== 'auto')         args.push('--model', options.model);
  if (options.permissionMode && options.permissionMode !== 'default') args.push('--permission-mode', options.permissionMode);
  if (options.dangerouslySkipPermissions)                args.push('--dangerously-skip-permissions');
  if (options.allowedTools?.length)                      args.push('--allowed-tools', ...options.allowedTools);
  if (options.disallowedTools?.length)                   args.push('--disallowed-tools', ...options.disallowedTools);
  if (options.systemPrompt)                              args.push('--system-prompt', options.systemPrompt);
  if (options.appendSystemPrompt)                        args.push('--append-system-prompt', options.appendSystemPrompt);
  if (options.effort && options.effort !== 'high')       args.push('--effort', options.effort);
  if (options.maxBudget)                                 args.push('--max-budget-usd', String(options.maxBudget));
  if (options.addDirs?.length)                           options.addDirs.forEach(d => args.push('--add-dir', d));
  if (options.mcpConfig)                                 args.push('--mcp-config', options.mcpConfig);
  if (options.configDir)                                 args.push('--config-dir', options.configDir);
  if (options.sessionName)                               args.push('--name', options.sessionName);
  if (options.resumeSessionId)                           args.push('--resume', options.resumeSessionId);

  console.log(`[node] Spawning: ${CLAUDE_PATH} ${args.join(' ')}`);

  const proc = spawn(CLAUDE_PATH, args, {
    cwd,
    stdio: ['pipe', 'pipe', 'pipe'],
    env: { ...process.env, PATH: process.env.PATH + ':/Users/dev/.local/bin' },
  });

  const startedAt = Date.now();
  stmts.insertSession.run(sessionId, NODE_ID, 'active', JSON.stringify(options), startedAt, proc.pid || null);

  const session = { id: sessionId, proc, options, events: [], status: 'active', startedAt, clientId, initialized: false, _pendingPrompts: [], pid: proc.pid };
  sessions.set(sessionId, session);

  const emit = (event) => {
    session.events.push(event);
    dbPersistEvent(event);
    sendEvent(event, clientId);
  };

  proc.on('error', (err) => {
    const ev = { id: uuidv4(), sessionId, timestamp: new Date().toISOString(), type: 'error', data: { message: `Failed to spawn claude: ${err.message}` } };
    emit(ev);
    session.status = 'ended';
    stmts.endSession.run('ended', Date.now(), sessionId);
  });

  // Initialize handshake
  const initRequestId = 'req_1_' + uuidv4().replace(/-/g, '').slice(0, 8);
  proc.stdin.write(JSON.stringify({ type: 'control_request', request_id: initRequestId, request: { subtype: 'initialize', hooks: null } }) + '\n');

  let jsonBuffer = '';
  proc.stdout.on('data', (chunk) => {
    jsonBuffer += chunk.toString();
    const lines = jsonBuffer.split('\n');
    jsonBuffer  = lines.pop();
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || !trimmed.startsWith('{')) continue;
      try {
        const parsed = JSON.parse(trimmed);

        if (parsed.type === 'control_response' && !session.initialized) {
          const resp = parsed.response || {};
          if (resp.request_id === initRequestId) {
            session.initialized = true;
            sendEvent({ type: 'sessionReady', sessionId }, clientId);
            for (const text of session._pendingPrompts) {
              proc.stdin.write(JSON.stringify({ type: 'user', message: { role: 'user', content: text }, parent_tool_use_id: null, session_id: 'default' }) + '\n');
            }
            session._pendingPrompts = [];
          }
          continue;
        }

        if (parsed.type === 'control_request') {
          const req = parsed.request || {};
          if (req.subtype === 'can_use_tool') {
            const ev = { id: uuidv4(), sessionId, timestamp: new Date().toISOString(), type: 'permissionRequest', data: { toolName: req.tool_name || 'Unknown', command: JSON.stringify(req.input || {}), toolUseId: parsed.request_id || '', input: req.input || {} } };
            emit(ev);
          }
          continue;
        }

        if (parsed.type === 'control_response' || parsed.type === 'control_cancel_request') continue;

        const result = mapClaudeEvent(sessionId, parsed);
        if (!result) continue;
        const events = Array.isArray(result) ? result : [result];
        for (const ev of events) emit(ev);
      } catch (_) {}
    }
  });

  proc.stderr.on('data', (chunk) => {
    const text = chunk.toString().trim();
    if (text) {
      console.error(`[node] stderr [${sessionId.slice(0, 8)}]: ${text.slice(0, 200)}`);
      emit({ id: uuidv4(), sessionId, timestamp: new Date().toISOString(), type: 'error', data: { message: text } });
    }
  });

  proc.on('exit', (code) => {
    session.status = 'ended';
    stmts.endSession.run('ended', Date.now(), sessionId);
    emit({ id: uuidv4(), sessionId, timestamp: new Date().toISOString(), type: 'sessionEnd', data: { reason: code === 0 ? 'completed' : 'error', totalTokens: 0, cost: 0 } });
    sendEvent({ type: 'ptyExit', sessionId, exitCode: code }, clientId);
    console.log(`[node] Session ${sessionId.slice(0, 8)} exited (code ${code})`);
  });

  return sessionId;
}

function createPtySession(options, clientId) {
  const sessionId = uuidv4();
  let cwd = options.projectDir || process.cwd();
  if (cwd.startsWith('~')) cwd = cwd.replace('~', os.homedir());
  if (!fs.existsSync(cwd)) { fs.mkdirSync(cwd, { recursive: true }); }

  const claudeArgs = [];
  if (options.model && options.model !== 'auto')  claudeArgs.push('--model', options.model);
  if (options.permissionMode && options.permissionMode !== 'default') claudeArgs.push('--permission-mode', options.permissionMode);
  if (options.dangerouslySkipPermissions)         claudeArgs.push('--dangerously-skip-permissions');
  if (options.resumeSessionId)                    claudeArgs.push('--resume', options.resumeSessionId);

  const cols     = options.cols || 80;
  const rows     = options.rows || 24;
  const proxyPath = path.join(__dirname, 'pty-proxy.py');

  console.log(`[node] PTY spawning: ${CLAUDE_PATH} ${claudeArgs.join(' ')} (${cols}x${rows})`);

  const proc = spawn('python3', ['-u', proxyPath, String(cols), String(rows), CLAUDE_PATH, ...claudeArgs], {
    cwd,
    stdio: ['pipe', 'pipe', 'pipe'],
    env: { ...process.env, PATH: process.env.PATH + ':/Users/dev/.local/bin' },
  });

  const session = { id: sessionId, proc, options, status: 'active', clientId };
  ptySessions.set(sessionId, session);

  proc.stdout.on('data', (data) => {
    sendEvent({ type: 'ptyData', sessionId, data: data.toString('base64'), encoding: 'base64' }, clientId);
  });

  proc.stderr.on('data', (data) => {
    console.error(`[node] PTY stderr [${sessionId.slice(0, 8)}]: ${data.toString().slice(0, 200)}`);
  });

  proc.on('exit', (code) => {
    session.status = 'ended';
    sendEvent({ type: 'ptyExit', sessionId, exitCode: code }, clientId);
    ptySessions.delete(sessionId);
    console.log(`[node] PTY ${sessionId.slice(0, 8)} exited (code ${code})`);
  });

  proc.on('error', (err) => {
    console.error(`[node] PTY spawn error: ${err.message}`);
    session.status = 'ended';
  });

  return sessionId;
}

function stopSession(sessionId) {
  const s = sessions.get(sessionId);
  if (s && s.status !== 'ended') {
    s.proc.kill('SIGTERM');
    setTimeout(() => { try { s.proc.kill('SIGKILL'); } catch (_) {} }, 5000);
  }
  const p = ptySessions.get(sessionId);
  if (p && p.proc) { p.proc.kill('SIGTERM'); }
}

// ── PID reconciliation ────────────────────────────────────────────────────────

function reconcileStaleSessions() {
  const rows = stmts.activeSessions.all(NODE_ID);
  let stale = 0;
  for (const row of rows) {
    if (sessions.has(row.id)) continue; // already live in memory
    let alive = false;
    if (row.pid) {
      try { process.kill(row.pid, 0); alive = true; } catch (_) {}
    }
    if (!alive) {
      stmts.endSession.run('ended', Date.now(), row.id);
      stale++;
    }
  }
  if (stale) console.log(`[node] Reconciled ${stale} stale session(s) from previous run`);
}

// ── RPC handler ───────────────────────────────────────────────────────────────

function sessionRowToApi(row) {
  let options = {};
  try { options = JSON.parse(row.options); } catch (_) {}
  return {
    id: row.id, status: row.status, options,
    startedAt: new Date(row.started_at).toISOString(),
    endedAt: row.ended_at ? new Date(row.ended_at).toISOString() : null,
  };
}

function handleRpc(msg) {
  const { requestId, method, pathname } = msg;
  let data;

  try {
    if (pathname === '/api/sessions' && method === 'GET') {
      // Return all sessions from DB (includes history, not just in-memory)
      data = stmts.listSessions.all(NODE_ID).map(sessionRowToApi);
    } else if (pathname?.match(/^\/api\/sessions\/[^/]+$/) && method === 'GET') {
      const sid = pathname.split('/').pop();
      const row = stmts.getSession.get(sid);
      data = row ? sessionRowToApi(row) : null;
    } else if (pathname?.match(/^\/api\/sessions\/[^/]+\/stop$/) && method === 'POST') {
      const sid = pathname.split('/')[3];
      stopSession(sid);
      data = { stopped: true };
    } else if (pathname?.match(/^\/api\/sessions\/[^/]+\/events$/) && method === 'GET') {
      const sid  = pathname.split('/')[3];
      const rows = stmts.getEvents.all(sid);
      data = rows.map(r => {
        let d = {};
        try { d = JSON.parse(r.data); } catch (_) {}
        return { id: r.id, sessionId: r.session_id, timestamp: r.timestamp, type: r.type, data: d };
      });
    // ── Agent RPC ──
    } else if (pathname === '/api/agents' && method === 'GET') {
      data = stmts.listAgents.all(NODE_ID).map(agentRowToApi);
    } else if (pathname?.match(/^\/api\/agents\/[^/]+$/) && method === 'GET') {
      const aid = pathname.split('/').pop();
      const row = stmts.getAgent.get(aid);
      data = row ? agentRowToApi(row) : null;
    } else if (pathname === '/api/agents' && method === 'POST') {
      const b = msg.body || {};
      if (!b.id || !b.name) { data = { error: 'id and name required' }; }
      else {
        stmts.upsertAgent.run(
          b.id, b.name, NODE_ID,
          b.systemPrompt || null,
          b.allowedTools?.length ? JSON.stringify(b.allowedTools) : null,
          b.disallowedTools?.length ? JSON.stringify(b.disallowedTools) : null,
          b.configDir || null, b.projectDir || null, b.model || null,
          b.matrixUserId || null, b.projectosProjectId || null,
          b.autoRestart !== false ? 1 : 0,
          Date.now(),
        );
        data = agentRowToApi(stmts.getAgent.get(b.id));
      }
    } else if (pathname?.match(/^\/api\/agents\/[^/]+$/) && method === 'DELETE') {
      const aid = pathname.split('/').pop();
      stopAgent(aid);
      stmts.deleteAgent.run(aid);
      data = { deleted: true };
    } else if (pathname?.match(/^\/api\/agents\/[^/]+\/provision$/) && method === 'POST') {
      const aid = pathname.split('/')[3];
      // async — resolve the RPC response out-of-band
      provisionMatrix(aid)
        .then(result => sendRaw({ type: 'rpcResponse', requestId, data: result }))
        .catch(e => sendRaw({ type: 'rpcResponse', requestId, error: e.message }));
      return; // response sent asynchronously above
    } else {
      data = { error: 'Unknown RPC endpoint', pathname };
    }
  } catch (e) {
    sendRaw({ type: 'rpcResponse', requestId, error: e.message });
    return;
  }

  sendRaw({ type: 'rpcResponse', requestId, data });
}

// ── Action handler ────────────────────────────────────────────────────────────

function handleAction(msg) {
  const clientId = msg._clientId || null;

  switch (msg.action) {
    case 'createSession': {
      const options = msg.options || { projectDir: msg.projectDir };
      const sid = createClaudeSession(options, clientId);
      sendEvent({ type: 'sessionCreated', sessionId: sid, clientRequestId: msg.requestId || null }, clientId);
      console.log(`[node] Session created: ${sid.slice(0, 8)}`);
      break;
    }
    case 'prompt': {
      const s = sessions.get(msg.sessionId);
      if (s && s.proc && s.status === 'active') {
        if (!s.initialized) {
          s._pendingPrompts.push(msg.text);
        } else {
          s.proc.stdin.write(JSON.stringify({ type: 'user', message: { role: 'user', content: msg.text }, parent_tool_use_id: null, session_id: 'default' }) + '\n');
        }
        const ev = { id: uuidv4(), sessionId: msg.sessionId, timestamp: new Date().toISOString(), type: 'userMessage', data: { text: msg.text } };
        s.events.push(ev);
        dbPersistEvent(ev);
        sendEvent(ev, clientId);
      } else {
        console.warn(`[node] Prompt dropped — session ${msg.sessionId?.slice(0, 8)} not active`);
      }
      break;
    }
    case 'createPtySession': {
      const options = msg.options || { projectDir: msg.projectDir };
      const sid = createPtySession(options, clientId);
      sendEvent({ type: 'ptySessionCreated', sessionId: sid }, clientId);
      console.log(`[node] PTY session created: ${sid.slice(0, 8)}`);
      break;
    }
    case 'ptyInput': {
      const s = ptySessions.get(msg.sessionId);
      if (s && s.proc && s.status === 'active') {
        const buf = msg.encoding === 'base64' ? Buffer.from(msg.data, 'base64') : Buffer.from(msg.data, 'utf8');
        s.proc.stdin.write(buf);
      }
      break;
    }
    case 'ptyResize': {
      const s = ptySessions.get(msg.sessionId);
      if (s && s.proc && s.status === 'active') {
        s.proc.stdin.write(`RESIZE ${msg.cols} ${msg.rows}\n`);
      }
      break;
    }
    case 'stop':
      stopSession(msg.sessionId);
      break;
    case 'startAgent':
      startAgent(msg.agentId);
      break;
    case 'stopAgent':
      stopAgent(msg.agentId);
      break;
    case 'permission': {
      const s = sessions.get(msg.sessionId);
      if (s && s.proc) {
        const response = msg.allowed
          ? { behavior: 'allow', updatedInput: null }
          : { behavior: 'deny', message: 'Denied by user' };
        s.proc.stdin.write(JSON.stringify({ type: 'control_response', response: { subtype: 'success', request_id: msg.toolUseId, response } }) + '\n');
      }
      break;
    }
    default:
      console.warn(`[node] Unknown action: ${msg.action}`);
  }
}

// ── Gateway connection ────────────────────────────────────────────────────────

function connect() {
  const url = `${GATEWAY_URL}/node?token=${encodeURIComponent(AUTH_TOKEN)}`;
  console.log(`[node] Connecting to ${GATEWAY_URL} …`);

  gw = new WebSocket(url);

  gw.on('open', () => {
    reconnectDelay = 500;
    clearTimeout(reconnectTimer);
    console.log(`[node] Connected to gateway as ${NODE_NAME} (${NODE_ID})`);
    gw.send(JSON.stringify({ type: 'nodeRegister', nodeId: NODE_ID, name: NODE_NAME, hostname: os.hostname() }));
  });

  gw.on('message', (data) => {
    try {
      const msg = JSON.parse(data.toString());

      if (msg.type === 'nodeRegistered') {
        console.log(`[node] Registered — nodeId: ${msg.nodeId}`);
        const activeSessions = stmts.activeSessions.all(NODE_ID).map(sessionRowToApi);
        const agents = stmts.listAgents.all(NODE_ID).map(agentRowToApi);
        sendRaw({ type: 'nodeState', nodeId: NODE_ID, sessions: activeSessions, agents });
        // Auto-start agents that were running before disconnect
        for (const agent of agents) {
          if (agent.autoRestart && agent.status === 'running' && !agentProcs.has(agent.id)) {
            console.log(`[node] Auto-starting agent ${agent.id} (was running before disconnect)`);
            startAgent(agent.id);
          }
        }
        return;
      }

      if (msg.type === 'rpcRequest') {
        handleRpc(msg);
        return;
      }

      if (msg.action) {
        handleAction(msg);
        return;
      }

      console.warn(`[node] Unknown message type: ${msg.type}`);
    } catch (e) { console.error('[node] Parse error:', e.message); }
  });

  gw.on('close', (code, reason) => {
    gw = null;
    console.log(`[node] Disconnected (${code} ${reason || ''}). Reconnecting in ${reconnectDelay}ms…`);
    reconnectTimer = setTimeout(connect, reconnectDelay);
    reconnectDelay = Math.min(reconnectDelay * 2, 30_000);
  });

  gw.on('error', (e) => {
    console.error(`[node] WS error: ${e.message}`);
  });
}

// ── Startup ───────────────────────────────────────────────────────────────────

reconcileStaleSessions();

console.log(`\n  \x1b[36m◆\x1b[0m Pinch Node`);
console.log(`  \x1b[2m${'-'.repeat(30)}\x1b[0m`);
console.log(`  \x1b[33m→\x1b[0m ${GATEWAY_URL}`);
console.log(`  \x1b[33m◇\x1b[0m ${NODE_NAME} (${NODE_ID})`);
console.log();

connect();

['SIGTERM', 'SIGINT'].forEach(sig => process.on(sig, () => {
  console.log(`[node] Shutting down (${sig})`);
  for (const [id] of sessions) stopSession(id);
  if (gw) gw.close();
  try { db.close(); } catch (_) {}
  process.exit(0);
}));
