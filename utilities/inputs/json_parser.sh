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

__convert_yaml_to_json()
{
  typeset yamlfile=
  
  OPTIND=1
  while getoptex "f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename' ) yamlfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${yamlfile}" ] || [ ! -f "${yamlfile}" ] && return "${FAIL}"
  
  typeset tmpfile="$( remove_extension "$( __extract_value 'RESULTS_DIR' )/$( \basename "${yamlfile}" )" )_convert_from_yaml.json"
  if [ "x${yaml_exe}" != "x" ]
  then
    ${yaml_exe} < "${yamlfile}" > "${tmpfile}"
    printf "%s\n" "${tmpfile}"
  
    return "${PASS}"
  else
    return "${FAIL}"
  fi
}

__explode_json_rules()
{
  typeset filename="$1"
  typeset tmpfile="$2"
  
  ###
  ### Explode the file in the event there are includes and those includes have includes...
  ###
  typeset json_q="${filename}"
  
  while [ $( is_empty --str "${json_q}" ) -eq "${NO}" ]
  do
    typeset subrules=
    typeset current_file="$( printf "%s\n" "${json_q}" | \cut -f 1 -d ' ' )"
    
    json_q=$( printf "%s\n" ${json_q} | \grep -v "${current_file}" | \tr '\n' ' ' )
   
    ###
    ### Allow YAML extensions to be converted to JSON for parsing
    ###
    typeset fext=$( get_extension "${current_file}" )
    if [ "${fext}" == 'yaml' ] && [ "${USE_YAML}" == "${YES}" ]
    then
      yaml2jsonfile=$( __convert_yaml_to_json --filename "${current_file}" )
      current_file="${yaml2jsonfile}"
      if [ "x${current_file}" == "x" ]
      then
        return "${FAIL}"
      fi
    fi
    
    ###
    ### If this file has a rules section, we will add them to the json_q
    ### If this file has a tag section, we will merge it so that we can work through
    ###   the json_q to complete the build up process
    ###
    call_json_with_filter --filter '.test_selection.rules' --jsonfile "${current_file}" > /dev/null
    typeset has_rule_section=$?
    
    call_json_with_filter --filter '.test_selection.tags.tag' --jsonfile "${current_file}" > /dev/null
    typeset has_tag_section=$?
    
    ###
    ### Need to move this to a separate function
    ###
    if [ "${has_tag_section}" -eq "${PASS}" ]
    then
      __merge_json_sections --input-file "${current_file}" --result-file "${tmpfile}"
    fi
    
    if [ "${has_rule_section}" -eq "${PASS}" ]
    then
      subrules="$( call_json_with_filter --filter '.test_selection.rules.rule ' --jsonfile "${current_file}" --remove-array | tr '\n' ' ' )"
    fi
    
    ###
    ### Find the rules subsection to see what to include into the final JSON file...
    ###
    typeset sbr
    for sbr in ${subrules}
    do
      if [ ! -f "${sbr}" ]
      then
        found_subfile=$( find "${__HARNESS_TOPLEVEL}/drivers/tags" -name "${sbr}" | head -n 1 )
        if [ -z "${found_subfile}" ] || [ ! -f "${found_subfile}" ]
        then
          print_btf_detail --msg "Unable to locate file << ${sbr} >> for tag selection processing." --prefix "$( __extract_value 'PREFIX_WARN' )"
          continue
        else
          sbr="${found_subfile}"
        fi
      fi
      json_q+=" ${sbr}"
    done
    json_q="$( trim "${json_q}" )"
    
    [ "${USE_YAML}" == "${YES}" ] && \rm -f "${current_file}"
  done
  
  return "${PASS}"
}

###
### REQUIREMENTS : .run_harness [ still needs more refactoring to ensure input
###                               processing can be decoupled ]
###
__handle_json_dependency_input()
{
  return "${PASS}"
}

