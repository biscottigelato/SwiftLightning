# SwiftLightning

**A Lightning Network light wallet implementation on native iOS using Swift**

SwiftLightning is a work-in-progress codename for a Lightning Network light wallet implementation. This project is meant to focus on a native Swift implemenation focused on iOS, but potentially also for native Mac OSX in the future.

# Getting Started

## Tools & Libraries

Install Go Lang from https://golang.org/

Install Go Dep
```
$ brew install dep
```

Get gomobile
```
$ go get golang.org/x/mobile/cmd/gomobile
$ gomobile init # it might take a few minutes
```

Get GSED
```
$ brew install gnu-sed
```

Install Swift Protobuf
```
$ brew install swift-protobuf
```

Install Swift GRPC. The following sometimes doesn't work. So follow the instructions on the Swift GRPC Github for the most accurate instructions
```
$ git clone https://www.github.com/grpc/grpc-swift
make install
```

## Build & Install

Get Swift Lightning
```
$ go get github.com/biscottigelato/SwiftLightning
```

Package LND Framework
```
$ ./packagelnd.sh
```

Convert rpc.proto to Swift
```
$ ./gen_protos.sh
```

Install all Cocoapod dependencies
```
$ cd ios
$ pod install
```

Finall, Start Xcode!
```
$ xcode ios/SwiftLightning.xcworkspace
```