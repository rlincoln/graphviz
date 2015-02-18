FROM rlincoln/ppapi_common

RUN naclports --toolchain=pnacl --arch=pnacl -v install cairo
RUN naclports --toolchain=pnacl --arch=pnacl -v install expat
RUN naclports --toolchain=pnacl --arch=pnacl -v install freetype
RUN naclports --toolchain=pnacl --arch=pnacl -v install fontconfig
RUN naclports --toolchain=pnacl --arch=pnacl -v install libpng
RUN naclports --toolchain=pnacl --arch=pnacl -v install zlib

ADD . /naclports/src/ports/graphviz

RUN naclports --toolchain=pnacl --arch=pnacl -v install graphviz

# git checkout cmd/gvpr/lib/Makefile configure macosx/build/graphviz.pmdoc/02graphviz.xml
