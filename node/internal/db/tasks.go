package db

import (
	"database/sql"
	"time"
)

// Task represents a task with due date and priority
type Task struct {
	ID          string
	Title       string
	Description string
	DueDate     int64
	Priority    string
	Status      string
	CreatedBy   string
	CreatedAt   int64
	CompletedAt int64
}

// CreateTask creates a new task in the database
func CreateTask(db *sql.DB, id, title, description string, dueDate int64, priority, createdBy string) error {
	now := time.Now().Unix()
	query := `
		INSERT INTO tasks (id, title, description, due_date, priority, status, created_by, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	`
	_, err := db.Exec(query, id, title, description, dueDate, priority, "pending", createdBy, now)
	return err
}

// GetTasks retrieves all tasks from the database
func GetTasks(db *sql.DB) ([]Task, error) {
	query := `
		SELECT id, title, description, due_date, priority, status, created_by, created_at, completed_at
		FROM tasks
		ORDER BY due_date ASC
	`
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tasks []Task
	for rows.Next() {
		var task Task
		var completedAt sql.NullInt64
		err := rows.Scan(&task.ID, &task.Title, &task.Description, &task.DueDate, &task.Priority, &task.Status, &task.CreatedBy, &task.CreatedAt, &completedAt)
		if err != nil {
			return nil, err
		}
		if completedAt.Valid {
			task.CompletedAt = completedAt.Int64
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}

// GetTask retrieves a specific task by ID
func GetTask(db *sql.DB, id string) (*Task, error) {
	query := `
		SELECT id, title, description, due_date, priority, status, created_by, created_at, completed_at
		FROM tasks
		WHERE id = ?
	`
	row := db.QueryRow(query, id)

	var task Task
	var completedAt sql.NullInt64
	err := row.Scan(&task.ID, &task.Title, &task.Description, &task.DueDate, &task.Priority, &task.Status, &task.CreatedBy, &task.CreatedAt, &completedAt)
	if err != nil {
		return nil, err
	}
	if completedAt.Valid {
		task.CompletedAt = completedAt.Int64
	}

	return &task, nil
}

// GetTasksByStatus retrieves tasks filtered by status
func GetTasksByStatus(db *sql.DB, status string) ([]Task, error) {
	query := `
		SELECT id, title, description, due_date, priority, status, created_by, created_at, completed_at
		FROM tasks
		WHERE status = ?
		ORDER BY due_date ASC
	`
	rows, err := db.Query(query, status)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tasks []Task
	for rows.Next() {
		var task Task
		var completedAt sql.NullInt64
		err := rows.Scan(&task.ID, &task.Title, &task.Description, &task.DueDate, &task.Priority, &task.Status, &task.CreatedBy, &task.CreatedAt, &completedAt)
		if err != nil {
			return nil, err
		}
		if completedAt.Valid {
			task.CompletedAt = completedAt.Int64
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}

// GetTasksByPriority retrieves tasks filtered by priority
func GetTasksByPriority(db *sql.DB, priority string) ([]Task, error) {
	query := `
		SELECT id, title, description, due_date, priority, status, created_by, created_at, completed_at
		FROM tasks
		WHERE priority = ?
		ORDER BY due_date ASC
	`
	rows, err := db.Query(query, priority)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tasks []Task
	for rows.Next() {
		var task Task
		var completedAt sql.NullInt64
		err := rows.Scan(&task.ID, &task.Title, &task.Description, &task.DueDate, &task.Priority, &task.Status, &task.CreatedBy, &task.CreatedAt, &completedAt)
		if err != nil {
			return nil, err
		}
		if completedAt.Valid {
			task.CompletedAt = completedAt.Int64
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}

// UpdateTask updates an existing task
func UpdateTask(db *sql.DB, id, title, description string, dueDate int64, priority, status string) error {
	query := `
		UPDATE tasks
		SET title = ?, description = ?, due_date = ?, priority = ?, status = ?
		WHERE id = ?
	`
	_, err := db.Exec(query, title, description, dueDate, priority, status, id)
	return err
}

// CompleteTask marks a task as completed
func CompleteTask(db *sql.DB, id string) error {
	now := time.Now().Unix()
	query := `
		UPDATE tasks
		SET status = 'completed', completed_at = ?
		WHERE id = ?
	`
	_, err := db.Exec(query, now, id)
	return err
}

// DeleteTask deletes a task from the database
func DeleteTask(db *sql.DB, id string) error {
	query := `DELETE FROM tasks WHERE id = ?`
	_, err := db.Exec(query, id)
	return err
}

// GetOverdueTasks retrieves tasks that are past their due date and not completed
func GetOverdueTasks(db *sql.DB) ([]Task, error) {
	now := time.Now().Unix()
	query := `
		SELECT id, title, description, due_date, priority, status, created_by, created_at, completed_at
		FROM tasks
		WHERE due_date < ? AND status != 'completed'
		ORDER BY due_date ASC
	`
	rows, err := db.Query(query, now)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tasks []Task
	for rows.Next() {
		var task Task
		var completedAt sql.NullInt64
		err := rows.Scan(&task.ID, &task.Title, &task.Description, &task.DueDate, &task.Priority, &task.Status, &task.CreatedBy, &task.CreatedAt, &completedAt)
		if err != nil {
			return nil, err
		}
		if completedAt.Valid {
			task.CompletedAt = completedAt.Int64
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}
