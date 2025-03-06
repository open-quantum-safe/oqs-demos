const http2 = require('http2');
const fs = require('fs');
const { exit } = require('process');

const options = {
  key: fs.readFileSync('./server_key.key'),
  cert: fs.readFileSync('./server_cert.crt'),
  allowHTTP1: false,
  //ecdhCurve: 'X25519MLKEM768:mlkem1024:p521_mlkem1024:mlkem768:p384_mlkem768:mlkem512:p256_mlkem512:secp521r1:secp384r1:X25519:prime256v1:X448'
};

const port = 8443;

// Create the HTTP/2 server
const server = http2.createSecureServer(options);

server.on('stream', (stream, headers) => {

  // Check if the requested path is 'hello' or 'exit'
  const path = headers[':path'];
  console.log(path);

  switch (path) {
    case '/hello':
      stream.respond({
        ':status': 200,
        'content-type': 'text/plain',
      });
      stream.write('Hello, World!');
      stream.end();
      break;

    case '/exit':
      // Close the connection when the path is /exit
      stream.respond({
        ':status': 200,
        'content-type': 'text/plain',
      });
      stream.write('Terminating Server');
      stream.end();
      setImmediate(() => {exit(0)});
      break;

    default:
      // Respond with a 404 Not Found for any other paths
      stream.respond({
        ':status': 404,
        'content-type': 'text/plain'
      });
      stream.write('Not Found');
      stream.end();
  }
});

server.listen(port);
console.log('Server running at https://localhost:' + port);
