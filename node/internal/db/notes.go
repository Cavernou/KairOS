package db

import (
	"database/sql"
	"time"
)

// Note represents a structured text note
type Note struct {
	ID        string
	Title     string
	Content   string
	Tags      string
	CreatedBy string
	CreatedAt int64
	UpdatedAt int64
}

// CreateNote creates a new note in the database
func CreateNote(db *sql.DB, id, title, content, tags, createdBy string) error {
	now := time.Now().Unix()
	query := `
		INSERT INTO notes (id, title, content, tags, created_by, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	`
	_, err := db.Exec(query, id, title, content, tags, createdBy, now, now)
	return err
}

// GetNotes retrieves all notes from the database
func GetNotes(db *sql.DB) ([]Note, error) {
	query := `
		SELECT id, title, content, tags, created_by, created_at, updated_at
		FROM notes
		ORDER BY updated_at DESC
	`
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var notes []Note
	for rows.Next() {
		var note Note
		err := rows.Scan(&note.ID, &note.Title, &note.Content, &note.Tags, &note.CreatedBy, &note.CreatedAt, &note.UpdatedAt)
		if err != nil {
			return nil, err
		}
		notes = append(notes, note)
	}

	return notes, nil
}

// GetNote retrieves a specific note by ID
func GetNote(db *sql.DB, id string) (*Note, error) {
	query := `
		SELECT id, title, content, tags, created_by, created_at, updated_at
		FROM notes
		WHERE id = ?
	`
	row := db.QueryRow(query, id)

	var note Note
	err := row.Scan(&note.ID, &note.Title, &note.Content, &note.Tags, &note.CreatedBy, &note.CreatedAt, &note.UpdatedAt)
	if err != nil {
		return nil, err
	}

	return &note, nil
}

// UpdateNote updates an existing note
func UpdateNote(db *sql.DB, id, title, content, tags string) error {
	now := time.Now().Unix()
	query := `
		UPDATE notes
		SET title = ?, content = ?, tags = ?, updated_at = ?
		WHERE id = ?
	`
	_, err := db.Exec(query, title, content, tags, now, id)
	return err
}

// DeleteNote deletes a note from the database
func DeleteNote(db *sql.DB, id string) error {
	query := `DELETE FROM notes WHERE id = ?`
	_, err := db.Exec(query, id)
	return err
}

// SearchNotes searches notes by title, content, or tags
func SearchNotes(db *sql.DB, searchTerm string) ([]Note, error) {
	query := `
		SELECT id, title, content, tags, created_by, created_at, updated_at
		FROM notes
		WHERE title LIKE ? OR content LIKE ? OR tags LIKE ?
		ORDER BY updated_at DESC
	`
	searchPattern := "%" + searchTerm + "%"
	rows, err := db.Query(query, searchPattern, searchPattern, searchPattern)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var notes []Note
	for rows.Next() {
		var note Note
		err := rows.Scan(&note.ID, &note.Title, &note.Content, &note.Tags, &note.CreatedBy, &note.CreatedAt, &note.UpdatedAt)
		if err != nil {
			return nil, err
		}
		notes = append(notes, note)
	}

	return notes, nil
}
