// SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"strconv"
	"time"
)

// https://blog.cloudflare.com/the-complete-guide-to-golang-net-http-timeouts/
const (
	readTimeout    = 5 * time.Second
	writeTimeout   = 10 * time.Second
	idleTimeout    = 30 * time.Second
	handlerTimeout = 15 * time.Second
)

func main() {
	port, err := getPort()
	if err != nil {
		slog.Error("usage", slog.Any("error", err))
		os.Exit(64) // EX_USAGE
	}
	certPath, err := getCertPath()
	if err != nil {
		slog.Error("usage", slog.Any("error", err))
		os.Exit(64) // EX_USAGE
	}
	keyPath, err := getKeyPath()
	if err != nil {
		slog.Error("usage", slog.Any("error", err))
		os.Exit(64) // EX_USAGE
	}

	os.Exit(run(port, certPath, keyPath))
}

func run(port int, certPath string, keyPath string) int {
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
			os.Exit(70) // EX_SOFTWARE
		}
	}(&server)

	slog.Info(fmt.Sprintf("Listen local: https://localhost:%d", port))

	if err := server.ListenAndServeTLS(certPath, keyPath); err != nil {
		slog.Error("listen", slog.Any("error", err))
		return 70 // EX_SOFTWARE
	}

	return 0
}

func getPort() (int, error) {
	port := getEnvAsInt("PORT", 3000)
	if port < 1 || port > 65535 {
		return -1, fmt.Errorf("port must be between 1 and 65535: %d", port)
	}
	return port, nil
}

func getCertPath() (string, error) {
	path := getEnv("CERT_PATH", "cert.pem")
	if _, err := os.Stat(path); err != nil {
		return "", fmt.Errorf("cert path %q invalid", path)
	}
	return path, nil
}

func getKeyPath() (string, error) {
	path := getEnv("KEY_PATH", "key.pem")
	if _, err := os.Stat(path); err != nil {
		return "", fmt.Errorf("key path %q invalid", path)
	}
	return path, nil
}

func getEnv(key string, defaultVal string) string {
	if v, exists := os.LookupEnv(key); exists {
		return v
	}
	return defaultVal
}

func getEnvAsInt(key string, defaultVal int) int {
	if v, exists := os.LookupEnv(key); exists {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return defaultVal
}
