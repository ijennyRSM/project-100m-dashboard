import http from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(new URL('../', import.meta.url)));
const port = Number(process.env.PORT || 5500);
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.svg': 'image/svg+xml', '.json': 'application/json' };
http.createServer(async (req, res) => {
  try {
    const path = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    const parts = path.split('/');
    if (parts.some(p => p.startsWith('.') || ['node_modules', 'test-results', 'playwright-report'].includes(p))) throw Error('Forbidden');
    const file = resolve(root, '.' + (path.endsWith('/') ? path + 'index.html' : path));
    if (!file.startsWith(root + sep) || !(await stat(file)).isFile()) throw Error('Not found');
    res.writeHead(200, { 'Content-Type': types[extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' });
    res.end(await readFile(file));
  } catch { res.writeHead(404); res.end('Not found'); }
}).listen(port, '127.0.0.1', () => console.log(`PROJECT 100M: http://localhost:${port}`));