###
### Handle reading JSON structure input as tag selection file
###
__handle_json_tagselect_input()
{
  typeset filename="$1"
  typeset startpt="$2"
  typeset RC

  typeset tmpfile="$( __extract_value 'RESULTS_DIR' )/$( \basename "${filename}" )"
  tmpfile=$( remove_extension "${tmpfile}" )
  tmpfile+="_$( __extract_value 'START_TIME' ).tmp"
  
  printf "%s\n" '{' '  "test_selection": {' '    "tags": {' > "${tmpfile}"
  printf "%s\n" '      "tag": []' >> "${tmpfile}"
  printf "%s\n" '    }' '  }' '}' >> "${tmpfile}"
  
  __explode_json_rules "${filename}" "${tmpfile}"

  typeset globaltags=
  typeset directive_q="${startpt}"
  typeset seen_headers=
  
  json_set_file --jsonfile "${tmpfile}"

  if [ "x${jq_exe}" == "x" ]
  then
    \rm -f "${tmpfile}"
    json_unset_file
    return "${FAIL}"
  fi

  typeset number_entries=$( "${jq_exe}" '.test_selection.tags | .tag | length' "${tmpfile}" )
  while [ $( is_empty --str "${directive_q}" ) -eq "${NO}" ]
  do
    ###
    ### Remove the current pointer and begin processing
    ###
    directive_q=$( printf "%s\n" ${directive_q} | \grep -v "${startpt}" )
    seen_headers+=" ${startpt}"
    
    typeset count=0
    while [ "${count}" -lt "${number_entries}" ]
    do
      typeset name="$( call_json_with_filter --filter '.test_selection.tags' --filter ".tag[${count}]" --filter '.name' )"
      RC=$?
      if [ "${RC}" -ne "${PASS}" ]
      then
        count="${number_entries}"
        break
      fi
      [ "${name}" == "T-${startpt}" ] && break
      count=$( increment "${count}" )
    done
    
    ###
    ### Didn't find it...
    ###
    if [ "${count}" -eq "${number_entries}" ]
    then
      print_btf_detail --msg "Unable to find ${startpt} tag..." --prefix "$( __extract_value 'PREFIX_WARN' )"
      break
    fi
    
    ###
    ### Extract defect tags
    ###
    typeset defect_section="$( call_json_with_filter --filter '.test_selection.tags' --filter ".tag[${count}]" --filter '.defects' )"
    RC=$?
    if [ "${RC}" -eq "${PASS}" ]
    then
      globaltags+=" $( call_json_with_filter --filter '.test_selection.tags' --filter ".tag[${count}]" --filter '.defects' --filter 'to_entries[]' --filter '.key' | tr '\n' ' ' )"
    fi
    
    ###
    ### Extract user story tags
    ###
    typeset user_story_section="$( call_json_with_filter --filter '.test_selection.tags' --filter ".tag[${count}]" --filter '.user_stories' )"
    RC=$?
    if [ "${RC}" -eq "${PASS}" ]
    then
      globaltags+=" $( call_json_with_filter --filter '.test_selection.tags' --filter ".tag[${count}]" --filter '.user_stories' --filter 'to_entries[]' --filter '.key' | tr '\n' ' ' )"
    fi
    
    ###
    ### Extract additional one-off tags
    ###
    typeset user_story_section="$( call_json_with_filter --filter '.test_selection.tags' --filter ".tag[${count}]" --filter '.add_tags' )"
    RC=$?
    if [ "${RC}" -eq "${PASS}" ]
    then
      globaltags+=" $( call_json_with_filter --filter '.test_selection.tags' --filter ".tag[${count}]" --filter '.add_tags' --filter '.[]' | tr '\n' ' ' )"
    fi
    
    ###
    ### Determine if this is link to "earlier" versions
    ###
    typeset see_section="$( call_json_with_filter --filter '.test_selection.tags' --filter ".tag[${count}]" --filter '.see_also' )"
    RC=$?
    if [ "${RC}" -eq "${PASS}" ] && [ "$( __check_for --key 'NO_TAG_RECURSION' --failure )" -eq "${YES}" ]
    then
      [ $( __seen_tag_header "${see_section}" "${seen_headers}" ) -eq "${NO}" ] && directive_q+=" ${see_section}"
    fi
        
    ###
    ### Reset the pointer to the next element in the list
    ###
    startpt="$( trim "$( printf "%s\n" "${directive_q}" )" | \cut -f 1 -d ' ' )"
  done
  
  json_unset_file
  [ -f "${tmpfile}" ] && \rm -f "${tmpfile}"
  
  __add_global_tags_from_file "${globaltags}"
  RC=$?
  return "${RC}"
}

