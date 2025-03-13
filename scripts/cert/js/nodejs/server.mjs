// SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

/* eslint-disable no-console */

import { readFileSync } from 'node:fs';
import process from 'node:process';

['uncaughtException', 'unhandledRejection'].forEach((s) =>
  process.once(s, (e) => {
    console.error(e);
    process.exit(70); // EX_SOFTWARE
  }),
);
['SIGINT', 'SIGTERM'].forEach((signal) =>
  process.on(signal, () => process.exit(0)),
);

// eslint-disable-next-line dot-notation
const port = Number(process.env['PORT'] ?? 3000);
if (isNaN(port) || port < 1 || port > 65535) {
  console.error(`port must be between 1 and 65535: ${port}`);
  process.exit(64); // EX_USAGE
}
// eslint-disable-next-line dot-notation
const certPath = process.env['CERT_PATH'] ?? 'cert.pem';
// eslint-disable-next-line dot-notation
const keyPath = process.env['KEY_PATH'] ?? 'key.pem';

// eslint-disable-next-line init-declarations
let engine;
try {
  engine = await import('node:https');
} catch {
  console.error('https support is disabled');
  process.exit(78); // EX_CONFIG
}

const options = {};
try {
  options.cert = readFileSync(certPath);
} catch {
  console.error(`cert path "${certPath}" invalid`);
  process.exit(64); // EX_USAGE
}
try {
  options.key = readFileSync(keyPath);
} catch {
  console.error(`key path "${keyPath}" invalid`);
  process.exit(64); // EX_USAGE
}

const server = engine.createServer(options, (_, w) => {
  w.writeHead(200).end('<!doctype html><title>Test</title><h1>Test</h1>');
});

server.keepAliveTimeout = 5000;
server.requestTimeout = 10000;
server.timeout = 15000;

server.listen(port, () => {
  console.log(`Listen local: https://localhost:${port}`);
});

server.on('timeout', (socket) => {
  socket.destroy();
});

server.on('error', (err) => {
  if (err.syscall === 'listen') {
    switch (err.code) {
      case 'EACCES':
        console.error('Port requires elevated privileges');
        process.exit(77); // EX_NOPERM
        break;
      case 'EADDRINUSE':
        console.error('Port is already in use');
        process.exit(75); // EX_TEMPFAIL
        break;
      default:
      // just log
    }
  }

  console.error(err);
});
