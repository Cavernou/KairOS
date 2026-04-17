package queue

import (
	"context"
	"path/filepath"
	"testing"
	"time"

	"github.com/kairos-project/kairos/node/internal/db"
)

func TestEnqueueAndReadyForReceiver(t *testing.T) {
	store, err := db.Open(filepath.Join(t.TempDir(), "queue.db"))
	if err != nil {
		t.Fatalf("Open returned error: %v", err)
	}
	defer store.Close()

	if err := store.Migrate(); err != nil {
		t.Fatalf("Migrate returned error: %v", err)
	}

	service := NewService(store, 100, 168)
	now := time.Unix(1_700_000_000, 0)
	if err := service.Enqueue(context.Background(), "id-1", "K-2222-2222", []byte("payload"), now); err != nil {
		t.Fatalf("Enqueue returned error: %v", err)
	}

	items, err := service.ReadyForReceiver(context.Background(), "K-2222-2222", now)
	if err != nil {
		t.Fatalf("ReadyForReceiver returned error: %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("expected 1 item, got %d", len(items))
	}
}
