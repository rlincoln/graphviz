
ConfigureStep() {
  LogExecute cd ${SRC_DIR}
  DefaultConfigureStep
}

BuildStep() {
  LogExecute cd ${SRC_DIR}
  SetupCrossEnvironment
  #DefaultBuildStep
}

TestStep() {
  echo "Skipping tests"
  #DefaultTestStep
}

InstallStep() {
#  MakeDir ${DESTDIR_LIB}
#  LogExecute install ${SRC_DIR}/bin/lib/lib*.a ${DESTDIR_LIB}/
  MakeDir ${DESTDIR_INCLUDE}
  LogExecute install ${SRC_DIR}/src/*.h ${DESTDIR_INCLUDE}/
  LogExecute install ${SRC_DIR}/check_stdint.h ${DESTDIR_INCLUDE}/

  #DefaultInstallStep
}

