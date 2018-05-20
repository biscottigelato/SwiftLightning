<img src="https://www.swiftlightning.io/img/SwiftLightningProject.png" alt="Swift Lightning Project Logo">

# SwiftLightning

**A Lightning Network light wallet implementation on native iOS using Swift**

[SwiftLightning](https://swiftlightning.io) is a work-in-progress codename for a [Lightning Network](https://lightning.network) light wallet implementation based on the open sourced [LND - Lightning Network Daemon](https://github.com/lightningnetwork/lnd). This project is written in native Swift for iOS. By being an early implementation of a mobile Lighting wallet, it is hoped that SwiftLightning can act as a test harness to help accelerate LND's features and reliability for iOS.

# Getting Started

## Building LND

A LND branch with support for direct functional bindings is required to build SwiftLighting. An example of that can be found at https://github.com/halseth/lnd/tree/mobile-test-5. You should be able to generate Lndmobile.framework with mobile-test-5 branch by running
```
$ ./lnd/mobile/build_mobile.sh
```
Lndmobile.framework should then be found under /lnd/mobile/build/ios/. Please see the instruction in the [LND Github page](https://github.com/lightningnetwork/lnd) for further details. Once Lndmobile.framework is generated, copy it to /SwiftLightning/ios/Lndmobile.framework.

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

If there is change to the LND .proto files, you might need to regenerate the Swift proto bindings.

Install Go Lang from https://golang.org/

Install Swift Protobuf
```
$ brew install swift-protobuf
```

Install Swift GRPC. The following sometimes doesn't work. So follow the instructions on the Swift GRPC Github for the most accurate instructions
```
$ git clone https://www.github.com/grpc/grpc-swift
make install
```

You will need to have LND in your GOPATH for this script to work
```
$ ./gen_protos.sh
```