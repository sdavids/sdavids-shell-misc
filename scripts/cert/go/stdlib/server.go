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

func main() {
	const port = 3000

	server := http.Server{
		Addr:         fmt.Sprintf(":%d", port),
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
		IdleTimeout:  5 * time.Second,
		Handler: http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			_, err := w.Write([]byte("<!doctype html><title>Test</title><h1>Test</h1>"))
			if err != nil {
				slog.Error("handle response", slog.Any("error", err))
			}
		}),
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
