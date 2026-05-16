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

  // ── Accounts (foundation) ──
  // For now, single admin account. Structure supports future multi-user.
  const DEFAULT_USER = { id: 'admin', name: 'Admin', role: 'admin' };

  function getCurrentUser(req) {
    // Future: parse auth header/token
    return DEFAULT_USER;
  }

  // GET /api/me — current user info
  if (url.pathname === '/api/me' && req.method === 'GET') {
    return json(res, getCurrentUser(req));
  }

  // GET /api/my-projects — merged: scanned + history, deduplicated, user-scoped
  if (url.pathname === '/api/my-projects' && req.method === 'GET') {
    const user = getCurrentUser(req);
    const projectMap = new Map(); // directory → project info

    // Source 1: Session history from ~/.claude/projects/
    const claudeDir2 = path.join(os.homedir(), '.claude', 'projects');
    if (fs.existsSync(claudeDir2)) {
      for (const folder of fs.readdirSync(claudeDir2)) {
        const folderPath = path.join(claudeDir2, folder);
        if (!fs.statSync(folderPath).isDirectory()) continue;

        const sessions = fs.readdirSync(folderPath).filter(f => f.endsWith('.jsonl') && f.match(/^[0-9a-f]{8}-/));
        if (sessions.length === 0) continue;

        const projectDir = '/' + folder.replace(/-/g, '/');
        if (projectDir.startsWith('/ssh/')) continue; // skip remote sessions

        const projectName = folder.split('-').pop() || folder;

        let lastModified = 0;
        for (const s of sessions) {
          try {
            const mt = fs.statSync(path.join(folderPath, s)).mtimeMs;
            if (mt > lastModified) lastModified = mt;
          } catch {}
        }

        // Check if directory still exists on disk
        const dirExists = fs.existsSync(projectDir);

        projectMap.set(projectDir, {
          id: folder,
          name: projectName,
          directory: projectDir,
          shortCode: projectName.length >= 2 ? projectName.substring(0, 2).toUpperCase() : projectName.toUpperCase(),
          sessionCount: sessions.length,
          lastActive: new Date(lastModified).toISOString(),
          source: 'history',
          hasSpecs: false,
          hasPlans: false,
          hasBrainstorm: false,
          hasFindings: false,
          exists: dirExists,
        });
      }
    }

    // Source 2: Scan for docs/superpowers structure (only dirs that exist)
    const home2 = os.homedir();
    const searchRoots2 = ['Developer','Projects','Documents','Code','dev','src','repos','workspace','Work','Desktop']
      .map(d => path.join(home2, d));

    function checkDocStructure(dir) {
      return {
        hasSpecs: fs.existsSync(path.join(dir, 'docs', 'superpowers', 'specs')),
        hasPlans: fs.existsSync(path.join(dir, 'docs', 'superpowers', 'plans')),
        hasBrainstorm: fs.existsSync(path.join(dir, '.superpowers', 'brainstorm')),
        hasFindings: (() => { try { return fs.existsSync(path.join(dir, 'docs')) && fs.readdirSync(path.join(dir, 'docs')).some(f => f.endsWith('.md')); } catch { return false; } })(),
      };
    }

    for (const root of searchRoots2) {
      if (!fs.existsSync(root)) continue;
      try {
        const entries = fs.readdirSync(root);
        for (const entry of entries) {
          if (entry.startsWith('.')) continue;
          const p = path.join(root, entry);
          try { if (!fs.statSync(p).isDirectory()) continue; } catch { continue; }

          const docs = checkDocStructure(p);
          if (docs.hasSpecs || docs.hasPlans || docs.hasBrainstorm) {
            const existing = projectMap.get(p);
            if (existing) {
              // Merge: add doc info to existing history entry
              existing.hasSpecs = docs.hasSpecs;
              existing.hasPlans = docs.hasPlans;
              existing.hasBrainstorm = docs.hasBrainstorm;
              existing.hasFindings = docs.hasFindings;
              existing.source = 'both';
            } else {
              projectMap.set(p, {
                id: p.replace(/\//g, '-').replace(/^-/, ''),
                name: path.basename(p),
                directory: p,
                shortCode: path.basename(p).substring(0, 2).toUpperCase(),
                sessionCount: 0,
                lastActive: null,
                source: 'scan',
                ...docs,
                exists: true,
              });
            }
          }

          // Check one level deeper
          try {
            for (const sub of fs.readdirSync(p)) {
              if (sub.startsWith('.')) continue;
              const sp = path.join(p, sub);
              try { if (!fs.statSync(sp).isDirectory()) continue; } catch { continue; }
              const sdocs = checkDocStructure(sp);
              if (sdocs.hasSpecs || sdocs.hasPlans || sdocs.hasBrainstorm) {
                const existing = projectMap.get(sp);
                if (existing) {
                  existing.hasSpecs = sdocs.hasSpecs;
                  existing.hasPlans = sdocs.hasPlans;
                  existing.hasBrainstorm = sdocs.hasBrainstorm;
                  existing.hasFindings = sdocs.hasFindings;
                  existing.source = 'both';
                } else {
                  projectMap.set(sp, {
                    id: sp.replace(/\//g, '-').replace(/^-/, ''),
                    name: path.basename(sp),
                    directory: sp,
                    shortCode: path.basename(sp).substring(0, 2).toUpperCase(),
                    sessionCount: 0,
                    lastActive: null,
                    source: 'scan',
                    ...sdocs,
                    exists: true,
                  });
                }
              }
            }
          } catch {}
        }
      } catch {}
    }

    // Sort: projects with recent sessions first, then by name
    const sorted = [...projectMap.values()]
      .filter(p => p.exists !== false) // hide deleted projects
      .sort((a, b) => {
        // Active projects first
        if (a.lastActive && !b.lastActive) return -1;
        if (!a.lastActive && b.lastActive) return 1;
        if (a.lastActive && b.lastActive) return new Date(b.lastActive) - new Date(a.lastActive);
        return a.name.localeCompare(b.name);
      });

    return json(res, { user: user, projects: sorted });
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

  // ── Pinch Session REST API ──

  if (url.pathname === '/api/sessions' && req.method === 'GET') {
    const list = [];
    for (const [id, s] of sessions) {
      list.push({ id, projectId: 'current', name: s.options.sessionName || 'Session', status: s.status, createdAt: new Date(s.startedAt).toISOString(), model: s.options.model || 'default' });
    }
    return json(res, list);
  }
  if (url.pathname.match(/^\/api\/sessions\/[^/]+$/) && req.method === 'GET') {
    const id = url.pathname.split('/').pop();
    const s = sessions.get(id);
    if (!s) return json(res, { error: 'Not found' }, 404);
    return json(res, { id, status: s.status, options: s.options, startedAt: new Date(s.startedAt).toISOString(), eventCount: s.events.length });
  }
  if (url.pathname.match(/^\/api\/sessions\/[^/]+\/stop$/) && req.method === 'POST') {
    const id = url.pathname.split('/')[3];
    stopSession(id);
    return json(res, { stopped: true });
  }
  if (url.pathname.match(/^\/api\/sessions\/[^/]+\/events$/) && req.method === 'GET') {
    const id = url.pathname.split('/')[3];
    const s = sessions.get(id);
    if (!s) return json(res, { error: 'Not found' }, 404);
    return json(res, s.events);
  }
  // GET /api/history — list all historical Claude sessions across all projects
  if (url.pathname === '/api/history' && req.method === 'GET') {
    const claudeDir = path.join(os.homedir(), '.claude', 'projects');
    const results = [];

    if (fs.existsSync(claudeDir)) {
      for (const projectFolder of fs.readdirSync(claudeDir)) {
        const projectPath = path.join(claudeDir, projectFolder);
        if (!fs.statSync(projectPath).isDirectory()) continue;

        // Convert folder name back to path: -Users-parker-Developer-foo → /path/to/dev/foo
        const projectDir = '/' + projectFolder.replace(/-/g, '/');
        const projectName = projectFolder.split('-').pop() || projectFolder;

        for (const file of fs.readdirSync(projectPath)) {
          if (!file.endsWith('.jsonl')) continue;
          const sessionId = file.replace('.jsonl', '');
          // Skip subagent directories and non-UUID files
          if (!file.match(/^[0-9a-f]{8}-/)) continue;

          const filePath = path.join(projectPath, file);
          const stat = fs.statSync(filePath);

          // Read first few lines to get session info
          let firstUserMessage = null;
          let messageCount = 0;
          let model = null;
          let sessionStart = null;

          try {
            const content = fs.readFileSync(filePath, 'utf8');
            const lines = content.split('\n').filter(l => l.trim());
            for (const line of lines.slice(0, 50)) {
              try {
                const obj = JSON.parse(line);
                if (obj.type === 'user' && !firstUserMessage) {
                  firstUserMessage = typeof obj.message?.content === 'string'
                    ? obj.message.content.substring(0, 200)
                    : '';
                  sessionStart = obj.timestamp;
                }
                if (obj.type === 'assistant' && !model && obj.message?.model) {
                  model = obj.message.model;
                }
                if (obj.type === 'user' || obj.type === 'assistant') messageCount++;
              } catch {}
            }
          } catch {}

          results.push({
            id: sessionId,
            projectDir,
            projectName,
            firstMessage: firstUserMessage || '(no message)',
            model: model || 'unknown',
            startedAt: sessionStart || stat.mtime.toISOString(),
            lastModified: stat.mtime.toISOString(),
            sizeBytes: stat.size,
            messageCount,
          });
        }
      }
    }

    // Sort by lastModified, newest first
    results.sort((a, b) => new Date(b.lastModified) - new Date(a.lastModified));
    return json(res, results);
  }

  // GET /api/history/:sessionId — read full session JSONL as parsed events
  if (url.pathname.match(/^\/api\/history\/[0-9a-f-]+$/) && req.method === 'GET') {
    const sessionId = url.pathname.split('/').pop();
    const claudeDir = path.join(os.homedir(), '.claude', 'projects');

    // Search all project folders for this session
    let filePath = null;
    if (fs.existsSync(claudeDir)) {
      for (const projectFolder of fs.readdirSync(claudeDir)) {
        const candidate = path.join(claudeDir, projectFolder, sessionId + '.jsonl');
        if (fs.existsSync(candidate)) {
          filePath = candidate;
          break;
        }
      }
    }

    if (!filePath) return json(res, { error: 'Session not found' }, 404);

    const fileContent = fs.readFileSync(filePath, 'utf8');
    const events = [];
    for (const line of fileContent.split('\n')) {
      if (!line.trim()) continue;
      try {
        const obj = JSON.parse(line);
        if (obj.type === 'user') {
          events.push({
            id: obj.uuid || uuidv4(),
            sessionId: obj.sessionId || sessionId,
            timestamp: obj.timestamp,
            type: 'userMessage',
            data: { text: typeof obj.message?.content === 'string' ? obj.message.content : '' },
          });
        } else if (obj.type === 'assistant' && obj.message?.content) {
          const blocks = obj.message.content;
          if (Array.isArray(blocks)) {
            for (const block of blocks) {
              if (block.type === 'text') {
                events.push({
                  id: (obj.uuid || uuidv4()) + '-text',
                  sessionId: obj.sessionId || sessionId,
                  timestamp: obj.timestamp,
                  type: 'assistantText',
                  data: { text: block.text, done: true },
                });
              } else if (block.type === 'tool_use') {
                events.push({
                  id: (obj.uuid || uuidv4()) + '-tool-' + block.id,
                  sessionId: obj.sessionId || sessionId,
                  timestamp: obj.timestamp,
                  type: 'toolUse',
                  data: { toolName: block.name, input: block.input || {}, toolUseId: block.id },
                });
              }
            }
          }
        }
      } catch {}
    }
    return json(res, events);
  }

  if (url.pathname === '/api/health' && req.method === 'GET') {
    return json(res, { status: 'ok', uptime: process.uptime(), activeSessions: [...sessions.values()].filter(s => s.status === 'active').length, totalSessions: sessions.size });
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

// ── Session Manager ──
const sessions = new Map();

function createClaudeSession(ws, options) {
  const sessionId = uuidv4();
  const claudePath = process.env.CLAUDE_PATH || '/Users/dev/.local/bin/claude';
  let cwd = options.projectDir || process.cwd();
  if (cwd.startsWith('~')) cwd = cwd.replace('~', require('os').homedir());
  const fs = require('fs');
  if (!fs.existsSync(cwd)) { fs.mkdirSync(cwd, { recursive: true }); console.log(`Created directory: ${cwd}`); }

  // Print mode with stream-json for structured events + multi-turn via input-format
  const args = ['--print', '--output-format', 'stream-json', '--verbose', '--input-format', 'stream-json'];
  if (options.model && options.model !== 'auto') args.push('--model', options.model);
  if (options.permissionMode && options.permissionMode !== 'default') args.push('--permission-mode', options.permissionMode);
  if (options.dangerouslySkipPermissions) args.push('--dangerously-skip-permissions');
  if (options.allowDangerouslySkipPermissions) args.push('--allow-dangerously-skip-permissions');
  if (options.allowedTools && options.allowedTools.length) args.push('--allowed-tools', ...options.allowedTools);
  if (options.disallowedTools && options.disallowedTools.length) args.push('--disallowed-tools', ...options.disallowedTools);
  if (options.systemPrompt) args.push('--system-prompt', options.systemPrompt);
  if (options.appendSystemPrompt) args.push('--append-system-prompt', options.appendSystemPrompt);
  if (options.effort && options.effort !== 'high') args.push('--effort', options.effort);
  if (options.maxBudget) args.push('--max-budget-usd', String(options.maxBudget));
  if (options.addDirs && options.addDirs.length) {
    for (const dir of options.addDirs) args.push('--add-dir', dir);
  }
  if (options.mcpConfig) args.push('--mcp-config', options.mcpConfig);
  if (options.worktree) args.push('--worktree');
  if (options.sessionName) args.push('--name', options.sessionName);
  if (options.resumeSessionId) args.push('--resume', options.resumeSessionId);

  console.log(`Spawning: ${claudePath} ${args.join(' ')}`);
  console.log(`CWD: ${cwd}`);

  const { spawn } = require('child_process');

  const proc = spawn(claudePath, args, {
    cwd,
    stdio: ['pipe', 'pipe', 'pipe'],
    env: { ...process.env, PATH: process.env.PATH + ':/Users/dev/.local/bin' },
  });

  const session = { id: sessionId, proc, options, events: [], status: 'active', startedAt: Date.now(), ws, initialized: false };
  sessions.set(sessionId, session);

  proc.on('error', (err) => {
    console.error(`Spawn error for session ${sessionId}: ${err.message}`);
    const errEvent = { id: uuidv4(), sessionId, timestamp: new Date().toISOString(), type: 'error', data: { message: `Failed to spawn claude: ${err.message}` } };
    session.events.push(errEvent);
    sendToClient(ws, errEvent);
    session.status = 'ended';
  });

  // Send initialize handshake
  const initRequestId = 'req_1_' + uuidv4().replace(/-/g, '').slice(0, 8);
  proc.stdin.write(JSON.stringify({
    type: 'control_request',
    request_id: initRequestId,
    request: { subtype: 'initialize', hooks: null },
  }) + '\n');
  console.log(`Sent initialize handshake for session ${sessionId}`);

  // Parse stdout as NDJSON
  let jsonBuffer = '';

  proc.stdout.on('data', (chunk) => {
    jsonBuffer += chunk.toString();
    const lines = jsonBuffer.split('\n');
    jsonBuffer = lines.pop();
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || !trimmed.startsWith('{')) continue;
      try {
        const parsed = JSON.parse(trimmed);

        // Handle init handshake response
        if (parsed.type === 'control_response' && !session.initialized) {
          const resp = parsed.response || {};
          if (resp.request_id === initRequestId) {
            session.initialized = true;
            console.log(`Session ${sessionId} initialized (${resp.subtype})`);
            sendToClient(ws, { type: 'sessionReady', sessionId });
            // Send any queued prompts
            if (session._pendingPrompts) {
              for (const text of session._pendingPrompts) {
                const userMsg = JSON.stringify({
                  type: 'user',
                  message: { role: 'user', content: text },
                  parent_tool_use_id: null,
                  session_id: 'default',
                });
                proc.stdin.write(userMsg + '\n');
                console.log(`Sent queued prompt to session ${sessionId}`);
              }
              session._pendingPrompts = [];
            }
          }
          continue;
        }

        // Handle permission requests from Claude (control_request)
        if (parsed.type === 'control_request') {
          const req = parsed.request || {};
          if (req.subtype === 'can_use_tool') {
            const event = {
              id: uuidv4(), sessionId,
              timestamp: new Date().toISOString(),
              type: 'permissionRequest',
              data: {
                toolName: req.tool_name || 'Unknown',
                command: JSON.stringify(req.input || {}),
                toolUseId: parsed.request_id || '',
                input: req.input || {},
              },
            };
            session.events.push(event);
            sendToClient(ws, event);
          }
          continue;
        }

        // Skip other control messages
        if (parsed.type === 'control_response' || parsed.type === 'control_cancel_request') continue;

        // Map Claude events for timeline
        const result = mapClaudeEvent(sessionId, parsed);
        if (!result) continue;
        const events = Array.isArray(result) ? result : [result];
        for (const event of events) {
          session.events.push(event);
          sendToClient(ws, event);
        }
      } catch (e) { /* not JSON, skip */ }
    }
  });

  proc.stderr.on('data', (chunk) => {
    const errText = chunk.toString().trim();
    if (errText) {
      console.error(`Session ${sessionId} stderr: ${errText.slice(0, 200)}`);
      const errEvent = { id: uuidv4(), sessionId, timestamp: new Date().toISOString(), type: 'error', data: { message: errText } };
      session.events.push(errEvent);
      sendToClient(ws, errEvent);
    }
  });

  proc.on('exit', (code) => {
    session.status = 'ended';
    console.log(`Session ${sessionId} exited with code ${code}`);
    const endEvent = { id: uuidv4(), sessionId, timestamp: new Date().toISOString(), type: 'sessionEnd', data: { reason: code === 0 ? 'completed' : 'error', totalTokens: 0, cost: 0 } };
    session.events.push(endEvent);
    sendToClient(ws, endEvent);
    // Also notify terminal view
    if (ws.readyState === 1) {
      ws.send(JSON.stringify({ type: 'ptyExit', sessionId, exitCode: code }));
    }
  });

  return sessionId;
}

function mapClaudeEvent(sessionId, parsed) {
  const id = uuidv4();
  const timestamp = new Date().toISOString();
  const type = parsed.type || '';

  // System events: init, hooks, etc.
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
    // Skip hook events — they're internal noise
    return null;
  }

  // Assistant message: {"type":"assistant","message":{"content":[{"type":"text","text":"..."}],...}}
  if (type === 'assistant') {
    const msg = parsed.message;
    if (!msg) return null;

    const content = msg.content || [];
    const texts = [];
    const toolUses = [];

    for (const block of content) {
      if (block.type === 'text') {
        texts.push(block.text || '');
      } else if (block.type === 'thinking') {
        // Extended thinking block
        return { id, sessionId, timestamp, type: 'assistantThinking', data: { thinking: block.thinking || '', done: true } };
      } else if (block.type === 'tool_use') {
        toolUses.push(block);
      }
    }

    // Emit text blocks
    const events = [];
    if (texts.length > 0) {
      events.push({ id, sessionId, timestamp, type: 'assistantText', data: {
        text: texts.join('\n'),
        done: msg.stop_reason === 'end_turn',
        model: msg.model || '',
        usage: msg.usage || {},
      }});
    }

    // Emit tool_use blocks from within assistant message
    for (const tu of toolUses) {
      events.push({ id: uuidv4(), sessionId, timestamp, type: 'toolUse', data: {
        toolName: tu.name || 'Unknown',
        input: tu.input || {},
        toolUseId: tu.id || uuidv4(),
      }});
    }

    // Return array of events or single event
    if (events.length === 0) return null;
    if (events.length === 1) return events[0];
    return events; // caller must handle array
  }

  // Tool use (top-level, streaming format)
  if (type === 'tool_use') {
    return { id, sessionId, timestamp, type: 'toolUse', data: {
      toolName: parsed.name || 'Unknown',
      input: parsed.input || {},
      toolUseId: parsed.tool_use_id || parsed.id || uuidv4(),
    }};
  }

  // Tool result
  if (type === 'tool_result') {
    return { id, sessionId, timestamp, type: 'toolResult', data: {
      toolUseId: parsed.tool_use_id || '',
      success: !parsed.is_error,
      output: typeof parsed.content === 'string' ? parsed.content : JSON.stringify(parsed.content || ''),
      duration: parsed.duration_ms || 0,
    }};
  }

  // Result event — turn complete, but NOT session end (session stays alive for multi-turn)
  if (type === 'result') {
    return { id, sessionId, timestamp, type: 'turnComplete', data: {
      reason: parsed.subtype === 'success' ? 'completed' : 'error',
      result: parsed.result || '',
      totalTokens: (parsed.usage?.input_tokens || 0) + (parsed.usage?.output_tokens || 0),
      cost: parsed.total_cost_usd || 0,
      duration: parsed.duration_ms || 0,
      model: parsed.modelUsage ? Object.keys(parsed.modelUsage)[0] : '',
      usage: parsed.usage || {},
    }};
  }

  // Control requests (permission prompts from Claude)
  if (type === 'control_request') {
    const req = parsed.request || {};
    if (req.subtype === 'can_use_tool') {
      return { id, sessionId, timestamp, type: 'permissionRequest', data: {
        toolName: req.tool_name || 'Unknown',
        command: JSON.stringify(req.input || {}),
        toolUseId: parsed.request_id || '',
        input: req.input || {},
      }};
    }
    // Other control requests (initialize responses, etc.) — skip
    return null;
  }

  // Control responses — skip
  if (type === 'control_response' || type === 'control_cancel_request') return null;

  // Rate limit events
  if (type === 'rate_limit_event') return null;

  // Error
  if (type === 'error') {
    return { id, sessionId, timestamp, type: 'error', data: {
      message: parsed.message || parsed.error || JSON.stringify(parsed),
    }};
  }

  // Unknown — skip instead of dumping raw JSON
  return null;
}

function sendToClient(ws, event) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(event));
}

