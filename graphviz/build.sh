
ConfigureStep() {
  cd ${SRC_DIR}

#  echo ${PNACLFINALIZE}  
#  echo ${TRANSLATOR}
#  echo ${NACL_SEL_LDR_X8664}
  echo ${PREFIX}

#  EXTRA_CONFIGURE_ARGS+=--enable-static 
  DefaultConfigureStep

#  SetupCrossEnvironment
#  ./configure --prefix=/usr
}

BuildStep() {
  SetupCrossEnvironment
  #export CC=${NACLCC}
  #export AR=${NACLAR}
  #export RANLIB=${NACLRANLIB}

  cd ${SRC_DIR}
#  export OS_JOBS=1
  #export CFLAGS="-Wno-unused-result -Wno-parentheses"
  #export BUILD_DIR
  

  export PNACLFINALIZE  
  export TRANSLATOR
  export HOST_ARCH=x86_64
  export NACL_SEL_LDR_X8664
  export NACL_IRT_X8664
	
  DefaultBuildStep
  #SetupCrossEnvironment
}

#PostBuildStep() {
#  find . -type f -print0 | xargs -0 sed -i 's/${PREFIX}//usr/g'
#  DefaultPostBuildStep
#}

TestStep() {
#echo "Skipping tests"
  DefaultTestStep
}

InstallStep() {
# MakeDir ${DESTDIR_LIB}
  #LogExecute install ${SRC_DIR}/SRC/libsuperlu_*.a ${DESTDIR_LIB}/
# MakeDir ${DESTDIR_INCLUDE}
  #LogExecute install ${SRC_DIR}/SRC/*.h ${DESTDIR_INCLUDE}/

  cd ${SRC_DIR}
# export INSTALL_LIB=${DESTDIR_LIB}
#export INSTALL_INCLUDE=${DESTDIR_INCLUDE}


  #export ${DESTDIR_LIB}
  #export ${DESTDIR_INCLUDE}

  DefaultInstallStep

  cd ${DESTDIR}
  find . -type f -print0 -name '*.pc' -o -name '*.la' | xargs -0 sed -i "s|${PREFIX}|/usr|g"
}

PostInstallTestStep() {
  DefaultPostInstallTestStep
#  LogExecute cd ${SRC_DIR}/cmd/dot/
#  LogExecute export GVBINDIR=${DESTDIR_LIB}/graphviz
#  LogExecute ls ${GVBINDIR}
#  RunSelLdrCommand dot_static.pexe -c -v
#  LogExecute sed -i.bak "s|-a -B|-E GVBINDIR=${GVBINDIR} -a -B|g" dot_static.pexe_64.sh
#  LogExecute ./dot_static.pexe_64.sh -c -v


#  local PEXE=dot.pexe
#  local NEXE_64=dot_64.nexe
#  local SCRIPT_64=dot_64.sh
#  shift
#  TranslateAndWriteSelLdrScript "${PEXE}" x86-64 "${NEXE_64}" "${SCRIPT_64}"
#  echo "[sel_ldr x86-64] ${SCRIPT_64} -c"
#  "./${SCRIPT_64}" "-c"
}