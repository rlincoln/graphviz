
ConfigureStep() {
  cd ${SRC_DIR}
  DefaultConfigureStep
}

BuildStep() {
  SetupCrossEnvironment
  #export CC=${NACLCC}
  #export AR=${NACLAR}
  #export RANLIB=${NACLRANLIB}

  cd ${SRC_DIR}
  export OS_JOBS=1
  export BLAS_LIB="-lf2cblas"
  export LAPACK_LIB="-lf2clapack"
  #export CFLAGS="-Wno-unused-result -Wno-parentheses"
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
  #LogExecute install ${SRC_DIR}/SRC/libsuperlu_*.a ${DESTDIR_LIB}/
  MakeDir ${DESTDIR_INCLUDE}
  #LogExecute install ${SRC_DIR}/SRC/*.h ${DESTDIR_INCLUDE}/

  cd ${SRC_DIR}
  export INSTALL_LIB=${DESTDIR_LIB}
  export INSTALL_INCLUDE=${DESTDIR_INCLUDE}


  #export ${DESTDIR_LIB}
  #export ${DESTDIR_INCLUDE}

  DefaultInstallStep
}
