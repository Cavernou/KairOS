package mockapi

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"

	"github.com/kairos-project/kairos/node/internal/activation"
	"github.com/kairos-project/kairos/node/internal/contacts"
	"github.com/kairos-project/kairos/node/internal/crypto"
	"github.com/kairos-project/kairos/node/internal/db"
	"github.com/kairos-project/kairos/node/internal/identity"
	"github.com/kairos-project/kairos/node/internal/memory"
	"github.com/kairos-project/kairos/node/internal/queue"
	"github.com/kairos-project/kairos/node/internal/trust"
)

func TestMockAPIActivateAndQueueMessage(t *testing.T) {
	store, err := db.Open(filepath.Join(t.TempDir(), "mockapi.db"))
	if err != nil {
		t.Fatalf("Open returned error: %v", err)
	}
	defer store.Close()

	if err := store.Migrate(); err != nil {
		t.Fatalf("Migrate returned error: %v", err)
	}

	identityService := identity.NewService(store)
	activationService := activation.NewService(store, 3600)
	queueService := queue.NewService(store, 100, 168)
	contactService := contacts.NewService(store)
	if err := SeedDefaults(context.Background(), contactService); err != nil {
		t.Fatalf("SeedDefaults returned error: %v", err)
	}

	server := NewServer(
		"kairos.ts.net",
		false,
		identityService,
		activationService,
		queueService,
		crypto.NewService(),
		contactService,
		trust.NewService(store),
		memory.NewService(store),
		"", // Empty sound dir for tests
		store,
	)

	handler := server.Handler()

	activatePayload := map[string]any{
		"device_id":   "device-1",
		"kair_number": "K-1234-5678",
		"public_key":  []byte("public-key"),
	}
	response := performJSONRequest(t, handler, http.MethodPost, "/mock/v1/activate", activatePayload)
	if response.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", response.Code)
	}

	var activationBody activateResponse
	if err := json.Unmarshal(response.Body.Bytes(), &activationBody); err != nil {
		t.Fatalf("Decode activation response: %v", err)
	}

	if activationBody.ActivationState != "pending_admin_code" {
		t.Fatalf("expected pending_admin_code, got %q", activationBody.ActivationState)
	}
	if activationBody.DebugAdminCode == "" {
		t.Fatalf("expected debug admin code to be returned")
	}

	messagePayload := map[string]any{
		"id":                "msg-1",
		"type":              "message",
		"sender_kair":       "K-1234-5678",
		"receiver_kair":     "K-2000-0002",
		"timestamp":         1700000000000,
		"encrypted_payload": []byte("ciphertext"),
		"node_route":        []string{"home-node"},
		"has_attachments":   false,
	}
	response = performJSONRequest(t, handler, http.MethodPost, "/mock/v1/messages", messagePayload)
	if response.Code != http.StatusOK {
		t.Fatalf("expected 200 for message send, got %d", response.Code)
	}

	queueResponse := performJSONRequest(t, handler, http.MethodGet, "/mock/v1/queue?receiver_kair=K-2000-0002", nil)
	if queueResponse.Code != http.StatusOK {
		t.Fatalf("expected 200 for queue fetch, got %d", queueResponse.Code)
	}

	var queued []queuedItem
	if err := json.Unmarshal(queueResponse.Body.Bytes(), &queued); err != nil {
		t.Fatalf("Decode queue response: %v", err)
	}
	if len(queued) != 1 {
		t.Fatalf("expected 1 queued item, got %d", len(queued))
	}
}

func performJSONRequest(t *testing.T, handler http.Handler, method, path string, payload any) *httptest.ResponseRecorder {
	t.Helper()

	var requestBody *bytes.Reader
	if payload != nil {
		body, err := json.Marshal(payload)
		if err != nil {
			t.Fatalf("Marshal payload: %v", err)
		}
		requestBody = bytes.NewReader(body)
	} else {
		requestBody = bytes.NewReader(nil)
	}

	request, err := http.NewRequest(method, path, requestBody)
	if err != nil {
		t.Fatalf("NewRequest: %v", err)
	}
	request.Header.Set("Content-Type", "application/json")

	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	return response
}
