#!/bin/sh

# Clean-up the grpc folder
rm -Rdf ios/SwiftLightning/grpc
mkdir ios/SwiftLightning/grpc

# Generate the protos.
protoc -I/usr/local/include -I. \
       -I$GOPATH/src \
       -I$GOPATH/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
       --swift_out=ios/Protobuf \
       vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.proto

# Find all files and flatten the directory structure
find ios/Protobuf -type f -exec cp {} ios/Protobuf \;
rm -Rdf ios/Protobuf/vendor