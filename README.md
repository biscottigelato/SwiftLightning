SwiftLightning

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

Install Swift Protobuf
```
$ brew install swift-protobuf
```

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

Run SwiftLightning.xcworkspace