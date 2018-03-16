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

file_builder_extension='.explode'

__check_text_for_define()
{
  typeset line="$1"
  [ $( is_empty --str "${line}" ) -eq "${YES}" ] && return "${FAIL}"
  
  ###
  ### Handle @define instructions for setting variables to be used in
  ###  future processing.
  ###
  ### E.g.  :  @define MYVAR="ABCDEFG HIJK LMNOP"
  ###
  printf "%s\n" "${line}" | \grep -q '@define'
  if [ $? -eq "${PASS}" ]
  then
    typeset kvpair=$( printf "%s\n" "${line}" | \cut -f 2- -d ' ' )
    typeset key=$( printf "%s\n" "${kvpair}" | \cut -f 1 -d '=' )
    typeset value=$( printf "%s\n" "${kvpair}" | \cut -f 2 -d '=' )

    memopts=$( __import_variable --key "${key}" --value "${value}" --use-memory "${YES}" )
    eval "${memopts}"

    append_output --data "Defined : << ${key} >> with value << ${value} >> for use in processing of stages/suites" --channel "$( __define_internal_variable 'CMD' )"
    return "${PASS}"
  fi
  return "${FAIL}"
}

__explode_text_file()
{
  typeset filename="$1"
  typeset tmpfile="$2"
  typeset search_dir="$3"
  
  ###
  ### Strip away comment lines upfront to provide quicker parsing
  ###  
  \awk -F'#' '{if ( length($1) > 0 ) print $1}' "${filename}" > "${tmpfile}"

  ###
  ### Explode the file in the event there are includes and those includes have includes...
  ###
  typeset modification="${YES}"
  while [ "${modification}" -ne "${NO}" ]
  do
    modification="${NO}"
    while read -r -u 9 line
    do
      ###
      ### Remove excess comments and empty lines, trim excess whitespace
      ###   and validate the instruction to process is indeed a known
      ###   instruction keyword
      ###
      line="${line%%#*}"
      [ $( is_empty --str "${line}" ) -eq "${YES}" ] && continue

      ###
      ### Trim out excess whitespace in line and extract the instruction from the line
      ###
      line=$( trim "${line}" )
      line=$( __internal_substitute "${line}" )  ### Allows for re-use of internal defined variables
      line=$( __substitute "${line}" )           ### Allows for pre-defined variables

      __check_text_for_define "${line}"
      [ $? -eq "${PASS}" ] && continue
     
      printf "%s\n" "${line}" | \grep -q "@include"
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        typeset subfile="$( get_element --data "${line}" --id 2 --separator ' ' )"
        if [ ! -f "${subfile}" ] && [ -n "${search_dir}" ] && [ -d "${search_dir}" ]
        then
          found_subfile=$( \find "${search_dir}" -name "${subfile}" | \head -n 1 )
          if [ -z "${found_subfile}" ] || [ ! -f "${found_subfile}" ]
          then
            print_btf_detail --msg "Unable to locate file << ${subfile} >> for include processing" --prefix "$( __extract_value 'PREFIX_WARN' )"
            continue
          else
            subfile="${found_subfile}"
          fi
        fi
        
        if [ -n "${search_dir}" ]
        then
          \cat "${subfile}" >> "${tmpfile}${file_builder_extension}"
          modification="${YES}"
        else
          if [ -f "${subfile}" ]
          then
            \cat "${subfile}" >> "${tmpfile}${file_builder_extension}"
            modification="${YES}"
          fi
        fi
      else
        printf "%s\n" "${line}" >> "${tmpfile}${file_builder_extension}"
      fi
    done 9< "${tmpfile}"
    
    if [ -f "${tmpfile}${file_builder_extension}" ]
    then
      \mv -f "${tmpfile}${file_builder_extension}" "${tmpfile}"
    else
      print_btf_detail --msg 'Problem encountered for parsing input file for explosion substitution' --prefix "$( __extract_value 'PREFIX_ERROR' )"
      log_error 'Problem encountered for parsing input file for explosion substitution'
      return "${FAIL}"
    fi
  done
  
  return "${PASS}"  
}

