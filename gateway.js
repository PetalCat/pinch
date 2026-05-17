/**
 * Pinch Gateway — the central hub.
 *
 * The Flutter app connects here (WebSocket /ws + HTTP REST).
 * Nodes connect here (WebSocket /node) and dial out — no inbound requirements on node machines.
 * The gateway routes actions from the app to the right node and multiplexes
 * events from all nodes back to connected app clients.
 *
 * Filesystem-heavy REST endpoints (history, projects, docs) are served
 * locally since the gateway lives on the main box. Session-state endpoints
 * proxy to the primary node via RPC over the node WebSocket.
 *
 * Run: node gateway.js [--port 3847]
 */

'use strict';

const http   = require('http');
const fs     = require('fs');
const path   = require('path');
const os     = require('os');
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

// ── Config ──────────────────────────────────────────────────────────────────

const GATEWAY_PORT = parseInt(process.env.PINCH_PORT || '7464');
const CONFIG_DIR   = path.join(os.homedir(), '.config', 'pinch');
const CONFIG_FILE  = path.join(CONFIG_DIR, 'gateway.json');
const RECENT_FILE  = path.join(CONFIG_DIR, 'recent.json');

function loadConfig() {
  try { return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf-8')); }
  catch { return {}; }
}
function saveConfig(c) {
  fs.mkdirSync(CONFIG_DIR, { recursive: true });
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(c, null, 2));
}
function getNodeAuthToken() {
  const cfg = loadConfig();
  if (!cfg.nodeAuthToken) {
    cfg.nodeAuthToken = 'pinch_' + uuidv4().replace(/-/g, '');
    saveConfig(cfg);
  }
  return cfg.nodeAuthToken;
}
const NODE_AUTH_TOKEN = getNodeAuthToken();

let currentProjectDir = null;

// ── Registries ───────────────────────────────────────────────────────────────

// nodeId → { ws, name, hostname, connectedAt, lastSeen }
const nodes   = new Map();
// clientId → ws
const clients = new Map();
// requestId → { resolve, reject, timer }
const pendingRpc = new Map();

// ── Node routing helpers ─────────────────────────────────────────────────────

function primaryNode() {
  for (const n of nodes.values()) {
    if (n.ws.readyState === WebSocket.OPEN) return n;
  }
  return null;
}

function nodeById(nodeId) {
  const n = nodes.get(nodeId);
  if (n && n.ws.readyState === WebSocket.OPEN) return n;
  return null;
}

function routeAction(nodeId, msg) {
  const n = nodeId ? nodeById(nodeId) : primaryNode();
  if (!n) return false;
  n.ws.send(JSON.stringify(msg));
  return true;
}

function nodeRpc(nodeId, method, pathname, body, timeoutMs = 6000) {
  return new Promise((resolve, reject) => {
    const n = nodeId ? nodeById(nodeId) : primaryNode();
    if (!n) return reject(new Error('No node connected'));
    const requestId = uuidv4();
    const timer = setTimeout(() => {
      pendingRpc.delete(requestId);
      reject(new Error('Node RPC timeout'));
    }, timeoutMs);
    pendingRpc.set(requestId, { resolve, reject, timer });
    n.ws.send(JSON.stringify({ type: 'rpcRequest', requestId, method, pathname, body: body || null }));
  });
}

function broadcastToClients(event) {
  const msg = JSON.stringify(event);
  for (const ws of clients.values()) {
    if (ws.readyState === WebSocket.OPEN) ws.send(msg);
  }
}

function sendToClient(clientId, event) {
  const ws = clients.get(clientId);
  if (ws && ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(event));
}

// ── Filesystem helpers (gateway-local) ───────────────────────────────────────

function loadRecent() {
  try { return JSON.parse(fs.readFileSync(RECENT_FILE, 'utf-8')); }
  catch { return []; }
}
function saveRecent(projects) {
  fs.mkdirSync(CONFIG_DIR, { recursive: true });
  fs.writeFileSync(RECENT_FILE, JSON.stringify(projects.slice(0, 10), null, 2));
}
function addRecent(dir) {
  const recent = loadRecent().filter(p => p.path !== dir);
  recent.unshift({ path: dir, name: path.basename(dir) });
  saveRecent(recent);
}
function slugify(filename) {
  return filename.replace(/\.md$|\.html$/i, '').replace(/^\d{4}-\d{2}-\d{2}-/, '').replace(/-/g, ' ');
}
function isPathSafe(base, filePath) {
  try {
    const real = fs.realpathSync(filePath);
    const b    = fs.realpathSync(base);
    return real.startsWith(b + path.sep) || real === b;
  } catch { return false; }
}

