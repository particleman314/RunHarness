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

if [ -z "${CANOPUS_EMAIL_FILE}" ]
then
  email_options_map=
  email_property_map=
  
  __set_internal_value 'EMAIL_MAP' 'email_property_map'
  __set_internal_value 'EMAIL_OPTIONS' 'email_options_map'
  __set_internal_value 'EMAIL_FILE' 'subsystem_results.email'
  __set_internal_value 'EMAIL_FULLPATH_FILE'
fi

[ -z "${SLCF_SHELL_TOP}" ] || [ -z "${PASS}" ] && return 1

. "${__HARNESS_TOPLEVEL}/utilities/outputs/output_support.sh"
[ $? -ne 0 ] && return 1

. "${__HARNESS_TOPLEVEL}/utilities/outputs/human_readable_output_support.sh"
[ $? -ne 0 ] && return 1

. "${SLCF_SHELL_TOP}/lib/emailmgt.sh"
[ $? -ne 0 ] && return 1

. "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
[ $? -ne 0 ] && return 1

__get_mail_recipients()
{
  typeset mail_recips=
  if [ -n "${MAILTO}" ]
  then
    mail_recips="$( printf "%s\n" "${MAILTO}" | \tr -s ' ' | \tr ' ' ',' | \tr ',' '\n' | \awk -F@ '{print $1}' | \sort | \uniq )"
  else
    if [ -n "$( __extract_value 'MAIL_RECIPIENTS' )" ]
    then
      mail_recips="$( __extract_value 'MAIL_RECIPIENTS' )"
    else
      mail_recips=$( __get_maintainer )
    fi
  fi
  
  typeset mail_recipient_options=
  typeset mr
  for mr in ${mail_recips}
  do
    mail_recipient_options+="--email-recipients ${mr} "
  done
  
  [ -n "${mail_recipient_options}" ] && printf "%s\n" "${mail_recipient_options}"

  return "${PASS}"
}

__handle_email_output_option()
{
  __handle_output_formatter_option "$( __extract_value 'EMAIL_OPTIONS' )" $@
  return $?
}

__prepare_email_output_management()
{
  typeset text_full_details_enabled="$( hget --map "$( __extract_value 'TEXT_OPTIONS' )" --key 'full_details' )"
  [ -n "${text_full_details_enabled}" ] && [ "${text_full_details_enabled}" -eq "${YES}" ] && hput --map "$( __extract_value 'EMAIL_OPTIONS' )" --key 'reuse_text_output' --value "${YES}"
  return "${PASS}"
}

can_record_stdout_stderr_email_output()
{
  printf "%d\n" "${NO}"
  return "${PASS}"
}

complete_email_output()
{
  return "${PASS}"
}

complete_email_output_test_suite()
{
  __complete_textual_output_test_suite "$( __extract_value 'EMAIL_FULLPATH_FILE' )"
  return $?
}

get_email_output_filename()
{
  printf "%s\n" "$( __extract_value 'EMAIL_FILE' )"
  return "${PASS}"
}

get_subsystem_id_code_email_output()
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

initiate_email_output()
{
  __clear_output_formatter "$( __extract_value 'EMAIL_MAP' )"
  [ $? -ne "${PASS}" ] && return "${FAIL}"
  return "${PASS}"
}

initiate_email_output_test_suite()
{
  typeset subsys_id=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'SUBSYSTEM_ID' )
  typeset keyword=$( __determine_header_entry )
  [ -n "$( __extract_value 'EMAIL_FULLPATH_FILE' )" ] && printf "%s\n%s\n" "${keyword} ${subsys_id} : Tests for << $( __extract_value 'TEST_SUBSYSTEM' ) >>" "$( __extract_value 'DBL_DIVIDER' )" >> "$( __extract_value 'EMAIL_FULLPATH_FILE' )"
  return "${PASS}"
}

merge_email_output()
{
  ### Possible to bootstrap from text_output
  typeset mergefile="$1"
  typeset finalfile="$2"

  [ ! -f "${mergefile}" ] && return "${FAIL}"
  
  printf "\n" >> "${finalfile}"
  \cat "${mergefile}" >> "${finalfile}"
  return "${PASS}"  
}

record_email_output_testfile_error_4_suite()
{
  __record_textual_output_testfile_error_4_suite "$( __extract_value 'EMAIL_FULLPATH_FILE' )" $@
  return $?
}

record_email_output_testfile_output_4_suite()
{
  __record_textual_output_testfile_output_4_suite "$( __extract_value 'EMAIL_FULLPATH_FILE' )" $@
  return $?
}

record_email_output_testfile_result_4_suite()
{
  return "${PASS}"
}

record_email_output_settings_to_output()
{
  __record_properties "$( __extract_value 'FULLPATH_FILE' )" "$( __extract_value 'EMAIL_MAP' )"
  return $?
}

