package memory

import (
	"context"

	"github.com/kairos-project/kairos/node/internal/db"
)

type Entry struct {
	ID         string
	MemoryType string
	TargetID   string
	Content    string
	Importance float64
	CreatedAt  int64
}

type Service struct {
	store *db.Store
}

func NewService(store *db.Store) *Service {
	return &Service{store: store}
}

func (s *Service) Store(ctx context.Context, entry Entry) error {
	_, err := s.store.DB.ExecContext(
		ctx,
		`INSERT OR REPLACE INTO ai_memory (id, memory_type, target_id, content, importance, created_at) VALUES (?, ?, ?, ?, ?, ?)`,
		entry.ID,
		entry.MemoryType,
		entry.TargetID,
		entry.Content,
		entry.Importance,
		entry.CreatedAt,
	)
	return err
}

func (s *Service) Retrieve(ctx context.Context, id string) (Entry, error) {
	var entry Entry
	err := s.store.DB.QueryRowContext(
		ctx,
		`SELECT id, memory_type, target_id, content, importance, created_at FROM ai_memory WHERE id = ?`,
		id,
	).Scan(&entry.ID, &entry.MemoryType, &entry.TargetID, &entry.Content, &entry.Importance, &entry.CreatedAt)
	return entry, err
}
