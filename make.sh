#!/bin/bash

cd "$( dirname "$0" )"

docker run -P -v $(pwd):/root -e OUTBASE=lib -w /root rlincoln/graphviz \
  make clean all TOOLCHAIN=pnacl CONFIG=Release