release_email_output()
{
  ###
  ### There are four cases which can show up in the text/email format intertwining...
  ###   1) text_output/email_output  -->  full/full
  ###   2) text_output/email_output  -->  not-full/full
  ###   3) text_output/email_output  -->  not-full/not-full
  ###   4) text_output/email_output  -->  full/not-full
  ###
  ### Cases #1 and #3 should reuse the text_output already generated...
  ### Case #2 needs to add on from the output already generated by text_output
  ### Case #4 needs to skip doing any work since it does NOT copy from text_output
  ###
  typeset text_flag=$( default_value --def 0 "$( hget --map "$( __extract_value 'TEXT_OPTIONS' )" --key 'full_details' )" )
  typeset email_flag=$( default_value --def 0 "$( hget --map "$( __extract_value 'EMAIL_OPTIONS' )" --key 'full_details' )" )
  typeset release_file="$( __extract_value 'EMAIL_FULLPATH_FILE' ).final"
  
  typeset RC="${PASS}"
  if [ "${text_flag}" -eq "${email_flag}" ]
  then
    ### Case #1 and Case #3
    \cp -f "$( __extract_value 'TEXT_FULLPATH_FILE' ).final" "${release_file}"
  else
    if [ "${text_flag}" -eq "${YES}" ] && [ "${email_flag}" -eq "${NO}" ]
    then
      ### Case #4
      \cat "$( __extract_value 'TEXT_FULLPATH_FILE' ).header" "$( __extract_value 'EMAIL_FULLPATH_FILE' )" > "${release_file}"
    else
      ### Case #2
      release_file=$( __release_overall_information "$( __extract_value 'EMAIL_FULLPATH_FILE' )" )
      RC=$?
    fi
  fi
  
  if [ "${RC}" -eq "${PASS}" ]
  then
    typeset mail_recipient_options="$( __get_mail_recipients )"
    if [ -n "${mail_recipient_options}" ]
    then
      typeset title="$( hget --map "$( __extract_value 'EMAIL_OPTIONS' )" --key 'email_title' )"
      if [ $( is_empty --str "${title}" ) -eq "${YES}" ]
      then
        title='Results from CANOPUS Test Harness'
      else
        title="$( printf "%s\n" "${title}" | \sed -e "s#$( __extract_value 'SPACE_MARKER' )# #g" )"
      fi
      title+=" $( compute_reduced_pulse_index -p "$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_PASS' )" -f "$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_FAIL' )" -s "$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_SKIP' )" --scale 2 --format '%0.f' )% PASS"
      send_an_email --title "${title}" --current-user "$( __extract_value 'CURRENT_USER' )" ${mail_recipient_options} --file-to-send "${release_file}" --company 'ca.com'    
      RC=$?
    fi
  fi
  
  return "${RC}"
}

set_email_output_filename()
{
  typeset filepath="$1"
  if [ -z "$1" ]
  then
    __set_internal_value 'EMAIL_FULLPATH_FILE' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )/$( __extract_value 'EMAIL_FILE' )"
  else
    __set_internal_value 'EMAIL_FULLPATH_FILE' "${filepath}"
  fi
  return "${PASS}"
}

update_email_output_testsuite_stats()
{  
  ###
  ### There are four cases which can show up in the text/email format intertwining...
  ###   1) text_output/email_output  -->  full/full
  ###   2) text_output/email_output  -->  not-full/full
  ###   3) text_output/email_output  -->  not-full/not-full
  ###   4) text_output/email_output  -->  full/not-full
  ###
  ### Cases #1 and #3 should reuse the text_output already generated...
  ### Case #2 needs to add on from the output already generated by text_output
  ### Case #4 needs to skip doing any work since it does NOT copy from text_output
  ###
  typeset text_flag="$( default_value --def "${NO}" "$( hget --map "$( __extract_value 'TEXT_OPTIONS' )" --key 'full_details' )" )"
  typeset email_flag="$( default_value --def "${NO}" "$( hget --map "$( __extract_value 'EMAIL_OPTIONS' )" --key 'full_details' )" )"
  typeset use_map_io="$( default_value --def "${NO}" "$( hget --map "$( __extract_value 'EMAIL_OPTIONS' )" --key 'use_io' )" )"
  
  if [ "${text_flag}" -eq "${email_flag}" ]
  then
    ### Case #1 and Case #3
    \cp -f "$( __extract_value 'TEXT_FULLPATH_FILE' )" "$( __extract_value 'EMAIL_FULLPATH_FILE' )"
  else
    if [ "${text_flag}" -eq "${NO}" ] && [ "${email_flag}" -eq "${YES}" ]
    then
      ### Case #2
      \cp -f "$( __extract_value 'TEXT_FULLPATH_FILE' )" "$( __extract_value 'EMAIL_FULLPATH_FILE' )"
      
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
        if [ "${use_map_io}" -eq "${NO}" ]
        then
          hread_map --filename "${testmapfile}"
          tmap="$( hget_mapname --filename "${testmapfile}" )"
          utots_opt=" --map ${tmap}"
        else
          utots_opt=" --mapfile ${testmapfile}"
        fi
        __update_textual_output_testsuite_stats ${utots_opt} --path "$( __extract_value 'EMAIL_FULLPATH_FILE' )"  --map-options "$( __extract_value 'EMAIL_OPTIONS' )"
        [ "${use_map_io}" -eq "${NO}" ] && hclear --map "${tmap}"
      done
    fi
  fi
  return "${PASS}"    
}
