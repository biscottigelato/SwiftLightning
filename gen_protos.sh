#!/bin/sh

rm -Rdf ios/SwiftLightning/grpc
mkdir ios/SwiftLightning/grpc

# Generate the protos.
protoc -I/usr/local/include -I. \
       -I$GOPATH/src \
       -I$GOPATH/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
       --swift_out=ios/SwiftLightning/grpc \
       vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.proto