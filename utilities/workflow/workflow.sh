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
# Software Package : Shell Automated Testing -- Test Framework Workflow Utilities
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __register_file_in_workflow
#    __request_previous_stage_location
#    __request_workflow_stage_id
#    __request_workflow_stage_location
#    __request_workflow_stage_name
#
###############################################################################

__register_file_in_workflow()
{
  typeset RC="${PASS}"
  typeset input="$1"
  typeset content="$2"
  
  [ $( is_empty --str "${content}" ) -eq "${YES}" ] || [ $( is_empty --str "${input}" ) -eq "${YES}" ] && return "${FAIL}"

  hadd_item --map "$( __extract_value 'WORKFLOW_MAP' )" --key "${input}_content" --value "${content}"
  return $?
}

__request_previous_stage_location()
{
  typeset RC="${PASS}"
  typeset current_stage_id=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'SUBSYSTEM_ID' )
  if [ $( is_empty --str "${current_stage_id}" ) -eq "${YES}" ] || [ $( is_numeric_data --data "${current_stage_id}" ) -ne "${YES}" ]
  then
    return "${FAIL}"
  fi
  
  typeset previous_stage_id=$(( current_stage_id - 1 ))
  [ "${previous_stage_id}" -le 0 ] && return "${FAIL}"
  
  __request_workflow_stage_location "${previous_stage_id}"
  return $?
}

__request_workflow_stage_id()
{
  typeset stagename="$1"
  [ $( is_empty --str "${stagename}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_empty --str "$( __extract_value 'WORKFLOW_MAPNAME' )" ) -eq "${YES}" ] || [ $( hexists_map --map "$( __extract_value 'WORKFLOW_MAPNAME' )" ) -eq "${NO}" ] && return "${FAIL}"
  
  typeset matched_stage_id=$( hget --map "$( __extract_value 'WORKFLOW_MAPNAME' )" --key "${stagename}" )
  [ -n "${matched_stage_id}" ] && printf "%s\n" "${matched_stage_id}" | \sed -e 's#^STAGE_##'
  return "${PASS}"
}

__request_workflow_stage_location()
{
  typeset RC="${PASS}"
  typeset current_subsys_id="$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'SUBSYSTEM_ID' )"
  typeset input="$1"
  typeset match=0
  
  [ $( is_empty --str "${input}" ) -eq "${YES}" ] && return "${FAIL}"
  
  if [ $( is_numeric_data --data "${input}" ) -ne "${YES}" ]
  then
    match="$( __request_workflow_stage_id "${input}" )"
    [ $( is_empty --str "${match}" ) -eq "${YES}" ] && return "${FAIL}"
  else
    match="${input}"
  fi
  [ "${match}" -gt "${current_subsys_id}" ] && return "${FAIL}"

  hget --map "$( __extract_value 'WORKFLOW_MAP' )" --key "STAGE_${match}_OUTPUT"
  RC=$?
  return "${RC}"
}

__request_workflow_stage_name()
{
  typeset stageid="$1"
  if [ $( is_empty --str "${stageid}" ) -eq "${YES}" ] || [ $( is_numeric_data --data "${stageid}" ) -ne "${YES}" ] || [ "${stageid}" -lt 0 ]
  then
    return "${FAIL}"
  fi
  [ $( is_empty --str "$( __extract_value 'WORKFLOW_MAPNAME' )" ) -eq "${YES}" ] || [ $( hexists_map --map "$( __extract_value 'WORKFLOW_MAPNAME' )" ) -eq "${NO}" ] && return "${FAIL}"
  
  typeset matched_stagename=$( hget --map "$( __extract_value 'WORKFLOW_MAPNAME' )" --key "STAGE_${stageid}" )
  [ -n "${matched_stagename}" ] && printf "%s\n" "${matched_stagename}"
  return "${PASS}"
}
