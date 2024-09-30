// SPDX-FileCopyrightText: © 2020 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

import { readFileSync } from 'node:fs';
import process from 'node:process';

['uncaughtException', 'unhandledRejection'].forEach((s) =>
  process.once(s, (e) => {
    console.error(e);
    process.exit(70); // EX_SOFTWARE
  }),
);
['SIGINT', 'SIGTERM'].forEach((s) => process.once(s, () => process.exit(0)));

// eslint-disable-next-line init-declarations
let https;
try {
  https = await import('node:https');
} catch {
  console.error('https support is disabled');
  process.exit(78); // EX_CONFIG
}

const port = 3000;

const server = https.createServer(
  {
    key: readFileSync('key.pem'),
    cert: readFileSync('cert.pem'),
  },
  (_, w) => {
    w.writeHead(200).end('<!doctype html><title>Test</title><h1>Test</h1>');
  },
);
server.keepAliveTimeout = 5000;
server.requestTimeout = 5000;
server.timeout = 5000;
server.listen(port);

console.log(`Listen local: https://localhost:${port}`);
