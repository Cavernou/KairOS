package crypto

import "testing"

func TestEncryptDecryptRoundTrip(t *testing.T) {
	service := NewService()
	key, err := service.GenerateSessionKey()
	if err != nil {
		t.Fatalf("GenerateSessionKey returned error: %v", err)
	}

	nonce, ciphertext, err := service.Encrypt(key, []byte("kairos"))
	if err != nil {
		t.Fatalf("Encrypt returned error: %v", err)
	}

	plaintext, err := service.Decrypt(key, nonce, ciphertext)
	if err != nil {
		t.Fatalf("Decrypt returned error: %v", err)
	}

	if string(plaintext) != "kairos" {
		t.Fatalf("expected round-trip plaintext, got %q", string(plaintext))
	}
}
