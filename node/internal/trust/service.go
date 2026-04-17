package trust

import (
	"context"
	"time"

	"github.com/kairos-project/kairos/node/internal/db"
)

type Service struct {
	store *db.Store
}

func NewService(store *db.Store) *Service {
	return &Service{store: store}
}

func (s *Service) Update(ctx context.Context, kairNumber string, delta float64) error {
	_, err := s.store.DB.ExecContext(
		ctx,
		`INSERT INTO trust_scores (kair_number, score, interaction_count, last_updated)
		 VALUES (?, ?, 1, ?)
		 ON CONFLICT(kair_number) DO UPDATE SET
		   score = trust_scores.score + excluded.score,
		   interaction_count = trust_scores.interaction_count + 1,
		   last_updated = excluded.last_updated`,
		kairNumber,
		delta,
		time.Now().Unix(),
	)
	return err
}
