
ConfigureStep() {
  cd ${SRC_DIR}/build/gcc
  #DefaultConfigureStep
}

BuildStep() {
  LogExecute cd ${SRC_DIR}/build/gcc

  SetupCrossEnvironment

  # Specify compiler to be used
  export COMPILER=${CC}

  # Specify ar tool to be used
  export ARCHIVER=${AR}

  # Debug flags if any
  export DEBUGGING="-O0 -g" #-fno-stack-protector

  # Warning flags
  export WARNING="-Wpacked -Wall"

  # Add aditional CFLAGS if any 
  export ADDITIONAL_CFLAGS=

  # Whether to include the grammar generation module in the build
  export INCLUDE_GRAMMAR_GENERATION=true

  # In case INCLUDE_GRAMMAR_GENERATION equals true; whether to
  # support parsing of schema-mode EXI encoded XML Schemas
  export INCLUDE_SCHEMA_EXI_GRAMMAR_GENERATION=true

  DefaultBuildStep
  #LogExecute make dynlib
}

TestStep() {
#echo "Skipping tests"
  DefaultTestStep
}

InstallStep() {
  MakeDir ${DESTDIR_LIB}
  LogExecute install ${SRC_DIR}/bin/lib/libexip.a ${DESTDIR_LIB}/

  MakeDir ${DESTDIR_INCLUDE}
  LogExecute install ${SRC_DIR}/bin/headers/*.h ${DESTDIR_INCLUDE}/
}

PostInstallTestStep() {
  DefaultPostInstallTestStep
}
