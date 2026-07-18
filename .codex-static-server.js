const http = require('http');
const fs = require('fs');
const path = require('path');
const root = path.resolve(process.argv[2] || '.');
const port = Number(process.argv[3] || 8090);
const types = {'.html':'text/html','.js':'text/javascript','.css':'text/css','.png':'image/png','.jpg':'image/jpeg','.jpeg':'image/jpeg','.json':'application/json','.wasm':'application/wasm','.svg':'image/svg+xml','.ico':'image/x-icon','.ttf':'font/ttf','.otf':'font/otf'};
http.createServer((req,res)=>{
  let urlPath = decodeURIComponent(req.url.split('?')[0]);
  if (urlPath === '/') urlPath = '/index.html';
  let file = path.resolve(path.join(root, urlPath));
  if (!file.startsWith(root + path.sep) && file !== root) { res.writeHead(403); return res.end('Forbidden'); }
  fs.stat(file, (err, st)=>{
    if (err || !st.isFile()) file = path.join(root, 'index.html');
    fs.readFile(file, (err2, data)=>{
      if (err2) { res.writeHead(404); return res.end('Not found'); }
      res.writeHead(200, {'Content-Type': types[path.extname(file).toLowerCase()] || 'application/octet-stream', 'Access-Control-Allow-Origin':'*'});
      res.end(data);
    });
  });
}).listen(port, '127.0.0.1', ()=>console.log(`Serving ${root} on http://127.0.0.1:${port}`));
