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

if [ -z "${CANOPUS_JUNIT_XML_FILE}" ]
then
  junit_xml_options=
  junit_xml_property_map=
  
  __set_internal_value 'JUNIT_XML_MAP' 'junit_xml_property_map'
  __set_internal_value 'JUNIT_XML_OPTIONS' 'junit_xml_options'
  __set_internal_value 'JUNIT_XML_FILE' 'junit.xml'
  __set_internal_value 'JUNIT_XML_FULLPATH_FILE'
fi

[ -z "${SLCF_SHELL_TOP}" ] || [ -z "${PASS}" ] && return 1

. "${__HARNESS_TOPLEVEL}/utilities/outputs/output_support.sh"
[ $? -ne 0 ] && return 1

. "${SLCF_SHELL_TOP}/lib/xmlmgt.sh"
[ $? -ne 0 ] && return 1

__convert_special_characters()
{
  typeset data="$1"
  typeset direction="${2:-'forward'}"
  
  if [ "${direction}" == 'forward' ]
  then
    data=$( printf "%s" "${data}" | \sed 's/&/_____AMP_____/g; s/</_____LT_____/g; s/>/_____GT_____/g; s/"/_____QUOT_____/g; s/'"'"'/_____CODE39_____/g' )
  fi
  if [ "${direction}" == 'backward' ]
  then
    data=$( printf "%s" "${data}" | \sed 's/_____AMP_____/\&/g; s/_____LT_____/\</g; s/_____GT_____/\>/g; s/_____QUOT_____/"/g; s/_____CODE39_____/'"'"'/g' )
  fi
  
  printf "%s\n" "${data}"
  return "${PASS}"
}

__handle_junit_xml_output_option()
{
  __handle_output_formatter_option "$( __extract_value 'JUNIT_XML_OPTIONS' )" $@
  return $?
}

__prepare_junit_xml_output_management()
{
  return "${PASS}"
}

__record_junit_xml_output_testfile_stream_4_suite()
{
  typeset data="$1"  
  typeset outputtype="${2:-'stdout'}"
  
  case "${outputtype}" in
  'stdout' ) outputtype='system-out';;
  'stderr' ) outputtype='system-err';;
  esac
  
  typeset junit_outputfile="$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )"
  
  [ -z "${junit_outputfile}" ] && return "${FAIL}"
  
  typeset xmlconvfile="$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/xmlconverted_file.txt"
  
  __convert_special_characters "${data}" 'forward' > "${xmlconvfile}"

  typeset line=
  while read -r -u 9 line
  do
    printf "%s\n" "         <${outputtype}>${line}</${outputtype}>" >> "${junit_outputfile}"
  done 9< "${xmlconvfile}"
  
  [ -f "${xmlconvfile}" ] && \rm -f "${xmlconvfile}"
  
  __replace_in_file_special_characters "${junit_outputfile}"
  return "${PASS}"
}

__replace_in_file_special_characters()
{
  typeset filename="$1"
  [ ! -f "${filename}" ] && return "${FAIL}"
  
  \sed 's/_____AMP_____/\&amp;/g; s/_____LT_____/\&lt;/g; s/_____GT_____/\&gt;/g; s/_____QUOT_____/\&quot;/g; s/_____CODE39_____/\&#39;/g' "${filename}" >> "${filename}.tmp"
  mv -f "${filename}.tmp" "${filename}"
  return "${PASS}"
}

can_record_stdout_stderr_junit_xml_output()
{
  printf "%d\n" "${YES}"
  return "${PASS}"
}

