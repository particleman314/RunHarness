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

if [ -z "$( __extract_value 'DB_FILE' )" ]
then
  db_property_map=
  db_options_map=
  
  __set_internal_value 'DB_MAP' 'db_property_map'
  __set_internal_value 'DB_OPTIONS' 'db_options_map'
  __set_internal_value 'DB_FILE' 'susbsystem_results.db'
  __set_internal_value 'DB_FULLPATH_FILE'
  __set_internal_value 'DB_ROOT'
fi

[ -z "${SLCF_SHELL_TOP}" ] || [ -z "${PASS}" ] && return 1

. "${__HARNESS_TOPLEVEL}/utilities/outputs/.output_support.sh"
[ $? -ne 0 ] && return 1

. "${SLCF_SHELL_TOP}/lib/filedb.sh"
[ $? -ne 0 ] && return 1

__handle_db_output_option()
{
  __handle_output_formatter_option "$( __extract_value 'DB_OPTIONS' )" $@
  return $?
}

__prepare_db_output_management()
{
  return "${PASS}"
}

__update_db_output_testsuite_field()
{
  typeset tmpfile="$( __extract_value 'DB_FULLPATH_FILE' ).tmp"

  typeset fieldname="$1"
  typeset value="$2"
  
  [ -z "${fieldname}" ] && return "${FAIL}"
  
  typeset root="$( __extract_value 'DB_ROOT' )"
  \sed -e "s#${root}/${fieldname}:\\w*#${root}/${fieldname}:${value}#" "$( __extract_value 'DB_FULLPATH_FILE' )" > "${tmpfile}"
  [ -f "${tmpfile}" ] && \mv -f "${tmpfile}" "$( __extract_value 'DB_FULLPATH_FILE' )"

  return $?
}

can_record_stdout_stderr_db_output()
{
  printf "%d\n" "${NO}"
  return "${PASS}"
}

complete_db_output()
{
  return "${PASS}"
}

complete_db_output_test_suite()
{
  return "${PASS}"
}

get_db_output_filename()
{
  printf "%s\n" "$( __extract_value 'DB_FILE' )"
  return "${PASS}"
}

initiate_db_output()
{
  __clear_output_formatter "$( __extract_value 'DB_MAP' )"
  [ $? -ne "${PASS}" ] && return "${FAIL}"
  
  __set_internal_value 'DB_ROOT' "/testsuites/testsuite/$( __extract_value 'TEST_SUBSYSTEM' )"

  return "${PASS}"
}

initiate_db_output_test_suite()
{
  typeset subsys_id=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ID' )
  [ -n "$( __extract_value 'DB_FULLPATH_FILE' )" ] && printf "%s\n%s\n" "Stage ${subsys_id} : Tests for << $( __extract_value 'TEST_SUBSYSTEM' ) UTC: $( __extract_value 'DATE_UTC' )>>" "$( __extract_value 'DBL_DIVIDER' )" >> "$( __extract_value 'DB_FULLPATH_FILE' )"
  return "${PASS}"
}

merge_db_output()
{
  typeset mergefile="$1"
  typeset finalfile="$2"

  [ ! -f "${mergefile}" ] && return "${FAIL}"
  
  sed '1d' "${mergefile}" >> "${finalfile}"
  return "${PASS}"  
}

record_db_output_testfile_error_4_suite()
{
  typeset testname="$1"
  typeset data="$2"
  shift 2
  
  [ -z "${data}" ] && return "${FAIL}"
  [ -f "${data}" ] && data=$( \cat "${data}" )

  [ -n "$( __extract_value 'DB_FULLPATH_FILE' )" ] && printf "%s\n" "$( __extract_value 'DB_ROOT' )/${testname}/system-err:${data}" >> "$( __extract_value 'DB_FULLPATH_FILE' )"
  return "${PASS}"    
}

record_db_output_testfile_output_4_suite()
{
  typeset testname="$1"
  typeset data="$2"
  shift 2
  
  [ -z "${data}" ] && return "${FAIL}"
  [ -f "${data}" ] && data=$( cat "${data}" )

  [ -n "$( __extract_value 'DB_FULLPATH_FILE' )" ] && printf "%s\n" "$( __extract_value 'DB_ROOT' )/${testname}/system-out:${data}" >> "$( __extract_value 'DB_FULLPATH_FILE' )"
  return "${PASS}"
}