// ── PTY Sessions (real terminal via pty-proxy.py) ──
const ptySessions = new Map();

function createPtySession(ws, options) {
  const { spawn } = require('child_process');
  const sessionId = uuidv4();
  const claudePath = process.env.CLAUDE_PATH || '/Users/dev/.local/bin/claude';
  let cwd = options.projectDir || process.cwd();
  if (cwd.startsWith('~')) cwd = cwd.replace('~', require('os').homedir());
  const fs = require('fs');
  if (!fs.existsSync(cwd)) { fs.mkdirSync(cwd, { recursive: true }); }

  const claudeArgs = [];
  if (options.model && options.model !== 'auto') claudeArgs.push('--model', options.model);
  if (options.permissionMode && options.permissionMode !== 'default') claudeArgs.push('--permission-mode', options.permissionMode);
  if (options.dangerouslySkipPermissions) claudeArgs.push('--dangerously-skip-permissions');
  if (options.resumeSessionId) claudeArgs.push('--resume', options.resumeSessionId);

  const cols = options.cols || 80;
  const rows = options.rows || 24;
  const proxyPath = require('path').join(__dirname, 'pty-proxy.py');

  console.log(`PTY spawning: ${claudePath} ${claudeArgs.join(' ')} in ${cwd} (${cols}x${rows})`);

  const proc = spawn('python3', ['-u', proxyPath, String(cols), String(rows), claudePath, ...claudeArgs], {
    cwd,
    stdio: ['pipe', 'pipe', 'pipe'],
    env: { ...process.env, PATH: process.env.PATH + ':/Users/dev/.local/bin' },
  });

  const session = { id: sessionId, proc, options, status: 'active', ws };
  ptySessions.set(sessionId, session);

  proc.stdout.on('data', (data) => {
    if (ws.readyState === 1) {
      // Send raw bytes as base64 to preserve binary terminal data
      ws.send(JSON.stringify({ type: 'ptyData', sessionId, data: data.toString('base64'), encoding: 'base64' }));
    }
  });

  proc.stderr.on('data', (data) => {
    console.error(`PTY stderr [${sessionId}]: ${data.toString().slice(0, 200)}`);
  });

  proc.on('exit', (code) => {
    session.status = 'ended';
    if (ws.readyState === 1) {
      ws.send(JSON.stringify({ type: 'ptyExit', sessionId, exitCode: code }));
    }
    ptySessions.delete(sessionId);
    console.log(`PTY session ${sessionId} exited with code ${code}`);
  });

  proc.on('error', (err) => {
    console.error(`PTY spawn error [${sessionId}]: ${err.message}`);
    session.status = 'ended';
  });

  return sessionId;
}

