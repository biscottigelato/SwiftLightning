dep ensure

# cp -v $GOPATH/pkg/dep/sources/https---github.com-lightningnetwork-lnd/*.go ./lnd
cp -v vendor/github.com/lightningnetwork/lnd/*.go ./lnd

gsed -i 's/package main/package lnd/g' lnd/*.go

gomobile bind -target=ios -o=ios/Lightningd.framework github.com/biscottigelato/SwiftLightning/gomobile