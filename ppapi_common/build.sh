
ConfigureStep() {
  LogExecute cd ${START_DIR}/
  echo ${PREFIX}
  DefaultConfigureStep
}

BuildStep() {
  SetupCrossEnvironment
  cd ${START_DIR}/
#  export OS_JOBS=1

  export TOOLCHAIN=pnacl

  DefaultBuildStep
}

TestStep() {
  DefaultTestStep
}

InstallStep() {
  MakeDir ${DESTDIR_LIB}
  LogExecute install ${START_DIR}/pnacl/Release/libppapi_common.a ${DESTDIR_LIB}/
  MakeDir ${DESTDIR_INCLUDE}
  LogExecute install ${START_DIR}/lib/ppapi_common.h ${DESTDIR_INCLUDE}/
  #DefaultInstallStep
}
