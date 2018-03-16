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

DEFAULT_XML_FILE_BUILDER_EXTENSION='.explode'
DEFAULT_TEST_RESULT="$( __handle_spaced_output 'eq 0' )"

__explode_xml_driver_file()
{
  typeset RC="${PASS}"
  typeset filename="$1"
  [ -z "${filename}" ] && return "${FAIL}"
  
  ###
  ### Validate filename as XML
  ### 
  typeset validXML=$( xml_validate --xmlfile "${filename}" )
  [ "${validXML}" -eq "${NO}" ] && return "${FAIL}"

  ###
  ### Get rootnode of XML
  ### 
  typeset rootnode=$( xml_get_rootnode_name --xmlfile "${filename}" )
  [ $( is_empty --str "${rootnode}" ) -eq "${YES}" ] && return "${FAIL}"

  ###
  ### Build temporary file used to house the collection of processed files
  ###
  typeset tmpfile="$( __extract_value 'RESULTS_DIR' )/$( \basename "${filename}" )"
  tmpfile=$( remove_extension "${tmpfile}" )
  tmpfile+="$( __extract_value 'START_TIME' ).tmp"
  \touch "${tmpfile}"
  
  typeset section_types=
  typeset sectype=
  list_add --object 'section_types' --data 'defines:define includes:include'

  for sectype in $( list_data --object 'section_types' )
  do
    typeset plural=$( get_element --data "${sectype}" --id 1 --separator ':' )
    typeset singular=$( get_element --data "${sectype}" --id 2 --separator ':' )
    if [ $( xml_has_node --xpath "/${rootnode}" --node "${plural}" --xmlfile "${filename}" ) -eq "${YES}" ]
    then
      typeset matched_section_subfile=$( xml_get_subxml --xpath "/${rootnode}/${plural}" --xmlfile "${filename}" )

      if [ -s "${matched_section_subfile}" ]
      then
        typeset xmlmethod="__process_xml_${plural}"
        eval "${xmlmethod} \"${matched_section_subfile}\" \"${tmpfile}\""
      fi
      remove_output_file --filename "${matched_section_subfile}"
    fi
  done
  
  ###
  ### The structure of the XML driver file needs to be unchanging so that we
  ###   we can use the hardcoded deriviate to get the remaining suites
  ###
  __squish_toplevel "${filename}" "${tmpfile}" "/${rootnode}/suites/suite"
  RC=$?
  printf "%s\n" "${tmpfile}"
  return "${RC}"
}

