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

if [ -n "${SLCF_SHELL_TOP}" ] && [ -d "${SLCF_SHELL_TOP}/lib" ]
then
  . "${SLCF_SHELL_TOP}/lib/hashmaps.sh"
  [ $? -ne 0 ] && return 1
else
  return 1
fi

__cache_recorded_value()
{
  typeset name=
  typeset value=
  typeset mapname=
  
  OPTIND=1
  while getoptex "m: map-name: n: name: v: value:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map-name'  ) mapname="${OPTARG}";;
    'n'|'name'      ) name="${OPTARG}";;
    'v'|'value'     ) value="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${name}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_empty --str "${name}" ) -eq "${YES}" ] || [ $( is_empty --str "${value}" ) -eq "${YES}" ] && return "${FAIL}"
  hadd_item --map "${mapname}" --key "${name}" --value "${value}"
  return $?
}

__clear_output_formatter()
{
  typeset mapname="$1"
  [ $( is_empty --str "${mapname}" ) -eq "${YES}" ] && return "${FAIL}"
  hclear --map "${mapname}"
  return "${PASS}"
}

__handle_output_formatter_option()
{
  typeset mapname="$1"
  typeset kvpair="$2"

  [ $( is_empty --str "${kvpair}" ) -eq "${YES}" ] || [ $( is_empty --str "${mapname}" ) -eq "${YES}" ] && return "${FAIL}"

  ###
  ### First field is the formatter name which is no longer needed
  ###
  typeset key="$( get_element --data "${kvpair}" --id 2 --separator ':' )"
  typeset val="$( get_element --data "${kvpair}" --id 3 --separator ':' )"

  hput --map "${mapname}" --key "${key}" --value "${val}"
  return "${PASS}"
}

__record_properties()
{
  typeset fullpath_file="$1"
  typeset mapname="$2"
  shift 2
  
  [ $( is_empty --str "${mapname}" ) -eq "${YES}" ] && return "${FAIL}"
  
  if [ -n "${fullpath_file}" ]
  then
    printf "%s\n" "Properties : " >> "${fullpath_file}"
  
    typeset propkeys=$( hkeys --map "${mapname}" )
    typeset pk
    for pk in ${propkeys}
    do
      typeset value=$( hget --map "${mapname}" --key "${pk}" )
      printf "%s\n" "${pk} = ${value}" >> "${fullpath_file}"
    done
  fi
  
  return "${PASS}"
}
