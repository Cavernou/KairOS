package main

import (
	"context"
	"flag"
	"log"
	"net"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"github.com/kairos-project/kairos/node/internal/activation"
	"github.com/kairos-project/kairos/node/internal/config"
	"github.com/kairos-project/kairos/node/internal/contacts"
	"github.com/kairos-project/kairos/node/internal/crypto"
	"github.com/kairos-project/kairos/node/internal/db"
	"github.com/kairos-project/kairos/node/internal/identity"
	"github.com/kairos-project/kairos/node/internal/memory"
	"github.com/kairos-project/kairos/node/internal/mockapi"
	"github.com/kairos-project/kairos/node/internal/queue"
	"github.com/kairos-project/kairos/node/internal/transport"
	"github.com/kairos-project/kairos/node/internal/trust"
	"google.golang.org/grpc"
)

func main() {
	configPath := flag.String("config", "", "Path to node config YAML")
	flag.Parse()

	cfg, err := config.Load(*configPath)
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	store, err := db.Open(cfg.DBPath)
	if err != nil {
		log.Fatalf("open db: %v", err)
	}
	defer store.Close()

	if err := store.Migrate(); err != nil {
		log.Fatalf("migrate db: %v", err)
	}

	identityService := identity.NewService(store)
	activationService := activation.NewService(store, cfg.AdminCodeInterval)
	queueService := queue.NewService(store, cfg.QueueRetryLimit, cfg.QueueTTLHours)
	cryptoService := crypto.NewService()
	contactService := contacts.NewService(store)
	trustService := trust.NewService(store)
	memoryService := memory.NewService(store)
	if err := mockapi.SeedDefaults(context.Background(), contactService); err != nil {
		log.Fatalf("seed contacts: %v", err)
	}

	server := transport.NewServer(
		identityService,
		activationService,
		queueService,
		cryptoService,
		contactService,
		trustService,
		memoryService,
	)

	lis, err := net.Listen("tcp", cfg.ListenAddr)
	if err != nil {
		log.Fatalf("listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	server.RegisterGRPC(grpcServer)

	log.Printf("kairos-node configured for %s on %s", cfg.Tailnet, cfg.ListenAddr)

	var mockHTTPServer *http.Server
	if cfg.MockHTTPEnabled {
		soundDir := "./sounds"
		mockGateway := mockapi.NewServer(
			cfg.Tailnet,
			cfg.TailscaleEnabled,
			identityService,
			activationService,
			queueService,
			cryptoService,
			contactService,
			trustService,
			memoryService,
			soundDir,
		)
		mockHTTPServer = &http.Server{
			Addr:    cfg.MockHTTPListenAddr,
			Handler: mockGateway.Handler(),
		}

		go func() {
			log.Printf("kairos-node mock http gateway listening on %s", cfg.MockHTTPListenAddr)
			if err := mockHTTPServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
				log.Printf("mock http server stopped: %v", err)
			}
		}()
	}

	go func() {
		if err := grpcServer.Serve(lis); err != nil {
			log.Printf("grpc server stopped: %v", err)
		}
	}()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	<-ctx.Done()
	grpcServer.GracefulStop()
	if mockHTTPServer != nil {
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := mockHTTPServer.Shutdown(shutdownCtx); err != nil {
			log.Printf("mock http shutdown: %v", err)
		}
	}
	log.Printf("kairos-node shutting down cleanly")
}
