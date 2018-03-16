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

if [ -z "$( __extract_value 'TEXT_FILE' )" ]
then
  text_options_map=
  text_property_map=
  
  __set_internal_value 'TEXT_MAP' 'text_property_map'
  __set_internal_value 'TEXT_OPTIONS' 'text_options_map'
  __set_internal_value 'TEXT_FILE' 'subsystem_results.txt'
  __set_internal_value 'TEXT_FULLPATH_FILE'
fi

[ -z "${SLCF_SHELL_TOP}" ] || [ -z "${PASS}" ] && return 1

. "${__HARNESS_TOPLEVEL}/utilities/outputs/.output_support.sh"
[ $? -ne 0 ] && return 1

. "${__HARNESS_TOPLEVEL}/utilities/outputs/.human_readable_output_support.sh"
[ $? -ne 0 ] && return 1

. "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
[ $? -ne 0 ] && return 1

__handle_text_output_option()
{
  __handle_output_formatter_option "$( __extract_value 'TEXT_OPTIONS' )" $@
  return $?
}

__prepare_text_output_management()
{
  return "${PASS}"
}

can_record_stdout_stderr_text_output()
{
  printf "%d\n" "${NO}"
  return "${PASS}"
}

complete_text_output()
{
  return "${PASS}"
}

complete_text_output_test_suite()
{
  __complete_textual_output_test_suite "$( __extract_value 'TEXT_FULLPATH_FILE' )"
  return $?
}

get_subsystem_id_code_text_output()
{
  typeset f="$1"
  if [ ! -f "${f}" ]
  then
    printf "%s\n" 0
  else
    \head -n 1 "${f}" | \cut -f 2 -d ' '
  fi
  return "${PASS}"
}

get_text_output_filename()
{
  printf "%s\n" "$( __extract_value 'TEXT_FILE' )"
  return "${PASS}"
}

initiate_text_output()
{
  __clear_output_formatter "$( __extract_value 'TEXT_MAP' )"
  [ $? -ne "${PASS}" ] && return "${FAIL}"
  return "${PASS}"
}

initiate_text_output_test_suite()
{
  typeset subsys_id=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'SUBSYSTEM_ID' )
  typeset keyword=$( __determine_header_entry )
  
  typeset fullsize=$( __get_char_count --non-file "$( __extract_value 'DBL_DIVIDER' )" )
  typeset spacersize=$(( fullsize -3 -16 -$( __get_char_count --non-file "${keyword}" ) -$( __get_char_count --non-file "${subsys_id}" ) -$( __get_char_count --non-file "$( __extract_value 'TEST_SUBSYSTEM' )" )))
  typeset spacer=$( printf "%${spacersize}s" '-' | \tr '-' ' ' )

  [ -n "$( __extract_value 'TEXT_FULLPATH_FILE' )" ] && printf "%s\n%s\n" "${keyword} ${subsys_id} :${spacer}Tests for << $( __extract_value 'TEST_SUBSYSTEM' ) >>" "$( __extract_value 'DBL_DIVIDER' )" >> "$( __extract_value 'TEXT_FULLPATH_FILE' )"
  return "${PASS}"
}

merge_text_output()
{
  typeset mergefile="$1"
  typeset finalfile="$2"

  [ ! -f "${mergefile}" ] && return "${FAIL}"
  
  printf "\n" >> "${finalfile}"
  \cat "${mergefile}" >> "${finalfile}"
  return "${PASS}"  
}

record_text_output_testfile_error_4_suite()
{
  __record_textual_output_testfile_error_4_suite "$( __extract_value 'TEXT_FULLPATH_FILE' )" "$@"
  return $?
}

record_text_output_testfile_output_4_suite()
{
  __record_textual_output_testfile_output_4_suite "$( __extract_value 'TEXT_FULLPATH_FILE' )" "$@"
  return $?
}

record_text_output_testfile_result_4_suite()
{
  return "${PASS}"
}

record_text_output_settings_to_output()
{
  __record_properties "$( __extract_value 'TEXT_FULLPATH_FILE' )" "$( __extract_value 'TEXT_MAP' )"
  return $?
}

release_text_output()
{
  typeset release_file=$( __release_overall_information "$( __extract_value 'TEXT_FULLPATH_FILE' )" )
  return $?
}

set_text_output_filename()
{
  typeset filepath="$1"
  if [ -z "$1" ]
  then
    __set_internal_value 'TEXT_FULLPATH_FILE' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )/$( __extract_value 'TEXT_FILE' )"
  else
    __set_internal_value 'TEXT_FULLPATH_FILE' "${filepath}"
  fi
  return "${PASS}"
}

update_text_output_testsuite_stats()
{
  record_step ${HOTSPOT_ARGS} --header 'testsuite_stats' --msg "Starting update of output information via [ text output ] formatter..."

  typeset full_details="$( default_value --def "${NO}" "$( hget --map "$( __extract_value 'TEXT_OPTIONS' )" --key 'full_details' )" )"
  typeset use_map_io="$( default_value --def "${NO}" "$( hget --map "$( __extract_value 'TEXT_OPTIONS' )" --key 'use_io' )" )"
  
  if [ "${full_details}" -eq "${YES}" ]
  then
    typeset true_name="$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TRUE_NAME' )"
    typeset subsysmapfile="$( __extract_value 'TEST_SUITES' )/${true_name}_class.map"
    
    [ ! -f "${subsysmapfile}" ] && return "${PASS}"
    
    typeset testnames
    if [ "${use_map_io}" -eq "${NO}" ]
    then
      hread_map --filename "${subsysmapfile}"
      typeset smap="$( hget_mapname --filename "${subsysmapfile}" )"
      testnames="$( __access_data --map "${smap}" --key 'suite_tests' )"
      hclear --map "${smap}"
    else
      testnames="$( __access_data --mapfile "${subsysmapfile}" --key 'suite_tests' )"
    fi
    
    typeset tn
    for tn in ${testnames}
    do
      typeset testmapfile="$( __extract_value 'TEST_SUITES' )/${true_name}/${tn}.map"
      typeset tmap
      typeset utots_opt
      if [ "${use_map_io}" -eq "${NO}" ]
      then
        hread_map --filename "${testmapfile}"
        tmap="$( hget_mapname --filename "${testmapfile}" )"
        utots_opt=" --map ${tmap}"
      else
        utots_opt=" --mapfile ${testmapfile}"
      fi
      __update_textual_output_testsuite_stats ${utots_opt} --path "$( __extract_value 'TEXT_FULLPATH_FILE' )" --map-options "$( __extract_value 'TEXT_OPTIONS' )"
      [ "${use_map_io}" -eq "${NO}" ] && hclear --map "${tmap}"
    done
  fi
  return "${PASS}"    
}
