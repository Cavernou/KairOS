package transport

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/kairos-project/kairos/node/internal/activation"
	"github.com/kairos-project/kairos/node/internal/contacts"
	"github.com/kairos-project/kairos/node/internal/crypto"
	"github.com/kairos-project/kairos/node/internal/db"
	"github.com/kairos-project/kairos/node/internal/identity"
	"github.com/kairos-project/kairos/node/internal/memory"
	"github.com/kairos-project/kairos/node/internal/queue"
	"github.com/kairos-project/kairos/node/internal/trust"
	kairospb "github.com/kairos-project/kairos/node/proto"
	"google.golang.org/grpc/metadata"
)

func TestSendMessageAndFetchQueue(t *testing.T) {
	store, err := db.Open(filepath.Join(t.TempDir(), "transport.db"))
	if err != nil {
		t.Fatalf("Open returned error: %v", err)
	}
	defer store.Close()

	if err := store.Migrate(); err != nil {
		t.Fatalf("Migrate returned error: %v", err)
	}

	server := NewServer(
		identity.NewService(store),
		activation.NewService(store, 3600),
		queue.NewService(store, 100, 168),
		crypto.NewService(),
		contacts.NewService(store),
		trust.NewService(store),
		memory.NewService(store),
	)

	_, err = server.SendMessage(context.Background(), &kairospb.MessagePacket{
		Id:               "msg-1",
		Type:             "message",
		SenderKair:       "K-1111-1111",
		ReceiverKair:     "K-2222-2222",
		EncryptedPayload: []byte("ciphertext"),
	})
	if err != nil {
		t.Fatalf("SendMessage returned error: %v", err)
	}

	stream := &fetchQueueTestStream{ctx: context.Background()}
	err = server.FetchQueue(&kairospb.FetchRequest{ReceiverKair: "K-2222-2222"}, stream)
	if err != nil {
		t.Fatalf("FetchQueue returned error: %v", err)
	}
	if len(stream.items) != 1 {
		t.Fatalf("expected 1 queued item, got %d", len(stream.items))
	}
}

type fetchQueueTestStream struct {
	ctx   context.Context
	items []*kairospb.QueuedItem
}

func (s *fetchQueueTestStream) Send(item *kairospb.QueuedItem) error {
	s.items = append(s.items, item)
	return nil
}

func (s *fetchQueueTestStream) SetHeader(metadata.MD) error { return nil }
func (s *fetchQueueTestStream) SendHeader(metadata.MD) error { return nil }
func (s *fetchQueueTestStream) SetTrailer(metadata.MD)       {}
func (s *fetchQueueTestStream) Context() context.Context     { return s.ctx }
func (s *fetchQueueTestStream) SendMsg(any) error            { return nil }
func (s *fetchQueueTestStream) RecvMsg(any) error            { return nil }
