// SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

package de.sdavids.example.spring.https;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
public class Server {

  @RestController
  static class Controller {

    @GetMapping("/")
    public String index() {
      return "<!doctype html><title>Test</title><h1>Test</h1>";
    }
  }

  public static void main(String[] args) {
    SpringApplication.run(Server.class, args);
  }
}
