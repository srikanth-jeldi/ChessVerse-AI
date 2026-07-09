const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(process.argv[2] || path.join(__dirname, '..', 'mobile', 'build', 'web'));
const port = Number(process.argv[3] || 8090);

const types = {
  '.css': 'text/css',
  '.html': 'text/html',
  '.ico': 'image/x-icon',
  '.jpg': 'image/jpeg',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.webp': 'image/webp',
};

http
  .createServer((request, response) => {
    let requestPath = decodeURIComponent(request.url.split('?')[0]);
    if (requestPath === '/' || requestPath === '') {
      requestPath = '/index.html';
    }

    let filePath = path.resolve(root, `.${requestPath}`);
    if (!filePath.startsWith(root)) {
      response.writeHead(403);
      response.end('Forbidden');
      return;
    }

    fs.stat(filePath, (statError, stat) => {
      if (statError || !stat.isFile()) {
        filePath = path.join(root, 'index.html');
      }

      fs.readFile(filePath, (readError, data) => {
        if (readError) {
          response.writeHead(404);
          response.end('Not found');
          return;
        }

        response.writeHead(200, {
          'Content-Type': types[path.extname(filePath)] || 'application/octet-stream',
        });
        response.end(data);
      });
    });
  })
  .listen(port, '127.0.0.1', () => {
    console.log(`ChessVerse web preview: http://127.0.0.1:${port}`);
  });
