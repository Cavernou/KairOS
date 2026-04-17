package queue

import (
	"context"
	"time"

	"github.com/kairos-project/kairos/node/internal/db"
)

type Item struct {
	ID          string
	ReceiverKair string
	Payload     []byte
	RetryCount  int
	NextRetry   time.Time
	CreatedAt   time.Time
	ExpiresAt   time.Time
	Status      string
}

type Service struct {
	store      *db.Store
	retryLimit int
	ttlHours   int
}

func NewService(store *db.Store, retryLimit, ttlHours int) *Service {
	return &Service{store: store, retryLimit: retryLimit, ttlHours: ttlHours}
}

func (s *Service) Enqueue(ctx context.Context, id, receiverKair string, payload []byte, now time.Time) error {
	_, err := s.store.DB.ExecContext(
		ctx,
		`INSERT INTO message_queue (id, receiver_kair, payload, retry_count, next_retry, created_at, expires_at, status) VALUES (?, ?, ?, 0, ?, ?, ?, 'queued')`,
		id,
		receiverKair,
		payload,
		NextRetryAt(0, now).Unix(),
		now.Unix(),
		now.Add(time.Duration(s.ttlHours)*time.Hour).Unix(),
	)
	return err
}

func (s *Service) MarkAttempt(ctx context.Context, id, outcome, detail string, now time.Time) error {
	_, err := s.store.DB.ExecContext(
		ctx,
		`INSERT INTO delivery_attempts (queue_id, attempted_at, outcome, detail) VALUES (?, ?, ?, ?)`,
		id,
		now.Unix(),
		outcome,
		detail,
	)
	return err
}

func (s *Service) BumpRetry(ctx context.Context, id string, retryCount int, now time.Time) error {
	status := "queued"
	if retryCount >= s.retryLimit {
		status = "failed"
	}
	_, err := s.store.DB.ExecContext(
		ctx,
		`UPDATE message_queue SET retry_count = ?, next_retry = ?, status = ? WHERE id = ?`,
		retryCount,
		NextRetryAt(retryCount, now).Unix(),
		status,
		id,
	)
	return err
}

func (s *Service) ReadyForReceiver(ctx context.Context, receiverKair string, now time.Time) ([]Item, error) {
	rows, err := s.store.DB.QueryContext(
		ctx,
		`SELECT id, receiver_kair, payload, retry_count, next_retry, created_at, expires_at, status
		 FROM message_queue
		 WHERE receiver_kair = ? AND status = 'queued' AND next_retry <= ?
		 ORDER BY created_at ASC`,
		receiverKair,
		now.Unix(),
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []Item
	for rows.Next() {
		var item Item
		var nextRetry, createdAt, expiresAt int64
		if err := rows.Scan(&item.ID, &item.ReceiverKair, &item.Payload, &item.RetryCount, &nextRetry, &createdAt, &expiresAt, &item.Status); err != nil {
			return nil, err
		}
		item.NextRetry = time.Unix(nextRetry, 0)
		item.CreatedAt = time.Unix(createdAt, 0)
		item.ExpiresAt = time.Unix(expiresAt, 0)
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Service) MarkDelivered(ctx context.Context, id string) error {
	_, err := s.store.DB.ExecContext(ctx, `UPDATE message_queue SET status = 'delivered' WHERE id = ?`, id)
	return err
}

func (s *Service) FailExpired(ctx context.Context, now time.Time) error {
	_, err := s.store.DB.ExecContext(
		ctx,
		`UPDATE message_queue SET status = 'failed' WHERE status = 'queued' AND expires_at <= ?`,
		now.Unix(),
	)
	return err
}