__explode_xml_tag_file()
{
  typeset filename="$1"
  typeset tmpfile="$2"
  typeset search_dir="$3"
  
  ###
  ### Explode the file in the event there are includes and those includes have includes...
  ###
  typeset xml_q=
  queue_add --object 'xml_q' --data "${filename}"
  
  while [ $( queue_size --object 'xml_q' ) -gt 0 ]
  do
    typeset current_file="$( queue_offer --object 'xml_q' )"   
    typeset rootnode=$( xml_get_rootnode_name --xmlfile "${current_file}" )
    [ $( is_empty --str "${rootnode}" ) -eq "${YES}" ] && continue
    
    ###
    ### Find the rules subsection to see what to include into the final XML file...
    ###
    typeset subrules="$( xml_get_single_entry --xmlfile "${current_file}" --xpath "/${rootnode}/rules" --field 'rule' --format "%s" )"
    typeset sbr=
    for sbr in ${subrules}
    do
      sbr="$( __evaluate_variable "${sbr}" )"
      if [ ! -f "${sbr}" ]
      then
        found_subfile=$( find "${search_dir}" -name "${sbr}" | \head -n 1 )
        if [ -z "${found_subfile}" ] || [ ! -f "${found_subfile}" ]
        then
          print_btf_detail --msg "Unable to locate file << ${sbr} >> for tag selection processing." --prefix "$( __extract_value 'PREFIX_WARN' )"
          continue
        else
          sbr="${found_subfile}"
        fi
      fi
      queue_add --object 'xml_q' --data "${sbr}"
    done
    
    typeset all_nodes="$( xml_get_multi_entry --xmlfile "${current_file}" --xpath "/${rootnode}/tags/tag" --field '@name' --format "%s" )"
    
    typeset nn=
    for nn in ${all_nodes}
    do
      nn="$( __evaluate_variable "${nn}" )"

      typeset subsection_file=$( xml_get_subxml --xmlfile "${current_file}" --xpath "/${rootnode}/tags/tag[@name='${nn}']" )
      RC=$?
      if [ "${RC}" -ne "${PASS}" ] || [ ! -f "${subsection_file}" ]
      then
        print_btf_detail --msg "Unable to extract tagged section << ${nn} >> for tag selection processing.  Skipping" --prefix "$( __extract_value 'PREFIX_WARN' )"
        continue
      fi
      
      printf "\n" >> "${subsection_file}"
      
      typeset already_exist_node="$( xml_get_multi_entry --xmlfile "${tmpfile}" --xpath "/${rootnode}/tags/tag" --field '@name' --format "%s" )"
      printf "%s\n" ${already_exist_node} | \grep -q "${nn}"
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        print_btf_detail --msg "Already found pre-existing node by name <<${nn}>> in expanded file.  Merging..." --prefix "$( __extract_value 'PREFIX_WARN' )"
      fi
      __merge_xml_tag_sections --result-file "${tmpfile}" --input-file "${subsection_file}" --merge_type "${RC}"
      remove_output_file --channel "$( find_output_channel -f "${subsection_file}" )"
    done
  done
  
  queue_clear --object 'xml_q'
  return "${PASS}"
}

__handle_xml_dependency_input()
{
  return "${PASS}"
}

__handle_xml_tagselect_input()
{
  ###
  ### Handle reading XML structure input as tag selection file
  ###
  typeset filename="$1"
  typeset startpt="$2"
  typeset RC

  typeset tmpfile="$( __extract_value 'RESULTS_DIR' )/$( \basename "${filename}" )"
  tmpfile=$( remove_extension "${tmpfile}" )
  tmpfile+="_$( __extract_value 'START_TIME' ).tmp"
  
  if [ "x${xml_exe}" == "x" ]
  then
    \rm -f "${tmpfile}"
    return "${FAIL}"
  fi

  xml_generate_new_file --xmlfile "${tmpfile}" --rootnode-id 'test_selection' --subnode 'tags'  
  __explode_xml_tag_file "${filename}" "${tmpfile}" "${__HARNESS_TOPLEVEL}/drivers/tags"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  
  typeset globaltags=
  typeset seen_headers=
  typeset directive_q=
  queue_add --object 'directive_q' --data "${startpt}"
  
  xml_set_file --xmlfile "${tmpfile}"
  typeset rootnode="$( xml_get_rootnode_name )"

  while [ $( queue_size --object 'directive_q' ) -gt 0 ]
  do
    ###
    ### Remove the current pointer and begin processing
    ###
    queue_add --object 'seen_headers' --data "$( queue_offer --object 'directive_q' )"
    
    ###
    ### Extract defect tags
    ###
    typeset defect_tags="$( trim "$( xml_get_single_entry --xpath "/${rootnode}/tags/tag[@name='T-${startpt}']/defects" --field 'defect' --format "%s" | tr '\n' ' ' )" )"
    [ -n "${defect_tags}" ] && $( list_add --object 'globaltags' --data "${defect_tags}" )
    
    ###
    ### Extract user story tags
    ###
    typeset user_story_tags="$( trim "$( xml_get_single_entry --xpath "/${rootnode}/tags/tag[@name='T-${startpt}']/user_stories" --field 'user_story' --format "%s" | tr '\n' ' ' )" )"
    [ -n "${user_story_tags}" ] && $( list_add --object 'globaltags' --data "${user_story_tags}" )
    
    ###
    ### Extract additional one-off tags
    ###
    typeset add_on_tags="$( trim "$( xml_get_single_entry --xpath "/${rootnode}/tags/tag[@name='T-${startpt}']" --field 'add_tag' --format "%s" | tr '\n' ' ' )" )"
    [ -n "${add_on_tags}" ] && $( list_add --object 'globaltags' --data "${add_on_tags}" )
    
    ###
    ### Determine if this is link to "earlier" versions
    ###
    typeset see_section="$( xml_get_single_entry --xpath "/${rootnode}/tags/tag[@name='T-${startpt}']" --field 'see_also' --format "%s" )"
    if [ -n "${see_section}" ] && [ "$( __check_for --key 'NO_TAG_RECURSION' --failure )" -eq "${YES}" ]
    then
      [ $( __seen_tag_header "${see_section}" "$( queue_data --object 'seen_headers' )" ) -eq "${NO}" ] && queue_add --object 'directive_q' --data "${see_section}"
    fi
        
    ###
    ### Reset the pointer to the next element in the list
    ###
    startpt="$( trim "$( queue_offer --object 'directive_q' )" )"
  done
  
  xml_unset_file
  [ -f "${tmpfile}" ] && \rm -f "${tmpfile}"
  
  __add_global_tags_from_file "$( list_data --object 'globaltags' )"
  RC=$?
  
  list_clear --object 'globaltags'
  queue_clear --object 'seen_headers'
  queue_clear --object 'directive_q'
  
  return "${RC}"
}

