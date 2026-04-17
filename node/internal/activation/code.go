package activation

import (
	"crypto/rand"
	"fmt"
	"math/big"
)

func GenerateAdminCode() (string, error) {
	max := big.NewInt(10000)
	value, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%04d", value.Int64()), nil
}
