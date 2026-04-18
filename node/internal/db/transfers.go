package db

import (
	"context"
)

// CreateFileTransfer creates a new file transfer record in the database
func (s *Store) CreateFileTransfer(ctx context.Context, transferID, senderKair, receiverKair string, totalChunks, receivedChunks int, checksum string) error {
	query := `
		INSERT INTO file_transfers (transfer_id, sender_kair, receiver_kair, total_chunks, received_chunks, checksum, status)
		VALUES (?, ?, ?, ?, ?, ?, 'queued')
	`
	_, err := s.DB.ExecContext(ctx, query, transferID, senderKair, receiverKair, totalChunks, receivedChunks, checksum)
	return err
}

// GetFileTransfer retrieves a file transfer by ID
func (s *Store) GetFileTransfer(ctx context.Context, transferID string) (map[string]interface{}, error) {
	query := `
		SELECT transfer_id, sender_kair, receiver_kair, total_chunks, received_chunks, checksum, status
		FROM file_transfers
		WHERE transfer_id = ?
	`
	row := s.DB.QueryRowContext(ctx, query, transferID)

	var transferIDOut, senderKair, receiverKair, checksum, status string
	var totalChunks, receivedChunks int

	err := row.Scan(&transferIDOut, &senderKair, &receiverKair, &totalChunks, &receivedChunks, &checksum, &status)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"transfer_id":     transferIDOut,
		"sender_kair":     senderKair,
		"receiver_kair":   receiverKair,
		"total_chunks":    totalChunks,
		"received_chunks": receivedChunks,
		"checksum":        checksum,
		"status":          status,
	}, nil
}

// UpdateFileTransferStatus updates the status of a file transfer
func (s *Store) UpdateFileTransferStatus(ctx context.Context, transferID, status string) error {
	query := `
		UPDATE file_transfers
		SET status = ?
		WHERE transfer_id = ?
	`
	_, err := s.DB.ExecContext(ctx, query, status, transferID)
	return err
}
