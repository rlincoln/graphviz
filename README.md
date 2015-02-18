# Graphviz NaCl Module

This package consists of:

 - a [naclport][naclports] of [Graphviz][graphviz],
 - a [NaCl][nacl] module based on [ppapi_common][] and
 - a Graphviz [polymer.dart][] web component

## naclports

Build a [PNaCl][pnacl] Graphviz library using naclports and add it to the
NaCl SDK:

    naclports --toolchain=pnacl --arch=pnacl -v install ./

Alternatively, use [Docker][docker] to provide the dependencies:

    docker build -t graphviz .

## NaCl module

Build the Graphviz NaCl module in a container:

    docker run -P -v $(pwd):/root -e OUTBASE=lib -w /root graphviz make

## Polymer.dart web component

The [example][./example] directory contains a demo of the Graphviz polymer.dart
web component.

[naclports]: https://code.google.com/p/naclports/
[graphviz]: http://www.graphviz.org/
[nacl]: https://developer.chrome.com/native-client
[ppapi_common]: https://pub.dartlang.org/packages/ppapi_common
[polymer.dart]: https://www.dartlang.org/polymer/
[pnacl]: https://developer.chrome.com/native-client/nacl-and-pnacl
[docker]: https://www.docker.com/
