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

import static java.lang.String.format;
import static java.lang.System.getenv;
import static java.net.HttpURLConnection.HTTP_OK;
import static java.nio.file.Files.newInputStream;
import static java.util.Objects.requireNonNull;
import static java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor;
import static java.util.logging.Level.SEVERE;
import static java.util.logging.Logger.getLogger;

import com.sun.net.httpserver.HttpsConfigurator;
import com.sun.net.httpserver.HttpsServer;
import java.io.IOException;
import java.lang.invoke.MethodHandles;
import java.net.InetSocketAddress;
import java.nio.file.Path;
import java.security.KeyStore;
import java.util.logging.Logger;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;

public final class Server {

  public static void main(String[] args) throws Exception {
    var port = 3000;

    var server =
        HttpsServer.create(
            new InetSocketAddress(port),
            0,
            "/",
            exchange -> {
              var response = "<!doctype html><title>Test</title><h1>Test";
              exchange.sendResponseHeaders(HTTP_OK, response.length());
              try (var body = exchange.getResponseBody()) {
                body.write(response.getBytes());
              } catch (IOException e) {
                LOGGER.log(SEVERE, "handle response", e);
              }
            });
    server.setHttpsConfigurator(new HttpsConfigurator(newSSLContext()));
    server.setExecutor(newVirtualThreadPerTaskExecutor());
    server.start();

    LOGGER.info(format("Listen local: https://localhost:%d", port));
  }

  static {
    System.setProperty("sun.net.httpserver.maxReqTime", "5");
    System.setProperty("sun.net.httpserver.maxRspTime", "5");
    System.setProperty("sun.net.httpserver.idleInterval", "5000");
  }

  private static final Logger LOGGER = getLogger(MethodHandles.lookup().lookupClass().getName());

  private static SSLContext newSSLContext() throws Exception {
    var keyStorePath = requireNonNull(getenv("KEYSTORE_PATH"), "keystore path");
    var keyStorePassword =
        requireNonNull(getenv("KEYSTORE_PASS"), "keystore password").toCharArray();

    var keyStore = KeyStore.getInstance(KeyStore.getDefaultType());
    keyStore.load(newInputStream(Path.of(keyStorePath)), keyStorePassword);

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
}
