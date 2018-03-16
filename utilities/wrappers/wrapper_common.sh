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
# Software Package : Shell Automated Testing -- Wrapper Executable Framework
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

__get_file_setting_info()
{
  typeset in_filename="$1"
  [ ! -f "${in_filename}" ] && return "${FAIL}"
  
  typeset field_id="$2"
  typeset match_text="$( \grep "${field_id}" "${in_filename}" )"

  if [ -n "${match_text}" ]
  then
    match_text="$( printf "%s\n" "${match_text}" | \tr -s ' ' | \tr -s '/' | \tr -s '#' )"
    printf "%s\n" "${match_text}" | \sed -e "s#^\\s*[/#]*\\s*\\w*\\s*${field_id}##" ## TODO : LOOK AT THIS TO SEE HOW TO REWRITE for BSD
  fi
  
  return "${PASS}"
}

__get_compilable_file_options()
{
  __get_file_setting_info "$1" 'Compilation Args:'
  return $?
}

__get_compilable_file_output_name()
{
  typeset outfile_name="$( __get_file_setting_info "$1" 'Compilation Jarfile:' )"
  outfile_name="$( printf "%s\n" "${outfile_name}" | \tr -s ' ' | \sed -e 's#^ ##' )"
  [ -z "${outfile_name}" ] && outfile_name="$( printf "%s\n" "$1" | \sed -e 's#\.\(\w*\)$##' ).jar"  ### TODO : Should this use remove_extension command???

  printf "%s\n" "${outfile_name}"
  return "${PASS}"
}

__get_execution_file_options()
{
  __get_file_setting_info "$1" 'Runtime Args:'
  return $?
}

__get_expected_result()
{
  __get_file_setting_info "$1" 'Expected Result:'
  return $?    
}

__get_linker_file_options()
{
  __get_file_setting_info "$1" 'Linker Args:'
  return $?
}

__record_test_and_arguments()
{
  typeset tn="$1"
  shift
  
  typeset args="$@"
  
  __stdout
  __stdout "Running Test << ${tn} >>"
  [ -n "${args}" ] && __stdout "Arguments    << ${args} >>"
  __stdout
}

