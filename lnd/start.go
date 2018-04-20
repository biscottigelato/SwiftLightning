package lnd

import (
	"os"
	"path/filepath"
	"strings"
)

// StartMain is the hook for updating the default configuration for non-terminal, library applications
func StartMain(appSupportDir string, arguments string) error {

	// Update all Default Directory locations
	defaultLndDir = filepath.Join(appSupportDir, "lnd")
	defaultConfigFile = filepath.Join(defaultLndDir, defaultConfigFilename)
	defaultDataDir = filepath.Join(defaultLndDir, defaultDataDirname)
	defaultLogDir = filepath.Join(defaultLndDir, defaultLogDirname)

	defaultTLSCertPath = filepath.Join(defaultLndDir, defaultTLSCertFilename)
	defaultTLSKeyPath = filepath.Join(defaultLndDir, defaultTLSKeyFilename)

	defaultAdminMacPath = filepath.Join(defaultLndDir, defaultAdminMacFilename)
	defaultReadMacPath = filepath.Join(defaultLndDir, defaultReadMacFilename)
	defaultInvoiceMacPath = filepath.Join(defaultLndDir, defaultInvoiceMacFilename)

	defaultBtcdDir = filepath.Join(appSupportDir, "btcd")
	defaultBtcdRPCCertFile = filepath.Join(defaultBtcdDir, "rpc.cert")

	defaultLtcdDir = filepath.Join(appSupportDir, "ltcd")
	defaultLtcdRPCCertFile = filepath.Join(defaultLtcdDir, "rpc.cert")

	defaultBitcoindDir = filepath.Join(appSupportDir, "bitcoin")
	defaultLitecoindDir = filepath.Join(appSupportDir, "litecoin")

	// Split programmatic arguments into an argument array
	argStringArray := strings.Split(arguments, " ")
	lndStringArray := []string{"lnd"}
	lndStringArray = append(lndStringArray, argStringArray...)

	// Override OS Arguments
	os.Args = lndStringArray

	// Head to 'main'.lndMain()
	return lndMain()
}
