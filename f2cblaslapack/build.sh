
ConfigureStep() {
  cd ${SRC_DIR}
  #DefaultConfigureStep
}

LIB_SUFFIX=a
BLAS_LIB_NAME=libf2cblas.${LIB_SUFFIX}
LAPACK_LIB_NAME=libf2clapack.${LIB_SUFFIX}

BuildStep() {
  SetupCrossEnvironment

  export CC=${CC}
  export COPTFLAGS=-O
  export CNOOPT=-O0
  export AR_FLAGS=cr
  #-Wshift-op-parentheses -Wlogical-op-parentheses

  export MAKE_OPTIONS=CC="${CC}" COPTFLAGS="${COPTFLAGS}" CNOOPT="${CNOOPT}" AR="${AR}" AR_FLAGS="${AR_FLAGS}" RM="/bin/rm"

  #export BLAS_LIB_NAME=libf2cblas.${LIB_SUFFIX}
  export MAKE_OPTIONS_BLAS=${MAKE_OPTIONS} LIBNAME="${BLAS_LIB_NAME}"

  cd ${SRC_DIR}/blas
  make -j${OS_JOBS} lib ${MAKE_OPTIONS_BLAS}
  ${RANLIB} ../${BLAS_LIB_NAME}

  #export LAPACK_LIB_NAME=libf2clapack.${LIB_SUFFIX}
  export MAKE_OPTIONS_LAPACK=${MAKE_OPTIONS} LIBNAME="${LAPACK_LIB_NAME}"

  cd ${SRC_DIR}/lapack
  make -j${OS_JOBS} lib ${MAKE_OPTIONS_LAPACK}
  ${RANLIB} ../${LAPACK_LIB_NAME}
}

TestStep() {
  DefaultTestStep
}

InstallStep() {
  MakeDir ${DESTDIR_LIB}
  LogExecute install ${SRC_DIR}/${BLAS_LIB_NAME} ${DESTDIR_LIB}/
  LogExecute install ${SRC_DIR}/${LAPACK_LIB_NAME} ${DESTDIR_LIB}/
}
