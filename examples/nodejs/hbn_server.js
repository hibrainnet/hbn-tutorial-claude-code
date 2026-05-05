const http = require('http');

const HBN_PORT = 3000;
const HBN_HOST = 'localhost';

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello, World!\n');
});

server.listen(HBN_PORT, HBN_HOST, () => {
  console.log(`서버 실행 중: http://${HBN_HOST}:${HBN_PORT}`);
});
