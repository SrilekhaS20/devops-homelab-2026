const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Auto-deployed from GitHub! v2.0\n');
});

server.listen(3000, () => {
  console.log('Server running on port 3000');
});