complete_junit_xml_output()
{
  typeset junit_output_file="$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )"
  
  typeset maptype
  typeset keyprefix

  [ -n "${junit_output_file}" ] && printf "%s\n" "</testsuites>" >> "${junit_output_file}"
  
  if [ $# -gt 0 ]
  then
    maptype='OVERALL'
    keyprefix='TOTAL'
  else
    maptype='SUBSYSTEM'
    keyprefix='SUBSYSTEM'
  fi

  ###
  ### Update the full statistics for all testsuites run
  ###

  xml_set_file --xmlfile "${junit_output_file}"
  typeset rootnode=$( xml_get_rootnode_name )
  
  __disable_xml_failure

  xml_edit_entry --xpath "//${rootnode}/@errors" --value "$( hget --map "$( __extract_value "${maptype}_MAP" )" --key "${keyprefix}_TESTS_ERROR_EXECUTION" )" --overwrite
  xml_edit_entry --xpath "//${rootnode}/@failures" --value "$( hget --map "$( __extract_value "${maptype}_MAP" )" --key "${keyprefix}_ASSERTIONS_FAIL" )" --overwrite
  xml_edit_entry --xpath "//${rootnode}/@skipped" --value "$( hget --map "$( __extract_value "${maptype}_MAP" )" --key "${keyprefix}_ASSERTIONS_SKIP" )" --overwrite

  typeset run_tests=$( hget --map "$( __extract_value "${maptype}_MAP" )" --key "${keyprefix}_TESTS_RUN" )
  typeset counted_tests=$( hget --map "$( __extract_value "${maptype}_MAP" )" --key "${keyprefix}_TESTS_COUNTED" )
  typeset disabled_count=$(( counted_tests - run_tests ))
    
  xml_edit_entry --xpath "//${rootnode}/@disabled" --value "${disabled_count}" --overwrite
  xml_edit_entry --xpath "//${rootnode}/@tests" --value "${run_tests}" --overwrite
  xml_edit_entry --xpath "//${rootnode}/@assertions" --value "$( hget --map "$( __extract_value "${maptype}_MAP" )" --key "${keyprefix}_ASSERTIONS" )" --overwrite
  xml_edit_entry --xpath "//${rootnode}/@time" --value "$( hget --map "$( __extract_value "${maptype}_MAP" )" --key "${keyprefix}_TIME" )" --overwrite
  xml_edit_entry --xpath "//${rootnode}/@test_time" --value "$( hget --map "$( __extract_value "${maptype}_MAP" )" --key "${keyprefix}_RUNTIME" )" --overwrite

  xml_delete_entry --xpath "//${rootnode}/@name" --overwrite
  
  __enable_xml_failure

  return "${PASS}"
}

complete_junit_xml_output_test_suite()
{
  [ -n "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )" ] && printf "%s\n" "   </testsuite>" >> "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )"
  return "${PASS}"
}

get_junit_xml_output_filename()
{
  printf "%s\n" "$( __extract_value 'JUNIT_XML_FILE' )"
  return "${PASS}"
}

get_subsystem_id_code_junit_xml_output()
{
  typeset xmlfile="$1"
  if [ ! -f "${xmlfile}" ]
  then
    printf "%d\n" 0
  else
    xml_set_file --xmlfile "${xmlfile}"
    
    typeset rootnode=$( xml_get_rootnode_name )
    xml_get_single_entry --xpath "//${rootnode}/testsuite" --field '@id' --format '%d'
  fi
  return "${PASS}"
}

initiate_junit_xml_output()
{
  __clear_output_formatter "$( __extract_value 'JUNIT_XML_MAP' )"
  [ $? -ne "${PASS}" ] && return "${FAIL}"

  typeset junit_output_file="$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )"
  if [ -n "${junit_output_file}" ]
  then
    printf "%s\n" "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> "${junit_output_file}"
    printf "%s\n" "<testsuites disabled=\"0\" errors=\"0\" failures=\"0\" name=\"$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TRUE_NAME' )\" tests=\"0\" time=\"0\" test_time=\"0\" assertions=\"0\">" >> "${junit_output_file}"
  fi
  return "${PASS}"
}

initiate_junit_xml_output_test_suite()
{
  [ -n "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )" ] && printf "%s\n" "   <testsuite name=\"$( __extract_value 'TEST_SUBSYSTEM' )\" package=\"$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TRUE_NAME' )\" disabled=\"0\" errors=\"0\" failures=\"0\" hostname=\"$( get_machine_ip )\" id=\"$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'SUBSYSTEM_ID' )\" assertions=\"0\" tests=\"0\" time=\"0\" skipped=\"\" timestamp=\"$( __extract_value 'DATE_UTC' )\">" >> "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )"
  return "${PASS}"
}

merge_junit_xml_output()
{
  typeset mergefile="$1"
  typeset finalfile="$2"
  
  [ ! -f "${mergefile}" ] && return "${FAIL}"
  
  \sed '1,2d;$d' "${mergefile}" >> "${finalfile}"
  return "${PASS}"  
}

record_junit_xml_output_testfile_error_4_suite()
{
  typeset data="$1"
  shift
  
  [ -z "${data}" ] && return "${FAIL}"
  [ -f "${data}" ] && data=$( cat "${data}" )

  __record_junit_xml_output_testfile_stream_4_suite "${data}" 'system-err'
  return "${PASS}"    
}

record_junit_xml_output_testfile_output_4_suite()
{
  typeset data="$1"
  shift
  
  [ -z "${data}" ] && return "${FAIL}"
  [ -f "${data}" ] && data=$( cat "${data}" )

  __record_junit_xml_output_testfile_stream_4_suite "${data}" 'system-out'
  return "${PASS}"
}

record_junit_xml_output_testfile_result_4_suite()
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
  typeset numasserts=0
  
  if [ "$(is_empty --str "${data}" )" -eq "${NO}" ]
  then
    passcnt=$( get_element --data "${data}" --id 1 --separator ':' )
    failcnt=$( get_element --data "${data}" --id 2 --separator ':' )
    skipcnt=$( get_element --data "${data}" --id 3 --separator ':' )
    numasserts=$(( passcnt + failcnt + skipcnt ))
  fi
  
  if [ -n "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )" ]
  then
    if [ "${rsttype}" == 'error' ]
    then
      printf "%s\n" "      <error classname=\"$( __extract_value 'TEST_SUBSYSTEM' ).${testname}\" name=\"${testname}\" id=\"${testid}\">Error condition encountered for ${testname}</error>" >> "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )"
    else
      printf "%s\n" "      <testcase classname=\"$( __extract_value 'TEST_SUBSYSTEM' ).${testname}\" name=\"${testname}\" id=\"${testid}\" time=\"${runtime}\" passcnt=\"${passcnt}\" failcnt=\"${failcnt}\" skipcnt=\"${skipcnt}\" assertions=\"${numasserts}\" status=\"${rsttype}\">" >> "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )"

      case "${rsttype}" in
      'fail'  ) printf "%s\n" "         <failure message=\"${cause}\"></failure>" >> "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )";;
      'skip'  ) printf "%s\n" "         <skipped message=\"skipped test\"></skipped>" >> "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )";;
      esac
  
      printf "%s\n" "      </testcase>" >> "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )"
    fi
  fi
  return "${PASS}"
}

