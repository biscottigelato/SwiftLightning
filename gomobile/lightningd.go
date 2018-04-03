package lightningd

import (
	"log"

	"github.com/biscottigelato/SwiftLightning/lnd"
)

// HelloWorld - Sanity Hello World Function
func HelloWorld() {
	log.Printf("Hello World")
}

// StartDaemon - Start the LND Daemon
func StartDaemon() {
	lnd.LndMain()
}
