package lnd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// StartMain is the hook for updating the default configuration for
// non-terminal, library applications
func StartMain(appDataDir string, argv string) error {

	// Update all Default Directory locations
	defaultLndDir = filepath.Join(appDataDir, "lnd")
	defaultConfigFile = filepath.Join(defaultLndDir, defaultConfigFilename)
	defaultDataDir = filepath.Join(defaultLndDir, defaultDataDirname)
	defaultLogDir = filepath.Join(defaultLndDir, defaultLogDirname)

	defaultTLSCertPath = filepath.Join(defaultLndDir, defaultTLSCertFilename)
	defaultTLSKeyPath = filepath.Join(defaultLndDir, defaultTLSKeyFilename)

	defaultAdminMacPath = filepath.Join(defaultLndDir, defaultAdminMacFilename)
	defaultReadMacPath = filepath.Join(defaultLndDir, defaultReadMacFilename)
	defaultInvoiceMacPath = filepath.Join(defaultLndDir, defaultInvoiceMacFilename)

	defaultBtcdDir = filepath.Join(appDataDir, "btcd")
	defaultBtcdRPCCertFile = filepath.Join(defaultBtcdDir, "rpc.cert")

	defaultLtcdDir = filepath.Join(appDataDir, "ltcd")
	defaultLtcdRPCCertFile = filepath.Join(defaultLtcdDir, "rpc.cert")

	defaultBitcoindDir = filepath.Join(appDataDir, "bitcoin")
	defaultLitecoindDir = filepath.Join(appDataDir, "litecoin")

	// Split programmatic arguments into an argument array
	argStringArray := strings.Split(argv, " ")
	lndStringArray := []string{"lnd"}
	lndStringArray = append(lndStringArray, argStringArray...)
	os.Args = lndStringArray

	for index, argument := range os.Args {
		fmt.Printf("OS Arg %d: %v\n", index, argument)
	}

	return lndMain()
}
