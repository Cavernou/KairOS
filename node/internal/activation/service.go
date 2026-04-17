package activation

import (
	"context"
	"errors"
	"time"

	"github.com/kairos-project/kairos/node/internal/db"
)

type Service struct {
	store    *db.Store
	interval int
}

func NewService(store *db.Store, interval int) *Service {
	return &Service{store: store, interval: interval}
}

func (s *Service) IssueCode(ctx context.Context) (string, error) {
	code, err := GenerateAdminCode()
	if err != nil {
		return "", err
	}

	now := time.Now().Unix()
	expiresAt := now + int64(s.interval)

	_, err = s.store.DB.ExecContext(ctx, `INSERT OR REPLACE INTO admin_codes (code, issued_at, expires_at) VALUES (?, ?, ?)`, code, now, expiresAt)
	return code, err
}

func (s *Service) VerifyCode(ctx context.Context, code string) error {
	var expiresAt int64
	err := s.store.DB.QueryRowContext(ctx, `SELECT expires_at FROM admin_codes WHERE code = ?`, code).Scan(&expiresAt)
	if err != nil {
		return errors.New("admin code not found")
	}
	if time.Now().Unix() > expiresAt {
		return errors.New("admin code expired")
	}
	return nil
}

func (s *Service) CurrentCode(ctx context.Context, now time.Time) (string, error) {
	var code string
	err := s.store.DB.QueryRowContext(
		ctx,
		`SELECT code FROM admin_codes WHERE expires_at > ? ORDER BY issued_at DESC LIMIT 1`,
		now.Unix(),
	).Scan(&code)
	if err == nil {
		return code, nil
	}
	return s.IssueCode(ctx)
}
