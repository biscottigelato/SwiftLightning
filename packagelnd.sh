if [ "$1" = "--clean" ]
then
  rm -f Gopkg.toml
  rm -f Gopkg.lock
  rm -Rdf vendor
  rm -Rdf ios/Lndmobile.framework

elif [ "$1" = "--init" ]
then
  # This just gets lnd into /vendor
  cp -v Gopkgtoml.base Gopkg.toml
  cp -v Gopkglock.base Gopkg.lock
  dep ensure -vendor-only

  # Get the mobile package to local
  mkdir mobile
  cp vendor/github.com/lightningnetwork/lnd/mobile/*.* ./mobile
  dep ensure

  gomobile bind -target=ios -o=ios/Lndmobile.framework github.com/biscottigelato/SwiftLightning/mobile

elif [ "$1" = "--bind" ]
then
  gomobile bind -target=ios -o=ios/Lndmobile.framework github.com/biscottigelato/SwiftLightning/mobile

else
  echo "Please specify --init, --bind, or --clean"
fi