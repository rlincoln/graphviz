FROM rlincoln/nacl-sdk:pepper_38

ADD . /naclports/src/ports/ppapi-common

RUN naclports --toolchain=pnacl --arch=pnacl -v install ppapi-common
