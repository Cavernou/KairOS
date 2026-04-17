package queue

import (
	"testing"
	"time"
)

func TestNextRetryAt(t *testing.T) {
	now := time.Unix(1_700_000_000, 0)
	next := NextRetryAt(2, now)
	expected := now.Add(5 * time.Minute)
	if !next.Equal(expected) {
		t.Fatalf("expected %v, got %v", expected, next)
	}
}
