#!/bin/sh

docker run -P -v $(pwd):/root -e OUTBASE=. -w /root rlincoln/ppapi_common \
  make clean all TOOLCHAIN=pnacl CONFIG=Release

