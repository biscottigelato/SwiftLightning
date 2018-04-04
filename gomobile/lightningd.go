package lightningd

import (
	"fmt"

	"github.com/biscottigelato/SwiftLightning/lnd"
)

// StartLND is the function to start the LN Daemon
func StartLND(appDataDir string, argv string) {
	err := lnd.StartMain(appDataDir, argv)

	if err != nil {
		fmt.Printf("lndMain error - %v", err)
	}
}