__stdout()
{
  if [ -z "$( __extract_value 'STDOUT' )" ]
  then
    [ $# -lt 1 ] && printf "\n" || printf "%s\n" "$@" 
  else
    [ $# -lt 1 ] && printf "\n" 1>>"$( __extract_value 'STDOUT' )" || printf "%s\n" "$@" 1>>"$( __extract_value 'STDOUT' )"
  fi
}

__stderr()
{
  if [ -n "$( __extract_value 'STDERR' )" ]
  then
    [ $# -ge 1 ] && printf "%s\n" "$@" 2>>"$( __extract_value 'STDERR' )"
  fi
}

__stdout_and_stderr()
{
  __stdout $@
  __stderr $@
}

check_result()
{
  if [ $# -lt 2 ]
  then
    if [ $# -eq 1 ]
    then
      assert_success --dnr "$1"
    else
      assert_true --dnr 0
    fi
  else
    typeset actual_result="$1"
    typeset expected_result="$2"
    assert_equals --dnr "${actual_result}" "${expected_result}"
  fi
  
  ###
  ### This will be the result from the assertion which we can use as the overall
  ###   delimiter of whether the result is as expected
  ###
  return "$( __get_last_result )"
}

display_program()
{
  if [ "$( __check_for --key 'DETAIL' )" -eq "${YES}" ]
  then
    typeset text="$1"
    typeset prg="$2"
  
    printf "\n$( __extract_value 'PREFIX_INFO' ) Using %s\t--->\t%s\n\n" "${text}" "[ ${prg} ]"
  fi
  return "${PASS}"
}

executable_wrapper()
{
  typeset RC="${FAIL}"
  typeset executable_name="$1"
  shift
  
  typeset base_cmd="${executable_name} $@"
  if [ "$( __check_for --key 'DETAIL' )" -eq "${YES}" ]
  then
    if [ -n "$( __extract_value 'STDOUT' )" ]
    then
      printf "Launching --> \n%s\n\n" "${cmd}" >> "$( __extract_value 'STDOUT' )"
      typeset final_cmd="${base_cmd} 1>>\"$( __extract_value 'STDOUT' )\" 2>&1"
      append_output --data "${final_cmd}" --channel "${__PROGRAM_VARIABLE_PREFIX}_CMD"
      eval "${final_cmd}"
      RC=$?
    fi
  else
    typeset final_cmd="${base_cmd} 1>>\"$( __extract_value 'STDOUT' )\" 2>>\"$( __extract_value 'STDERR' )\""
    append_output --data "${final_cmd}" --channel "${__PROGRAM_VARIABLE_PREFIX}_CMD"
    eval "${final_cmd}"
    RC=$?
  fi
  return "${RC}"
}

extract_non_harness_output()
{
  [ $# -lt 1 ] && return 0
  
  (
    typeset line
    IFS=$'\n'
    printf "%s\n" $@ | while read -r line
    do
      typeset replaced_line=$( printf "%s\n" "${line}" | \sed 's/\[\\w*\] //' ) ## TODO: Need to rewrite for BSD
      if [ "${replaced_line}" != "${line}" ]
      then
        printf "%s\n" "${line}" >> "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/result.txt"
      else
        printf "%s\n" "${line}"
      fi
    done
  )
}

run_wrapper()
{
  typeset RC
  [ -z "${SLCF_SHELL_TOP}" ] && return "${FAIL}"
  
  . "${SLCF_SHELL_TOP}/lib/hashmaps.sh"

  typeset mapfile="$1"
  
  typeset __testfile="$( haccess_entry_via_file --filename "${mapfile}" --key 'full_testname' )"
  typeset __compiler="$( haccess_entry_via_file --filename "${mapfile}" --key 'compiler' )"
  typeset __linker="$( haccess_entry_via_file --filename "${mapfile}" --key 'linker' )"
  typeset __executable="$( haccess_entry_via_file --filename "${mapfile}" --key 'executable' )"
  
  [ -n "${__compiler}" ] && [ "${__compiler}" == '<NONE>' ] && __compiler=
  [ -n "${__linker}" ] && [ "${__linker}" == '<NONE>' ] && __linker=
  [ -n "${__executable}" ] && [ "${__executable}" == '<NONE>' ] && __executable=
  
  [ -z "${__executable}" ] && return "${FAIL}"

  typeset spmrk="$( __extract_value 'SPACE_MARKER' )"
  if [ -n "${__executable}" ] && [ "${__executable}" == 'shell' ]
  then
    typeset __executable_args="$( haccess_entry_via_file --filename "${mapfile}" --key 'executable_arguments' )"
    __executable_args="$( __evaluate_variable "$( printf "%s\n" "${__executable_args}" | \sed -e 's#^A##' -e 's#[ $( printf "%t" )$( printf "\n" )]# #g' -e "s#${spmrk}# #g" )" 3 )"
    #__executable_args="$( __substitute "$( printf "%s\n" "${__executable_args}" | sed -e 's#^A##' -e 's#%\(\w*\)%#\$\{\1\}#g' -e 's#[ \t\n]# #g' -e "s#${spmrk}# #g" )" )"
    __record_test_and_arguments "${__testfile}:${__executable}:EXEC" ${__executable_args}
    . "./${__testfile}" ${__executable_args} 1>>"$( __extract_value 'STDOUT' )" 2>>"$( __extract_value 'STDERR' )"
    RC=$?
    printf "%d\n" "${RC}" >> "$( __extract_value 'RETURN_ERROR' )"
  else
    if [ -n "${__compiler}" ]
    then
      RC="${PASS}"
      
      which "${__compiler}" > /dev/null 2>&1
      [ $? -ne "${PASS}" ] && return "${FAIL}"
      
      __compiler=$( which "${__compiler}" )
     
      typeset __compile_args="$( haccess_entry_via_file --filename "${mapfile}" --key 'compiler_arguments' )"
      typeset __compiler_handler="$( haccess_entry_via_file --filename "${mapfile}" --key 'compiler_handler' )"     

      __compile_args="$( __evaluate_variable "$( printf "%s\n" "${__compile_args}" | \sed -e 's#^A##' -e 's#[ $( printf "%t" )$( printf "\n" )]# #g' -e "s#${spmrk}# #g" )" 3 )"

      __record_test_and_arguments "${__testfile}:${__compiler}:COMPILER" ${__compile_args}
      typeset result=
      if [ -n "${__compiler_handler}" ]
      then
        eval "result=\$( ${__compiler_handler} ${__compiler} ${__testfile} ${__compile_args} )"
        RC=$?
      fi
      printf "%s\n" "${result}" 1>>"$( __extract_value 'STDOUT' )"
      printf "%d\n" "${RC}" > "$( __extract_value 'RETURN_ERROR' )"
      [ "${RC}" -ne "${PASS}" ] && return "${RC}"
    fi
  
    if [ -n "${__linker}" ]
    then
      RC="${PASS}"
      which "${__linker}" > /dev/null 2>&1
      [ $? -ne "${PASS}" ] && return "${FAIL}"
      
      __linker=$( which "${__linker}" )
      
      typeset __linker_handler="$( haccess_entry_via_file --filename "${mapfile}" --key 'linker_handler' )"     
      typeset __linker_args="$( haccess_entry_via_file --filename "${mapfile}" --key 'linker_arguments' )"

      __linker_args="$( __evaluate_variable "$( printf "%s\n" "${__linker_args}" | \sed -e 's#^A##' -e 's#[ $( printf "%t" )$( printf "\n" )]# #g' -e "s#${spmrk}# #g" )" 3 )"

      __record_test_and_arguments "${__testfile}:${__linker}:LINKER" ${__linker_args}
      
      typeset result=
      if [ -n "${__linker_handler}" ]
      then
        eval "result=\$( ${__linker_handler} ${__linker} ${__testfile} ${__linker_args} )"
        RC=$?
      fi
      printf "%s\n" "${result}" 1>>"$( __extract_value 'STDOUT' )"
      printf "%d\n" "${RC}" > "$( __extract_value 'RETURN_ERROR' )"
      [ "${RC}" -ne "${PASS}" ] && return "${RC}"
    fi

    \which "${__executable}" > /dev/null 2>&1
    [ $? -ne "${PASS}" ] && return "${FAIL}"
    __executable=$( which "${__executable}" )

    typeset __executable_args="$( haccess_entry_via_file --filename "${mapfile}" --key 'executable_arguments' )"
    typeset __executable_handler="$( haccess_entry_via_file --filename "${mapfile}" --key 'executable_handler' )"
   
    __executable_args="$( __evaluate_variable "$( printf "%s\n" "${__executable_args}" | \sed -e 's#^A##' -e 's#[ $( printf "%t" )$( printf "\n" )]# #g' -e "s#${spmrk}# #g" )" 3 )"

    __record_test_and_arguments "${__testfile}:${__executable}:EXEC" ${__executable_args}
    
    typeset result=
    if [ -n "${__executable_handler}" ]
    then
      eval "result=\$( ${__executable_handler} ${__executable} ${__testfile} ${__executable_args} )"
      RC=$?
      printf "%s\n" "${result}" 1>>"$( __extract_value 'STDOUT' )"
      printf "%d\n" "${RC}" >> "$( __extract_value 'RETURN_ERROR' )"
      [ "${RC}" -ne "${PASS}" ] && return "${RC}"
    else
      display_program 'executable' "${__executable}" >> "$( __extract_value 'STDOUT' )"
      executable_wrapper "${__executable}" "${__testfile}" ${__executable_args}
      RC=$?
      printf "%d\n" "${RC}" > "$( __extract_value 'RETURN_ERROR' )"
      [ -f "$( __extract_value 'STDERR' )" ] && [ $( __calculate_filesize "$( __extract_value 'STDERR' )" ) -gt 0 ] && [ "${RC}" -eq 0 ] && RC=1
    fi
  fi

  return "${RC}"
}
