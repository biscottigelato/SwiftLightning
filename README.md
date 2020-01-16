<img src="https://www.swiftlightning.io/img/SwiftLightningProject.png" alt="Swift Lightning Project Logo">

# SwiftLightning

**A Lightning Network light wallet implementation on native iOS using Swift**

[SwiftLightning](https://swiftlightning.io) is a work-in-progress codename for a [Lightning Network](https://lightning.network) light wallet implementation based on the open sourced [LND - Lightning Network Daemon](https://github.com/lightningnetwork/lnd). This project is written in native Swift for iOS. By being an early implementation of a mobile Lighting wallet, it is hoped that SwiftLightning can act as a test harness to help accelerate LND's features and reliability for iOS.

# Getting Started

## Tools & Pre-requisites

The Go (lang) toolchain, including Go Dep and Gomobile, along with the Google Protocol Buffer Compiler are required. This is in addition to of course the Xcode toolchain on MacOS. You can get these tools respectively at

Go from https://golang.org/

Go Dep from https://github.com/golang/dep

Gomobile from https://github.com/golang/go/wiki/Mobile

Protoc from https://github.com/google/protobuf

## Building LND with mobile support

https://blog.lightning.engineering/posts/2019/11/21/mobile-lnd.html


## Build & Install

Make sure Lndmobile.framework is placed under /SwiftLightning/ios/

Install all Cocoapod dependencies
```
$ cd ios
$ pod install
```

Start Xcode!
```
$ xcode ios/SwiftLightning.xcworkspace
```

## Reconverting LND .proto files into Swift

If there are changes to the LND .proto files, you might need to regenerate the Swift proto bindings.

Install Swift Protobuf
```
$ brew install swift-protobuf
```

Install Swift GRPC. The following sometimes doesn't work. So follow the instructions on the Swift GRPC Github for the most accurate instructions
```
$ git clone https://www.github.com/grpc/grpc-swift
$ git checkout tags/0.4.0
make install
```

You will need to have LND in your GOPATH for this script to work
```
$ ./gen_protos.sh
```
