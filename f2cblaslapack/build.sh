
ConfigureStep() {
  cd ${SRC_DIR}
  #DefaultConfigureStep
}

BuildStep() {
  SetupCrossEnvironment

  export CC=${CC}
  export COPTFLAGS=-O
  export CNOOPT=-O0
  export AR_FLAGS=cr
  export LIB_SUFFIX=a

  export MAKE_OPTIONS=CC="${CC}" COPTFLAGS="${COPTFLAGS}" CNOOPT="${CNOOPT}" AR="${AR}" AR_FLAGS="${AR_FLAGS}" RM="/bin/rm"

  export BLAS_LIB_NAME=libf2cblas.${LIB_SUFFIX}
  export MAKE_OPTIONS_BLAS=${MAKE_OPTIONS} LIBNAME="${BLAS_LIB_NAME}"

  cd ${SRC_DIR}/blas
  make lib ${MAKE_OPTIONS_BLAS}
  ${RANLIB} ../${BLAS_LIB_NAME}

  export LAPACK_LIB_NAME=libf2clapack.${LIB_SUFFIX}
  export MAKE_OPTIONS_LAPACK=${MAKE_OPTIONS} LIBNAME="${LAPACK_LIB_NAME}"

  cd ${SRC_DIR}/lapack
  make lib ${MAKE_OPTIONS_LAPACK}
  ${RANLIB} ../${LAPACK_LIB_NAME}
}

TestStep() {
  echo "test"
  #DefaultTestStep
}

InstallStep() {
  echo "INSTALL"
  #DefaultInstallStep
}