__handle_xml_test_input()
{
  typeset RC="${PASS}"
  ###
  ### Handle reading XML structure input as driver file
  ###
  typeset filename="$1"
  typeset tmpfile="$( __explode_xml_driver_file "${filename}" )"
  [ $? -ne "${PASS}" ] && return "${FAIL}"
  
  ###
  ### Add the root node to the XML file now that it is completed its explosion
  ###
  \mv -f "${tmpfile}" "${tmpfile}${DEFAULT_XML_FILE_BUILDER_EXTENSION}"
  
  xml_generate_new_file --xmlfile "${tmpfile}${DEFAULT_XML_FILE_BUILDER_EXTENSION}" --rootnode-id '/test_selection/suites' --preserve

  ###
  ### Validate it to be sure we have a valid XML file to process
  ###
  validXML=$( xml_validate --xmlfile "${tmpfile}${DEFAULT_XML_FILE_BUILDER_EXTENSION}" )
  [ "${validXML}" -eq "${NO}" ] && return "${FAIL}"

  ###
  ### Set it as the default file to access while processing
  ###
  xml_set_file --xmlfile "${tmpfile}${DEFAULT_XML_FILE_BUILDER_EXTENSION}" 

  ###
  ### Loop over suite entries
  ###
  typeset rootnode=$( xml_get_rootnode_name )
  typeset num_suites=$( xml_count_entries --xpath "/${rootnode}/suites/suite" )
  typeset count=1
  
  while [ "${count}" -le "${num_suites}" ]
  do
    typeset subfile=$( xml_get_subxml --xpath "/${rootnode}/suites/suite[${count}]" )
    RC=$?
    if [ "${RC}" -ne "${PASS}" ] || [ ! -f "${subfile}" ]
    then
      print_btf_detail --msg "Unable to properly extricate suite #${count} in file order..." --prefix "$( __extract_value 'PREFIX_ERROR' )"
      log_error "Unable to properly extricate suite #${count} in file order..."
    else
      __process_xml_suite "${subfile}" "${count}"  #### This will process each suite in turn...
      [ $? -ne "${PASS}" ] && log_error 'Improperly defined suite encountered'
      remove_output_file --filename "${subfile}"
    fi
    count=$( increment "${count}" )
  done

  ###
  ### Unset default (std) file
  ###
  xml_unset_file
  
  return "${PASS}"
}

