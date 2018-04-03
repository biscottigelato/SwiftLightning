if [ "$1" = "--clean" ]
then
  rm -f Gopkg.toml
  rm -f Gopkg.lock
  rm -Rdf vendor
  rm -Rdf ios/Lightningd.framework

  mv lnd/daemon.go lnd/daemon.bak
  rm -f lnd/*.go
  mv lnd/daemon.bak lnd/daemon.go
  
elif [ "$1" = "--init" ]
then
  # This just gets lnd into /vendor
  cp -v Gopkg.base Gopkg.toml
  dep ensure

  # This makes a copy of lnd main package files along with it's Gopkg.toml
  cp -v vendor/github.com/lightningnetwork/lnd/*.go ./lnd
  cp -v -f vendor/github.com/lightningnetwork/lnd/Gopkg.toml Gopkg.toml
  dep ensure

  gsed -i 's/package main/package lnd/g' lnd/*.go

  gomobile bind -target=ios -o=ios/Lightningd.framework github.com/biscottigelato/SwiftLightning/gomobile

elif [ "$1" = "--bind" ]
then
  gomobile bind -target=ios -o=ios/Lightningd.framework github.com/biscottigelato/SwiftLightning/gomobile

else
  echo "Please specify --init, --bind, or --clean"
fi