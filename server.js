const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

const PORT = 3847;
const CONFIG_DIR = path.join(os.homedir(), '.config', 'project-docs');
const RECENT_FILE = path.join(CONFIG_DIR, 'recent.json');

let currentProjectDir = null;

// ── Config persistence ──

function loadRecent() {
  try {
    return JSON.parse(fs.readFileSync(RECENT_FILE, 'utf-8'));
  } catch {
    return [];
  }
}

function saveRecent(projects) {
  fs.mkdirSync(CONFIG_DIR, { recursive: true });
  fs.writeFileSync(RECENT_FILE, JSON.stringify(projects.slice(0, 10), null, 2));
}

function addRecent(dir) {
  const recent = loadRecent().filter(p => p.path !== dir);
  const name = path.basename(dir);
  recent.unshift({ path: dir, name });
  saveRecent(recent);
}

// ── Doc scanning ──

function slugify(filename) {
  return filename
    .replace(/\.md$|\.html$/i, '')
    .replace(/^\d{4}-\d{2}-\d{2}-/, '')
    .replace(/-/g, ' ');
}

function scanDocs(projectDir) {
  const docs = { specs: [], plans: [], findings: [], brainstorm: [] };
  if (!projectDir) return docs;

  const specsDir = path.join(projectDir, 'docs', 'superpowers', 'specs');
  if (fs.existsSync(specsDir)) {
    for (const f of fs.readdirSync(specsDir).filter(f => f.endsWith('.md')).sort()) {
      docs.specs.push({ id: `specs/${f}`, name: slugify(f), file: path.join(specsDir, f) });
    }
  }

  const plansDir = path.join(projectDir, 'docs', 'superpowers', 'plans');
  if (fs.existsSync(plansDir)) {
    for (const f of fs.readdirSync(plansDir).filter(f => f.endsWith('.md')).sort()) {
      docs.plans.push({ id: `plans/${f}`, name: slugify(f), file: path.join(plansDir, f) });
    }
  }

  const docsDir = path.join(projectDir, 'docs');
  if (fs.existsSync(docsDir)) {
    for (const f of fs.readdirSync(docsDir).filter(f => f.endsWith('.md'))) {
      docs.findings.push({ id: `findings/${f}`, name: slugify(f), file: path.join(docsDir, f) });
    }
  }

  const brainstormDir = path.join(projectDir, '.superpowers', 'brainstorm');
  if (fs.existsSync(brainstormDir)) {
    for (const session of fs.readdirSync(brainstormDir).sort()) {
      const sessionDir = path.join(brainstormDir, session);
      if (!fs.statSync(sessionDir).isDirectory()) continue;
      for (const f of fs.readdirSync(sessionDir).filter(f => f.endsWith('.html')).sort()) {
        docs.brainstorm.push({
          id: `brainstorm/${session}/${f}`,
          name: slugify(f),
          session,
          file: path.join(sessionDir, f),
        });
      }
    }
  }

  return docs;
}

function resolveDocPath(projectDir, docId) {
  const [prefix, ...rest] = docId.split('/');
  const remainder = rest.join('/');
  switch (prefix) {
    case 'specs': return path.join(projectDir, 'docs', 'superpowers', 'specs', remainder);
    case 'plans': return path.join(projectDir, 'docs', 'superpowers', 'plans', remainder);
    case 'findings': return path.join(projectDir, 'docs', remainder);
    case 'brainstorm': return path.join(projectDir, '.superpowers', 'brainstorm', remainder);
    default: return null;
  }
}

function isPathSafe(projectDir, filePath) {
  try {
    const real = fs.realpathSync(filePath);
    const base = fs.realpathSync(projectDir);
    return real.startsWith(base + path.sep) || real === base;
  } catch {
    return false;
  }
}

// ── Pinch helpers ──

function getRecentProjects() {
  return loadRecent();
}