###
### Handle reading JSON structure input as driver file
###
__handle_json_test_input()
{
  typeset filename="$1"

  typeset validJSON=$( json_validate --jsonfile "${filename}" )
  [ "${validJSON}" -eq "${NO}" ] && return "${FAIL}"
  json_set_file --jsonfile "${filename}" 

  typeset suite_num_id=0
  typeset test_num_id=1

  typeset entrytype="$( call_json_with_filter --filter '.suitedir' --filter 'type' )"

  pause "${entrytype}"
  ###
  ### Expecting an array of JSON objects
  ###
  if [ "${entrytype}" == 'array' ]
  then
    typeset number_suites="$( call_json_with_filter --filter '.suitedir' --filter 'length' )"
    typeset count=0

    pause "${number_suites}"
    ###
    ### For each array entry "peel off" into a separate "temporary" JSON file
    ###  of just that information for easier parsing
    ###
    while [ "${count}" -lt "${number_suites}" ]
    do
      typeset test_jsonfile=$( json_get_subjson --jpath ".suitedir[${count}]" )
      typeset current_suitepath="$( __substitute "$( call_json_with_filter --jsonfile "${test_jsonfile}" --filter '.suitepath' )" )"
      if [ -z "${current_suitepath}" ] || [ ! -d "${current_suitepath}" ]
      then
        remove_output_file --channel "$( find_output_channel --file "${test_jsonfile}" )"
        count=$( increment "${count}" )
        continue
      fi

      ###
      ### Start collecting information
      ###
      typeset current_suiteid="$( call_json_with_filter --jsonfile "${test_jsonfile}" --filter '.suiteid' )"
      if [ -z "${current_suiteid}" ]
      then
        current_suiteid="$( remove_extension "$( \basename "${current_suitepath}" )" )"
      fi
      
      typeset current_suitesubject="$( __substitute "$( call_json_with_filter --jsonfile "${test_jsonfile}" --filter '.suitesubject' )" )"
      [ -z "${current_subject}" ] && current_subject=$( \basename "${current_path}" )
      
      typeset current_suitedrv="$( __substitute "$( call_json_with_filter --jsonfile "${test_jsonfile}" --filter '.suitedriver' )" )"
      typeset current_suitelang="$( __substitute "$( call_json_with_filter --jsonfile "${test_jsonfile}" --filter '.suitelanguage' )" )"
      typeset current_suitetags="$( __make_list_from_json_array "$( call_json_with_filter --jsonfile "${test_jsonfile}" --filter '.suitetags[]' )" )"

      pause "${current_suiteid} ++ ${current_suitedrv} ++ ${current_suitelang} ++ ${current_suitetags}"
      entrytype="$( call_json_with_filter --jsonfile "${test_jsonfile}" --filter '.suitetests' --filter 'type' )"

      pause "suitetests -> ${entrytype}"
      ###
      ### Expecting an array of JSON objects
      ###
      if [ "${entrytype}" == 'array' ]
      then
        typeset current_suitetests="$( __make_list_from_json_array "$( call_json_with_filter --jsonfile "${test_jsonfile}" --filter '.suitetests[]' --filter 'keys[]' )" )"
        typeset number_tests="$( call_json_with_filter --jsonfile "${test_jsonfile}" --filter '.suitetests[]' --filter 'keys' --filter 'length' )"
        typeset count2=0

        pause "${current_suitetests} ++ ${number_tests}"
        ###
        ### For each array entry "peel off" into a separate "temporary" JSON file
        ###  of just that information for easier parsing
        ###
        while [ "${count2}" -lt "${number_tests}" ]
        do
          typeset test_jsonfile2=$( json_get_subjson --jsonfile "${test_jsonfile}" --filter '.suitetests[0]' --filter 'keys[]' )
          cat "${test_jsonfile2}"
          pause
        done
      #typeset current_deps=
      
      #typeset test_jsonfile_deps=$( json_get_subjson --jpath ".testdir[${count}].dependencies" )
      #if [ $? -ne "${PASS}" ]
      #then
      #  typeset depfile="$( call_json_with_filter --jsonfile "${test_jsonfile}" --filter '.dependency_file' )"
      #  [ -n "${depfile}" ] && -f "${depfile}" ] && current_deps="$( parse_dependency_file --file "${depfile}" --id "${current_id}" )"
      #else
      #  current_deps="$( call_json_with_filter --jsonfile "${test_jsonfile_deps}" --filter '.deps[]' | tr '\n' ',' | sed -e 's#,$##' )"
      fi
      
      #if [ -z "${current_tests}" ]
      #then
      #  printf "%s\n" "${current_path}:${current_id}:${current_subject}:${current_lang}:${current_drv}::${current_args}:${current_deps}:${current_tags}"
      #else
      #  printf "%s\n" "${current_path}:${current_id}:${current_subject}:${current_drv}:${current_deps}:${current_tests}:${current_args}:${current_deps}:${current_tags}"
      #fi
      
      ###
      ### Cleanup "temporary file(s)"
      ###
      remove_output_file --channel "$( find_output_channel --file "${test_jsonfile}" )"
      #[ -n "${test_jsonfile_deps}" ] && remove_output_file --channel "$( find_output_channel --file "${test_jsonfile_deps}" )"
      count=$( increment "${count}" )
    done
  else
    json_fail --message "JSON file should be a collection of array entries.  Unable to read JSON file..."
    return $?
  fi

  ###
  ### Unset default (std) file
  ###
  json_unset_file
  return "${PASS}"
}