__merge_xml_tag_sections()
{
  typeset outfile
  typeset infile
  typeset merge_type=1
  
  OPTIND=1
  while getoptex "r: result-file: i: input-file: m: merge-type:" "$@"
  do
    case "${OPTOPT}" in
    'r'|'result-file'   ) outfile="${OPTARG}";;
    'i'|'input-file'    ) infile="${OPTARG}";;
    'm'|'merge-type'    ) merge_type="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${outfile}" ] || [ -z "${infile}" ] && return "${FAIL}"
  
  typeset header_last_line=$( \cat "${outfile}" | \grep -n "<tags>" | \cut -f 1 -d ':' )
  
  \sed -e "${header_last_line}r ${infile}" "${outfile}" >> "${outfile}.tmp"
  \mv -f "${outfile}.tmp" "${outfile}"
  
  return "${PASS}"
}

__process_xml_defines()
{
  typeset xml_define_file="$1"
  [ -z "${xml_define_file}" ] || [ ! -f "${xml_define_file}" ] && return "${FAIL}"

  typeset RC="${PASS}"
  typeset memopts=

  typeset rootnode=$( xml_get_rootnode_name --xmlfile "${xml_define_file}" )

  typeset total_num=$( xml_count_entries --xpath "/${rootnode}/define" --xmlfile "${xml_define_file}" )
  typeset count=1
  
  while [ "${count}" -le "${total_num}" ]
  do
    typeset xkey="$( __xml_substitution_method "$( xml_get_attribute --xpath "/${rootnode}/define[${count}]" --attr "key" --xmlfile "${xml_define_file}" )" )"
    typeset xvalue="$( __xml_substitution_method "$( xml_get_attribute --xpath "/${rootnode}/define[${count}]" --attr "value" --xmlfile "${xml_define_file}" )" )"

    [ $( is_empty --str "${xkey}" ) -eq "${YES}" ] && continue
    memopts+=$( __import_variable --key "${xkey}" --value "${xvalue}" --use-memory "${YES}" )
    count=$(( count + 1 ))
  done
  
  eval "${memopts}"
  return "${RC}"
}

__process_xml_includes()
{
  typeset RC="${PASS}"
  typeset xml_include_file="$1"
  typeset tmpfile="$2"
  
  [ -z "${xml_include_file}" ] || [ ! -f "${xml_include_file}" ] && return "${FAIL}"
  [ -z "${tmpfile}" ] || [ ! -f "${tmpfile}" ] && return "${FAIL}"

  typeset rootnode=$( xml_get_rootnode_name --xmlfile "${xml_include_file}" )

  typeset global_directory="$( __xml_substitution_method "$( xml_get_attribute --xpath "/${rootnode}" --attr 'directory' --xmlfile "${xml_include_file}" )" )"

  typeset total_num=$( xml_count_entries --xpath "/${rootnode}/include" --xmlfile "${xml_include_file}" )
  typeset count=1

  while [ "${count}" -le "${total_num}" ]
  do
    typeset subfile="$( __xml_substitution_method "$( xml_get_text --xpath "/${rootnode}" --field "include[${count}]" --xmlfile "${xml_include_file}" )" )"
    if [ $( is_empty --str "${subfile}" ) -eq "${YES}" ]
    then
      count=$( increment "${count}" )
      continue
    fi
    
    typeset local_directory="$( __xml_substitution_method "$( xml_get_attribute --xpath "/${rootnode}/include[${count}]" --attr 'directory' --xmlfile "${xml_include_file}" )" )"

    typeset search_paths=
    [ $( is_empty --str "${local_directory}" ) -eq "${NO}" ] && [ -d "${local_directory}" ] && list_add --object 'search_paths' --data "${local_directory}/${subfile}"
    list_add --object 'search_paths' --data "${subfile}"
    [ $( is_empty --str "${global_directory}" ) -eq "${NO}" ] && [ -d "${global_directory}" ] && list_add --object 'search_paths' --data "${global_directory}/${subfile}"
    
    typeset found="${NO}"
    typeset sp
    for sp in $( list_data --object 'search_paths' )
    do
      if [ -f "${sp}" ]
      then
        subfile="${sp}"
        found="${YES}"
        break
      fi
    done

    list_clear --object 'search_paths'
    if [ "${found}" -eq "${NO}" ]
    then
      log_warning "Unable to find any file << ${subfile} >>"
      count=$( increment "${count}" )
      continue
    fi
    ###
    ### Include this file as XML by...
    ###   1) parsing it for defines and apply them...
    ###   2) checking it for includes and recursively incorporating them into the overall
    ###      built XML file to be returned.
    ###
    typeset tmpfile_include=$( __explode_xml_driver_file "${subfile}" )
    RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      count=$( increment "${count}" )
      continue
    fi
    
    if [ -f "${tmpfile_include}" ]
    then
      \cat "${tmpfile}" "${tmpfile_include}" > "${tmpfile}.concat"
      \mv -f "${tmpfile}.concat" "${tmpfile}"
    fi
    
    count=$( increment "${count}" )
  done
  
  return "${PASS}"
}

