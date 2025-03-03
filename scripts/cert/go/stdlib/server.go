// SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"time"
)

const port = 3000

const (
	readTimeout    = 5 * time.Second
	writeTimeout   = 5 * time.Second
	idleTimeout    = 5 * time.Second
	handlerTimeout = 2 * time.Second
)

func main() {
	server := http.Server{
		Addr:         fmt.Sprintf(":%d", port),
		ReadTimeout:  readTimeout,
		WriteTimeout: writeTimeout,
		IdleTimeout:  idleTimeout,
		Handler: http.TimeoutHandler(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			_, err := w.Write([]byte("<!doctype html><title>Test</title><h1>Test</h1>"))
			if err != nil {
				slog.Error("handle response", slog.Any("error", err))
			}
		}), handlerTimeout, ""),
	}
	defer func(server *http.Server) {
		if err := server.Close(); err != nil {
			slog.Error("server close", slog.Any("error", err))
			os.Exit(70)
		}
	}(&server)

	slog.Info(fmt.Sprintf("Listen local: https://localhost:%d", port))

	if err := server.ListenAndServeTLS("cert.pem", "key.pem"); err != nil {
		slog.Error("listen", slog.Any("error", err))
		os.Exit(70)
	}
}
