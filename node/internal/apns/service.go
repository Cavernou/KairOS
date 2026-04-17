package apns

type Service struct {
	Enabled bool
}

func NewService(enabled bool) *Service {
	return &Service{Enabled: enabled}
}

func (s *Service) NotifyQueueAvailable(deviceToken string) error {
	if !s.Enabled {
		return nil
	}
	return nil
}
