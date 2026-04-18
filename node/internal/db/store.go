package db

import (
	"database/sql"

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

	// Update contacts table
	_, err = s.DB.Exec(`
		UPDATE contacts 
		SET knumber = 'K-' || SUBSTR(knumber, 3, 4)
		WHERE knumber LIKE 'K-%-%-%-%'
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

	return nil
}