__process_xml_suite()
{
  typeset particular_suite_file="$1"
  typeset suite_num_id="$2"
  
  typeset rootnode=$( xml_get_rootnode_name --xmlfile "${particular_suite_file}" )
  
  typeset current_suite_path="$( __xml_substitution_method "$( xml_get_text --xmlfile "${particular_suite_file}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_SUITEDIR' )" --format '%s' )" )"
  [ $( is_empty --str "${current_suite_path}" ) -eq "${YES}" ] || [ ! -d "${current_suite_path}" ] && return "${FAIL}"

  typeset current_suite_id="$( __xml_substitution_method "$( xml_get_attribute --xmlfile "${particular_suite_file}" --xpath "/${rootnode}" --attr "$( __extract_value 'KEYWORD_SUITEID' )" --format '%s' )" )"
  if [ $( is_empty --str "${current_suite_id}" ) -eq "${YES}" ]
  then
    current_suite_id="$( __xml_substitution_method "$( xml_get_text --xmlfile "${particular_suite_file}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_SUITEID' )" --format '%s' )" )"
  fi
  
  [ $( is_empty --str "${current_suite_id}" ) -eq "${YES}" ] && current_suite_id="$( \basename "${current_suite_path}" )"

  typeset current_suite_subject="$( __xml_substitution_method "$( xml_get_text --xmlfile "${particular_suite_file}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_SUITESUBJECT' )" --format '%s' )" )"
  [ $( is_empty --str "${current_suite_subject}" ) -eq "${YES}" ] && current_suite_subject="$( to_upper "${current_suite_id}" )"
  
  typeset current_suite_drv=
  if [ $( xml_has_node --xmlfile "${particular_suite_file}" --xpath "/${rootnode}" --node "$( __extract_value 'KEYWORD_SUITEDRIVER' )" ) -eq "${YES}" ]
  then
    current_suite_drv="$( __xml_substitution_method "$( xml_get_text --xmlfile "${particular_suite_file}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_SUITEDRIVER' )" --format '%s' )" )"
    typeset relativepath="$( xml_get_attribute --xmlfile "${particular_suite_file}" --xpath "/${rootnode}/$( __extract_value 'KEYWORD_SUITEDRIVER' )" --attr 'relative' --format '%s' )"
    [ -z "${relativepath}" ] && relativepath=0
    [ $( is_true "${relativepath}" ) -eq "${YES}" ] && relativepath=1
    [ "${relativepath}" -eq 1 ] && current_suite_drv="${current_suite_path}/${current_suite_drv}"
  fi

  typeset current_suite_lang="$( __xml_substitution_method "$( xml_get_text --xmlfile "${particular_suite_file}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_SUITELANGUAGE' )" --format '%s' )" )"
  
  ###
  ### Begin collection process for tags and tests
  ###
  typeset subfile=$( xml_get_subxml --xmlfile "${particular_suite_file}" --xpath "/${rootnode}/suitetags" )
  typeset current_suite_tags=
  if [ $( is_empty --str "${subfile}" ) -eq "${NO}" ] && [ -f "${subfile}" ]
  then
    current_suite_tags="$( __process_xml_suite_test_tags "${subfile}" )"
    remove_output_file --filename "${subfile}"
  fi
  
  typeset testnames="$( xml_get_multi_entry --xmlfile "${particular_suite_file}" --xpath "/${rootnode}/suitetests/suitetest" --field "@$( __extract_value 'KEYWORD_TESTNAME' )" --format '%s' --no-match )"
  typeset RC="${PASS}"
  
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

  typeset outputline="${current_suite_path}:${current_suite_id}:${current_suite_subject}:${current_suite_lang}:${current_suite_drv}:${suite_num_id}"  # Suite parameters
  typeset tnc=1
  typeset tn
  if [ -n "${testnames}" ]
  then
    for tn in ${testnames}
    do
      subfile=$( xml_get_subxml --xmlfile "${particular_suite_file}" --xpath "/suite/suitetests/suitetest[@$( __extract_value 'KEYWORD_TESTNAME' )='${tn}']" )
      if [ $( is_empty --str "${subfile}" ) -eq "${YES}" ] || [ ! -f "${subfile}" ]
      then
        log_warning "Unable to find section necessary for << ${tn} >> in XML file..."
        continue
      fi
      typeset testinfo="$( __process_xml_suite_test "${subfile}" "${tnc}" "${outputline}" "${current_suite_tags}" )"
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        typeset newtnc=$( printf "%s\n" "${testinfo}" | \tail -n 1 )
        testinfo=$( printf "%s\n" "${testinfo}" | \sed '$d' )
      
        printf "%s\n" "${testinfo}"
        tnc="${newtnc}"
      fi
      remove_output_file --filename "${subfile}"
    done
  else
    typeset testinfo="::::::"
    [ -n "${current_suite_tags}" ] && testinfo=":::::${current_suite_tags}:${DEFAULT_TEST_RESULT}"
    printf "%s\n" "${outputline}:${testinfo}"
  fi
  return "${PASS}"
}

