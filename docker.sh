#!/bin/sh

cd "$( dirname "$0" )"

# Run in privileged mode and change /dev/shm exec mount option.
docker run -v $(pwd):/naclports/src/ports/graphviz \
  --privileged -t rlincoln/ppapi_common sh -c \
  "mount -o remount,exec /dev/shm && \
  naclports --toolchain=pnacl --arch=pnacl -v install graphviz"

docker commit $(docker ps -l -q) graphviz
