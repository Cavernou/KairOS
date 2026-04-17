package db

import (
	"database/sql"
	"time"
)

// TelemetryEvent represents an activity log event
type TelemetryEvent struct {
	ID        int64
	EventType string
	Details   string
	DeviceID  string
	Timestamp int64
}

// LogEvent logs a telemetry event to the database
func LogEvent(db *sql.DB, eventType, details, deviceID string) error {
	query := `
		INSERT INTO telemetry_events (event_type, details, device_id, timestamp)
		VALUES (?, ?, ?, ?)
	`
	_, err := db.Exec(query, eventType, details, deviceID, time.Now().Unix())
	return err
}

// GetTelemetryEvents retrieves telemetry events from the database
func GetTelemetryEvents(db *sql.DB, limit int) ([]TelemetryEvent, error) {
	query := `
		SELECT id, event_type, details, device_id, timestamp
		FROM telemetry_events
		ORDER BY timestamp DESC
		LIMIT ?
	`
	rows, err := db.Query(query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []TelemetryEvent
	for rows.Next() {
		var event TelemetryEvent
		err := rows.Scan(&event.ID, &event.EventType, &event.Details, &event.DeviceID, &event.Timestamp)
		if err != nil {
			return nil, err
		}
		events = append(events, event)
	}

	return events, nil
}

// GetEventsByType retrieves telemetry events filtered by type
func GetEventsByType(db *sql.DB, eventType string, limit int) ([]TelemetryEvent, error) {
	query := `
		SELECT id, event_type, details, device_id, timestamp
		FROM telemetry_events
		WHERE event_type = ?
		ORDER BY timestamp DESC
		LIMIT ?
	`
	rows, err := db.Query(query, eventType, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []TelemetryEvent
	for rows.Next() {
		var event TelemetryEvent
		err := rows.Scan(&event.ID, &event.EventType, &event.Details, &event.DeviceID, &event.Timestamp)
		if err != nil {
			return nil, err
		}
		events = append(events, event)
	}

	return events, nil
}

// CleanupOldEvents removes telemetry events older than the specified days
func CleanupOldEvents(db *sql.DB, days int) error {
	cutoff := time.Now().AddDate(0, 0, -days).Unix()
	query := `DELETE FROM telemetry_events WHERE timestamp < ?`
	_, err := db.Exec(query, cutoff)
	return err
}
