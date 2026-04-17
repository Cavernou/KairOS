package transport

type ActivateDeviceRequest struct {
	DeviceID   string
	KairNumber string
	PublicKey  []byte
	AdminCode  string
}

type ActivateDeviceResponse struct {
	Activated       bool
	ActivationState string
	DeviceID        string
	KairNumber      string
}

type MessagePacket struct {
	ID               string
	Type             string
	SenderKair       string
	ReceiverKair     string
	Timestamp        int64
	EncryptedPayload []byte
	NodeRoute        []string
	HasAttachments   bool
}

type SendResult struct {
	ID         string
	Status     string
	RetryCount int
}

type MemoryRequest struct {
	ID string
}

type FetchQueueRequest struct {
	ReceiverKair string
}
