
ConfigureStep() {
  echo "CONFIGURE"
  cd ${SRC_DIR}
  #echo "PWD: ${PWD}"
#  ls -al

  #printenv

  export PETSC_DIR=${SRC_DIR}

  # pnacl arch variables
  if [ "${NACL_ARCH}" = "pnacl" ]; then
    export NACL_TRANSLATOR=${TRANSLATOR}
    export PNACL_FINALIZE=${PNACLFINALIZE}
    export HOST_ARCH=x86_64
  fi

  echo "CC=${NACLCC}"
  echo "CFLAGS=${NACLPORTS_CFLAGS}"
  echo "CXX=${NACLCXX}"
  echo "CXXFLAGS=${NACLPORTS_CXXFLAGS}"
  echo "CPPFLAGS=${NACLPORTS_CPPFLAGS}"
  echo "LDFLAGS=${NACLPORTS_LDFLAGS}"
  echo "AR=${NACLAR}"

  #echo "PREFIX=${PREFIX}"

  #export EXTRA_CONFIGURE_ARGS="--with-mpi=0 CC=${NACLCC} CFLAGS=\"${NACLPORTS_CFLAGS}\" CXX=${NACLCXX} CXXFLAGS=\"${NACLPORTS_CXXFLAGS}\" CPPFLAGS=\"${NACLPORTS_CPPFLAGS}\" LDFLAGS=\"${NACLPORTS_LDFLAGS}\" AR=${NACLAR}"
  #export EXTRA_CONFIGURE_ARGS=--with-mpi=0 LDFLAGS="1 3"
  #export EXTRA_CONFIGURE_ARGS="--with-mpi=0 CC=${NACLCC} CFLAGS=\"${NACLPORTS_CFLAGS}\" CXX=${NACLCXX} CXXFLAGS=\"${NACLPORTS_CXXFLAGS}\" CPPFLAGS=\"${NACLPORTS_CPPFLAGS}\"  AR=${NACLAR}"
  #echo "  LDFLAGS: \"${NACLPORTS_LDFLAGS}\""
  #echo "  ARGS: ${EXTRA_CONFIGURE_ARGS:-}"
  #export EXTRA_CONFIGURE_ARGS="--with-mpi=0"
#  DefaultConfigureStep


  #conf_build=$(/bin/sh "${SCRIPT_DIR}/config.guess")

  SetupCrossEnvironment

  #CFLAGS+=" -std=gnu++11 -stdlib=libc++"
  #CFLAGS+=" -std=c++11"
  #echo "CFLAGS=${CFLAGS}"

  #./configure --with-mpi=0 CC=${NACLCC} CFLAGS="${NACLPORTS_CFLAGS}" CXX=${NACLCXX} CXXFLAGS="${NACLPORTS_CXXFLAGS}" CPPFLAGS="${NACLPORTS_CPPFLAGS}" LDFLAGS="${NACLPORTS_LDFLAGS}" AR=${NACLAR}
#  ./configure --with-mpi=0 --CC=${CC} --CFLAGS="${CFLAGS}" --CXX=${CXX} --CXXFLAGS="${CXXFLAGS}" --CPPFLAGS="${CPPFLAGS}" --LDFLAGS="${LDFLAGS}" --AR=${AR}
  #./configure --with-mpi=0 --download-f2cblaslapack=1 --with-cc=${CC} --CFLAGS="${CFLAGS}" --with-cxx=${CXX} --CXXFLAGS="${CXXFLAGS}" --CPPFLAGS="${CPPFLAGS}" --LDFLAGS="${LDFLAGS}" --with-ar=${AR}
  #./configure --prefix=/usr --with-mpi=0 --with-blas-lapack-dir=/tmp/pnaclblas --with-cc=${CC} --CFLAGS="${CFLAGS}" --with-cxx=${CXX} --CXXFLAGS="${CXXFLAGS}" --CPPFLAGS="${CPPFLAGS}" --LDFLAGS="${LDFLAGS}" --with-ar=${AR}
  ./configure --with-fc=0 --prefix=/usr --with-mpi=0 --with-blas-lapack-dir=${NACLPORTS_LIBDIR} --with-cc=${CC} --CFLAGS="${CFLAGS}" --with-cxx=${CXX} --CXXFLAGS="${CXXFLAGS}" --CPPFLAGS="${CPPFLAGS}" --LDFLAGS="${LDFLAGS}" --with-ar=${AR}

#--with-blas-lapack-lib=[/tmp/liblapack.a,/tmp/libblas.a]
#--with-shared-libraries=1

  # --with-blas-lapack-dir=
  # --with-fortran=0

  #./configure --with-mpi=0 LDFLAGS="1 3"

  #local CONFIGURE=${NACL_CONFIGURE_PATH:-${SRC_DIR}/configure}

#  LogExecute "${CONFIGURE}" \
#    --build=${conf_build} \
#    --host=${conf_host} \
#    --prefix=${PREFIX} \
#    --with-http=no \
#    --with-html=no \
#    --with-ftp=no \
#    --${NACL_OPTION}-mmx \
#    --${NACL_OPTION}-sse \
#    --${NACL_OPTION}-sse2 \
#    --${NACL_OPTION}-asm \
#    --with-x=no \
#    ${EXTRA_CONFIGURE_ARGS:-}
}

BuildStep() {
  echo "BUILD"
  cd ${SRC_DIR}
  #DefaultBuildStep
  if [ "${VERBOSE:-}" = "1" ]; then
    MAKE_TARGETS+=" VERBOSE=1 V=1"
  fi
  LogExecute make PETSC_DIR=${SRC_DIR} PETSC_ARCH=arch-linux2-c-debug all
}

TestStep() {
  cd ${SRC_DIR}
  #make PETSC_DIR=${SRC_DIR} PETSC_ARCH=arch-linux2-c-debug test
}

InstallStep() {
  echo "INSTALL"
  cp ${SRC_DIR}/include/mpiuni/mpi.h ${SRC_DIR}/include/mpi.h

  cd ${SRC_DIR}
  DESTDIR=${DESTDIR}/${PREFIX}
  #DESTDIR_PETSC=${DESTDIR}/${PREFIX}/petsc
  DefaultInstallStep
}