function getProjectById(id) {
  const projects = getRecentProjects();
  const index = parseInt(id.replace('p', ''));
  return projects[index] ? { ...projects[index], id, directory: projects[index].path } : null;
}

function scanDocsForPinch(projectDir) {
  const docs = [];
  const categories = [
    { dir: 'docs/superpowers/specs', category: 'spec' },
    { dir: 'docs/superpowers/plans', category: 'plan' },
    { dir: 'docs', category: 'finding' },
  ];
  for (const cat of categories) {
    const fullDir = path.join(projectDir, cat.dir);
    if (fs.existsSync(fullDir)) {
      const files = fs.readdirSync(fullDir).filter(f => f.endsWith('.md'));
      for (const f of files) {
        docs.push({
          path: path.join(cat.dir, f),
          title: f.replace(/^\d{4}-\d{2}-\d{2}-/, '').replace(/-/g, ' ').replace('.md', ''),
          category: cat.category,
          date: null,
          docId: null,
        });
      }
    }
  }
  return docs;
}

function scanFileTree(dir, maxDepth, currentDepth = 0) {
  if (currentDepth >= maxDepth) return [];
  const skip = ['node_modules', '.git', '.dart_tool', 'build', '.superpowers', 'dist', 'target'];
  const items = [];
  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (skip.includes(entry.name) || entry.name.startsWith('.')) continue;
      if (entry.isDirectory()) {
        const children = scanFileTree(path.join(dir, entry.name), maxDepth, currentDepth + 1);
        items.push({ name: entry.name, type: 'directory', children, count: children.length });
      } else {
        items.push({ name: entry.name, type: 'file' });
      }
    }
  } catch (e) { /* ignore permission errors */ }
  return items;
}

// ── HTTP handling ──

function parseBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', c => { body += c; });
    req.on('end', () => {
      try { resolve(JSON.parse(body)); }
      catch { resolve({}); }
    });
  });
}

