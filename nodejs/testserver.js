const http2 = require('http2');
const fs = require('fs');

const options = {
  key: fs.readFileSync('./server_key.key'),
  cert: fs.readFileSync('./server_cert.crt'),
  allowHTTP1: true,
  //could override the default openssl defined curves
  //ecdhCurve: 'X25519MLKEM768:mlkem1024:p521_mlkem1024:mlkem768:p384_mlkem768:mlkem512:p256_mlkem512:secp521r1:secp384r1:X25519:prime256v1:X448'
};

const port = 8443;

const server = http2.createSecureServer(options, (req, res) => {
  if (req.url === '/hello') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Hello World!\n');
  } else if (req.url === '/exit') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Terminating Server\n');
    setImmediate(() => {exit(0)});

  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(port, () => {
    console.log('Server running at https://localhost:' + port);
});