__find_text_subsection_in_file()
{
  typeset filename
  typeset outputfile
  typeset startpt

  OPTIND=1
  while getoptex "origfile: outfile: t: tag:" "$@"
  do
    case "${OPTOPT}" in
        'origfile'   ) filename="${OPTARG}";;
        'outfile'    ) outputfile="${OPTARG}";;
    't'|'tag'        ) startpt="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset startline=$( \grep -n "$( __extract_value 'KEYWORD_TAG_GROUP' )${startpt}:" "${filename}" )
  [ -z "${startline}" ] && return "${FAIL}"
  
  startline=$( get_element --data "${startline}" --id 1 --separator ':' )
  typeset othermarkers=$( \grep -n "$( __extract_value 'KEYWORD_TAG_GROUP' )" "${filename}" | \cut -f 1 -d ':' | \tr '\n' ' ' )
  typeset endline=-1
  
  typeset lindx
  for lindx in ${othermarkers}
  do
    [ "${lindx}" -le "${startline}" ] && continue
    endline=$(( ${lindx} - 1 ))
    startline=$(( ${startline} + 1 ))
    break
  done
  
  [ "${endline}" -gt -1 ] && copy_file_segment --filename "${filename}" -b "${startline}" -e "${endline}" --outputfile "${outputfile}"
  return "${PASS}"
}

__handle_txt_dependency_input()
{
  typeset filename="$1"
  [ -z "${filename}" ] || [ ! -f "${filename}" ] && return "${FAIL}"
  
  typeset line
  while read -r -u 7 line
  do
    line=$( trim "${line}" )
    line=$( printf "%s\n" "${line}" | \sed -e 's#\s*-*>\s*#|#g' )
          
    typeset id=$( get_element --data "${line}" --id 1 --separator ':' )
    typeset edep=$( get_element --data "${line}" --id 2 --separator ':' )
    
    __handle_dependency_push "${edep}" "${id}"
  done 7<"${filename}"
  
  return "${PASS}"
}

###
### Handle reading TXT structure input as tag selection file
###
__handle_txt_tagselect_input()
{
  typeset filename="$1"
  typeset startpt="$2"
  
  typeset RC

  typeset tmpfile="$( __extract_value 'RESULTS_DIR' )/$( \basename "${filename}" )"
  tmpfile=$( remove_extension "${tmpfile}" )
  tmpfile+="_$( __extract_value 'START_TIME' ).tmp"
  __explode_text_file "${filename}" "${tmpfile}" "${__HARNESS_TOPLEVEL}/drivers/tags"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  
  typeset globaltags=
  typeset directive_q=
  typeset seen_headers=
  
  queue_add --object 'directive_q' --data "${startpt}"
  
  typeset new_entry="${NO}"

  typeset keywords="$( __extract_value 'TAG_PARSING_KEYWORDS' )"
    
  while [ $( queue_size --object 'directive_q' ) -gt 0 ]
  do
    ###
    ### Remove the current pointer and begin processing
    ###
    queue_add --object 'seen_headers' --data "$( queue_offer --object 'directive_q' )"
    
    typeset subsectionfile="${tmpfile}___${startpt}.subsection"
    __find_text_subsection_in_file --origfile "${tmpfile}" --outfile "${subsectionfile}" --tag "${startpt}"
    RC=$?
    
    [ "${RC}" -ne "${PASS}" ] || [ ! -f "${subsectionfile}" ] && return "${FAIL}"

    typeset line
    while read -r -u 9 line
    do
      ###
      ### Remove excess comments and empty lines, trim excess whitespace
      ###   and validate the instruction to process is indeed a known
      ###   instruction keyword
      ###
      line="${line%%#*}"
      [ $( is_empty --str "${line}" ) -eq "${YES}" ] && continue

      ###
      ### Trim out excess whitespace in line and extract the instruction from the line
      ###
      line=$( trim "${line}" )
      typeset instruction=$( printf "%s\n" "${line}" | \cut -f 1 -d ':' )

      ###
      ### If the instruction is not in the approved list, then skip this line and move to the next one
      ###
      printf "%s\n" ${keywords} | \grep -q "${instruction}"
      RC=$?
      [ "${RC}" -ne "${PASS}" ] && continue
    
      ###
      ### Go through each keyword to see if it is present and has data associated
      ###   with it for purposes of processing
      ###
      typeset tag_ID="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TAG_DEFECT' ):" )"
      [ -z "${tag_ID}" ] && tag_ID="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TAG_USERSTORY' ):" )"
      [ -z "${tag_ID}" ] && tag_ID="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TAG_ADDONTAG' ):" )"
      typeset see_section="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TAG_SEEALSO' ):" )"

      if [ -n "${tag_ID}" ]
      then
        tag_ID="$( get_element --data "${tag_ID}" --id 1 --separator ' ' )"
        list_add --object 'globaltags' --data "${tag_ID}"
      fi
      if [ -n "${see_section}" ] && [ "$( __check_for --key 'NO_TAG_RECURSION' --failure )" -eq "${YES}" ]
      then
        [ $( __seen_tag_header "${see_section}" "$( queue_data --object 'seen_headers' )" ) -eq "${NO}" ] && queue_add --object 'directive_q' --data "${see_section}"
      fi
        
    done 9< "${subsectionfile}"
    \rm -f "${subsectionfile}"
    startpt="$( trim "$( queue_offer --object 'directive_q' )" )"
  done
  
  [ -f "${tmpfile}" ] && \rm -f "${tmpfile}"

  __add_global_tags_from_file "$( list_data --object 'globaltags' )"
  RC=$?
  
  list_clear --object 'globaltags'
  queue_clear --object 'seen_headers'
  queue_clear --object 'directive_q'
  
  return "${RC}"
}