function json(res, data, status = 200) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // ── Pinch REST API ──

  if (url.pathname === '/api/projects' && req.method === 'GET') {
    const projects = getRecentProjects().map((p, i) => ({
      id: `p${i}`,
      name: path.basename(p.path),
      directory: p.path,
      shortCode: path.basename(p.path).substring(0, 2).toUpperCase(),
    }));
    json(res, projects);
    return;
  }

  const projectSessionsMatch = url.pathname.match(/^\/api\/projects\/([^/]+)\/sessions$/);
  if (projectSessionsMatch && req.method === 'GET') {
    json(res, []);
    return;
  }

  const projectDocsExactMatch = url.pathname.match(/^\/api\/projects\/([^/]+)\/docs$/);
  if (projectDocsExactMatch && req.method === 'GET') {
    const project = getProjectById(projectDocsExactMatch[1]);
    if (!project) { json(res, { error: 'Project not found' }, 404); return; }
    const docs = scanDocsForPinch(project.directory);
    json(res, docs);
    return;
  }

  const projectDocsContentMatch = url.pathname.match(/^\/api\/projects\/([^/]+)\/docs\/(.+)$/);
  if (projectDocsContentMatch && req.method === 'GET') {
    const project = getProjectById(projectDocsContentMatch[1]);
    if (!project) { json(res, { error: 'Project not found' }, 404); return; }
    const docPath = projectDocsContentMatch[2];
    const fullPath = path.join(project.directory, docPath);
    if (!isPathSafe(project.directory, fullPath)) { json(res, { error: 'Access denied' }, 403); return; }
    try {
      const data = fs.readFileSync(fullPath, 'utf-8');
      json(res, { content: data, path: docPath });
    } catch {
      json(res, { error: 'Doc not found' }, 404);
    }
    return;
  }

  const projectFilesMatch = url.pathname.match(/^\/api\/projects\/([^/]+)\/files$/);
  if (projectFilesMatch && req.method === 'GET') {
    const project = getProjectById(projectFilesMatch[1]);
    if (!project) { json(res, { error: 'Project not found' }, 404); return; }
    const tree = scanFileTree(project.directory, 3);
    json(res, tree);
    return;
  }

  // Serve frontend
  if (url.pathname === '/' || url.pathname === '/index.html') {
    const html = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf-8');
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(html);
    return;
  }

  // Serve vendor JS files
  if (url.pathname.startsWith('/vendor/') && url.pathname.endsWith('.js')) {
    const vendorFile = path.join(__dirname, 'dist', url.pathname);
    if (fs.existsSync(vendorFile)) {
      res.writeHead(200, { 'Content-Type': 'application/javascript' });
      res.end(fs.readFileSync(vendorFile));
      return;
    }
  }

  // ── Project discovery ──

  if (url.pathname === '/api/discover-projects') {
    const home = os.homedir();
    const searchRoots = ['Developer','Projects','Documents','Code','dev','src','repos','workspace','Work','Desktop']
      .map(d => path.join(home, d));
    const found = [];
    const seen = new Set();

    function isProjectDir(dir) {
      const hasSpecs = fs.existsSync(path.join(dir, 'docs', 'superpowers', 'specs'));
      const hasPlans = fs.existsSync(path.join(dir, 'docs', 'superpowers', 'plans'));
      const hasBrainstorm = fs.existsSync(path.join(dir, '.superpowers', 'brainstorm'));
      let hasFindings = false;
      try {
        const docsDir = path.join(dir, 'docs');
        if (fs.existsSync(docsDir)) {
          hasFindings = fs.readdirSync(docsDir).some(f => f.endsWith('.md'));
        }
      } catch {}
      if (hasSpecs || hasPlans || hasBrainstorm) {
        return { path: dir, name: path.basename(dir), has_specs: hasSpecs, has_plans: hasPlans, has_brainstorm: hasBrainstorm, has_findings: hasFindings };
      }
      return null;
    }

    for (const root of searchRoots) {
      if (!fs.existsSync(root)) continue;
      try {
        // Check root
        const rootProj = isProjectDir(root);
        if (rootProj && !seen.has(rootProj.path)) { seen.add(rootProj.path); found.push(rootProj); }
        // 2 levels deep
        for (const entry of fs.readdirSync(root)) {
          if (entry.startsWith('.')) continue;
          const p = path.join(root, entry);
          try { if (!fs.statSync(p).isDirectory()) continue; } catch { continue; }
          const proj = isProjectDir(p);
          if (proj && !seen.has(proj.path)) { seen.add(proj.path); found.push(proj); }
          try {
            for (const sub of fs.readdirSync(p)) {
              if (sub.startsWith('.')) continue;
              const sp = path.join(p, sub);
              try { if (!fs.statSync(sp).isDirectory()) continue; } catch { continue; }
              const sproj = isProjectDir(sp);
              if (sproj && !seen.has(sproj.path)) { seen.add(sproj.path); found.push(sproj); }
            }
          } catch {}
        }
      } catch {}
    }
    found.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
    json(res, found);
    return;
  }

  // ── Project management APIs ──

  if (url.pathname === '/api/recent-projects') {
    json(res, loadRecent());
    return;
  }

  if (url.pathname === '/api/set-project' && req.method === 'POST') {
    const body = await parseBody(req);
    const dir = body.path;
    if (!dir || !fs.existsSync(dir)) {
      json(res, { error: 'Directory not found' }, 400);
      return;
    }
    currentProjectDir = dir;
    addRecent(dir);
    json(res, { ok: true, name: path.basename(dir), path: dir });
    return;
  }

  if (url.pathname === '/api/current-project') {
    json(res, currentProjectDir
      ? { path: currentProjectDir, name: path.basename(currentProjectDir) }
      : { path: null, name: null });
    return;
  }

  // ── Doc APIs (require active project) ──

  if (url.pathname === '/api/docs') {
    if (!currentProjectDir) {
      json(res, { specs: [], plans: [], findings: [], brainstorm: [] });
      return;
    }
    const docs = scanDocs(currentProjectDir);
    const safe = {};
    for (const [cat, items] of Object.entries(docs)) {
      safe[cat] = items.map(({ file, ...rest }) => rest);
    }
    json(res, safe);
    return;
  }

  if (url.pathname === '/api/content') {
    const docId = url.searchParams.get('id');
    if (!docId || !currentProjectDir) {
      json(res, { error: 'Missing id or project' }, 400);
      return;
    }
    const filePath = resolveDocPath(currentProjectDir, docId);
    if (!filePath || !fs.existsSync(filePath) || !isPathSafe(currentProjectDir, filePath)) {
      json(res, { error: 'Not found' }, 404);
      return;
    }
    const content = fs.readFileSync(filePath, 'utf-8');
    const isHtml = filePath.endsWith('.html');
    json(res, { id: docId, name: slugify(path.basename(filePath)), content, type: isHtml ? 'html' : 'markdown' });
    return;
  }

  // Serve brainstorm HTML files for iframe embedding
  if (url.pathname.startsWith('/brainstorm/') && currentProjectDir) {
    const relPath = url.pathname.slice('/brainstorm/'.length);
    const filePath = path.join(currentProjectDir, '.superpowers', 'brainstorm', relPath);
    if (fs.existsSync(filePath) && isPathSafe(currentProjectDir, filePath)) {
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(fs.readFileSync(filePath, 'utf-8'));
      return;
    }
    res.writeHead(404);
    res.end('Not found');
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

// Auto-load most recent project on startup
const recent = loadRecent();
if (recent.length > 0 && fs.existsSync(recent[0].path)) {
  currentProjectDir = recent[0].path;
}

server.listen(PORT, () => {
  console.log(`\n  \x1b[36m◆\x1b[0m Project Docs Reader + Pinch Server`);
  console.log(`  \x1b[2m${'-'.repeat(30)}\x1b[0m`);
  console.log(`  \x1b[32m→\x1b[0m http://localhost:${PORT}`);
  console.log(`  \x1b[32m⚡\x1b[0m ws://localhost:${PORT}/ws`);
  if (currentProjectDir) {
    console.log(`  \x1b[33m◇\x1b[0m ${path.basename(currentProjectDir)}`);
  }
  console.log();
});

// ── Pinch WebSocket ──

const wss = new WebSocket.Server({ server, path: '/ws' });

wss.on('connection', (ws) => {
  console.log('Pinch client connected');

  ws.on('message', (data) => {
    let msg;
    try { msg = JSON.parse(data.toString()); } catch { return; }

    switch (msg.action) {
      case 'prompt':
        handlePrompt(ws, msg);
        break;
      case 'createSession':
        ws.send(JSON.stringify({
          id: uuidv4(),
          sessionId: uuidv4(),
          timestamp: new Date().toISOString(),
          type: 'sessionStart',
          data: { model: 'opus-4.6', projectDir: msg.projectDir, sessionName: msg.name || 'New Session' },
        }));
        break;
      case 'stop':
        ws.send(JSON.stringify({
          id: uuidv4(),
          sessionId: msg.sessionId,
          timestamp: new Date().toISOString(),
          type: 'sessionEnd',
          data: { reason: 'stopped', totalTokens: 0, cost: 0 },
        }));
        break;
      case 'permission':
        // Acknowledge
        break;
    }
  });

  ws.on('close', () => console.log('Pinch client disconnected'));
});

function handlePrompt(ws, msg) {
  const sessionId = msg.sessionId;
  const events = [
    { type: 'assistantThinking', data: { thinking: 'Let me think about this...', done: true } },
    { type: 'assistantText', data: { text: `I received your prompt: "${msg.text}". This is a mock response from the server.`, done: true } },
  ];

  let delay = 500;
  for (const evt of events) {
    setTimeout(() => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          id: uuidv4(),
          sessionId,
          timestamp: new Date().toISOString(),
          ...evt,
        }));
      }
    }, delay);
    delay += 1000;
  }
}