function stopSession(sessionId) {
  const session = sessions.get(sessionId);
  if (!session || session.status === 'ended') return;
  session.proc.kill('SIGTERM');
  setTimeout(() => { try { session.proc.kill('SIGKILL'); } catch (_) {} }, 5000);
}

// ── Pinch WebSocket ──

const wss = new WebSocket.Server({ server, path: '/ws' });

wss.on('connection', (ws) => {
  console.log('Pinch client connected');
  ws.on('message', (data) => {
    try {
      const msg = JSON.parse(data.toString());
      switch (msg.action) {
        case 'createSession': {
          const sid = createClaudeSession(ws, msg.options || { projectDir: msg.projectDir });
          // Send session ID back so client knows which session to listen for
          sendToClient(ws, { type: 'sessionCreated', sessionId: sid, clientRequestId: msg.requestId || null });
          console.log(`Session created: ${sid}`);
          break;
        }
        case 'prompt': {
          console.log(`Prompt for session ${msg.sessionId}: "${(msg.text || '').substring(0, 50)}"`);
          const session = sessions.get(msg.sessionId);
          if (session) {
            console.log(`Session found — status: ${session.status}, proc: ${!!session.proc}, proc.pid: ${session.proc?.pid}, proc.killed: ${session.proc?.killed}`);
          }
          if (session && session.proc && session.status === 'active') {
            if (!session.initialized) {
              console.log(`Session ${msg.sessionId} not yet initialized, queuing prompt`);
              // Queue the prompt and send once initialized
              if (!session._pendingPrompts) session._pendingPrompts = [];
              session._pendingPrompts.push(msg.text);
            } else {
              // Send stream-json formatted user message
              const userMsg = JSON.stringify({
                type: 'user',
                message: { role: 'user', content: msg.text },
                parent_tool_use_id: null,
                session_id: 'default',
              });
              session.proc.stdin.write(userMsg + '\n');
              console.log(`Sent prompt to session ${msg.sessionId}`);
            }
            const userEvent = { id: uuidv4(), sessionId: msg.sessionId, timestamp: new Date().toISOString(), type: 'userMessage', data: { text: msg.text } };
            session.events.push(userEvent);
            sendToClient(ws, userEvent);
          } else {
            console.log(`Session ${msg.sessionId} not active. Available: ${[...sessions.keys()].join(', ')}`);
          }
          break;
        }
        case 'createPtySession': {
          const sid = createPtySession(ws, msg.options || { projectDir: msg.projectDir });
          sendToClient(ws, { type: 'ptySessionCreated', sessionId: sid });
          console.log(`PTY session created: ${sid}`);
          break;
        }
        case 'ptyInput': {
          const s = ptySessions.get(msg.sessionId);
          if (s && s.proc && s.status === 'active') {
            const buf = msg.encoding === 'base64'
              ? Buffer.from(msg.data, 'base64')
              : Buffer.from(msg.data, 'utf8');
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
          // Also stop PTY sessions
          const ptyS = ptySessions.get(msg.sessionId);
          if (ptyS && ptyS.proc) { ptyS.proc.kill('SIGTERM'); }
          break;
        case 'permission': {
          const s = sessions.get(msg.sessionId);
          if (s && s.proc) {
            const response = msg.allowed
              ? { behavior: 'allow', updatedInput: null }
              : { behavior: 'deny', message: 'Denied by user' };
            s.proc.stdin.write(JSON.stringify({
              type: 'control_response',
              response: {
                subtype: 'success',
                request_id: msg.toolUseId,
                response,
              },
            }) + '\n');
          }
          break;
        }
      }
    } catch (e) { console.error('WS message error:', e.message); }
  });
  ws.on('close', () => console.log('Pinch client disconnected'));
});

process.on('SIGTERM', () => {
  console.log('Shutting down');
  for (const [id] of sessions) stopSession(id);
  server.close(() => process.exit(0));
});
process.on('SIGINT', () => {
  console.log('Shutting down');
  for (const [id] of sessions) stopSession(id);
  server.close(() => process.exit(0));
});
