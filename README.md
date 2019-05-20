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

A LND branch with support for direct functional bindings is required to build SwiftLighting. An example of that can be found at https://github.com/biscottigelato/lnd/tree/mobile-tip. Assuming that the Go toolchain is properly installed, here is an example of how one can checkout this particular branch.

First, use 'go get' to retrieve master of LND
```
$ go get -d github.com/lightningnetwork/lnd
```
Under your $GOPATH where lnd was retrieved, you can change the remote to point to a particular branch by
```
$ git remote add biscottigelato https://github.com/biscottigelato/lnd
```
Finally, fetch & checkout the mobile support branch
```
$ git fetch biscottigelato
$ git checkout -b mobile-tip biscottigelato/mobile-tip
```
You should be able to generate Lndmobile.framework with mobile support branch by just executing
```
$ ./lnd/mobile/dep ensure
$ ./lnd/mobile/build_mobile.sh
```
Lndmobile.framework should then be found under /lnd/mobile/build/ios/. Please see the [LND Github page](https://github.com/lightningnetwork/lnd) for other details regarding LND. Once Lndmobile.framework is generated, copy it to /SwiftLightning/ios/Lndmobile.framework.

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