function checkDocStructure(dir) {
  return {
    hasSpecs:      fs.existsSync(path.join(dir, 'docs', 'superpowers', 'specs')),
    hasPlans:      fs.existsSync(path.join(dir, 'docs', 'superpowers', 'plans')),
    hasBrainstorm: fs.existsSync(path.join(dir, '.superpowers', 'brainstorm')),
    hasFindings:   (() => {
      try { return fs.existsSync(path.join(dir, 'docs')) && fs.readdirSync(path.join(dir, 'docs')).some(f => f.endsWith('.md')); }
      catch { return false; }
    })(),
  };
}

function scanDocs(projectDir) {
  const docs = { specs: [], plans: [], findings: [], brainstorm: [] };
  if (!projectDir) return docs;
  const cats = [
    { dir: path.join(projectDir, 'docs', 'superpowers', 'specs'),  key: 'specs',     prefix: 'specs' },
    { dir: path.join(projectDir, 'docs', 'superpowers', 'plans'),  key: 'plans',     prefix: 'plans' },
    { dir: path.join(projectDir, 'docs'),                          key: 'findings',  prefix: 'findings' },
  ];
  for (const cat of cats) {
    if (!fs.existsSync(cat.dir)) continue;
    for (const f of fs.readdirSync(cat.dir).filter(f => f.endsWith('.md')).sort())
      docs[cat.key].push({ id: `${cat.prefix}/${f}`, name: slugify(f) });
  }
  const brainstormDir = path.join(projectDir, '.superpowers', 'brainstorm');
  if (fs.existsSync(brainstormDir)) {
    for (const sess of fs.readdirSync(brainstormDir).sort()) {
      const sd = path.join(brainstormDir, sess);
      if (!fs.statSync(sd).isDirectory()) continue;
      for (const f of fs.readdirSync(sd).filter(f => f.endsWith('.html')).sort())
        docs.brainstorm.push({ id: `brainstorm/${sess}/${f}`, name: slugify(f), session: sess });
    }
  }
  return docs;
}

function resolveDocPath(projectDir, docId) {
  const [prefix, ...rest] = docId.split('/');
  const remainder = rest.join('/');
  switch (prefix) {
    case 'specs':      return path.join(projectDir, 'docs', 'superpowers', 'specs', remainder);
    case 'plans':      return path.join(projectDir, 'docs', 'superpowers', 'plans', remainder);
    case 'findings':   return path.join(projectDir, 'docs', remainder);
    case 'brainstorm': return path.join(projectDir, '.superpowers', 'brainstorm', remainder);
    default:           return null;
  }
}

// ── HTTP helpers ─────────────────────────────────────────────────────────────

function parseBody(req) {
  return new Promise(resolve => {
    let body = '';
    req.on('data', c => { body += c; });
    req.on('end', () => { try { resolve(JSON.parse(body)); } catch { resolve({}); } });
  });
}
function json(res, data, status = 200) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

