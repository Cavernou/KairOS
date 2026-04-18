package db

import (
	"database/sql"
	"time"

	_ "modernc.org/sqlite"
)

type Store struct {
	DB *sql.DB
}

func Open(path string) (*Store, error) {
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}

	if _, err := db.Exec(`PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON;`); err != nil {
		return nil, err
	}

	return &Store{DB: db}, nil
}

func (s *Store) Close() error {
	return s.DB.Close()
}

func (s *Store) Migrate() error {
	_, err := s.DB.Exec(schema)
	if err != nil {
		return err
	}

	// Migrate old K-Number formats to K-XXXX
	return s.migrateKairNumbers()
}

func (s *Store) migrateKairNumbers() error {
	// Update devices table
	_, err := s.DB.Exec(`
		UPDATE devices 
		SET kair_number = 'K-' || SUBSTR(kair_number, 3, 4)
		WHERE kair_number LIKE 'K-%-%-%-%'
	`)
	if err != nil {
		return err
	}

	// Update contacts table with K-XXXX-XXXX format (8 digits after K-)
	_, err = s.DB.Exec(`
		UPDATE contacts
		SET knumber = 'K-' || SUBSTR(knumber, 3, 4)
		WHERE knumber LIKE 'K-____-____' AND knumber NOT LIKE 'K-____'
	`)
	if err != nil {
		return err
	}

	// Also update contacts with K-XXXX-XXXX-XXXX format (12 digits after K-)
	_, err = s.DB.Exec(`
		UPDATE contacts
		SET knumber = 'K-' || SUBSTR(knumber, 3, 4)
		WHERE knumber LIKE 'K-%-%-%-%' AND knumber NOT LIKE 'K-____'
	`)
	if err != nil {
		return err
	}

	// Update trust_scores table
	_, err = s.DB.Exec(`
		UPDATE trust_scores 
		SET kair_number = 'K-' || SUBSTR(kair_number, 3, 4)
		WHERE kair_number LIKE 'K-%-%-%-%'
	`)
	if err != nil {
		return err
	}

	// Ensure node device exists with K-1919
	var nodeCount int
	err = s.DB.QueryRow("SELECT COUNT(*) FROM devices WHERE kair_number = 'K-1919'").Scan(&nodeCount)
	if err != nil {
		return err
	}

	if nodeCount == 0 {
		_, err = s.DB.Exec(`
			INSERT INTO devices (device_id, kair_number, display_name, status, created_at, last_seen)
			VALUES ('node-device-001', 'K-1919', 'Home Node', 'active', ?, ?)
		`, time.Now().Unix(), time.Now().Unix())
		if err != nil {
			return err
		}
	}

	return nil
}
