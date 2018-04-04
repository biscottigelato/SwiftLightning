package lightningd

import (
	"github.com/biscottigelato/SwiftLightning/lnd"
)

// StartDaemon - Start the LND Daemon
func StartDaemon(appDataDir string) {
	lnd.UpdateDefaultCfg(appDataDir)
	lnd.Main()
}
