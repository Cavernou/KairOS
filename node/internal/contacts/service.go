package contacts

import (
	"context"
	"time"

	"github.com/kairos-project/kairos/node/internal/db"
)

type Contact struct {
	KNumber         string
	DisplayName     string
	RealPhone       string
	Notes           string
	TrustStatus     string
	LastInteraction int64
	AvatarASCII     string
}

type Service struct {
	store *db.Store
}

func NewService(store *db.Store) *Service {
	return &Service{store: store}
}

func (s *Service) Upsert(ctx context.Context, contact Contact) error {
	_, err := s.store.DB.ExecContext(
		ctx,
		`INSERT INTO contacts (knumber, display_name, real_phone, notes, trust_status, last_interaction, avatar_ascii)
		 VALUES (?, ?, ?, ?, ?, ?, ?)
		 ON CONFLICT(knumber) DO UPDATE SET
		   display_name = excluded.display_name,
		   real_phone = excluded.real_phone,
		   notes = excluded.notes,
		   trust_status = excluded.trust_status,
		   last_interaction = excluded.last_interaction,
		   avatar_ascii = excluded.avatar_ascii`,
		contact.KNumber,
		contact.DisplayName,
		contact.RealPhone,
		contact.Notes,
		contact.TrustStatus,
		contact.LastInteraction,
		contact.AvatarASCII,
	)
	return err
}

func (s *Service) List(ctx context.Context) ([]Contact, error) {
	rows, err := s.store.DB.QueryContext(ctx, `SELECT knumber, display_name, real_phone, notes, trust_status, last_interaction, avatar_ascii FROM contacts ORDER BY display_name ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var contacts []Contact
	for rows.Next() {
		var item Contact
		if err := rows.Scan(&item.KNumber, &item.DisplayName, &item.RealPhone, &item.Notes, &item.TrustStatus, &item.LastInteraction, &item.AvatarASCII); err != nil {
			return nil, err
		}
		contacts = append(contacts, item)
	}
	return contacts, rows.Err()
}

func (s *Service) SeedDefaults(ctx context.Context) error {
	now := time.Now().Unix()
	defaults := []Contact{
		{
			KNumber:         "K-1000-0001",
			DisplayName:     "Home Node",
			Notes:           "Primary trusted node authority",
			TrustStatus:     "trusted",
			LastInteraction: now,
			AvatarASCII:     "[NODE]",
		},
		{
			KNumber:         "K-2000-0002",
			DisplayName:     "Field Contact",
			Notes:           "Recovered from macOS test node",
			TrustStatus:     "pending",
			LastInteraction: now - 1800,
			AvatarASCII:     "<:>",
		},
	}

	for _, contact := range defaults {
		if err := s.Upsert(ctx, contact); err != nil {
			return err
		}
	}
	return nil
}
