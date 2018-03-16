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

__complete_textual_output_test_suite()
{
  record_step ${HOTSPOT_FLAGS} --header 'shared_suite_output' --msg "common function for updating stats per suite"

  typeset tab_marker="$( __extract_value 'DISPLAY_TAB_MARKER' )"
  [ -n "${tab_marker}" ] && tab_marker="$( printf "%s\n" "${tab_marker}" | \sed -e "s#${tab_marker}#    #g" )"

  typeset fullpath_file="$1"
  [ $( is_empty --str "${fullpath_file}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset keyword=$( __determine_header_entry )

  typeset pass="$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_PASS' )"
  typeset fail="$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_FAIL' )"
  typeset skip="$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_SKIP' )"
  
  typeset sum=$(( pass + fail + skip ))
  
  typeset suite_alltime="$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TIME' )"     ## Suite time from start to finish
  typeset suite_runtime="$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_RUNTIME' )"  ## Sum of all tests runtimes
  typeset ovhtime=$( calculate_run_time --start "${suite_runtime}" --end "${suite_alltime}" --decimals 0 )

  if [ "${fail}" -gt 0 ]
  then
    printf "%s\n" "${keyword} Result               : [ FAIL ]" >> "${fullpath_file}"
    if [ $( __check_for --key 'WORKFLOW' --success ) -eq "${YES}" ] && [ $( __check_for --key 'SUITE_STOP_ON_FAIL' --success ) ]
    then
      printf "%s\n\n" "Explanation                : Found one or more failures from ${keyword} #$( __extract_value 'CURRENT_STAGE_ID' ) [ $( __extract_value 'CURRENT_STAGE' ) ]" >> "${fullpath_file}"
    else
      printf "%s\n\n" "Explanation                : Found one or more failures in this $( to_lower ${keyword} )" >> "${fullpath_file}"
    fi
    printf "%s\n" "Start Time                 : $( __change_time_to_local $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_START_TIME' ) )" >> "${fullpath_file}"
    printf "%s\n\n" "End Time                   : $( __change_time_to_local $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_END_TIME' ) )" >> "${fullpath_file}"
    printf "%s\n" "${keyword} Time                 : $( convert_time --num-seconds "${suite_alltime}" --match-digits )" >> "${fullpath_file}"  
    printf "%s${tab_marker}%s\n" "${keyword} Overhead Time        : $( convert_time --num-seconds "${ovhtime}" --match-digits )" "[ $( compute_percentage "${ovhtime}" "${suite_alltime}" )% ]" >> "${fullpath_file}"
    printf "%s${tab_marker}%s\n\n" "Total Test Runtime         : $( convert_time --num-seconds "${suite_runtime}" --match-digits )" "[ $( compute_percentage "${suite_runtime}" "${suite_alltime}" )% ]" >> "${fullpath_file}"
    printf "%s\n\n" "Details" >> "${fullpath_file}"
      
    typeset failed_test_lines=$( \grep -n 'FAILED' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )" | \cut -f 1 -d ':' )
    typeset ftl
    for ftl in ${failed_test_lines}
    do
      typeset dataline=$( copy_file_segment --filename "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )" -b "${ftl}" -e "${ftl}" )
      printf "%s\n" "${dataline}" >> "${fullpath_file}"
    done
    [ -n "${failed_test_lines}" ] && printf "\n" >> "${fullpath_file}"
  else    
    if [ "${pass}" -gt 0 ]
    then
      printf "%s\n" "${keyword} Result               : [ PASS ]" >> "${fullpath_file}"
      printf "%s\n\n" "Explanation                : Passed all tests in $( to_lower ${keyword} )" >> "${fullpath_file}"
    else
      printf "%s\n" "${keyword} Result               : [ SKIPPED ]" >> "${fullpath_file}"
      printf "%s\n\n" "Explanation                : No active tests in $( to_lower ${keyword} )" >> "${fullpath_file}"
    fi
    printf "%s\n" "Start Time                 : $( __change_time_to_local $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_START_TIME' ) )" >> "${fullpath_file}"
    printf "%s\n\n" "End Time                   : $( __change_time_to_local $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_END_TIME' ) )" >> "${fullpath_file}"
      
    printf "%s\n" "${keyword} Time                 : $( convert_time --num-seconds "${suite_alltime}" --match-digits )" >> "${fullpath_file}"  
    printf "%s${tab_marker}%s\n" "${keyword} Overhead Time        : $( convert_time --num-seconds "${ovhtime}" --match-digits )" "[ $( compute_percentage "${ovhtime}" "${suite_alltime}" )% ]" >> "${fullpath_file}"
    printf "%s${tab_marker}%s\n\n" "Total Test Runtime         : $( convert_time --num-seconds "${suite_runtime}" --match-digits )" "[ $( compute_percentage "${suite_runtime}" "${suite_alltime}" )% ]" >> "${fullpath_file}"
  fi

  typeset runtests="$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_RUN' )"
  typeset expectedtests="$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_EXPECTED' )"
  typeset skippedtests=$(( expectedtests - runtests ))
    
  printf "%s\n" "${keyword} TestFiles Processed  : ${runtests}" >> "${fullpath_file}"
  printf "%s\n" "${keyword} TestFiles Skipped    : ${skippedtests}" >> "${fullpath_file}"

  printf "%s\n" "Test Location              : $( __extract_value 'TEST_RESULTS_SUBSYSTEM' )"  >> "${fullpath_file}"
  printf "%s\n" "Test Machine               : $( hostname ) [$( get_machine_ip )]" >> "${fullpath_file}"
  if [ "${sum}" -gt 0 ]
  then
    printf "\n%s\n\n" "Test Statistics" >> "${fullpath_file}"

    typeset full_pulse=$( compute_pulse_index -p "${pass}" -f ${fail} -s ${skip} )
    typeset reduced_pulse=$( compute_reduced_pulse_index -p "${pass}" -f ${fail} -s ${skip} )
    printf "${tab_marker}%s\n" "--> Overall Pulse      : ${full_pulse}%" >> "${fullpath_file}"
    printf "${tab_marker}%s\n\n" "--> Reduced Pulse      : ${reduced_pulse}%" >> "${fullpath_file}"
    
    printf "${tab_marker}%s\n" "--> Passing            : ${pass}" >> "${fullpath_file}"
    printf "${tab_marker}%s\n" "--> Failing            : ${fail}" >> "${fullpath_file}"
    printf "${tab_marker}%s\n" "--> Skipped            : ${skip}" >> "${fullpath_file}"
  fi
  
  return "${PASS}"
}

__determine_header_entry()
{
  typeset keyword='Suite'
  [ "$( __check_for --key 'WORKFLOW' --success )" -eq "${YES}" ] && keyword='Stage'
  printf "%s\n" "${keyword}"
  return "${PASS}"
}

__generate_header_summary()
{
  record_step ${HOTSPOT_FLAGS} --header 'shared_header_output' --msg "generation of header summary"

  typeset tab_marker="$( __extract_value 'DISPLAY_TAB_MARKER' )"
  [ -n "${tab_marker}" ] && tab_marker="$( printf "%s\n" "${tab_marker}" | \sed -e "s#${tab_marker}#    #g" )"

  typeset fullpath_file="$1"
  shift
  
  if [ -n "${fullpath_file}" ]
  then
    typeset summaryfile="${fullpath_file}.header"
    __register_cleanup "${summaryfile}" outputs
    
    typeset keyword=$( __determine_header_entry )
    
    printf "%s\n\n" "=== Welcome to the CANOPUS Test Harness Report ===" >> "${summaryfile}"
    printf "%s\n" "$( __extract_value 'DBL_DIVIDER' )" >> "${summaryfile}"
    printf "%s\n" "Version      : $( __extract_value 'PROGRAM_VERSION' )" "Build #      : $( __extract_value 'PROGRAM_VERSION_BUILD' )" "Build Type   : $( __extract_value 'PROGRAM_BUILD_TYPE' )" "Build Date   : $( __extract_value 'PROGRAM_BUILD_DATE' )" >> "${summaryfile}"
    [ $( is_empty --str "$( __extract_value 'INPUT_FILE' )" ) -eq "${NO}" ] && printf "%s\n" "Input Driver : $( __extract_value 'INPUT_FILE' )" >> "${summaryfile}"
    printf "%s\n" "Arguments    : $( __extract_value 'INPUT_ARGS' )" >> "${summaryfile}"
    printf "%s\n\n" "$( __extract_value 'DBL_DIVIDER' )" >> "${summaryfile}"
    
    printf "%s\n" "All ${keyword}s" "$( __extract_value 'DBL_DIVIDER' )" >> "${summaryfile}"
    if [ $( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_FAIL' ) -gt 0 ]
    then
      printf "%s\n" "Overall Result             : [ FAIL ]" >> "${summaryfile}"
      if [ $( __check_for --key 'WORKFLOW' --success ) -eq "${YES}" ] && [ $( __check_for --key 'SUITE_STOP_ON_FAIL' --success ) -eq "${YES}" ]
      then
        typeset failed_stg="$( hget --map "$( __extract_value 'WORKFLOW_MAPNAME' )" --key 'failed_stages' )"
        if [ $( __get_word_count "${failed_stg}" ) -gt 1 ]
        then
          printf "%s\n\n" "Explanation                : One or more failures from ${keyword}s --> $( printf "%s\n" "${failed_stg}" | \tr ' ' ',' )" >> "${summaryfile}"
        else
          printf "%s\n\n" "Explanation                : One or more failures from ${keyword} #${failed_stg} [ $( __request_workflow_stage_name "${failed_stg}" ) ]" >> "${summaryfile}"
        fi
      else
        printf "%s\n\n" "Explanation                : One or more failures in some $( to_lower ${keyword} )(s)" >> "${summaryfile}"
      fi
    else
      printf "%s\n" "Overall Result             : [ PASS ]" >> "${summaryfile}"
      printf "%s\n" "Explanation                : All tests in all $( to_lower ${keyword} )s passed" >> "${summaryfile}"
    fi
    printf "\n%s\n" "Harness Output Folder      : $( __extract_value 'RESULTS_DIR' )" >> "${summaryfile}"
    printf "%s\n\n" "Harness Detail Output File : $( find_output_file --channel "$( __define_internal_variable 'INFO' )" )" >> "${summaryfile}"
    printf "%s\n" "Start Time                 : $( __change_time_to_local $( __extract_value 'START_TIME' ) )" >> "${summaryfile}"
    printf "%s\n\n" "End Time                   : $( __change_time_to_local $( __extract_value 'END_TIME' ) )" >> "${summaryfile}"
    
    typeset totalt=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_TIME' )
    typeset totalrt=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_RUNTIME' )
    typeset totalovh=$( calculate_run_time --start "${totalrt}" --end "${totalt}" --decimals 0 )
    
    printf "%s\n" "Total Time                 : $( convert_time --num-seconds "${totalt}" --match-digits )" >> "${summaryfile}"
    printf "%s${tab_marker}%s\n" "Total Overhead Time        : $( convert_time --num-seconds ${totalovh} --match-digits )" "[ $( compute_percentage ${totalovh} ${totalt} )% ]" >> "${summaryfile}"
    printf "%s${tab_marker}%s\n\n" "Total Test Runtime         : $( convert_time --num-seconds "${totalrt}" --match-digits )" "[ $( compute_percentage ${totalrt} ${totalt} )% ]" >> "${summaryfile}"

    typeset runtests="$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_TESTS_RUN' )"
    typeset expectedtests="$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_TESTS_EXPECTED' )"
    typeset skippedtests=$(( expectedtests - runtests ))
    
    printf "%s\n" "Total ${keyword}s Processed     : $( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'SUBSYSTEM_ID' )" >> "${summaryfile}"
    printf "%s\n" "Total TestFiles Processed  : ${runtests}" >> "${summaryfile}"
    printf "%s\n" "Total TestFiles Skipped    : ${skippedtests}" >> "${summaryfile}"
    printf "%s\n" "Total Assertions Processed : $( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS' )" >> "${summaryfile}"
    
    printf "\n%s\n\n" "Test Statistics" >> "${summaryfile}"
    typeset pass=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_PASS' )
    typeset fail=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_FAIL' )
    typeset skip=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_SKIP' )
    
    typeset full_pulse=$( compute_pulse_index -p "${pass}" -f "${fail}" -s "${skip}" )
    typeset reduced_pulse=$( compute_reduced_pulse_index -p "${pass}" -f "${fail}" -s "${skip}" )
    printf "${tab_marker}%s\n" "--> Overall Pulse      : ${full_pulse}%" >> "${summaryfile}"
    printf "${tab_marker}%s\n\n" "--> Reduced Pulse      : ${reduced_pulse}%" >> "${summaryfile}"
    printf "${tab_marker}%s\n" "--> Total Passing      : ${pass}" >> "${summaryfile}"
    printf "${tab_marker}%s\n" "--> Total Failing      : ${fail}" >> "${summaryfile}"
    printf "${tab_marker}%s\n" "--> Total Skipped      : ${skip}" >> "${summaryfile}"
    
    printf "%s\n\n" "$( __extract_value 'DBL_DIVIDER' )" >> "${summaryfile}"

    printf "%s\n" "${summaryfile}"
  fi

  return "${PASS}"
}

__record_textual_output_testfile_error_4_suite()
{
  typeset fullpath_file="$1"
  typeset data="$2"
  shift 2
  
  [ -z "${data}" ] && return "${FAIL}"
  [ -f "${data}" ] && data=$( \cat "${data}" )

  [ -n "${fullpath_file}" ] && printf "%s\n\n%s\n" "Error :" "${data}" >> "${fullpath_file}"
  return "${PASS}"
}

__record_textual_output_testfile_output_4_suite()
{
  typeset fullpath_file="$1"
  typeset data="$1"
  shift 2
  
  [ -z "${data}" ] && return "${FAIL}"
  [ -f "${data}" ] && data=$( \cat "${data}" )

  [ -n "${fullpath_file}" ] && printf "%s\n\n%s\n" "Output :" "${data}" >> "${fullpath_file}"
  return "${PASS}"
}

__release_overall_information()
{
  typeset fullpath_file="$1"
  shift
  
  typeset summaryfile=
  [ -n "${fullpath_file}" ] && summaryfile="$( __generate_header_summary "${fullpath_file}" )"
  
  if [ -n "${summaryfile}" ] && [ -f "${summaryfile}" ]
  then
    \cat "${summaryfile}" "${fullpath_file}" > "${fullpath_file}.final"
  else
    \cp -f "${fullpath_file}" "${fullpath_file}.final"
  fi
  
  printf "%s\n" "${fullpath_file}.final"
  __register_cleanup "${fullpath_file}.final" outputs
  return "${PASS}"
}

__update_textual_output_testsuite_stats()
{
  record_step ${HOTSPOT_FLAGS} --header 'shared_teststats_output' --msg "common function for updating stats per test"

  typeset tab_marker="$( __extract_value 'DISPLAY_TAB_MARKER' )"
  [ -n "${tab_marker}" ] && tab_marker="$( printf "%s\n" "${tab_marker}" | \sed -e "s#${tab_marker}#    #g" )"

  typeset access_opt=
  typeset fullpath_file=
  typeset options=
  
  OPTIND=1
  while getoptex "m: map: f: mapfile: p: path: map-options:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'|'f'|'mapfile'  )  access_opt="--${OPTOPT} ${OPTARG}";;
    'p'|'path'               )  fullpath_file="${OPTARG}";;
        'map-options'        )  options="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  typeset proper_tn_id="$( default_value --def 0 "$( __access_data ${access_opt} --key 'test_id' )" )"
  typeset proper_tn="$( __access_data ${access_opt} --key 'full_testname' )"
  typeset rantest="$( default_value --def "${NO}" "$( __access_data ${access_opt} --key 'was_run' )" )"

  typeset subsysrt=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_RUNTIME' )
  typeset fullsize=$( __get_char_count --non-file "$( __extract_value 'DBL_DIVIDER' )" )

  if [ -n "${rantest}" ] && [ "${rantest}" -eq "${YES}" ]
  then
    typeset proper_tn_rst="$( __access_data ${access_opt} --key 'result' )"
    typeset proper_tn_st="$( __access_data ${access_opt} --key 'start_time' )"
    typeset proper_tn_et="$( __access_data ${access_opt} --key 'end_time' )"
    typeset proper_tn_rt="$( __access_data ${access_opt} --key 'runtime' )"
    typeset proper_tn_rst="$( __access_data ${access_opt} --key 'result' )"
    typeset proper_tn_out="$( __access_data ${access_opt} --key 'stdout_file' )"
    typeset proper_tn_err="$( __access_data ${access_opt} --key 'stderr_file' )"

    typeset proper_tn_args="$( __access_data ${access_opt} --key 'executable_arguments' )"
    proper_tn_args="$( __substitute "$( printf "%s\n" "${proper_tn_args}" | \sed -e 's#^A##' -e 's#%\(\w*\)%#\$\{\1\}#g' -e 's#[ \t\n]# #g' -e "s#$( __extract_value 'SPACE_MARKER' )# #g" )" )"

    typeset nap="$( __access_data ${access_opt} --key 'num_assertions_pass' )"
    typeset naf="$( __access_data ${access_opt} --key 'num_assertions_fail' )"
    typeset nas="$( __access_data ${access_opt} --key 'num_assertions_skip' )"

    typeset exe_cmd="$( __access_data ${access_opt} --key 'exe_cmd' )"

    typeset spacersize=$(( fullsize -6 -9 -$( __get_char_count --non-file "${proper_tn}" ) -$( __get_char_count --non-file "${proper_tn_id}" )))
    typeset spacer=$( printf "%${spacersize}s" '-' | \tr '-' ' ' )

    typeset sum_assertions=$(( nap + naf + nas ))
    if [ "${sum_assertions}" -gt 0 ]
    then
      printf "\n" >> "${fullpath_file}"
      
      printf "${tab_marker}%s\n" "Test: ${proper_tn}${spacer}Test ID: ${proper_tn_id}" "$( __extract_value 'DBL_DIVIDER' )" >> "${fullpath_file}"
      if [ "${proper_tn_rst}" -ne "${PASS}" ] || [ "${naf}" -ge 1 ]
      then
        printf "${tab_marker}%s\n" "Result                 : [ FAIL ]" >> "${fullpath_file}"
        typeset numfailed=$( hget --map "${tmap}" --key 'SUBSYSTEM_ASSERTIONS_FAIL' )
        printf "${tab_marker}%s\n\n" "Explanation            : Found ${numfailed} assertion failure(s) in test. See $( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' ) for details" >> "${fullpath_file}"        
      else
        printf "${tab_marker}%s\n" "Result                 : [ PASS ]" >> "${fullpath_file}"
        printf "${tab_marker}%s\n\n" "Explanation            : Passed all assertion tests." >> "${fullpath_file}"
      fi

      printf "${tab_marker}%s\n" "Issued cmd             : ${exe_cmd} ${proper_tn}" >> "${fullpath_file}"
      [ -n "${proper_tn_args}" ] && printf "${tab_marker}%s\n" "Arguments              : ${proper_tn_args}" >> "${fullpath_file}"
  
      printf "${tab_marker}%s\n" "Output File(s)         : ${proper_tn_out}" >> "${fullpath_file}"
      printf "${tab_marker}%s\n\n" "Error File(s)          : ${proper_tn_err}" >> "${fullpath_file}"
      
      if [ "${proper_tn_rst}" -ne "${PASS}" ] || [ "${naf}" -ge 1 ]
      then
        if [ $( is_empty --str "${options}" ) -eq "${NO}" ] && [ $( hget --map "${options}" --key 'show_errors' ) -eq "${YES}" ]
        then
          printf "${tab_marker}%s\n\n" "Error File Details          :" >> "${fullpath_file}"
          \cat "${proper_tn_err}" >> "${fullpath_file}"
          printf "\n" >> "${fullpath_file}"
        fi
      fi
      
      printf "${tab_marker}%s\n" "Start Time             : $( __change_time_to_local "${proper_tn_st}" )" >> "${fullpath_file}"
      printf "${tab_marker}%s\n" "End Time               : $( __change_time_to_local "${proper_tn_et}" )" >> "${fullpath_file}"
      printf "${tab_marker}%s\n\n" "Runtime                : $( convert_time --num-seconds "${proper_tn_rt}" --match-digits )" >> "${fullpath_file}"
      printf "${tab_marker}%s\n" "Test Statistics" >> "${fullpath_file}"
      printf "${tab_marker}${tab_marker}%s\n" "--> Passing        : ${nap}" >> "${fullpath_file}"
      printf "${tab_marker}${tab_marker}%s\n" "--> Failing        : ${naf}" >> "${fullpath_file}"
      printf "${tab_marker}${tab_marker}%s\n" "--> Skipped        : ${nas}" >> "${fullpath_file}"
    else
      printf "\n" >> "${fullpath_file}"
      printf "${tab_marker}%s\n" "Test: ${proper_tn}   Test ID: ${proper_tn_id}" "$( __extract_value 'DBL_DIVIDER' )" >> "${fullpath_file}"
      printf "${tab_marker}%s\n" "Result                 : [ EMPTY ]" >> "${fullpath_file}"
      printf "${tab_marker}%s\n\n" "Explanation            : No assertions processed." >> "${fullpath_file}"
      
      printf "${tab_marker}%s\n" "Issued cmd             : ${exe_cmd} ${proper_tn}" >> "${fullpath_file}"
      [ -n "${proper_tn_args}" ] && printf "${tab_marker}%s\n" "Arguments              : ${proper_tn_args}" >> "${fullpath_file}"
      
      printf "${tab_marker}%s\n" "Output File(s)         : ${proper_tn_out}" >> "${fullpath_file}"
      printf "${tab_marker}%s\n\n" "Error File(s)          : ${proper_tn_err}" >> "${fullpath_file}"
      printf "${tab_marker}%s\n" "Start Time             : $( __change_time_to_local "${proper_tn_st}" )" >> "${fullpath_file}"
      printf "${tab_marker}%s\n" "End Time               : $( __change_time_to_local "${proper_tn_et}" )" >> "${fullpath_file}"
      printf "${tab_marker}%s\n\n" "Runtime                : $( convert_time --num-seconds "${proper_tn_rt}" )" >> "${fullpath_file}"
    fi      
  else
    typeset spacersize=$(( fullsize -6 -9 -$( __get_char_count --non-file "${proper_tn}" ) -$( __get_char_count --non-file "${proper_tn_id}" )))
    typeset spacer=$( printf "%${spacersize}s" '-' | \tr '-' ' ' )

    printf "\n" >> "${fullpath_file}"
    printf "${tab_marker}%s\n" "Test: ${proper_tn}${spacer}Test ID: ${proper_tn_id}" "$( __extract_value 'DBL_DIVIDER' )" >> "${fullpath_file}"
    printf "${tab_marker}%s\n" "Result                 : [ SKIPPED ]" >> "${fullpath_file}"
    printf "${tab_marker}%s\n\n" "Explanation            : Not processed." >> "${fullpath_file}"
  fi
  
  return "${PASS}"
}
