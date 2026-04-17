package activation

import "testing"

func TestGenerateAdminCode(t *testing.T) {
	code, err := GenerateAdminCode()
	if err != nil {
		t.Fatalf("GenerateAdminCode returned error: %v", err)
	}
	if len(code) != 4 {
		t.Fatalf("expected 4-digit code, got %q", code)
	}
}
