package config

import (
	"errors"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

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
	return Config{
		Tailnet:            "kairos.ts.net",
		ListenAddr:         "0.0.0.0:8080",
		TailscaleEnabled:   true, // Will auto-detect
		TailscaleAddr:      "",   // Will auto-detect
		MockHTTPEnabled:    true,
		MockHTTPListenAddr: "0.0.0.0:8081",
		DBPath:             "./var/kairos-node.db",
		MasterKeyPath:      "./var/node-master.key",
		AdminCodeInterval:  3600,
		QueueRetryLimit:    100,
		QueueTTLHours:      168,
		APNSEnabled:        false,
	}
}

func Load(path string) (Config, error) {
	cfg := Default()
	if path == "" {
		if err := ensureParent(cfg.DBPath); err != nil {
			return Config{}, err
		}
		// Auto-detect configuration
		cfg = autoDetectConfig(cfg)
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

	// Auto-detect configuration if not specified
	cfg = autoDetectConfig(cfg)

	return cfg, nil
}

func autoDetectConfig(cfg Config) Config {
	// Auto-detect Tailscale if enabled
	if cfg.TailscaleEnabled {
		if tailscaleIP := detectTailscaleIP(); tailscaleIP != "" {
			cfg.TailscaleAddr = tailscaleIP + ":8080"
			cfg.TailscaleEnabled = true
		} else {
			cfg.TailscaleEnabled = false
		}
	}

	// Auto-detect local IP if needed
	if strings.Contains(cfg.ListenAddr, "0.0.0.0") {
		if localIP := detectLocalIP(); localIP != "" {
			cfg.ListenAddr = localIP + ":8080"
		}
	}

	return cfg
}

func detectTailscaleIP() string {
	// Try to get Tailscale IP using tailscale status command
	cmd := exec.Command("tailscale", "status", "--json")
	output, err := cmd.Output()
	if err != nil {
		return ""
	}

	// Parse JSON to find Tailscale IP
	if strings.Contains(string(output), "\"TailscaleIPs\"") {
		// Simple extraction - in production use proper JSON parsing
		lines := strings.Split(string(output), "\n")
		for _, line := range lines {
			if strings.Contains(line, "\"TailscaleIPs\"") {
				// Extract IP from the line
				parts := strings.Split(line, "\"")
				for _, part := range parts {
					if strings.Contains(part, "100.") || strings.Contains(part, "fd7a:") {
						return strings.Trim(part, "[]\",")
					}
				}
			}
		}
	}

	// Fallback: check common Tailscale IP ranges
	interfaces, err := net.Interfaces()
	if err != nil {
		return ""
	}

	for _, iface := range interfaces {
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}

			if ip != nil && ip.IsPrivate() {
				ipStr := ip.String()
				if strings.HasPrefix(ipStr, "100.") || strings.HasPrefix(ipStr, "fd7a:") {
					return ipStr
				}
			}
		}
	}

	return ""
}

func detectLocalIP() string {
	interfaces, err := net.Interfaces()
	if err != nil {
		return ""
	}

	for _, iface := range interfaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}

			if ip != nil && ip.IsPrivate() && ip.To4() != nil {
				return ip.String()
			}
		}
	}

	return ""
}

func ensureParent(path string) error {
	parent := filepath.Dir(path)
	if parent == "." || parent == "/" {
		return nil
	}
	return os.MkdirAll(parent, 0o755)
}
