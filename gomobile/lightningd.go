package lightningd

import (
	"fmt"

	"github.com/biscottigelato/SwiftLightning/lnd"
)

// StartLND is the function to start the LN Daemon
func StartLND(appDataDir string, arguments string) {
	err := lnd.StartMain(appDataDir, arguments)

	if err != nil {
		fmt.Printf("lndMain error - %v", err)
	}
}
