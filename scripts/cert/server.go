/*
Copyright (c) 2024, Sebastian Davids

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
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
			_, err := w.Write([]byte("<!doctype html><title>Test</title><h1>Test"))
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
