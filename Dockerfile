FROM rlincoln/ppapi_common

ADD . /naclports/src/ports/graphviz

RUN naclports --toolchain=pnacl --arch=pnacl -v install graphviz
