package identity

import "testing"

func TestValidateKairNumber(t *testing.T) {
	if !ValidateKairNumber("K-1234-5678") {
		t.Fatalf("expected valid K-number to pass validation")
	}
	if ValidateKairNumber("1234-5678") {
		t.Fatalf("expected malformed K-number to fail validation")
	}
}