__make_list_from_json_array()
{
  typeset input="$1"
  [ -z "${input}" ] && return "${FAIL}"
  
  input=$( printf "%s\n" "${input}" | \tr '\n' ',' | \sed -e 's#,$##' | \tr ',' ' ' )
  printf "%s\n" "${input}"
  return "${PASS}"
}

__merge_json_sections()
{
  typeset outfile
  typeset infile
  
  OPTIND=1
  while getoptex "r: result-file: i: input-file:" "$@"
  do
    case "${OPTOPT}" in
    'r'|'result-file'   ) outfile="${OPTARG}";;
    'i'|'input-file'    ) infile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${outfile}" ] || [ -z "${infile}" ] && return "${FAIL}"

  if [ "x${jq_exe}" == "x" ]
  then
    return "${FAIL}"
  fi

  typeset new_type=$( ${jq_exe} ${__DEFAULT_JQ_OPTIONS} '.test_selection.tags.tag | type' ${infile} )
  typeset original_type=$( ${jq_exe} ${__DEFAULT_JQ_OPTIONS} '.test_selection.tags.tag | type' ${outfile} )
      
  if [ "${new_type}" == 'array' ]
  then
    ${jq_exe} ${__DEFAULT_JQ_OPTIONS} -s '.[].test_selection.tags.tag' "${infile}" > "${infile}.arrayoutput"
  else
    ${jq_exe} ${__DEFAULT_JQ_OPTIONS} -s '[.[].test_selection.tags.tag]' "${infile}" > "${infile}.arrayoutput"
  fi
  
  if [ "${original_type}" == 'array' ]
  then
    ${jq_exe} ${__DEFAULT_JQ_OPTIONS} -s '.[].test_selection.tags.tag' "${outfile}" > "${outfile}.arrayoutput"
  else
    ${jq_exe} ${__DEFAULT_JQ_OPTIONS} -s '[.[].test_selection.tags.tag]' "${outfile}" > "${outfile}.arrayoutput"
  fi
      
  ###
  ### Rewrite the temporary file for merging....
  ###
  printf "%s\n" '{' '  "test_selection": {' '    "tags": {' > "${outfile}"
  printf "%s" '      "tag":' >> "${tmpfile}"
  "${jq_exe}" -s '.[0] + .[1]' "${infile}.arrayoutput" "${outfile}.arrayoutput" | \sed -e 's#^#      #' >> "${outfile}"
  printf "%s\n" '    }' '  }' '}' >> "${outfile}"
  \rm -f "${infile}.arrayoutput" "${outfile}.arrayoutput"

  return "${PASS}"
}

if [ -n "${SLCF_SHELL_TOP}" ]
then
  . "${SLCF_SHELL_TOP}/lib/jsonmgt.sh"
  __RC=$?
  if [ "${__RC}" -eq 0 ]
  then
    . "${__HARNESS_TOPLEVEL}/utilities/inputs/basic_parser_functions.sh"
    __RC=$?
    [ "${__RC}" -ne "${PASS}" ] && return "${__RC}"
    
    . "${SLCF_SHELL_TOP}/utilities/common/program_utilities.sh"
    __RC=$?
    [ "${__RC}" -ne "${PASS}" ] && return "${__RC}"
  fi
  return "${__RC}"
else
  return 1
fi
