package identity

import (
	"context"
	"errors"
	"regexp"
	"time"

	"github.com/kairos-project/kairos/node/internal/db"
)

var kairPattern = regexp.MustCompile(`^K-\d{4}-\d{4}$`)

type Service struct {
	store *db.Store
}

func NewService(store *db.Store) *Service {
	return &Service{store: store}
}

func ValidateKairNumber(kairNumber string) bool {
	return kairPattern.MatchString(kairNumber)
}

func (s *Service) RegisterPendingDevice(ctx context.Context, deviceID, kairNumber string, publicKey []byte) error {
	if !ValidateKairNumber(kairNumber) {
		return errors.New("invalid K-number format")
	}

	_, err := s.store.DB.ExecContext(
		ctx,
		`INSERT INTO devices (device_id, kair_number, public_key, status, last_seen)
		 VALUES (?, ?, ?, 'pending', ?)
		 ON CONFLICT(device_id) DO UPDATE SET
		   kair_number = excluded.kair_number,
		   public_key = excluded.public_key,
		   status = 'pending',
		   last_seen = excluded.last_seen`,
		deviceID,
		kairNumber,
		publicKey,
		time.Now().Unix(),
	)
	return err
}

func (s *Service) ActivateDevice(ctx context.Context, deviceID string) error {
	_, err := s.store.DB.ExecContext(
		ctx,
		`UPDATE devices SET status = 'active', activation_timestamp = ?, last_seen = ? WHERE device_id = ?`,
		time.Now().Unix(),
		time.Now().Unix(),
		deviceID,
	)
	return err
}

func (s *Service) ListDevices(ctx context.Context) ([]Device, error) {
	rows, err := s.store.DB.QueryContext(
		ctx,
		`SELECT device_id, kair_number, public_key, status, activation_timestamp, last_seen FROM devices`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var devices []Device
	for rows.Next() {
		var device Device
		err := rows.Scan(
			&device.DeviceID,
			&device.KairNumber,
			&device.PublicKey,
			&device.Status,
			&device.ActivationTimestamp,
			&device.LastSeen,
		)
		if err != nil {
			return nil, err
		}
		devices = append(devices, device)
	}
	return devices, nil
}

type Device struct {
	DeviceID            string
	KairNumber          string
	PublicKey           []byte
	Status              string
	ActivationTimestamp int64
	LastSeen            int64
}
