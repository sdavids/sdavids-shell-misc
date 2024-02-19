/*
 * Copyright (c) 2024, Sebastian Davids
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { readFileSync } from 'node:fs';

let https;
try {
  https = await import('node:https');
} catch (_) {
  console.error('https support is disabled');
  process.exit(78);
}

const port = 3000;

const server = https.createServer(
  {
    key: readFileSync('key.pem'),
    cert: readFileSync('cert.pem'),
  },
  (_, w) => {
    w.writeHead(200).end('<!doctype html><title>Test</title><h1>Test');
  },
);
server.keepAliveTimeout = 5000;
server.requestTimeout = 5000;
server.timeout = 5000;
server.listen(port);

console.log(`Listen local: https://localhost:${port}`);

['uncaughtException', 'unhandledRejection'].forEach((s) =>
  process.once(s, (e) => {
    console.error(e);
    process.exit(70);
  }),
);
['SIGINT', 'SIGTERM'].forEach((s) => process.once(s, () => process.exit(0)));
