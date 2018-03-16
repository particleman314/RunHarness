#!/usr/bin/env bash

###############################################################################
# Copyright (c) 2017.  All rights reserved. 
# Mike Klusman IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
# COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS 
# ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
# STANDARD, Mike Klusman IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
# IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
# FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. 
# Mike Klusman EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
# THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
# ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
# FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
# AND FITNESS FOR A PARTICULAR PURPOSE. 
###############################################################################

###############################################################################
#
# Author           : Mike Klusman
# Software Package : Shell Automated Testing -- Python Wrapper
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

# --------------------------------------------------------------------
[ -z "${SLCF_SHELL_TOP}" ] && return "${FAIL}"

. "${SLCF_SHELL_TOP}/utilities/common/.define_pather.sh"
. "${__HARNESS_TOPLEVEL}/bin/setup.sh"
  
. "${__HARNESS_TOPLEVEL}/utilities/test/base_testing.sh"
. "${__HARNESS_TOPLEVEL}/utilities/test/test_framework.sh"

__check_compiler()
{
  typeset compiler_to_use=
  typeset stderrfile="$( __extract_value 'STDERR' )"
  
  ###
  ### Ask if the compiler is the default or specialized ( and meets a version requirement )
  ###
  typeset special_compiler="$( __get_file_setting_info "$1" 'Specialized Compiler: ' )"
  if [ -n "${special_compiler}" ]
  then
    if [ ! -f "${special_compiler}" ]
    then
      printf "$( __extract_value 'PREFIX_WARN' )%s\n" "Unable to find specialized compiler: ${specialized_compiler}" >> "${stderrfile}"
      printf "$( __extract_value 'PREFIX_WARN' )%s\n" "Using default compiler: ${__compiler}" >> "${stderrfile}"
      special_compiler=''
      compiler_to_use="$2"
    else
      compiler_to_use="${specialized_compiler}"
    fi
  else 
    compiler_to_use="$2"
  fi

  typeset request_version="$( __get_file_setting_info "$1" 'Compiler Version: ' )"
  if [ -n "${request_version}" ]
  then
    typeset input_markers="$( __get_word_count "${request_version}" )"
    if [ "${input_markers}" -ge 1 ]
    then
      typeset version_flag=$( get_element --data "${request_version}" --id 1 --separator ' ' | \tr -d '[()]' )
      typeset version_test=$( get_element --data "${request_version}" --id 2 --separator ' ' | \tr -d '[()]' )
      if [ -n "${version_test}" ]
      then
        typeset version_output="$( ${compiler_to_use} ${version_flag} 2>&1 )"
        #if [ "$( __check_compiler_version "${version_output}" "${version_test}" )" -eq "${NO}" ]
        #then
        #  printf "$( __extract_value 'PREFIX_ERROR' )%s\n" "Compiler <${__compiler}> haas version ${__compiler_version}, but requested ${version_test}" >> "${stderrfile}"
        #  return "${FAIL}"
        #fi
      fi
    fi
  fi
  
  printf "%s\n" "${compiler_to_use}"
  return "${PASS}"
}

__get_manifest_file()
{
  typeset mf="$( trim $( __get_file_setting_info "$1" 'Manifest File: ' ))"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"
  
  mfpath="$( trim $( haccess_entry_via_file --filename "${java_mapfile}" --key 'suite_path' ))"
  mf="${mfpath}/${mf}"
  
  printf "%s\n" "${mf}"
  return "${PASS}"  
}

__get_manifest_run_class()
{
  __get_file_setting_info "$1" 'Manifest Main Class:'
  return $?
}

__run_compiler()
{
  typeset __compiler="$1"
  typeset __testfile="$2"
  shift 2
  
  typeset __compiler_options=
  
  if [ -n "${__compiler}" ]
  then
    __compiler="$( __check_compiler "${__testfile}" "${__compiler}" )"
    [ $? -ne "${PASS}" ] && return "${FAIL}"
      
    display_program 'compiler' "${__compiler}"
    mkdir -p "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/classes"
    mkdir -p "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/src"
  
    # Read testfile to get compiler flags
    __compiler_options="$( __get_compilable_file_options "${__testfile}" )"
  
    typeset cmd="${__compiler} -d '$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/classes' -s '$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/src' ${__compiler_options} ${__testfile}"
    [ -n "$( __extract_value 'STDOUT' )" ] && printf "%s\n" "${cmd}" 1>>"$( __extract_value 'STDOUT' )"
    eval "${cmd} 1>>\"$( __extract_value 'STDOUT' )\" 2>>\"$( __extract_value 'STDERR' )\""
    typeset RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  fi
  
  return "${PASS}"
}

