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

if [ -z "${SLCF_HTML_FILE}" ]
then
  html_options_map=
  html_property_map=
  
  __set_internal_value 'HTML_MAP' 'html_property_map'
  __set_internal_value 'HTML_OPTIONS' 'html_options_map'
  __set_internal_value 'HTML_FILE ''subsystem_results.html'
  __set_internal_value 'HTML_FULLPATH_FILE'
fi

[ -z "${SLCF_SHELL_TOP}" ] || [ -z "${PASS}" ] && return 1

. "${__HARNESS_TOPLEVEL}/utiltiies/outputs/output_support.sh"
[ $? -ne 0 ] && return 1

. "${SLCF_SHELL_TOP}/lib/xmlmgt.sh"
[ $? -ne 0 ] && return 1

__handle_html_output_option()
{
  __handle_output_formatter_option "$( __extract_value 'HTML_OPTIONS' )" $@
  return $?
}

__initiate_html_body()
{
  return "${PASS}"
}

__prepare_html_header()
{
  return "${PASS}"
}

__prepare_html_output_management()
{
  [ ! -f "${__HARNESS_TOPLEVEL}/utilities/external/index.html" ] && return "${FAIL}"
  
  \cp -f "${__HARNESS_TOPLEVEL}/utilities/external/index.html" "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )"
  
  return "${PASS}"
}

can_record_stdout_stderr_html_output()
{
  printf "%d\n" "${YES}"
  return "${PASS}"
}

complete_html_output()
{
  [ -n "$( __extract_value 'HTML_FULLPATH_FILE' )" ] && printf "%s\n" "</body>" >> "$( __extract_value 'HTML_FULLPATH_FILE' )"
  return "${PASS}"
}

complete_html_output_test_suite()
{
  [ -n "$( __extract_value 'HTML_FULLPATH_FILE' )" ] && printf "%s\n" "   </table>" >> "$( __extract_value 'HTML_FULLPATH_FILE' )"
  return "${PASS}"
}

get_html_output_filename()
{
  printf "%s\n" "$( __extract_value 'HTML_FILE' )"
  return "${PASS}"
}

initiate_html_output()
{
  __clear_output_formatter "$( __extract_value 'HTML_MAP' )"
  [ $? -ne "${PASS}" ] && return "${FAIL}"

  if [ -n "$( __extract_value 'HTML_FULLPATH_FILE' )" ]
  then
    __prepare_html_header
    __initiate_html_body
  fi
  return "${PASS}"
}

initiate_html_output_test_suite()
{
  [ -n "$( __extract_value 'HTML_FULLPATH_FILE' )" ] && printf "%s\n" "   <testsuite name=\"$( __extract_value 'TEST_SUBSYSTEM' )\" errors=\"0\" tests=\"0\" failures=\"0\" time=\"0\" timestamp=\"$( __extract_value 'DATE_UTC' )\">" >> "${SLCF_HTML_FULLPATH_FILE}"
  return "${PASS}"
}

merge_html_output()
{
  typeset mergefile="$1"
  typeset finalfile="$2"
  
  [ ! -f "${mergefile}" ] && return "${FAIL}"
  
  sed '1,2d;$d' "${mergefile}" >> "${finalfile}"
  return "${PASS}"  
}

record_html_output_testfile_error_4_suite()
{
  typeset data="$1"
  shift
  
  [ -z "${data}" ] && return "${FAIL}"
  [ -f "${data}" ] && data=$( \cat "${data}" )

  [ -n "$( __extract_value 'HTML_FULLPATH_FILE' )" ] && printf "%s\n" "         <system-err>${data}</system-err>" >> "$( __extract_value 'HTML_FULLPATH_FILE' )"
  return "${PASS}"    
}

record_html_output_testfile_output_4_suite()
{
  typeset data="$1"
  shift
  
  [ -z "${data}" ] && return "${FAIL}"
  [ -f "${data}" ] && data=$( \cat "${data}" )

  [ -n "$( __extract_value 'HTML_FULLPATH_FILE' )" ] && printf "%s\n" "         <system-out>${data}</system-out>" >> "$( __extract_value 'HTML_FULLPATH_FILE' )"
  return "${PASS}"
}