record_junit_xml_output_settings_to_output()
{
  if [ -n "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )" ]
  then
    printf "%s\n" "     <properties>" >> "${filepath}"
  
    typeset propkeys=$( hkeys --map "$( __extract_value 'JUNIT_XML_MAP' )" )
    typeset pk=
    for pk in ${propkeys}
    do
      typeset value=$( hget --map "$( __extract_value 'JUNIT_XML_MAP' )" --key "${pk}" )
      printf "%s\n" "        <property name=\"${pk}\" value=\"${value}\">" >> "${filepath}"
    done
  
    printf "%s\n" "     </properties>" >> "${filepath}"
  fi
  
  return "${PASS}"
}

release_junit_xml_output()
{
  return "${PASS}"
}

set_junit_xml_output_filename()
{
  typeset filepath="$1"
  if [ -z "$1" ]
  then
    __set_internal_value 'JUNIT_XML_FULLPATH_FILE' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )/$( __extract_value 'JUNIT_XML_FILE' )"
  else
    __set_internal_value 'JUNIT_XML_FULLPATH_FILE' "${filepath}"
  fi
  return "${PASS}"
}

update_junit_xml_output_testsuite_stats()
{
  xml_set_file --xmlfile "$( __extract_value 'JUNIT_XML_FULLPATH_FILE' )"
  typeset rootnode=$( xml_get_rootnode_name )
  
  __disable_xml_failure
  
  xml_edit_entry --xpath "//${rootnode}/testsuite[@name='$( __extract_value 'TEST_SUBSYSTEM' )']/@errors" --value "$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_ERROR_EXECUTION' )" --overwrite
  xml_edit_entry --xpath "//${rootnode}/testsuite[@name='$( __extract_value 'TEST_SUBSYSTEM' )']/@tests" --value "$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_RUN' )" --overwrite
  xml_edit_entry --xpath "//${rootnode}/testsuite[@name='$( __extract_value 'TEST_SUBSYSTEM' )']/@failures" --value "$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_FAIL' )" --overwrite
  xml_edit_entry --xpath "//${rootnode}/testsuite[@name='$( __extract_value 'TEST_SUBSYSTEM' )']/@time" --value "$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_OVERALL_TIME' )" --overwrite
  xml_edit_entry --xpath "//${rootnode}/testsuite[@name='$( __extract_value 'TEST_SUBSYSTEM' )']/@skipped" --value "$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_SKIP' )" --overwrite
  
  __enable_xml_failure
  
  return "${PASS}"    
}
