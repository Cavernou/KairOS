package mockapi

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/kairos-project/kairos/node/internal/activation"
	"github.com/kairos-project/kairos/node/internal/contacts"
	"github.com/kairos-project/kairos/node/internal/crypto"
	"github.com/kairos-project/kairos/node/internal/identity"
	"github.com/kairos-project/kairos/node/internal/logging"
	"github.com/kairos-project/kairos/node/internal/memory"
	"github.com/kairos-project/kairos/node/internal/queue"
	"github.com/kairos-project/kairos/node/internal/sound"
	"github.com/kairos-project/kairos/node/internal/trust"
)

type Server struct {
	tailnet          string
	tailscaleEnabled bool
	identity         *identity.Service
	activation       *activation.Service
	queue            *queue.Service
	crypto           *crypto.Service
	contacts         *contacts.Service
	trust            *trust.Service
	memory           *memory.Service
	sound            *sound.Manager

	mu        sync.RWMutex
	reachable bool
}

type statusResponse struct {
	IsReachable        bool                `json:"is_reachable"`
	Tailnet            string              `json:"tailnet"`
	LastSync           int64               `json:"last_sync"`
	TailscaleConnected bool                `json:"tailscale_connected"`
	Devices            []map[string]string `json:"devices"`
}

type activateRequest struct {
	DeviceID   string `json:"device_id"`
	KairNumber string `json:"kair_number"`
	PublicKey  []byte `json:"public_key"`
	AdminCode  string `json:"admin_code"`
	AvatarData []byte `json:"avatar_data,omitempty"`
}

type activateResponse struct {
	Activated       bool   `json:"activated"`
	ActivationState string `json:"activation_state"`
	DeviceID        string `json:"device_id"`
	KairNumber      string `json:"kair_number"`
	DebugAdminCode  string `json:"debug_admin_code,omitempty"`
}

type sendResult struct {
	ID         string `json:"id"`
	Status     string `json:"status"`
	RetryCount int    `json:"retry_count"`
}

type messageRequest struct {
	ID               string   `json:"id"`
	Type             string   `json:"type"`
	SenderKair       string   `json:"sender_kair"`
	ReceiverKair     string   `json:"receiver_kair"`
	Timestamp        int64    `json:"timestamp"`
	EncryptedPayload []byte   `json:"encrypted_payload"`
	NodeRoute        []string `json:"node_route"`
	HasAttachments   bool     `json:"has_attachments"`
}

type queuedItem struct {
	ID               string `json:"id"`
	Type             string `json:"type"`
	EncryptedPayload []byte `json:"encrypted_payload"`
	Timestamp        int64  `json:"timestamp"`
	RetryCount       int    `json:"retry_count"`
}

type contactsResponse struct {
	Contacts []contactResponse `json:"contacts"`
}

type contactResponse struct {
	ID              string `json:"id"`
	DisplayName     string `json:"display_name"`
	RealPhone       string `json:"real_phone,omitempty"`
	Notes           string `json:"notes,omitempty"`
	TrustStatus     string `json:"trust_status"`
	LastInteraction int64  `json:"last_interaction"`
	AvatarASCII     string `json:"avatar_ascii,omitempty"`
}

type trustRequest struct {
	KairNumber string  `json:"kair_number"`
	Delta      float64 `json:"delta"`
	Reason     string  `json:"reason"`
}

type memoryRequest struct {
	ID         string  `json:"id"`
	MemoryType string  `json:"memory_type"`
	TargetID   string  `json:"target_id,omitempty"`
	Content    string  `json:"content"`
	Importance float64 `json:"importance"`
	CreatedAt  int64   `json:"created_at"`
}

type reachabilityRequest struct {
	Reachable bool `json:"reachable"`
}

type adminCodeResponse struct {
	Code      string `json:"code"`
	ExpiresAt int64  `json:"expires_at"`
}

