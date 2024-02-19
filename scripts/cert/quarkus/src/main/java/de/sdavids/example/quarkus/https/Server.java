// SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

package de.sdavids.example.quarkus.https;

import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;

import static jakarta.ws.rs.core.MediaType.TEXT_HTML;

@Path("/")
public class Server {

  @GET
  @Produces(TEXT_HTML)
  @RunOnVirtualThread
  public String index() {
    return "<!doctype html><title>Test</title><h1>Test</h1>";
  }
}
