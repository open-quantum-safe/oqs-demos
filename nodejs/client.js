const http2 = require('http2');
const fs = require('fs');
const { exit } = require('process');

// To run
// node client.js <host> <port> <path> <curve> <ca cert>
// curves can be for example x25519 (legacy kem), mlkem1024 (qsc kem)
const rootca = fs.readFileSync(process.argv[6]);
const hostname = process.argv[2];
const port = process.argv[3];
const path = process.argv[4];

const sessionOptions = {
  ecdhCurve: process.argv[5],
  minVersion: 'TLSv1.3',
  ciphers: 'TLS_AES_256_GCM_SHA384',
  ca: rootca,
};

const requestOptions = {
  method: 'GET',
};


const session = http2.connect(`https://${hostname}:${port}`, sessionOptions);

session.on('error', (err) => {
  console.error('Session Error:', err);
  exit(1);
});

const req = session.request({':path': path}, requestOptions);
req.end();

let data = '';

req.on('data', (chunk) => {
    data += chunk;
});

req.on('end', () => {
    console.log(data);
    session.close();
});

req.on('error', (err) => {
  console.error('Request Error:', err);
  session.close();
  exit(1);
});

