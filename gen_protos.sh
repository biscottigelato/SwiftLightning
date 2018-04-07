#!/bin/sh

# Clean-up the grpc folder
rm -Rdf ios/Protobuf
mkdir ios/Protobuf

# Generate the protos.
protoc -I/usr/local/include -I. \
       -I$GOPATH/src \
       -I$GOPATH/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
       --swift_out=ios/Protobuf \
       --swiftgrpc_out=ios/Protobuf \
       vendor/github.com/lightningnetwork/lnd/lnrpc/rpc.proto

# Find all files and flatten the directory structure
find ios/Protobuf -type f -exec cp {} ios/Protobuf \;
rm -Rdf ios/Protobuf/vendor