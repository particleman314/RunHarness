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
# Functions Supplied:
#
#    __add_global_tags_from_file
#    __discover_arguments_for_test
#    __discover_dependencies_for_test
#    __discover_expected_result_for_test
#    __get_file_setting_info
#
###############################################################################

__add_global_tags_from_file()
{
  typeset global_tags="$1"
  [ -z "${global_tags}" ] && return "${FAIL}"
  
  ###
  ### Make sure all tags are unique
  ###
  global_tags="$( printf "%s\n" ${global_tags} | \sort | \uniq | \tr '\n' ' ' )"
  
  __set_internal_value 'TAG' "${global_tags}"
  __set_internal_value 'USE_TAGS' "${YES}"

  return "${PASS}"
}

__discover_arguments_for_test()
{
  typeset testname=

  OPTIND=1
  while getoptex "t: test:" "$@"
  do
    case "${OPTOPT}" in
    't'|'test' ) testname="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ $( is_empty --str "${testname}" ) -eq "${YES}" ] && return "${FAIL}"

  __handle_spaced_output "$( __get_file_setting_info "${testname}" 'Arguments:' )"
  return $?
}

__discover_dependencies_for_test()
{
  typeset testname=

  OPTIND=1
  while getoptex "t: test:" "$@"
  do
    case "${OPTOPT}" in
    't'|'test' ) testname="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ $( is_empty --str "${testname}" ) -eq "${YES}" ] && return "${FAIL}"

  __handle_spaced_output "$( __get_file_setting_info "${testname}" 'Dependencies:' )"
  return $?
}

__discover_expected_result_for_test()
{
  typeset testname=

  OPTIND=1
  while getoptex "t: test:" "$@"
  do
    case "${OPTOPT}" in
    't'|'test' ) testname="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ $( is_empty --str "${testname}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset expected_return_val="$( default_value --def "${PASS}" $( __get_file_setting_info "${testname}" 'Expected Result:' ) )"
  printf "%s\n" "$( __handle_spaced_output "eq ${expected_return_val}" )"
  return $?
}

__get_file_setting_info()
{
  typeset in_filename="$1"
  [ ! -f "${in_filename}" ] && return "${FAIL}"
  
  typeset field_id="$2"
  typeset match_text="$( \cat "${in_filename}" | \grep "${field_id}" )"

  if [ -n "${match_text}" ]
  then
    match_text="$( printf "%s\n" "${match_text}" | \tr -s ' ' | \tr -s '/' | \tr -s '#' )"  #  This is a prescribed means to encode basic info
    printf "%s\n" "${match_text}" | \sed -e "s#[/#]\(\s*\)\(\w*\)${field_id}\(\s*\)##"
  fi
  
  return "${PASS}"    
}

__seen_tag_header()
{
  typeset new_header="$1"
  typeset seen_headers="$2"
  
  printf "%s\n" ${seen_headers} | \grep -q "${new_header}"
  if [ $? -eq "${PASS}" ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"
}

