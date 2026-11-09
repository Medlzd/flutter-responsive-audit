const http = require('http');
const fs = require('fs');
const path = require('path');

http.createServer((req, res) => {
  res.setHeader('Content-Type', 'text/html');
  fs.createReadStream(path.join(__dirname, 'index.html')).pipe(res);
}).listen(3000);