record_html_output_testfile_result_4_suite()
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
    passcnt=$( printf "%s\n" "${data}" | \cut -f 1 -d ':' )
    failcnt=$( printf "%s\n" "${data}" | \cut -f 2 -d ':' )
    skipcnt=$( printf "%s\n" "${data}" | \cut -f 3 -d ':' )
  fi
  
  if [ -n "$( __extract_value 'HTML_FULLPATH_FILE' )" ]
  then
    if [ "${rsttype}" == 'error' ]
    then
      printf "%s\n" "      <error classname=\"$( __extract_value 'TEST_SUBSYSTEM' ).${testname}\" name=\"${testname}\" id=\"${testid}\">Error condition encountered for ${testname}</error>" >> "$( __extract_value 'HTML_FULLPATH_FILE' )"
    else
      printf "%s\n" "      <testcase classname=\"$( __extract_value 'TEST_SUBSYSTEM' ).${testname}\" name=\"${testname}\" id=\"${testid}\" time=\"${runtime}\" passcnt=\"${passcnt}\" failcnt=\"${failcnt}\" skipcnt=\"${skipcnt}\">" >> "$( __extract_value 'HTML_FULLPATH_FILE' )"

      case "$rsttype" in
      'fail'  ) printf "%s\n" "         <failure message=\"${cause}\"</failure>" >> "$( __extract_value 'HTML_FULLPATH_FILE' )";;
      'skip'  ) printf "%s\n" "         <skipped></skipped>" >> "$( __extract_value 'HTML_FULLPATH_FILE' )";;
      esac
  
      printf "%s\n" "      </testcase>" >> "$( __extract_value 'HTML_FULLPATH_FILE' )"
    fi
  fi
  return "${PASS}"
}

record_html_output_settings_to_output()
{
  if [ -n "$( __extract_value 'HTML_FULLPATH_FILE' )" ]
  then
    printf "%s\n" "     <properties>" >> "${filepath}"
  
    typeset propkeys=$( hkeys --map "$( __extract_value 'HTML_MAP' )" )
    typeset pk
    for pk in ${propkeys}
    do
      typeset value=$( hget --map "$( __extract_value 'HTML_MAP' )" --key "${pk}" )
      printf "%s\n" "        <property name=\"${pk}\" value=\"${value}\">" >> "${filepath}"
    done
  
    printf "%s\n" "     </properties>" >> "${filepath}"
  fi
  
  return "${PASS}"
}

release_html_output()
{
  return "${PASS}"
}

set_html_output_filename()
{
  typeset filepath="$1"
  if [ -z "$1" ]
  then
    __set_internal_value 'HTML_FULLPATH_FILE' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )/$( __extract_value 'HTML_FILE' )"
  else
    __set_internal_value 'HTML_FULLPATH_FILE' "${filepath}"
  fi
  return "${PASS}"
}

update_html_output_testsuite_stats()
{
  xml_set_file --xmlfile "${SLCF_HTML_FULLPATH_FILE}"
  typeset rootnode=$( xml_get_rootnode_name )
  
  __disable_xml_failure
  
  xml_edit_entry --xpath "/${rootnode}/testsuite[@name='$( __extract_value 'TEST_SUBSYSTEM' )']/@errors" --value "$( __extract_value 'COUNT_TEST_ERROR_EXECUTION' )" --overwrite
  xml_edit_entry --xpath "/${rootnode}/testsuite[@name='$( __extract_value 'TEST_SUBSYSTEM' )']/@tests" --value "$( __extract_value 'COUNT_RUN_TEST_FILES' )" --overwrite
  xml_edit_entry --xpath "/${rootnode}/testsuite[@name='$( __extract_value 'TEST_SUBSYSTEM' )']/@failures" --value "$( __extract_value 'COUNT_TEST_FAIL' )" --overwrite
  xml_edit_entry --xpath "/${rootnode}/testsuite[@name='$( __extract_value 'TEST_SUBSYSTEM' )']/@time" --value "$( __extract_value 'TOTAL_TIME_SUBSYSTEM' )" --overwrite
  
  __enable_xml_failure
  
  return "${PASS}"    
}