// ── HTTP server ───────────────────────────────────────────────────────────────

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${GATEWAY_PORT}`);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }

  const p = url.pathname;

  // ── Gateway-specific endpoints ──

  if (p === '/api/health') {
    const nodeList = [...nodes.values()].map(n => ({
      nodeId: n.nodeId, name: n.name, hostname: n.hostname,
      connectedAt: n.connectedAt, lastSeen: n.lastSeen,
    }));
    return json(res, { status: 'ok', uptime: process.uptime(), nodes: nodeList });
  }

  if (p === '/api/nodes') {
    return json(res, [...nodes.values()].map(n => ({
      nodeId: n.nodeId, name: n.name, hostname: n.hostname, connectedAt: n.connectedAt,
    })));
  }

  // ── Session endpoints — proxy to node ──

  if (p === '/api/sessions' && req.method === 'GET') {
    try {
      const data = await nodeRpc(null, 'GET', '/api/sessions', null);
      return json(res, data);
    } catch { return json(res, []); }
  }

  const sessionMatch = p.match(/^\/api\/sessions\/([^/]+)(\/.*)?$/);
  if (sessionMatch) {
    const sid      = sessionMatch[1];
    const sub      = sessionMatch[2] || '';
    const nodeId   = url.searchParams.get('nodeId') || null;
    if (req.method === 'GET') {
      try { return json(res, await nodeRpc(nodeId, 'GET', `/api/sessions/${sid}${sub}`, null)); }
      catch (e) { return json(res, { error: e.message }, 503); }
    }
    if (req.method === 'POST' && sub === '/stop') {
      try { return json(res, await nodeRpc(nodeId, 'POST', `/api/sessions/${sid}/stop`, null)); }
      catch (e) { return json(res, { error: e.message }, 503); }
    }
  }

  // ── Agent endpoints — proxy to node ──

  if (p === '/api/agents' && req.method === 'GET') {
    try { return json(res, await nodeRpc(null, 'GET', '/api/agents', null)); }
    catch { return json(res, []); }
  }

  if (p === '/api/agents' && req.method === 'POST') {
    const body = await parseBody(req);
    try { return json(res, await nodeRpc(null, 'POST', '/api/agents', body)); }
    catch (e) { return json(res, { error: e.message }, 503); }
  }

  const agentMatch = p.match(/^\/api\/agents\/([^/]+)(\/.*)?$/);
  if (agentMatch) {
    const aid    = agentMatch[1];
    const sub    = agentMatch[2] || '';
    const nodeId = url.searchParams.get('nodeId') || null;
    if (req.method === 'GET' && !sub) {
      try { return json(res, await nodeRpc(nodeId, 'GET', `/api/agents/${aid}`, null)); }
      catch (e) { return json(res, { error: e.message }, 503); }
    }
    if (req.method === 'DELETE' && !sub) {
      try { return json(res, await nodeRpc(nodeId, 'DELETE', `/api/agents/${aid}`, null)); }
      catch (e) { return json(res, { error: e.message }, 503); }
    }
    if (req.method === 'POST' && sub === '/start') {
      const ok = routeAction(nodeId, { action: 'startAgent', agentId: aid });
      return json(res, ok ? { started: true } : { error: 'No node available' }, ok ? 200 : 503);
    }
    if (req.method === 'POST' && sub === '/stop') {
      const ok = routeAction(nodeId, { action: 'stopAgent', agentId: aid });
      return json(res, ok ? { stopped: true } : { error: 'No node available' }, ok ? 200 : 503);
    }
    if (req.method === 'POST' && sub === '/provision') {
      try { return json(res, await nodeRpc(nodeId, 'POST', `/api/agents/${aid}/provision`, null)); }
      catch (e) { return json(res, { error: e.message }, 503); }
    }
  }

  // ── Filesystem REST (gateway-local) ──

  if (p === '/api/me') return json(res, { id: 'admin', name: 'Admin', role: 'admin' });

  if (p === '/api/my-projects' && req.method === 'GET') {
    const projectMap = new Map();
    const claudeDir  = path.join(os.homedir(), '.claude', 'projects');
    if (fs.existsSync(claudeDir)) {
      for (const folder of fs.readdirSync(claudeDir)) {
        const fp = path.join(claudeDir, folder);
        if (!fs.statSync(fp).isDirectory()) continue;
        const sessions = fs.readdirSync(fp).filter(f => f.endsWith('.jsonl') && /^[0-9a-f]{8}-/.test(f));
        if (!sessions.length) continue;
        const projectDir = '/' + folder.replace(/-/g, '/');
        if (projectDir.startsWith('/ssh/')) continue;
        const name = folder.split('-').pop() || folder;
        let lastModified = 0;
        for (const s of sessions) {
          try { const mt = fs.statSync(path.join(fp, s)).mtimeMs; if (mt > lastModified) lastModified = mt; } catch {}
        }
        projectMap.set(projectDir, {
          id: folder, name, directory: projectDir,
          shortCode: name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
          sessionCount: sessions.length,
          lastActive: new Date(lastModified).toISOString(),
          source: 'history', exists: fs.existsSync(projectDir),
          hasSpecs: false, hasPlans: false, hasBrainstorm: false, hasFindings: false,
        });
      }
    }
    const searchRoots = ['Developer','Projects','Documents','Code','dev','src','repos','workspace','Work','Desktop']
      .map(d => path.join(os.homedir(), d));
    for (const root of searchRoots) {
      if (!fs.existsSync(root)) continue;
      try {
        for (const entry of fs.readdirSync(root)) {
          if (entry.startsWith('.')) continue;
          const p2 = path.join(root, entry);
          try { if (!fs.statSync(p2).isDirectory()) continue; } catch { continue; }
          const docs = checkDocStructure(p2);
          if (docs.hasSpecs || docs.hasPlans || docs.hasBrainstorm) {
            const ex = projectMap.get(p2);
            if (ex) { Object.assign(ex, docs); ex.source = 'both'; }
            else projectMap.set(p2, { id: p2.replace(/\//g, '-').replace(/^-/, ''), name: path.basename(p2), directory: p2, shortCode: path.basename(p2).substring(0, 2).toUpperCase(), sessionCount: 0, lastActive: null, source: 'scan', exists: true, ...docs });
          }
          try {
            for (const sub of fs.readdirSync(p2)) {
              if (sub.startsWith('.')) continue;
              const sp = path.join(p2, sub);
              try { if (!fs.statSync(sp).isDirectory()) continue; } catch { continue; }
              const sdocs = checkDocStructure(sp);
              if (sdocs.hasSpecs || sdocs.hasPlans || sdocs.hasBrainstorm) {
                const ex = projectMap.get(sp);
                if (ex) { Object.assign(ex, sdocs); ex.source = 'both'; }
                else projectMap.set(sp, { id: sp.replace(/\//g, '-').replace(/^-/, ''), name: path.basename(sp), directory: sp, shortCode: path.basename(sp).substring(0, 2).toUpperCase(), sessionCount: 0, lastActive: null, source: 'scan', exists: true, ...sdocs });
              }
            }
          } catch {}
        }
      } catch {}
    }
    const sorted = [...projectMap.values()].filter(p => p.exists !== false).sort((a, b) => {
      if (a.lastActive && !b.lastActive) return -1;
      if (!a.lastActive && b.lastActive) return 1;
      if (a.lastActive && b.lastActive) return new Date(b.lastActive) - new Date(a.lastActive);
      return a.name.localeCompare(b.name);
    });
    return json(res, { user: { id: 'admin', name: 'Admin', role: 'admin' }, projects: sorted });
  }

  if (p === '/api/projects') {
    const projects = loadRecent().map((proj, i) => ({
      id: `p${i}`, name: path.basename(proj.path), directory: proj.path,
      shortCode: path.basename(proj.path).substring(0, 2).toUpperCase(),
    }));
    return json(res, projects);
  }

  if (p === '/api/history' && req.method === 'GET') {
    const claudeDir = path.join(os.homedir(), '.claude', 'projects');
    const results = [];
    if (fs.existsSync(claudeDir)) {
      for (const projectFolder of fs.readdirSync(claudeDir)) {
        const projectPath = path.join(claudeDir, projectFolder);
        if (!fs.statSync(projectPath).isDirectory()) continue;
        const projectDir  = '/' + projectFolder.replace(/-/g, '/');
        const projectName = projectFolder.split('-').pop() || projectFolder;
        for (const file of fs.readdirSync(projectPath)) {
          if (!file.endsWith('.jsonl') || !/^[0-9a-f]{8}-/.test(file)) continue;
          const sessionId = file.replace('.jsonl', '');
          const filePath  = path.join(projectPath, file);
          const stat      = fs.statSync(filePath);
          let firstUserMessage = null, messageCount = 0, model = null, sessionStart = null;
          try {
            const lines = fs.readFileSync(filePath, 'utf8').split('\n').filter(l => l.trim());
            for (const line of lines.slice(0, 50)) {
              try {
                const obj = JSON.parse(line);
                if (obj.type === 'user' && !firstUserMessage) {
                  firstUserMessage = typeof obj.message?.content === 'string' ? obj.message.content.substring(0, 200) : '';
                  sessionStart = obj.timestamp;
                }
                if (obj.type === 'assistant' && !model && obj.message?.model) model = obj.message.model;
                if (obj.type === 'user' || obj.type === 'assistant') messageCount++;
              } catch {}
            }
          } catch {}
          results.push({ id: sessionId, projectDir, projectName, firstMessage: firstUserMessage || '(no message)', model: model || 'unknown', startedAt: sessionStart || stat.mtime.toISOString(), lastModified: stat.mtime.toISOString(), sizeBytes: stat.size, messageCount });
        }
      }
    }
    results.sort((a, b) => new Date(b.lastModified) - new Date(a.lastModified));
    return json(res, results);
  }

  if (p.match(/^\/api\/history\/[0-9a-f-]+$/) && req.method === 'GET') {
    const sessionId = p.split('/').pop();
    const claudeDir = path.join(os.homedir(), '.claude', 'projects');
    let filePath = null;
    if (fs.existsSync(claudeDir)) {
      for (const pf of fs.readdirSync(claudeDir)) {
        const c = path.join(claudeDir, pf, sessionId + '.jsonl');
        if (fs.existsSync(c)) { filePath = c; break; }
      }
    }
    if (!filePath) return json(res, { error: 'Not found' }, 404);
    const events = [];
    for (const line of fs.readFileSync(filePath, 'utf8').split('\n')) {
      if (!line.trim()) continue;
      try {
        const obj = JSON.parse(line);
        if (obj.type === 'user') events.push({ id: obj.uuid || uuidv4(), sessionId: obj.sessionId || sessionId, timestamp: obj.timestamp, type: 'userMessage', data: { text: typeof obj.message?.content === 'string' ? obj.message.content : '' } });
        else if (obj.type === 'assistant' && Array.isArray(obj.message?.content)) {
          for (const block of obj.message.content) {
            if (block.type === 'text') events.push({ id: (obj.uuid || uuidv4()) + '-text', sessionId: obj.sessionId || sessionId, timestamp: obj.timestamp, type: 'assistantText', data: { text: block.text, done: true } });
            else if (block.type === 'tool_use') events.push({ id: (obj.uuid || uuidv4()) + '-tool-' + block.id, sessionId: obj.sessionId || sessionId, timestamp: obj.timestamp, type: 'toolUse', data: { toolName: block.name, input: block.input || {}, toolUseId: block.id } });
          }
        }
      } catch {}
    }
    return json(res, events);
  }

  if (p === '/api/discover-projects' && req.method === 'GET') {
    const home = os.homedir();
    const searchRoots = ['Developer','Projects','Documents','Code','dev','src','repos','workspace','Work','Desktop'].map(d => path.join(home, d));
    const found = [], seen = new Set();
    function isProjectDir(dir) {
      const hs = fs.existsSync(path.join(dir, 'docs', 'superpowers', 'specs'));
      const hp = fs.existsSync(path.join(dir, 'docs', 'superpowers', 'plans'));
      const hb = fs.existsSync(path.join(dir, '.superpowers', 'brainstorm'));
      let hf = false;
      try { const dd = path.join(dir, 'docs'); if (fs.existsSync(dd)) hf = fs.readdirSync(dd).some(f => f.endsWith('.md')); } catch {}
      if (hs || hp || hb) return { path: dir, name: path.basename(dir), has_specs: hs, has_plans: hp, has_brainstorm: hb, has_findings: hf };
      return null;
    }
    for (const root of searchRoots) {
      if (!fs.existsSync(root)) continue;
      try {
        const rp = isProjectDir(root);
        if (rp && !seen.has(rp.path)) { seen.add(rp.path); found.push(rp); }
        for (const entry of fs.readdirSync(root)) {
          if (entry.startsWith('.')) continue;
          const p2 = path.join(root, entry);
          try { if (!fs.statSync(p2).isDirectory()) continue; } catch { continue; }
          const pr = isProjectDir(p2);
          if (pr && !seen.has(pr.path)) { seen.add(pr.path); found.push(pr); }
          try {
            for (const sub of fs.readdirSync(p2)) {
              if (sub.startsWith('.')) continue;
              const sp = path.join(p2, sub);
              try { if (!fs.statSync(sp).isDirectory()) continue; } catch { continue; }
              const sr = isProjectDir(sp);
              if (sr && !seen.has(sr.path)) { seen.add(sr.path); found.push(sr); }
            }
          } catch {}
        }
      } catch {}
    }
    found.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
    return json(res, found);
  }

  if (p === '/api/recent-projects') return json(res, loadRecent());

  if (p === '/api/set-project' && req.method === 'POST') {
    const body = await parseBody(req);
    const dir = body.path;
    if (!dir || !fs.existsSync(dir)) return json(res, { error: 'Directory not found' }, 400);
    currentProjectDir = dir;
    addRecent(dir);
    return json(res, { ok: true, name: path.basename(dir), path: dir });
  }

  if (p === '/api/current-project') return json(res, currentProjectDir ? { path: currentProjectDir, name: path.basename(currentProjectDir) } : { path: null, name: null });

  if (p === '/api/docs') {
    if (!currentProjectDir) return json(res, { specs: [], plans: [], findings: [], brainstorm: [] });
    return json(res, scanDocs(currentProjectDir));
  }

  if (p === '/api/content') {
    const docId = url.searchParams.get('id');
    if (!docId || !currentProjectDir) return json(res, { error: 'Missing id or project' }, 400);
    const filePath = resolveDocPath(currentProjectDir, docId);
    if (!filePath || !fs.existsSync(filePath) || !isPathSafe(currentProjectDir, filePath)) return json(res, { error: 'Not found' }, 404);
    const content = fs.readFileSync(filePath, 'utf-8');
    return json(res, { id: docId, name: slugify(path.basename(filePath)), content, type: filePath.endsWith('.html') ? 'html' : 'markdown' });
  }

  if (p.startsWith('/brainstorm/') && currentProjectDir) {
    const relPath  = p.slice('/brainstorm/'.length);
    const filePath = path.join(currentProjectDir, '.superpowers', 'brainstorm', relPath);
    if (fs.existsSync(filePath) && isPathSafe(currentProjectDir, filePath)) {
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(fs.readFileSync(filePath, 'utf-8'));
      return;
    }
    res.writeHead(404); res.end('Not found'); return;
  }

  if (p === '/api/projects') return json(res, loadRecent().map((proj, i) => ({ id: `p${i}`, name: path.basename(proj.path), directory: proj.path, shortCode: path.basename(proj.path).substring(0, 2).toUpperCase() })));

  const projectDocsMatch = p.match(/^\/api\/projects\/([^/]+)\/docs$/);
  if (projectDocsMatch && req.method === 'GET') {
    const projects = loadRecent();
    const idx = parseInt(projectDocsMatch[1].replace('p', ''));
    const proj = projects[idx];
    if (!proj) return json(res, { error: 'Not found' }, 404);
    const docs = [];
    const cats = [{ dir: 'docs/superpowers/specs', cat: 'spec' }, { dir: 'docs/superpowers/plans', cat: 'plan' }, { dir: 'docs', cat: 'finding' }];
    for (const c of cats) {
      const fd = path.join(proj.path, c.dir);
      if (fs.existsSync(fd)) for (const f of fs.readdirSync(fd).filter(f => f.endsWith('.md'))) docs.push({ path: path.join(c.dir, f), title: f.replace(/^\d{4}-\d{2}-\d{2}-/, '').replace(/-/g, ' ').replace('.md', ''), category: c.cat, date: null, docId: null });
    }
    return json(res, docs);
  }

  res.writeHead(404); res.end('Not found');
});

// ── WebSocket servers (noServer — manual upgrade routing to avoid ws path-rejection bug) ──

const wssApp  = new WebSocket.Server({ noServer: true });
const wssNode = new WebSocket.Server({ noServer: true });

server.on('upgrade', (request, socket, head) => {
  const pathname = new URL(request.url, `http://localhost:${GATEWAY_PORT}`).pathname;
  if (pathname === '/ws') {
    wssApp.handleUpgrade(request, socket, head, (ws) => wssApp.emit('connection', ws, request));
  } else if (pathname === '/node') {
    wssNode.handleUpgrade(request, socket, head, (ws) => wssNode.emit('connection', ws, request));
  } else {
    socket.destroy();
  }
});

