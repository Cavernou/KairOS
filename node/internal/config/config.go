package config

import (
	"errors"
	"os"
	"path/filepath"
	"runtime"

	"gopkg.in/yaml.v3"
)

type Config struct {
	Tailnet            string `yaml:"tailnet"`
	ListenAddr         string `yaml:"listen_addr"`
	TailscaleEnabled   bool   `yaml:"tailscale_enabled"`
	TailscaleAddr      string `yaml:"tailscale_addr"`
	MockHTTPEnabled    bool   `yaml:"mock_http_enabled"`
	MockHTTPListenAddr string `yaml:"mock_http_listen_addr"`
	DBPath             string `yaml:"db_path"`
	MasterKeyPath      string `yaml:"master_key_path"`
	AdminCodeInterval  int    `yaml:"admin_code_interval"`
	QueueRetryLimit    int    `yaml:"queue_retry_limit"`
	QueueTTLHours      int    `yaml:"queue_ttl_hours"`
	APNSEnabled        bool   `yaml:"apns_enabled"`
}

func Default() Config {
	if runtime.GOOS == "linux" {
		return Config{
			Tailnet:            "kairos.ts.net",
			ListenAddr:         ":8080",
			TailscaleEnabled:   false,
			TailscaleAddr:      "",
			MockHTTPEnabled:    false,
			MockHTTPListenAddr: ":8081",
			DBPath:             "/var/lib/kairos/node.db",
			MasterKeyPath:      "/var/lib/kairos/node-master.key",
			AdminCodeInterval:  3600,
			QueueRetryLimit:    100,
			QueueTTLHours:      168,
			APNSEnabled:        false,
		}
	} else {
		return Config{
			Tailnet:            "kairos.ts.net",
			ListenAddr:         ":8080",
			TailscaleEnabled:   false,
			TailscaleAddr:      "",
			MockHTTPEnabled:    true,
			MockHTTPListenAddr: ":8081",
			DBPath:             "./var/kairos-node.db",
			MasterKeyPath:      "./var/node-master.key",
			AdminCodeInterval:  3600,
			QueueRetryLimit:    100,
			QueueTTLHours:      168,
			APNSEnabled:        false,
		}
	}
}

func Load(path string) (Config, error) {
	cfg := Default()
	if path == "" {
		if err := ensureParent(cfg.DBPath); err != nil {
			return Config{}, err
		}
		return cfg, nil
	}

	raw, err := os.ReadFile(path)
	if err != nil {
		return Config{}, err
	}

	if err := yaml.Unmarshal(raw, &cfg); err != nil {
		return Config{}, err
	}

	if cfg.ListenAddr == "" || cfg.DBPath == "" || cfg.Tailnet == "" {
		return Config{}, errors.New("tailnet, listen_addr, and db_path are required")
	}

	if err := ensureParent(cfg.DBPath); err != nil {
		return Config{}, err
	}

	return cfg, nil
}

func ensureParent(path string) error {
	parent := filepath.Dir(path)
	if parent == "." || parent == "/" {
		return nil
	}
	return os.MkdirAll(parent, 0o755)
}
