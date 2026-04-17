package transport

import (
	"context"
	"errors"
	"io"
	"time"

	"github.com/kairos-project/kairos/node/internal/activation"
	"github.com/kairos-project/kairos/node/internal/contacts"
	"github.com/kairos-project/kairos/node/internal/crypto"
	"github.com/kairos-project/kairos/node/internal/identity"
	"github.com/kairos-project/kairos/node/internal/memory"
	"github.com/kairos-project/kairos/node/internal/queue"
	"github.com/kairos-project/kairos/node/internal/trust"
	kairospb "github.com/kairos-project/kairos/node/proto"
	"google.golang.org/grpc"
)

type Server struct {
	kairospb.UnimplementedKairOSNodeServer
	identity   *identity.Service
	activation *activation.Service
	queue      *queue.Service
	crypto     *crypto.Service
	contacts   *contacts.Service
	trust      *trust.Service
	memory     *memory.Service
}

func NewServer(
	identityService *identity.Service,
	activationService *activation.Service,
	queueService *queue.Service,
	cryptoService *crypto.Service,
	contactService *contacts.Service,
	trustService *trust.Service,
	memoryService *memory.Service,
) *Server {
	return &Server{
		identity:   identityService,
		activation: activationService,
		queue:      queueService,
		crypto:     cryptoService,
		contacts:   contactService,
		trust:      trustService,
		memory:     memoryService,
	}
}

func (s *Server) RegisterGRPC(grpcServer grpc.ServiceRegistrar) {
	kairospb.RegisterKairOSNodeServer(grpcServer, s)
}

func (s *Server) ActivateDevice(ctx context.Context, req *kairospb.ActivateRequest) (*kairospb.ActivateResponse, error) {
	if req.GetAdminCode() == "" {
		if err := s.identity.RegisterPendingDevice(ctx, req.GetDeviceId(), req.GetKairNumber(), req.GetPublicKey()); err != nil {
			return nil, err
		}

		return &kairospb.ActivateResponse{
			Activated:       false,
			ActivationState: "pending_admin_code",
			DeviceId:        req.GetDeviceId(),
			KairNumber:      req.GetKairNumber(),
		}, nil
	}

	if err := s.activation.VerifyCode(ctx, req.GetAdminCode()); err != nil {
		return nil, err
	}

	if err := s.identity.ActivateDevice(ctx, req.GetDeviceId()); err != nil {
		return nil, err
	}

	return &kairospb.ActivateResponse{
		Activated:       true,
		ActivationState: "active",
		DeviceId:        req.GetDeviceId(),
		KairNumber:      req.GetKairNumber(),
	}, nil
}

func (s *Server) SendMessage(ctx context.Context, packet *kairospb.MessagePacket) (*kairospb.SendResult, error) {
	if packet.GetId() == "" || packet.GetReceiverKair() == "" {
		return nil, errors.New("message packet is missing required fields")
	}

	if _, err := s.crypto.GenerateSessionKey(); err != nil {
		return nil, err
	}

	if err := s.queue.Enqueue(ctx, packet.GetId(), packet.GetReceiverKair(), packet.GetEncryptedPayload(), time.Now()); err != nil {
		return nil, err
	}

	return &kairospb.SendResult{
		Id:         packet.GetId(),
		Status:     "queued",
		RetryCount: 0,
	}, nil
}

func (s *Server) SendFileChunk(stream grpc.ClientStreamingServer[kairospb.FileChunk, kairospb.TransferStatus]) error {
	var (
		transferID     string
		receivedChunks int32
	)
	for {
		chunk, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			return stream.SendAndClose(&kairospb.TransferStatus{
				TransferId:     transferID,
				Status:         "received",
				ReceivedChunks: receivedChunks,
			})
		}
		if err != nil {
			return err
		}
		transferID = chunk.GetTransferId()
		receivedChunks++
	}
}

func (s *Server) FetchQueue(req *kairospb.FetchRequest, stream grpc.ServerStreamingServer[kairospb.QueuedItem]) error {
	items, err := s.queue.ReadyForReceiver(stream.Context(), req.GetReceiverKair(), time.Now())
	if err != nil {
		return err
	}
	for _, item := range items {
		if err := stream.Send(&kairospb.QueuedItem{
			Id:               item.ID,
			Type:             "message",
			EncryptedPayload: item.Payload,
			Timestamp:        item.CreatedAt.UnixMilli(),
			RetryCount:       int32(item.RetryCount),
		}); err != nil {
			return err
		}
		if err := s.queue.MarkDelivered(stream.Context(), item.ID); err != nil {
			return err
		}
	}
	return nil
}

func (s *Server) GetContacts(ctx context.Context, _ *kairospb.Empty) (*kairospb.ContactList, error) {
	entries, err := s.contacts.List(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]*kairospb.Contact, 0, len(entries))
	for _, entry := range entries {
		result = append(result, &kairospb.Contact{
			Knumber:         entry.KNumber,
			DisplayName:     entry.DisplayName,
			RealPhone:       entry.RealPhone,
			Notes:           entry.Notes,
			TrustStatus:     entry.TrustStatus,
			LastInteraction: entry.LastInteraction,
			AvatarAscii:     entry.AvatarASCII,
		})
	}
	return &kairospb.ContactList{Contacts: result}, nil
}

func (s *Server) StoreAIMemory(ctx context.Context, entry *kairospb.MemoryEntry) (*kairospb.Empty, error) {
	err := s.memory.Store(ctx, memory.Entry{
		ID:         entry.GetId(),
		MemoryType: entry.GetMemoryType(),
		TargetID:   entry.GetTargetId(),
		Content:    entry.GetContent(),
		Importance: entry.GetImportance(),
		CreatedAt:  entry.GetCreatedAt(),
	})
	return &kairospb.Empty{}, err
}

func (s *Server) RetrieveAIMemory(ctx context.Context, req *kairospb.MemoryQuery) (*kairospb.MemoryEntry, error) {
	entry, err := s.memory.Retrieve(ctx, req.GetKey())
	if err != nil {
		return nil, err
	}
	return &kairospb.MemoryEntry{
		Id:         entry.ID,
		MemoryType: entry.MemoryType,
		TargetId:   entry.TargetID,
		Content:    entry.Content,
		Importance: entry.Importance,
		CreatedAt:  entry.CreatedAt,
	}, nil
}

func (s *Server) UpdateTrustScore(ctx context.Context, req *kairospb.TrustUpdate) (*kairospb.Empty, error) {
	err := s.trust.Update(ctx, req.GetKairNumber(), req.GetDelta())
	return &kairospb.Empty{}, err
}