record_db_output_testfile_result_4_suite()
{
  typeset testname=
  typeset runtime=0.0
  typeset testid=0
  typeset rsttype='fail'
  typeset cause='Assertion Failure'
  
  OPTIND=1
  while getoptex "testname: type: cause: test-id: runtime: data:" "$@"
  do
    case "${OPTOPT}" in
    'testname'  ) testname="${OPTARG}";;
    'type'      ) rsttype="${OPTARG:-'fail'}";;
    'cause'     ) cause="${OPTARG}";;
    'test-id'   ) testid="${OPTARG}";;
    'runtime'   ) runtime="${OPTARG}";;
    'data'      ) data="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${testname}" ] && return "${FAIL}"
  
  typeset passcnt=0
  typeset failcnt=0
  typeset skipcnt=0
  
  if [ -n "${data}" ]
  then
    passcnt=$( get_element --data "${data}" --id 1 --separator ':' )
    failcnt=$( get_element --data "${data}" --id 2 --separator ':' )
    skipcnt=$( get_element --data "${data}" --id 3 --separator ':' )
  fi
  
  typeset root="$( __extract_value 'DB_ROOT' )/${testname}/${rsttype}"
  
  if [ -n "$( __extract_value 'DB_FULLPATH_FILE' )" ]
  then
    printf "%s\n" "${root}/id:${testid}" >> "$( __extract_value 'DB_FULLPATH_FILE' )"
    if [ "${rsttype}" != 'error' ]
    then
      printf "%s\n" "${root}/time:${runtime} $( __extract_value 'RUNTIME_UNIT' )" >> "$( __extract_value 'DB_FULLPATH_FILE' )"
      printf "%s\n" "${root}/passcnt:${passcnt}" >> "$( __extract_value 'DB_FULLPATH_FILE' )"
      printf "%s\n" "${root}/failcnt:${failcnt}" >> "$( __extract_value 'DB_FULLPATH_FILE' )"
      printf "%s\n" "${root}/skipcnt:${skipcnt}" >> "$( __extract_value 'DB_FULLPATH_FILE' )"

      case "$rsttype" in
      'fail'  ) printf "%s\n" "${root}/failure_message:${cause}" >> "$( __extract_value 'DB_FULLPATH_FILE' )";;
      'skip'  ) printf "%s\n" "${root}/skipped:1" >> "$( __extract_value 'DB_FULLPATH_FILE' )";;
      esac
    fi
  fi
  return "${PASS}"
}

record_db_output_settings_to_output()
{
  if [ -n "$( __extract_value 'DB_FULLPATH_FILE' )" ]
  then
    printf "%s\n" "$( __extract_value 'DB_ROOT' )/properties" >> "${filepath}"
  
    typeset propkeys=$( hkeys --map "$( __extract_value 'DB_MAP' )" )
    typeset pk
    for pk in ${propkeys}
    do
      typeset value=$( hget --map "$( __extract_value 'DB_MAP' )" --key "${pk}" )
      printf "%s\n" "$( __extract_value 'DB_ROOT' )/property/name-value:${pk}:value=${value}" >> "${filepath}"
    done
  fi
  
  return "${PASS}"
}

release_db_output()
{
  return "${PASS}"
}

set_db_output_filename()
{
  typeset filepath="$1"
  if [ -z "$1" ]
  then
    __set_internal_value 'DB_FULLPATH_FILE' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )/$( __extract_value 'DB_FILE' )"
  else
    __set_internal_value 'DB_FULLPATH_FILE' "${filepath}"
  fi
  return "${PASS}"
}

update_db_output_testsuite_stats()
{  
  __update_db_output_testsuite_field 'errors' $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_ERROR_EXECUTION' )
  __update_db_output_testsuite_field 'tests' $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_RUN' )
  __update_db_output_testsuite_field 'failures' $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_FAIL' )
  __update_db_output_testsuite_field 'time' $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TIME' )

  return "${PASS}"    
}
