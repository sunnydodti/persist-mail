package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "os/exec"
    "strings"
    "time"
)

type Response struct {
    Status  string `json:"status,omitempty"`
    Error   string `json:"error,omitempty"`
    Message string `json:"message,omitempty"`
}

func writeJSON(w http.ResponseWriter, status int, data Response) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}

func loggingMiddleware(next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        log.Printf("Request: %s %s", r.Method, r.URL.Path)
        next(w, r)
        log.Printf("Request completed in %v", time.Since(start))
    }
}

func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
    apiKey := os.Getenv("ADMIN_API_KEY")
    if apiKey == "" {
        log.Fatal("ADMIN_API_KEY environment variable not set")
    }

    return func(w http.ResponseWriter, r *http.Request) {
        if r.Header.Get("X-API-Key") != apiKey {
            writeJSON(w, http.StatusForbidden, Response{
                Status: "error",
                Error:  "forbidden",
            })
            log.Printf("Invalid API key attempt from %s", r.RemoteAddr)
            return
        }
        next(w, r)
    }
}

func createMailboxHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != "POST" {
        writeJSON(w, http.StatusMethodNotAllowed, Response{
            Status: "error",
            Error:  "method not allowed",
        })
        return
    }

    username := strings.TrimPrefix(r.URL.Path, "/mailbox/")
    if username == "" || strings.Contains(username, "/") {
        writeJSON(w, http.StatusBadRequest, Response{
            Status: "error",
            Error:  "invalid username",
        })
        return
    }

    // Execute the mailserver command
    cmd := exec.Command("docker", "exec", "mailserver", "/usr/local/bin/setup.sh", "email", "add", username, "password123")
    output, err := cmd.CombinedOutput()

    if err != nil {
        log.Printf("Error creating mailbox %s: %v\nOutput: %s", username, err, string(output))
        writeJSON(w, http.StatusInternalServerError, Response{
            Status:  "error",
            Error:   "internal error",
            Message: string(output),
        })
        return
    }

    log.Printf("Successfully created mailbox: %s", username)
    writeJSON(w, http.StatusOK, Response{
        Status:  "success",
        Message: fmt.Sprintf("Mailbox %s created successfully", username),
    })
}

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "5000"
    }

    addr := fmt.Sprintf("127.0.0.1:%s", port)
    
    log.Printf("Starting admin API server on %s", addr)
    
    http.HandleFunc("/mailbox/", loggingMiddleware(authMiddleware(createMailboxHandler)))
    
    if err := http.ListenAndServe(addr, nil); err != nil {
        log.Fatalf("Server failed to start: %v", err)
    }
}