func NewServer(
	tailnet string,
	tailscaleEnabled bool,
	identityService *identity.Service,
	activationService *activation.Service,
	queueService *queue.Service,
	cryptoService *crypto.Service,
	contactService *contacts.Service,
	trustService *trust.Service,
	memoryService *memory.Service,
	soundDir string,
) *Server {
	return &Server{
		tailnet:          tailnet,
		tailscaleEnabled: tailscaleEnabled,
		identity:         identityService,
		activation:       activationService,
		queue:            queueService,
		crypto:           cryptoService,
		contacts:         contactService,
		trust:            trustService,
		memory:           memoryService,
		sound:            sound.NewManager(soundDir),
		reachable:        true,
	}
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()

	// Serve web UI
	mux.Handle("/", http.FileServer(http.Dir("./web")))
	mux.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("./web/static"))))
	mux.Handle("/sounds/", http.StripPrefix("/sounds/", http.FileServer(http.Dir("./sounds"))))

	// API endpoints
	mux.HandleFunc("/mock/v1/status", s.handleStatus)
	mux.HandleFunc("/mock/v1/debug/reachability", s.handleReachability)
	mux.HandleFunc("/mock/v1/activate", s.handleActivate)
	mux.HandleFunc("/mock/v1/messages", s.handleMessages)
	mux.HandleFunc("/mock/v1/queue", s.handleQueue)
	mux.HandleFunc("/mock/v1/contacts", s.handleContacts)
	mux.HandleFunc("/mock/v1/trust", s.handleTrust)
	mux.HandleFunc("/mock/v1/memory/", s.handleMemoryByID)
	mux.HandleFunc("/mock/v1/memory", s.handleMemory)
	mux.HandleFunc("/mock/v1/admin-code", s.handleAdminCode)
	mux.HandleFunc("/mock/v1/files/upload", s.handleFileUpload)
	mux.HandleFunc("/mock/v1/files/", s.handleFileDownload)

	// Add Tailscale IP validation middleware
	return s.tailscaleMiddleware(mux)
}

func (s *Server) tailscaleMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// If Tailscale is enabled, validate IP is from Tailscale range (100.x.x.x)
		if s.tailnet != "" && s.tailscaleEnabled {
			host, _, err := net.SplitHostPort(r.RemoteAddr)
			if err == nil {
				ip := net.ParseIP(host)
				if ip != nil && !s.isTailscaleIP(ip) {
					http.Error(w, "Access denied: Tailscale required", http.StatusForbidden)
					return
				}
			}
		}
		next.ServeHTTP(w, r)
	})
}

func (s *Server) isTailscaleIP(ip net.IP) bool {
	// Tailscale IPs are in the 100.64.0.0/10 range
	if ip == nil {
		return false
	}

	// Check if IP is in 100.64.0.0/10 range (100.64.0.0 - 100.127.255.255)
	if ip.To4() == nil {
		return false
	}

	parts := strings.Split(ip.String(), ".")
	if len(parts) != 4 {
		return false
	}

	firstOctet, _ := strconv.Atoi(parts[0])
	secondOctet, _ := strconv.Atoi(parts[1])

	return firstOctet == 100 && secondOctet >= 64 && secondOctet <= 127
}

