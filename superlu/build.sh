
ConfigureStep() {
  cd ${SRC_DIR}
  DefaultConfigureStep
}

BuildStep() {
  cd ${SRC_DIR}
  export SUPERLU_ROOT=${SRC_DIR}
  export BLAS_LIB="-L/usr/lib -lblas"
  DefaultBuildStep
  #SetupCrossEnvironment
}

TestStep() {
  #echo "TEST"
  DefaultTestStep
}

InstallStep() {
  #echo "INSTALL"
  DefaultInstallStep
}
