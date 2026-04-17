package db

import (
	"database/sql"
	"time"
)

// CalendarEvent represents a calendar event
type CalendarEvent struct {
	ID          string
	Title       string
	Description string
	StartTime   int64
	EndTime     int64
	Location    string
	Attendees   string
	CreatedBy   string
	CreatedAt   int64
}

// CreateEvent creates a new calendar event in the database
func CreateEvent(db *sql.DB, id, title, description string, startTime, endTime int64, location, attendees, createdBy string) error {
	now := time.Now().Unix()
	query := `
		INSERT INTO calendar_events (id, title, description, start_time, end_time, location, attendees, created_by, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`
	_, err := db.Exec(query, id, title, description, startTime, endTime, location, attendees, createdBy, now)
	return err
}

// GetEvents retrieves all calendar events from the database
func GetEvents(db *sql.DB) ([]CalendarEvent, error) {
	query := `
		SELECT id, title, description, start_time, end_time, location, attendees, created_by, created_at
		FROM calendar_events
		ORDER BY start_time ASC
	`
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []CalendarEvent
	for rows.Next() {
		var event CalendarEvent
		err := rows.Scan(&event.ID, &event.Title, &event.Description, &event.StartTime, &event.EndTime, &event.Location, &event.Attendees, &event.CreatedBy, &event.CreatedAt)
		if err != nil {
			return nil, err
		}
		events = append(events, event)
	}

	return events, nil
}

// GetEvent retrieves a specific calendar event by ID
func GetEvent(db *sql.DB, id string) (*CalendarEvent, error) {
	query := `
		SELECT id, title, description, start_time, end_time, location, attendees, created_by, created_at
		FROM calendar_events
		WHERE id = ?
	`
	row := db.QueryRow(query, id)

	var event CalendarEvent
	err := row.Scan(&event.ID, &event.Title, &event.Description, &event.StartTime, &event.EndTime, &event.Location, &event.Attendees, &event.CreatedBy, &event.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &event, nil
}

// GetEventsInRange retrieves calendar events within a time range
func GetEventsInRange(db *sql.DB, startTime, endTime int64) ([]CalendarEvent, error) {
	query := `
		SELECT id, title, description, start_time, end_time, location, attendees, created_by, created_at
		FROM calendar_events
		WHERE start_time >= ? AND end_time <= ?
		ORDER BY start_time ASC
	`
	rows, err := db.Query(query, startTime, endTime)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []CalendarEvent
	for rows.Next() {
		var event CalendarEvent
		err := rows.Scan(&event.ID, &event.Title, &event.Description, &event.StartTime, &event.EndTime, &event.Location, &event.Attendees, &event.CreatedBy, &event.CreatedAt)
		if err != nil {
			return nil, err
		}
		events = append(events, event)
	}

	return events, nil
}

// UpdateEvent updates an existing calendar event
func UpdateEvent(db *sql.DB, id, title, description string, startTime, endTime int64, location, attendees string) error {
	query := `
		UPDATE calendar_events
		SET title = ?, description = ?, start_time = ?, end_time = ?, location = ?, attendees = ?
		WHERE id = ?
	`
	_, err := db.Exec(query, title, description, startTime, endTime, location, attendees, id)
	return err
}

// DeleteEvent deletes a calendar event from the database
func DeleteEvent(db *sql.DB, id string) error {
	query := `DELETE FROM calendar_events WHERE id = ?`
	_, err := db.Exec(query, id)
	return err
}

// GetUpcomingEvents retrieves events starting after the current time
func GetUpcomingEvents(db *sql.DB, limit int) ([]CalendarEvent, error) {
	now := time.Now().Unix()
	query := `
		SELECT id, title, description, start_time, end_time, location, attendees, created_by, created_at
		FROM calendar_events
		WHERE start_time > ?
		ORDER BY start_time ASC
		LIMIT ?
	`
	rows, err := db.Query(query, now, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []CalendarEvent
	for rows.Next() {
		var event CalendarEvent
		err := rows.Scan(&event.ID, &event.Title, &event.Description, &event.StartTime, &event.EndTime, &event.Location, &event.Attendees, &event.CreatedBy, &event.CreatedAt)
		if err != nil {
			return nil, err
		}
		events = append(events, event)
	}

	return events, nil
}
