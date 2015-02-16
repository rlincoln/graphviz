#!/bin/sh

export CHROME_PATH=$DART_SDK_ROOT/chromium/chrome

$CHROME_PATH --user-data-dir=/home/rwl/.dartium \
  --enable-experimental-web-platform-features --enable-html-imports \
  --no-first-run --no-default-browser-check --no-process-singleton-dialog \
  --flag-switches-begin --enable-nacl --flag-switches-end chrome://version/

