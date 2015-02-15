FROM rlincoln/nacl_sdk

ADD . /naclports/src/ports/ppapi-common

RUN naclports --toolchain=pnacl --arch=pnacl -v install ppapi-common