__process_xml_suite_test()
{
  typeset RC="${PASS}"
  typeset particular_test_file="$1"  
  typeset test_id="$2"
  typeset suite_info="$3"
  typeset suite_tags="$4"
  
  if [ -z "${particular_test_file}" ] || [ ! -f "${particular_test_file}" ]
  then
    [ -n "${suite_info}" ] && printf "%s\n" "${suite_info}"
    return "${FAIL}"
  fi
  
  typeset rootnode=$( xml_get_rootnode_name --xmlfile "${particular_test_file}" )
  
  typeset testname="$( __xml_substitution_method "$( xml_get_attribute --xmlfile "${particular_test_file}" --xpath "/${rootnode}" --attr "$( __extract_value 'KEYWORD_TESTNAME' )" --format '%s' )" )"
  typeset test_drv="$( __xml_substitution_method "$( xml_get_text --xmlfile "${particular_test_file}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_TESTDRIVER' )" --format '%s' )" )"
  typeset test_setup_drv="$( __xml_substitution_method "$( xml_get_text --xmlfile "${particular_test_file}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_TESTSETUPDRIVER' )" --format '%s' )" )"

  ###
  ### Check to see how suite tags are to be handled : TODO
  ### This is a section of XML to be processed...
  ###
  typeset test_specific_tags="${suite_tags} $( __xml_substitution_method "$( xml_get_text --xmlfile "${particular_test_file}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_TESTTAG' )" --format '%s' )" )"
  test_specific_tags=$( trim "${test_specific_tags}" )
  
  ###
  ### Needs to be handled differently (just like we did for the text parser)
  ###
  typeset test_deps="$( __xml_substitution_method "$( xml_get_text --xmlfile "${particular_test_file}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_TESTDEPENDENCY' )" --format '%s' )" )"

  typeset current_test_info=

  if [ "$( xml_has_attribute --xmlfile "${particular_test_file}" --xpath "/${rootnode}" --attr "multi_input" )" -eq "${YES}" ]
  then
    typeset num_inputsets=$( xml_count_entries --xmlfile "${particular_test_file}" --xpath "/${rootnode}/testinputsets/testinputset" )

    typeset count=1
    while [ "${count}" -le "${num_inputsets}" ]
    do
      current_test_info="${testname}:${test_id}:${test_drv}:${test_setup_drv}"
      typeset subfile=$( xml_get_subxml --xmlfile "${particular_test_file}" --xpath "/${rootnode}/testinputsets/testinputset[${count}]" )
      if [ $( is_empty --str "${subfile}" ) -eq "${NO}" ] && [ -f "${subfile}" ]
      then
        typeset testdata="$( __process_xml_suite_test_inputset "${subfile}" "${count}" )"
        RC=$?
        if [ "${RC}" -eq "${PASS}" ]
        then
          typeset testargs=$( get_element --data "${testdata}" --id 1 --separator '|' )
          typeset testresult=$( get_element --data "${testdata}" --id 2 --separator '|' )

          printf "%s\n" "${suite_info}:${current_test_info}:A${testargs}:${test_deps}:${test_specific_tags}:${testresult}"
        else
          print_btf_detail --msg "Bad parsing for input set #${count} related to test ${testname}" --prefix "$( __extract_value 'PREFIX_WARN' )"
          log_warning "Bad parsing for input set #${count} related to test ${testname}"
          remove_output_file --filename "${subfile}"

          count=$( increment "${count}" )
          continue
        fi
        remove_output_file --filename "${subfile}"
      fi
      count=$( increment "${count}" )
      test_id=$( increment "${test_id}" )
    done
  else
    current_test_info="${testname}:${test_id}:${test_drv}:${test_setup_drv}"
    typeset testargs=

    typeset subfile=$( xml_get_subxml --xmlfile "${particular_test_file}" --xpath "/${rootnode}/testarguments" )
    if [ $( is_empty --str "${subfile}" ) -eq "${NO}" ] && [ -f "${subfile}" ]
    then
      testargs="$( __process_xml_suite_test_arguments "${subfile}" )"
      remove_output_file --filename "${subfile}"
    fi
    
    typeset testresult="$( __xml_substitution_method "$( xml_get_text --xmlfile "${particular_test_file}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_TESTRESULT' )" --format '%s' )" )"
    [ $( is_empty --str "${testresult}" ) -eq "${YES}" ] && testresult="${DEFAULT_TEST_RESULT}"

    printf "%s\n" "${suite_info}:${current_test_info}:A${testargs}:${test_deps}:${test_specific_tags}:${testresult}"
    test_id=$( increment "${test_id}" )
  fi
  
  printf "%d\n" "${test_id}"
  return "${PASS}"
}

