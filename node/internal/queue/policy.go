package queue

import "time"

var retrySchedule = []time.Duration{
	0,
	time.Minute,
	5 * time.Minute,
	15 * time.Minute,
	time.Hour,
	4 * time.Hour,
	12 * time.Hour,
	24 * time.Hour,
}

func NextRetryAt(retryCount int, now time.Time) time.Time {
	if retryCount < 0 {
		retryCount = 0
	}
	if retryCount >= len(retrySchedule) {
		retryCount = len(retrySchedule) - 1
	}
	return now.Add(retrySchedule[retryCount])
}