###
### Handle reading TXT structure input as driver file
###
__handle_txt_test_input()
{
  typeset filename="$1"
  typeset default_id=1
  typeset suite_num_id=0
  typeset test_num_id=1
  
  typeset new_entry="${NO}"
  
  typeset current_suite_subject=
  typeset current_suite_path=
  typeset current_suite_id=
  typeset current_suite_drv=
  typeset current_suite_lang=
  typeset current_test_drv=
  typeset current_test_setup_drv=
  typeset current_test_lang=
  typeset current_test_tags=
  typeset current_test_deps=
  typeset current_test_args=
  typeset current_test_result="$( __handle_spaced_output "eq ${PASS}" )"
  
  ###
  ### Strip away comment lines upfront to provide quicker parsing
  ###  
  typeset tmpfile="$( __extract_value 'RESULTS_DIR' )/$( \basename "${filename}" )"
  tmpfile=$( remove_extension "${tmpfile}" )
  tmpfile+="_$( __extract_value 'START_TIME' ).tmp"
  __explode_text_file "${filename}" "${tmpfile}"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  
  \mv -f "${tmpfile}" "${tmpfile}${file_builder_extension}"

  ###
  ### Clean out an remaining comment lines
  ###
  \awk -F'#' '{if ( length($1) > 0 ) print $1}' "${tmpfile}${file_builder_extension}" > "${tmpfile}"

  ###
  ### Store away the expanded file to ensure we can back track to what was done and
  ###   what was declared to be done
  ###
  __register_cleanup "${tmpfile}${file_builder_extension}" inputs

  typeset RC
  typeset line
  typeset outputline=
  
  typeset keywords="$( __extract_value 'INPUT_TXT_PARSING_KEYWORDS' )"
  
  while read -r -u 9 line
  do
    ###
    ### Remove excess comments and empty lines, trim excess whitespace
    ###   and validate the instruction to process is indeed a known
    ###   instruction keyword
    ###
    line="${line%%#*}"
    [ $( is_empty --str "${line}" ) -eq "${YES}" ] && continue

    ###
    ### Trim out excess whitespace in line and extract the instruction from the line
    ###
    line=$( trim "${line}" )
    typeset instruction=$( printf "%s\n" "${line}" | \cut -f 1 -d ':' )

    ###
    ### If the instruction is not in the approved list, then skip this line and move to the next one
    ###
    printf "%s\n" ${keywords} | \grep -q "${instruction}"
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && continue
   
    ###
    ### Go through each keyword to see if it is present and has data associated
    ###   with it for purposes of processing
    ###
    typeset suite_dir_setting="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_SUITEDIR' ):" )"
    typeset suite_group_id="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_SUITEID' ):" )"
    typeset suite_subject="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_SUITESUBJECT' ):" )"
    typeset suite_lang="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_SUITELANGUAGE' ):" )"
    typeset suite_driver="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_SUITEDRIVER' ):" )"
    typeset suite_tags=="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_SUITETAG' ):" )"
    
    typeset test_setupdrv="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TESTSETUPDRIVER' ):" )"
    typeset testname="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TESTNAME' ):" )"
    typeset testargs="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TESTARGUMENT' ):" )"
    typeset testlang="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TESTLANGUAGE' ):" )"
    typeset testdrv="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TESTDRIVER' ):" )"
    typeset testtags="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TESTTAG' ):" )"
    typeset testdeps="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TESTDEPENDENCY' ):" )"
    typeset testresult="$( __check_keyword "${line}" "$( __extract_value 'KEYWORD_TESTRESULT' ):" )"

    ###
    ### Starting a new suite/stage
    ###
    if [ -n "${suite_dir_setting}" ]
    then
      suite_num_id=$( increment "${suite_num_id}" )
      
      ###
      ### Give a default name for the ID in the event one is NOT specified (incremented aautomatically)
      ###
      if [ $( __check_for --key 'WORKFLOW' --success ) -eq "${YES}" ]
      then
        [ $( is_empty --str "${current_suite_id}" ) -eq "${YES}" ] && current_suite_id="$( default_value --def "STAGE_${suite_num_id}" "${suite_group_id}" )"
      else
        [ $( is_empty --str "${current_suite_id}" ) -eq "${YES}" ] && current_suite_id="$( default_value --def "SUITE_${suite_num_id}" "${suite_group_id}" )"
      fi
      
      default_id=$( increment ${default_id} )
      
      ###
      current_suite_subject="$( to_upper "$( __handle_spaced_output "$( \basename "${suite_dir_setting}" )" )" )"
      current_suite_path="$( __handle_spaced_output "${suite_dir_setting}" )"
      
      new_entry="${YES}"
      if [ -n "${outputline}" ]
      then
        [ ! -f "${current_test_setup_drv}" ] && current_test_setup_drv=  ### Might need to check is absolute path before checking existence
        if [ $( is_empty --str "${testname}" ) -eq "${YES}" ]
        then
          printf "%s\n" "${outputline}:::${current_test_drv}:${current_test_setup_drv}:A${current_test_args}:${current_test_deps}:${current_test_tags}:${current_test_result}"
        else
          printf "%s\n" "${outputline}:${testname}:${test_num_id}:${current_test_drv}:${current_test_setup_drv}:A${current_test_args}:${current_test_deps}:${current_test_tags}:${current_test_result}"
        fi
        outputline=
      fi

      ###
      ### Initialize the "current settings" now for the new suite and test related data...
      ###
      current_suite_drv=
      current_suite_lang=
      
      current_test_setup_drv=
      current_test_args=
      current_test_tags=
      current_test_deps=
      current_test_drv=
      current_test_lang=
      current_test_result="$(__handle_spaced_output "eq ${PASS}" )"
      
      test_num_id=1
      outputline="${current_suite_path}:${current_suite_id}:${current_suite_subject}:${current_suite_lang}:${current_suite_drv}:${suite_num_id}"  # Suite parameters
      continue
    fi
   
    ###
    ### Ensure proper setting for each "batch" are sufficient
    ###
    [ -n "${suite_subject}" ]  && current_suite_subject="$( __handle_spaced_output "${suite_subject}" )"
    if [ -n "${suite_group_id}" ]
    then
      current_suite_id="$( __handle_spaced_output "${suite_group_id}" )"
      [ $( is_empty --str "${current_test_setup_drv}" ) -eq "${NO}" ] && [ -f "${current_suite_path}/__setup_${current_suite_id}.sh" ] && current_test_setup_drv="${current_suite_path}/__setup_${current_suite_id}.sh"
    fi
    
    [ -n "${suite_lang}" ]  && current_suite_lang="$( __handle_spaced_output "${suite_lang}" )"    
    [ -n "${suite_driver}" ]  && current_suite_drv="$( __handle_spaced_output "${suite_driver}" )"
    
    [ -n "${test_setupdrv}" ]  && current_test_setup_drv="$( __handle_spaced_output "${test_setupdrv}" )"
    
    [ -n "${testlang}" ]  && current_test_lang="$( __handle_spaced_output "${testlang}" )"
    [ -n "${testdrv}" ]  && current_test_drv="$( __handle_spaced_output "${testdrv}" )"
    [ -n "${testtags}" ] && current_test_tags="$( __handle_spaced_output "${testtags}" )"
    [ -n "${testargs}" ] && current_test_args+=" ${testargs}"

    [ -n "${testresult}" ] && current_test_result="$( __handle_spaced_output "${testresult}" )"

    ###
    ### Handle dependencies separately
    ###
    if [ -n "${testdeps}" ]
    then
      if [ -f "${testdeps}" ]
      then
        current_test_deps=$( parse_dependency_file --filename "${testdeps}" --id "${current_id}" )
      else
        typeset entries=$( printf "%s\n" "${testdeps}" | \sed -e 's# ##g' | \tr '|' '\n' )
        typeset edep
        for edep in ${entries}
        do
          edep=$( trim "${edep}" )
          edep=$( printf "%s\n" "${edep}" | \sed -e 's#\s*-*>\s*#|#g' )
          
          __handle_dependency_push "${edep}" "${current_id}"
        done
      fi
    fi
    
    ###
    ### If there is no suite path definition, then skip this since it is invalid
    ###
    if [ -$( is_empty --str "${current_suite_path}" ) -eq "${YES}" ]
    then
      new_entry="${NO}"
      continue
    fi
    
    ###
    ### Starting recording information with translation into "group batch file" format
    ###
    ### [ current_suite_path ]      Slot position 1  --> suite_path
    ### [ current_suite_id ]        Slot position 2  --> suite_id
    ### [ current_suite_subject ]   Slot position 3  --> suite_subject
    ### [ current_suite_lang ]      Slot position 4  --> suite_language
    ### [ current_suite_drv ]       Slot position 5  --> suite_driver
    ### [ suite_num_id ]            Slot position 6  --> [ internal generation ]
    ### [ testname ]                Slot position 7  --> test_name
    ### [ test_num_id ]             Slot position 8  --> [ internal generation ]
    ### [ current_test_drv ]        Slot position 9  --> test_driver
    ### [ current_test_setup_drv ]  Slot position 10 --> test_setup_driver
    ### [ current_test_args ]       Slot position 11 --> test_arguments
    ### [ current_test_deps ]       Slot position 12 --> other test dependencies
    ### [ current_test_tags ]       Slot position 13 --> test_tags
    ### [ current_test_result ]     Slot position 14 --> test_result
    ###
    
    [ $( is_empty --str "${current_subject}" ) -eq "${YES}" ] && current_subject="$( to_upper "${current_suite_id}" )"
    [ $( is_empty --str "${current_test_setup_drv}" ) -eq "${YES}" ] && current_test_setup_drv="${current_suite_path}/__setup_${current_suite_id}.sh"

    outputline="${current_suite_path}:${current_suite_id}:${current_suite_subject}:${current_suite_lang}:${current_suite_drv}:${suite_num_id}"  # Suite parameters
    if [ -n "${testname}" ]
    then
      current_test_args="$( __handle_spaced_output "${current_test_args}" )"
      [ ! -f "${current_test_setup_drv}" ] && current_test_setup_drv=
      
      printf "%s\n" "${outputline}:${testname}:${test_num_id}:${current_test_drv}:${current_test_setup_drv}:A${current_test_args}:${current_test_deps}:${current_test_tags}:${current_test_result}"
      current_test_args=
      current_test_result="$(__handle_spaced_output "eq ${PASS}" )"
      test_num_id=$( increment "${test_num_id}" )
      new_entry="${NO}"
      outputline=
    fi
  done 9< "${tmpfile}"
  
  [ -f "${tmpfile}" ] && \rm -f "${tmpfile}"
  
  if [ "${new_entry}" -eq "${YES}" ]
  then
    if [ -$( is_empty --str "${testname}" ) -eq "${YES}" ]
    then
      printf "%s\n" "${outputline}:::${current_test_drv}:${current_test_setup_drv}:A${current_test_args}:${current_test_deps}:${current_test_tags}:${current_test_result}"
    else
      printf "%s\n" "${outputline}:${testname}:${test_num_id}:${current_test_drv}:${current_test_setup_drv}:A${current_test_args}:${current_test_deps}:${current_test_tags}:${current_test_result}"      
    fi
  fi
  return "${PASS}"
}

# =====================================================================
. "${__HARNESS_TOPLEVEL}/utilities/inputs/.basic_parser_functions.sh"
[ $? -ne 0 ] && return 1

. "${SLCF_SHELL_TOP}/utilities/common/program_utilities.sh"
[ $? -ne 0 ] && return 1

return 0
