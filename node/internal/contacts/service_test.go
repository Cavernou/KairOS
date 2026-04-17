package contacts

import (
	"context"
	"path/filepath"
	"testing"
	"time"

	"github.com/kairos-project/kairos/node/internal/db"
)

func TestUpsertAndList(t *testing.T) {
	store, err := db.Open(filepath.Join(t.TempDir(), "contacts.db"))
	if err != nil {
		t.Fatalf("Open returned error: %v", err)
	}
	defer store.Close()

	if err := store.Migrate(); err != nil {
		t.Fatalf("Migrate returned error: %v", err)
	}

	service := NewService(store)
	err = service.Upsert(context.Background(), Contact{
		KNumber:         "K-1234-5678",
		DisplayName:     "Node",
		TrustStatus:     "trusted",
		LastInteraction: time.Now().Unix(),
		AvatarASCII:     "[NODE]",
	})
	if err != nil {
		t.Fatalf("Upsert returned error: %v", err)
	}

	contacts, err := service.List(context.Background())
	if err != nil {
		t.Fatalf("List returned error: %v", err)
	}
	if len(contacts) != 1 {
		t.Fatalf("expected 1 contact, got %d", len(contacts))
	}
}
