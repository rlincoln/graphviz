
ConfigureStep() {
  cd ${SRC_DIR}
  DefaultConfigureStep
}

BuildStep() {
  #SetupCrossEnvironment
  export CC=${NACLCC}
  export AR=${NACLAR}
  export RANLIB=${NACLRANLIB}

  cd ${SRC_DIR}
  export SUPERLU_ROOT=${SRC_DIR}
  #export SUPERLULIB=${SRC_DIR}/SRC/libsuperlu_4.3.a
  export BLAS_LIB="-L/usr/lib -lf2cblas"
  #export OS_JOBS=1
  export C_FLAGS="-Wno-unused-result -Wno-parentheses"
  #export BUILD_DIR
  DefaultBuildStep
  #SetupCrossEnvironment
}

TestStep() {
  echo "Skipping tests"
  #DefaultTestStep
}

InstallStep() {
  MakeDir ${DESTDIR_LIB}
  LogExecute install ${SRC_DIR}/SRC/libsuperlu_*.a ${DESTDIR_LIB}/
  MakeDir ${DESTDIR_INCLUDE}
  LogExecute install ${SRC_DIR}/SRC/*.h ${DESTDIR_INCLUDE}/
}