// ── WebSocket — App clients (/ws) ─────────────────────────────────────────────

wssApp.on('connection', (ws) => {
  const clientId = uuidv4();
  clients.set(clientId, ws);
  console.log(`[gateway] App client connected: ${clientId.slice(0, 8)}`);

  ws.on('message', (data) => {
    try {
      const msg = JSON.parse(data.toString());
      const nodeId = msg.nodeId || null;

      switch (msg.action) {
        case 'createSession':
        case 'createPtySession':
        case 'prompt':
        case 'stop':
        case 'permission':
        case 'ptyInput':
        case 'ptyResize': {
          const ok = routeAction(nodeId, { ...msg, _clientId: clientId });
          if (!ok) ws.send(JSON.stringify({ type: 'error', data: { message: 'No node available' } }));
          break;
        }
        default:
          console.warn(`[gateway] Unknown action from client: ${msg.action}`);
      }
    } catch (e) { console.error('[gateway] App WS parse error:', e.message); }
  });

  ws.on('close', () => {
    clients.delete(clientId);
    console.log(`[gateway] App client disconnected: ${clientId.slice(0, 8)}`);
  });
});

// ── WebSocket — Node connections (/node) ──────────────────────────────────────

wssNode.on('connection', (ws, req) => {
  // Auth check
  const urlParams = new URL(req.url, `http://localhost:${GATEWAY_PORT}`);
  const token     = urlParams.searchParams.get('token');
  if (token !== NODE_AUTH_TOKEN) {
    console.warn('[gateway] Node connection rejected — bad token');
    ws.close(4001, 'Unauthorized');
    return;
  }

  let nodeId = null;

  ws.on('message', (data) => {
    try {
      const msg = JSON.parse(data.toString());

      // Node registration
      if (msg.type === 'nodeRegister') {
        nodeId = msg.nodeId || uuidv4();
        nodes.set(nodeId, { nodeId, name: msg.name || nodeId, hostname: msg.hostname || 'unknown', ws, connectedAt: new Date().toISOString(), lastSeen: Date.now() });
        console.log(`[gateway] Node registered: ${msg.name || nodeId} (${msg.hostname})`);
        ws.send(JSON.stringify({ type: 'nodeRegistered', nodeId }));
        broadcastToClients({ type: 'nodeStatus', nodeId, status: 'online', name: msg.name || nodeId, hostname: msg.hostname });
        return;
      }

      if (nodeId) nodes.get(nodeId) && (nodes.get(nodeId).lastSeen = Date.now());

      // RPC response
      if (msg.type === 'rpcResponse') {
        const pending = pendingRpc.get(msg.requestId);
        if (pending) {
          clearTimeout(pending.timer);
          pendingRpc.delete(msg.requestId);
          if (msg.error) pending.reject(new Error(msg.error));
          else pending.resolve(msg.data);
        }
        return;
      }

      // Event forwarding to specific client
      if (msg._clientId) {
        sendToClient(msg._clientId, msg);
        return;
      }

      // Broadcast to all app clients (e.g. agent events with no specific client)
      broadcastToClients(msg);

    } catch (e) { console.error('[gateway] Node WS parse error:', e.message); }
  });

  ws.on('close', () => {
    if (nodeId) {
      nodes.delete(nodeId);
      console.log(`[gateway] Node disconnected: ${nodeId}`);
      broadcastToClients({ type: 'nodeStatus', nodeId, status: 'offline' });
    }
  });

  ws.on('error', (e) => console.error(`[gateway] Node WS error: ${e.message}`));
});

// ── Startup ───────────────────────────────────────────────────────────────────

const recent = loadRecent();
if (recent.length > 0 && fs.existsSync(recent[0].path)) currentProjectDir = recent[0].path;

server.listen(GATEWAY_PORT, () => {
  console.log('\n  \x1b[36m◆\x1b[0m Pinch Gateway');
  console.log(`  \x1b[2m${'-'.repeat(30)}\x1b[0m`);
  console.log(`  \x1b[32m→\x1b[0m http://localhost:${GATEWAY_PORT}`);
  console.log(`  \x1b[32m⚡\x1b[0m ws://localhost:${GATEWAY_PORT}/ws  (app)`);
  console.log(`  \x1b[32m⚡\x1b[0m ws://localhost:${GATEWAY_PORT}/node (nodes)`);
  console.log(`  \x1b[33m🔑\x1b[0m Node token: ${NODE_AUTH_TOKEN}`);
  if (currentProjectDir) console.log(`  \x1b[33m◇\x1b[0m  ${path.basename(currentProjectDir)}`);
  console.log();
});

['SIGTERM', 'SIGINT'].forEach(sig => process.on(sig, () => {
  console.log(`[gateway] Shutting down (${sig})`);
  server.close(() => process.exit(0));
}));