__run_executable()
{
  typeset __exe="$1"
  typeset __testfile="$2"
  shift 2
  
  if [ -n "${__exe}" ]
  then
    display_program 'executable' "${__exe}"
    typeset __runtime_options=$( __get_execution_file_options "${__testfile}" )
    [ -z "${__runtime_options}" ] && __runtime_options="-cp ."
    
    typeset __outfile=$( __get_compilable_file_output_name "${__testfile}" )
    
    [ ! -f "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/${__outfile}" ] && return "${FAIL}"
    
    chmod 755 "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/${__outfile}"
    
    typeset rundir="$( pwd -L )"
    
    cd "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )" > /dev/null 2>&1
    typeset cmd="${__exe} ${__runtime_options} -jar $( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/${__outfile}"
    [ -n "$( __extract_value 'STDOUT' )" ] && printf "%s\n" "${cmd}" 1>>"$( __extract_value 'STDOUT' )"
    eval "${cmd} 1>>\"$( __extract_value 'STDOUT' )\" 2>>\"$( __extract_value 'STDERR' )\""
    
    typeset RC=$?
    cd "${rundir}" > /dev/null 2>&1
    
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  fi
  
  return "${PASS}" 
}

__run_linker()
{
  typeset __linker="$1"
  typeset __testfile="$2"
  shift 2
  
  if [ -n "${__linker}" ]
  then
    display_program 'linker' "${__linker}"
    typeset manifest_file=$( __get_manifest_file "${__testfile}" )
    [ -z "${manifest_file}" ] && manifest_file="$( write_manifest_file "${__testfile}" )"

    typeset classfiles=$( find "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/classes" -type f -name "*.class" )
    typeset __outfile=$( __get_compilable_file_output_name "${__testfile}" )
  
    typeset cmd="${__linker} cvfm $( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/${__outfile} ${manifest_file} ${classfiles}"
    [ -n "$( __extract_value 'STDOUT' )" ] && printf "%s\n" "${cmd}" 1>>"$( __extract_value 'STDOUT' )"
    eval "${cmd} 1>>\"$( __extract_value 'STDOUT' )\" 2>>\"$( __extract_value 'STDERR' )\""
    typeset RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  fi
  
  return "${PASS}"
}

write_manifest_file()
{
  typeset input="$1"
  [ -z "${input}" ] || [ ! -f "${input}" ] && return "${FAIL}"
 
  typeset pkgname=$( \cat "${input}" | \grep "^package" | \cut -f 2 -d ' ' | \sed -e 's#;##' )
  typeset mainclass="$( __get_manifest_run_class "${input}" )"
  
  [ -z "${mainclass}" ] && mainclass=$( \cat "${input}" | \grep "^p" | \grep -v "^package" | \grep class | \cut -f 3 -d ' ' | \sed -e 's#{##' )
  
  if [ -n "${pkgname}" ] && [ -n "${mainclass}" ]
  then
    typeset mf="$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/manifest.txt"
    printf "%s\n" "Manifest-Version: 1.0" > "${mf}"
    printf "%s\n" "Class-Path: classes/" >> "${mf}"
    printf "%s\n" "Main-Class: ${pkgname}.${mainclass}" >> "${mf}"
    printf "%s\n" >> "${mf}"
    printf "%s\n" "${mf}"
    return "${PASS}"
  fi
  return "${FAIL}"
}

[ -z "${SLCF_SHELL_TOP}" ] && return "${FAIL}"
  
. "${SLCF_SHELL_TOP}/lib/hashmaps.sh"
[ $? -ne "${PASS}" ] && return "${FAIL}"

. "${__HARNESS_TOPLEVEL}/utilities/wrappers/wrapper_common.sh"

if [ "$( __check_for --key 'DETAIL' --success )" -eq "${YES}" ]
then
  __stdout '----------------------------------------------------------------'
  __stdout 'This is the bash wrapper script for Java'
  __stdout '----------------------------------------------------------------'
fi

java_mapfile="$1"

hadd_entry_via_file --filename "${java_mapfile}" --key 'compiler_handler' --value '__run_compiler'
hadd_entry_via_file --filename "${java_mapfile}" --key 'linker_handler' --value '__run_linker'
hadd_entry_via_file --filename "${java_mapfile}" --key 'executable_handler' --value '__run_executable'

__result_file="$( run_wrapper $@ )"
__RC=$?

unset __outfile

return "${__RC}"