__process_xml_suite_test_inputset()
{
  typeset xml_test_inpsetfile="$1"
  [ -z "${xml_test_inpsetfile}" ] || [ ! -f "${xml_test_inpsetfile}" ] && return "${FAIL}"
    
  typeset rootnode=$( xml_get_rootnode_name --xmlfile "${xml_test_inpsetfile}" )
  typeset testargs=
  typeset testresult=

  if [ $( xml_has_node --xpath "/${rootnode}" --node 'testarguments' --xmlfile "${xml_test_inpsetfile}" ) -eq "${YES}" ]
  then
    typeset subfile=$( xml_get_subxml --xmlfile "${xml_test_inpsetfile}" --xpath "/${rootnode}/testarguments" )
    if [ $( is_empty --str "${subfile}" ) -eq "${NO}" ] && [ -f "${subfile}" ]
    then
      testargs="$( __process_xml_suite_test_arguments "${subfile}" )"
      remove_output_file --filename "${subfile}"
      
      testresult="$( __xml_substitution_method "$( xml_get_text --xmlfile "${xml_test_inpsetfile}" --xpath "/${rootnode}" --field "$( __extract_value 'KEYWORD_TESTRESULT' )" --format '%s' )" )"
      [ $( is_empty --str "${testresult}" ) -eq "${YES}" ] && testresult="${DEFAULT_TEST_RESULT}"

    else
      testresult="${DEFAULT_TEST_RESULT}"
    fi
  else
    testresult="${DEFAULT_TEST_RESULT}"
  fi

  printf "%s\n" "${testargs}|${testresult}"
  return "${PASS}"
}

