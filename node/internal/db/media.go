package db

import (
	"database/sql"
	"time"
)

// Media represents a media file (image, audio, video)
type Media struct {
	ID         string
	Name       string
	Type       string
	FilePath   string
	Size       int64
	UploadedBy string
	UploadedAt int64
}

// CreateMedia creates a new media file record in the database
func CreateMedia(db *sql.DB, id, name, mediaType, filePath string, size int64, uploadedBy string) error {
	now := time.Now().Unix()
	query := `
		INSERT INTO media (id, name, type, file_path, size, uploaded_by, uploaded_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	`
	_, err := db.Exec(query, id, name, mediaType, filePath, size, uploadedBy, now)
	return err
}

// GetMedia retrieves all media files from the database
func GetMedia(db *sql.DB) ([]Media, error) {
	query := `
		SELECT id, name, type, file_path, size, uploaded_by, uploaded_at
		FROM media
		ORDER BY uploaded_at DESC
	`
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var media []Media
	for rows.Next() {
		var m Media
		err := rows.Scan(&m.ID, &m.Name, &m.Type, &m.FilePath, &m.Size, &m.UploadedBy, &m.UploadedAt)
		if err != nil {
			return nil, err
		}
		media = append(media, m)
	}

	return media, nil
}

// GetMediaByID retrieves a specific media file by ID
func GetMediaByID(db *sql.DB, id string) (*Media, error) {
	query := `
		SELECT id, name, type, file_path, size, uploaded_by, uploaded_at
		FROM media
		WHERE id = ?
	`
	row := db.QueryRow(query, id)

	var m Media
	err := row.Scan(&m.ID, &m.Name, &m.Type, &m.FilePath, &m.Size, &m.UploadedBy, &m.UploadedAt)
	if err != nil {
		return nil, err
	}

	return &m, nil
}

// GetMediaByType retrieves media files filtered by type
func GetMediaByType(db *sql.DB, mediaType string) ([]Media, error) {
	query := `
		SELECT id, name, type, file_path, size, uploaded_by, uploaded_at
		FROM media
		WHERE type = ?
		ORDER BY uploaded_at DESC
	`
	rows, err := db.Query(query, mediaType)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var media []Media
	for rows.Next() {
		var m Media
		err := rows.Scan(&m.ID, &m.Name, &m.Type, &m.FilePath, &m.Size, &m.UploadedBy, &m.UploadedAt)
		if err != nil {
			return nil, err
		}
		media = append(media, m)
	}

	return media, nil
}

// DeleteMedia deletes a media file record from the database
func DeleteMedia(db *sql.DB, id string) error {
	query := `DELETE FROM media WHERE id = ?`
	_, err := db.Exec(query, id)
	return err
}

// GetMediaStats returns statistics about media storage
func GetMediaStats(db *sql.DB) (map[string]int64, error) {
	stats := make(map[string]int64)

	// Get total size
	var totalSize int64
	err := db.QueryRow("SELECT SUM(size) FROM media").Scan(&totalSize)
	if err != nil {
		return nil, err
	}
	stats["total_size"] = totalSize

	// Get count by type
	types := []string{"image", "audio", "video"}
	for _, t := range types {
		var count int64
		err := db.QueryRow("SELECT COUNT(*) FROM media WHERE type = ?", t).Scan(&count)
		if err != nil {
			return nil, err
		}
		stats[t+"_count"] = count
	}

	return stats, nil
}
