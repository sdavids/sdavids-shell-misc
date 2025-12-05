// SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

import static java.util.Objects.requireNonNull;
import static java.util.Objects.requireNonNullElse;

import module java.logging;

import com.sun.net.httpserver.HttpsConfigurator;
import com.sun.net.httpserver.HttpsServer;

void main() throws Exception {
  var logger = Logger.getLogger(MethodHandles.lookup().lookupClass().getName());

  // see sun.net.httpserver.ServerConfig
  System.setProperty("sun.net.httpserver.maxReqTime", "5");
  System.setProperty("sun.net.httpserver.maxRspTime", "10");
  System.setProperty("sun.net.httpserver.idleInterval", "30000");

  var port = getPort();

  var server =
      HttpsServer.create(
          new InetSocketAddress(port),
          0,
          "/",
          exchange -> {
            var response = "<!doctype html><title>Test</title><h1>Test</h1>";
            exchange.sendResponseHeaders(HttpURLConnection.HTTP_OK, response.length());
            try (var body = exchange.getResponseBody()) {
              body.write(response.getBytes());
            } catch (IOException e) {
              logger.log(Level.SEVERE, "handle response", e);
            }
          });

  server.setHttpsConfigurator(new HttpsConfigurator(newSSLContext()));
  server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());

  server.start();

  logger.info(String.format("Listen local: https://localhost:%d", port));
}

int getPort() {
  var port = Integer.valueOf(requireNonNullElse(System.getenv("PORT"), "3000"));
  if (port < 1 || port > 65535) {
    throw new IllegalArgumentException("port must be between 1 and 65535: " + port);
  }
  return port;
}

SSLContext newSSLContext() throws Exception {
  var keyStorePath = requireNonNull(System.getenv("KEYSTORE_PATH"), "keystore path");

  var keyStorePassword =
      requireNonNull(System.getenv("KEYSTORE_PASS"), "keystore password").toCharArray();

  var keyStore = KeyStore.getInstance(KeyStore.getDefaultType());
  keyStore.load(Files.newInputStream(Path.of(keyStorePath)), keyStorePassword);

  var keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
  keyManagerFactory.init(keyStore, keyStorePassword);

  var trustManagerFactory =
      TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
  trustManagerFactory.init(keyStore);

  var sslContext = SSLContext.getInstance("TLS");
  sslContext.init(
      keyManagerFactory.getKeyManagers(), trustManagerFactory.getTrustManagers(), null);

  return sslContext;
}