__process_xml_suite_test_tags()
{
  typeset xml_test_tagfile="$1"
  [ $( is_empty --str "${xml_test_tagfile}" ) -eq "${YES}" ] || [ ! -f "${xml_test_tagfile}" ] && return "${FAIL}"
  
  typeset rootnode=$( xml_get_rootnode_name --xmlfile "${xml_test_tagfile}" )
  
  typeset testtags="$( __xml_substitution_method "$( xml_get_multi_entry --xmlfile "${xml_test_tagfile}" --xpath "/${rootnode}" --field 'testtag' --format '%s' --no-match --prefix '@' )" )"
  printf "%s\n" "${testtags}" | \sed -e 's#^@##'
  return "${PASS}"  
}

__process_xml_suite_test_arguments()
{
  typeset xml_test_argfile="$1"
  [ $( is_empty --str "${xml_test_argfile}" ) -eq "${YES}" ] || [ ! -f "${xml_test_argfile}" ] && return "${FAIL}"
  
  typeset rootnode=$( xml_get_rootnode_name --xmlfile "${xml_test_argfile}" )

  typeset testargs="$( __xml_substitution_method "$( xml_get_multi_entry --xmlfile "${xml_test_argfile}" --xpath "/${rootnode}" --field 'testargument' --format '%s' --no-match --prefix '@' )" )"
  printf "%s\n" "${testargs}" | \sed -e 's#^@##'
  return "${PASS}"
}

__squish_toplevel()
{
  typeset main_filename="$1"
  typeset partial_expanded_filename="$2"
  typeset xpath="$3"
  
  [ $( is_empty --str "${main_filename}" ) -eq "${YES}" ] || [ ! -f "${main_filename}" ] && return "${FAIL}"
  [ $( is_empty --str "${partial_expanded_filename}" ) -eq "${YES}" ] || [ ! -f "${partial_expanded_filename}" ] && return "${FAIL}"
  
  ###
  ### Take toplevel remainder and squish it into the temporary file before we
  ###    wrap it with a XML bow
  ###
  typeset tmpxmlfile="$( __extract_value 'RESULTS_DIR' )/single_suite.xml"
  typeset total_num=$( xml_count_entries --xpath "${xpath}" --xmlfile "${main_filename}" )
  
  typeset count=1
  while [ "${count}" -le "${total_num}" ]
  do
    xml_select_entry --xpath "${xpath}" --id "${count}" --xmlfile "${main_filename}" > "${tmpxmlfile}"
    
    if [ -f "${tmpxmlfile}" ]
    then
      \cat "${tmpxmlfile}" >> "${partial_expanded_filename}"
      \rm -f "${tmpxmlfile}"
    fi
    count=$( increment "${count}" )
  done
  
  return "${PASS}"
}

__xml_substitution_method()
{
  typeset input="$1"
  [ $( is_empty --str "${input}" ) -eq "${YES}" ] && return "${PASS}"
  
  typeset prefix_remove="$2"
  if [ $( is_empty --str "${prefix_remove}" ) -eq "${NO}" ]
  then
    input="$( printf "%s\n" "${input}" | \sed -e "s#^${prefix}##" )"
  fi
  
  typeset change_found="${YES}"
  while [ "${change_found}" -eq "${YES}" ]
  do
    input="$( __handle_spaced_output "${input}" )"

    typeset input_orig="${input}"
    input="$( printf "%s\n" "${input}" | \sed -e "s#\\\$#\$#g" -e "s#\\\{#\{#g" -e "s#\\\}#\}#g" )"

    [ "${input}" != "${input_orig}" ] && eval "input=${input}"
    
    input="$( __evaluate_variable "${input}" 2 )"
    [ "${input}" == "${input_orig}" ] && change_found="${NO}"
  done
  
  printf "%s\n" "${input}"
  return "${PASS}"
}

# ===========================================================================================
if [ -n "${SLCF_SHELL_TOP}" ]
then
  . "${SLCF_SHELL_TOP}/lib/xmlmgt.sh"
  __RC=$?
  if [ "${__RC}" -eq 0 ]
  then
    . "${__HARNESS_TOPLEVEL}/utilities/inputs/.basic_parser_functions.sh"
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
