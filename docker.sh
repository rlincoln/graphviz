#!/bin/sh

cd "$( dirname "$0" )"

# Cache dependencies and graphviz tarball.
docker build -t graphviz_deps .

# Run in privileged mode and change /dev/shm exec mount option.
docker run -v $(pwd):/naclports/src/ports/graphviz \
  --privileged -t graphviz_deps sh -c \
  "mount -o remount,exec /dev/shm && \
  naclports --toolchain=pnacl --arch=pnacl -v install graphviz"

docker commit $(docker ps -l -q) rlincoln/graphviz
