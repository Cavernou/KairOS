package sound

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"runtime"
)

type Manager struct {
	soundDir string
	enabled bool
}

func NewManager(soundDir string) *Manager {
	return &Manager{
		soundDir: soundDir,
		enabled:  true,
	}
}

func (m *Manager) Play(soundName string) error {
	if !m.enabled {
		return nil
	}

	soundPath := filepath.Join(m.soundDir, soundName)
	
	switch runtime.GOOS {
	case "darwin":
		return m.playDarwin(soundPath)
	case "linux":
		return m.playLinux(soundPath)
	default:
		return fmt.Errorf("unsupported platform: %s", runtime.GOOS)
	}
}

func (m *Manager) playDarwin(soundPath string) error {
	cmd := exec.Command("afplay", soundPath)
	return cmd.Run()
}

func (m *Manager) playLinux(soundPath string) error {
	cmd := exec.Command("aplay", soundPath)
	return cmd.Run()
}

func (m *Manager) SetEnabled(enabled bool) {
	m.enabled = enabled
}

func (m *Manager) IsEnabled() bool {
	return m.enabled
}