func (s *Server) handleStatus(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	if r.Method != http.MethodGet {
		logger.Error("Invalid method for status: %s", r.Method)
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	// Check if Tailscale is actually connected
	tailscaleConnected := checkTailscaleStatus()

	// Get KairOS devices from database
	kairosDevices, err := s.identity.ListDevices(r.Context())
	if err != nil {
		logger.Error("Failed to get KairOS devices: %v", err)
		kairosDevices = []identity.Device{}
	}

	// Convert KairOS devices to device map format
	var devices []map[string]string
	for _, device := range kairosDevices {
		// Only include active devices
		if device.Status == "active" {
			dev := map[string]string{
				"device_id":   device.DeviceID,
				"kair_number": device.KairNumber,
				"activated":   "true",
			}
			devices = append(devices, dev)
		}
	}

	logger.Info("Status requested - Tailscale connected: %v, KairOS Devices: %d", tailscaleConnected, len(devices))

	writeJSON(w, http.StatusOK, statusResponse{
		IsReachable:        s.isReachable(),
		Tailnet:            s.tailnet,
		LastSync:           time.Now().UnixMilli(),
		TailscaleConnected: tailscaleConnected,
		Devices:            devices,
	})
}

func checkTailscaleStatus() bool {
	// Try to run tailscale status command to check if connected
	cmd := exec.Command("tailscale", "status", "--json")
	output, err := cmd.Output()
	if err != nil {
		return false
	}

	// Parse JSON output
	var status map[string]interface{}
	if err := json.Unmarshal(output, &status); err != nil {
		return false
	}

	// Check if backend state is "Running"
	if backendState, ok := status["BackendState"].(string); ok {
		return backendState == "Running"
	}

	return false
}

func getTailscaleDevices() []map[string]string {
	// Get list of Tailscale devices
	cmd := exec.Command("tailscale", "status", "--json")
	output, err := cmd.Output()
	if err != nil {
		return nil
	}

	var status map[string]interface{}
	if err := json.Unmarshal(output, &status); err != nil {
		return nil
	}

	var devices []map[string]string
	if peers, ok := status["Peer"].(map[string]interface{}); ok {
		for _, peer := range peers {
			if peerMap, ok := peer.(map[string]interface{}); ok {
				device := make(map[string]string)
				if hostname, ok := peerMap["HostName"].(string); ok {
					device["hostname"] = hostname
				}
				if ip, ok := peerMap["TailscaleIPs"].([]interface{}); ok && len(ip) > 0 {
					if ipStr, ok := ip[0].(string); ok {
						device["ip"] = ipStr
					}
				}
				if online, ok := peerMap["Online"].(bool); ok {
					device["online"] = fmt.Sprintf("%t", online)
				}
				devices = append(devices, device)
			}
		}
	}

	return devices
}

func (s *Server) handleReachability(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req reachabilityRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	s.setReachable(req.Reachable)
	writeJSON(w, http.StatusOK, statusResponse{
		IsReachable: s.isReachable(),
		Tailnet:     s.tailnet,
		LastSync:    time.Now().UnixMilli(),
	})
}

func (s *Server) handleActivate(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	if r.Method != http.MethodPost {
		logger.Error("Invalid method for activate: %s", r.Method)
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var req activateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Error("Failed to decode activate request: %v", err)
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	logger.Info("Activation request: device=%s, kair=%s, admin_code=%s, avatar=%d bytes", req.DeviceID, req.KairNumber, req.AdminCode, len(req.AvatarData))

	// Validate K-number format
	if !identity.ValidateKairNumber(req.KairNumber) {
		logger.Error("Invalid K-number format: %s", req.KairNumber)
		writeJSON(w, http.StatusBadRequest, activateResponse{
			Activated:       false,
			ActivationState: "invalid_kair_number",
			DeviceID:        req.DeviceID,
			KairNumber:      req.KairNumber,
		})
		return
	}

	// Register device as pending
	if err := s.identity.RegisterPendingDevice(r.Context(), req.DeviceID, req.KairNumber, req.PublicKey); err != nil {
		logger.Error("Failed to register pending device: %v", err)
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	// Store avatar data if provided
	if len(req.AvatarData) > 0 {
		logger.Info("Avatar data received for device %s, size: %d bytes", req.DeviceID, len(req.AvatarData))
		// TODO: Store avatar data in database or file system
	}

	// If admin code provided, verify and activate
	if req.AdminCode != "" {
		if err := s.activation.VerifyCode(r.Context(), req.AdminCode); err != nil {
			logger.Error("Invalid admin code: %v", err)
			writeJSON(w, http.StatusUnauthorized, activateResponse{
				Activated:       false,
				ActivationState: "invalid_admin_code",
				DeviceID:        req.DeviceID,
				KairNumber:      req.KairNumber,
			})
			return
		}

		if err := s.identity.ActivateDevice(r.Context(), req.DeviceID); err != nil {
			logger.Error("Failed to activate device: %v", err)
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}

		logger.Info("Device activated: %s", req.DeviceID)
		writeJSON(w, http.StatusOK, activateResponse{
			Activated:       true,
			ActivationState: "active",
			DeviceID:        req.DeviceID,
			KairNumber:      req.KairNumber,
		})
		return
	}

	// No admin code, return current code for testing
	currentCode, err := s.activation.CurrentCode(r.Context(), time.Now())
	if err != nil {
		logger.Error("Failed to get current code: %v", err)
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	logger.Info("Pending activation, current code: %s", currentCode)
	writeJSON(w, http.StatusOK, activateResponse{
		Activated:       false,
		ActivationState: "pending_admin_code",
		DeviceID:        req.DeviceID,
		KairNumber:      req.KairNumber,
		DebugAdminCode:  currentCode,
	})
}

func (s *Server) handleMessages(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	if !s.isReachable() {
		writeJSON(w, http.StatusServiceUnavailable, sendResult{Status: "failed"})
		return
	}

	var req messageRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if req.ID == "" || req.ReceiverKair == "" {
		writeError(w, http.StatusBadRequest, "message packet is missing required fields")
		return
	}
	if _, err := s.crypto.GenerateSessionKey(); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	if err := s.queue.Enqueue(r.Context(), req.ID, req.ReceiverKair, req.EncryptedPayload, time.Now()); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	// Play sound on successful message queue
	go s.sound.Play("UserSendMessage.mp3")

	writeJSON(w, http.StatusOK, sendResult{
		ID:         req.ID,
		Status:     "queued",
		RetryCount: 0,
	})
}

func (s *Server) handleQueue(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	receiverKair := r.URL.Query().Get("receiver_kair")
	if receiverKair == "" {
		writeError(w, http.StatusBadRequest, "receiver_kair is required")
		return
	}

	items, err := s.queue.ReadyForReceiver(r.Context(), receiverKair, time.Now())
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	response := make([]queuedItem, 0, len(items))
	for _, item := range items {
		response = append(response, queuedItem{
			ID:               item.ID,
			Type:             "message",
			EncryptedPayload: item.Payload,
			Timestamp:        item.CreatedAt.UnixMilli(),
			RetryCount:       item.RetryCount,
		})
		if err := s.queue.MarkDelivered(r.Context(), item.ID); err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}
	}

	writeJSON(w, http.StatusOK, response)
}

func (s *Server) handleContacts(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	entries, err := s.contacts.List(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	response := contactsResponse{Contacts: make([]contactResponse, 0, len(entries))}
	for _, entry := range entries {
		response.Contacts = append(response.Contacts, contactResponse{
			ID:              entry.KNumber,
			DisplayName:     entry.DisplayName,
			RealPhone:       entry.RealPhone,
			Notes:           entry.Notes,
			TrustStatus:     entry.TrustStatus,
			LastInteraction: entry.LastInteraction * 1000,
			AvatarASCII:     entry.AvatarASCII,
		})
	}
	writeJSON(w, http.StatusOK, response)
}

func (s *Server) handleTrust(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req trustRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if err := s.trust.Update(r.Context(), req.KairNumber, req.Delta); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

func (s *Server) handleMemory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req memoryRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	err := s.memory.Store(r.Context(), memory.Entry{
		ID:         req.ID,
		MemoryType: req.MemoryType,
		TargetID:   req.TargetID,
		Content:    req.Content,
		Importance: req.Importance,
		CreatedAt:  req.CreatedAt / 1000,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

func (s *Server) handleMemoryByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	key := strings.TrimPrefix(r.URL.Path, "/mock/v1/memory/")
	if key == "" {
		writeError(w, http.StatusBadRequest, "memory key is required")
		return
	}

	entry, err := s.memory.Retrieve(r.Context(), key)
	if err != nil {
		writeError(w, http.StatusNotFound, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, memoryRequest{
		ID:         entry.ID,
		MemoryType: entry.MemoryType,
		TargetID:   entry.TargetID,
		Content:    entry.Content,
		Importance: entry.Importance,
		CreatedAt:  entry.CreatedAt * 1000,
	})
}

func (s *Server) handleAdminCode(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	if r.Method != http.MethodGet {
		logger.Error("Invalid method for admin code: %s", r.Method)
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	// Get current code (returns existing if not expired)
	code, err := s.activation.CurrentCode(r.Context(), time.Now())
	if err != nil {
		// If no code exists, issue a new one
		logger.Info("Issuing new admin code")
		code, err = s.activation.IssueCode(r.Context())
		if err != nil {
			logger.Error("Failed to issue admin code: %v", err)
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}

		// Play sound on new code generation
		go s.sound.Play("RadarPing.mp3")
		logger.Info("New admin code issued: %s", code)
	} else {
		logger.Info("Returning existing admin code")
	}

	writeJSON(w, http.StatusOK, adminCodeResponse{
		Code:      code,
		ExpiresAt: time.Now().Add(time.Hour).UnixMilli(),
	})
}

func (s *Server) handleFileUpload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	if r.Method != http.MethodPost {
		logger.Error("Invalid method for file upload: %s", r.Method)
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	// Parse multipart form
	err := r.ParseMultipartForm(32 << 20) // 32MB max
	if err != nil {
		logger.Error("Failed to parse multipart form: %v", err)
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	file, handler, err := r.FormFile("file")
	if err != nil {
		logger.Error("Failed to get file from form: %v", err)
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	defer file.Close()

	// Get target device ID
	targetDevice := r.FormValue("target_device")
	if targetDevice == "" {
		logger.Error("Missing target_device parameter")
		writeError(w, http.StatusBadRequest, "Missing target_device parameter")
		return
	}

	logger.Info("File upload request: %s to device %s", handler.Filename, targetDevice)

	// TODO: Implement actual file storage and transfer to target device
	// For now, just acknowledge receipt
	writeJSON(w, http.StatusOK, map[string]string{
		"status":        "queued",
		"file_name":     handler.Filename,
		"target_device": targetDevice,
	})

	go s.sound.Play("FileFolderOpen.mp3")
}

func (s *Server) handleFileDownload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	if r.Method != http.MethodGet {
		logger.Error("Invalid method for file download: %s", r.Method)
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	// Extract file ID from URL
	fileID := strings.TrimPrefix(r.URL.Path, "/mock/v1/files/")
	if fileID == "" {
		logger.Error("Missing file ID in download request")
		writeError(w, http.StatusBadRequest, "Missing file ID")
		return
	}

	logger.Info("File download request: %s", fileID)

	// TODO: Implement actual file retrieval
	writeError(w, http.StatusNotFound, "File not found")
}

func (s *Server) setReachable(value bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.reachable = value
}

func (s *Server) isReachable() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.reachable
}

func decodeJSON(r *http.Request, target any) error {
	defer r.Body.Close()
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return err
	}
	return nil
}

func writeError(w http.ResponseWriter, statusCode int, message string) {
	writeJSON(w, statusCode, map[string]string{"error": message})
}

func writeJSON(w http.ResponseWriter, statusCode int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(payload)
}

func SeedDefaults(ctx context.Context, contactService *contacts.Service) error {
	if contactService == nil {
		return errors.New("contact service is required")
	}
	return contactService.SeedDefaults(ctx)
}
