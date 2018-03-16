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
#    __convert_extension_to_key
#    __convert_argument_list
#    __convert_testname
#    __discover_driver_for_test
#    __generate_map_testname
#    __generate_filemap_name
#    __get_known_extension_types_for_language
#    __get_associated_language
#    __handle_dependency_push
#    __handle_spaced_output
#    __ignore_lines
#    __print_harness_header
#    __register_cleanup
#    __select_element
#    __verify_language_to_file
#    build_cmdline
#    collect_tags
#    display_files_in_build_system
#    find_tests
#    get_class_map_files
#    group_tests
#    help_banner
#    load_interpreted_datafile
#    log_error
#    log_warning
#    parse_dependency_file
#    parse_driver_file
#    prepare_copy_back
#    print_harness_header
#    run_suite
#    use_tag_aliases
#
###############################################################################

__convert_extension_to_key()
{
  if [ -z "$1" ]
  then
    printf "%s\n" 'UNKNOWN'
    return "${FAIL}"
  fi
  
  typeset exttypes=$( __get_known_extension_types_for_language | \tr ' ' '\n' )
  typeset et
  for et in ${exttypes}
  do
    typeset ext=$( get_element --data "${et}" --id 1 --separator ':' )
    typeset lang=$( get_element --data "${et}" --id 2 --separator ':' )
    
    if [ "$1" == "${ext}" ]
    then
      printf "%s\n" "${lang}"
      break
    fi
  done
  
  return "${PASS}"
}

__convert_argument_list()
{
  typeset input=

  OPTIND=1
  while getoptex "i: input:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'input' ) input="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${input}" ] && return "${FAIL}"
  
  typeset spcmark="$( __extract_value 'SPACE_MARKER' )"
  printf "%s\n" "${input}" | \sed -e 's#^A##' -e "s#${spcmark}# #g"
  return "${PASS}"
}

__convert_testname()
{
  typeset input=
  typeset suitename=
  
  OPTIND=1
  while getoptex "i: input: s: suitename:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'input'     ) input="${OPTARG}";;
    's'|'suitename' ) suitename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${input}" ] && return "${FAIL}"
  
  typeset mapdiv="$( __extract_value 'MAP_DIVIDER' )"
  typeset extmrk="$( __extract_value 'EXTENSION_MARKER' )"
  printf "%s\n" "${args}" | \sed -e "s#TEST_${suitename}${mapdiv}##" -e 's#[0-9]*_ID_##' -e "s#${extmrk}#.#"
  return "${PASS}"  
}

__discover_driver_for_test()
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
  
  typeset std_driver_dir="${__HARNESS_TOPLEVEL}/utilities/wrappers"
  typeset ext=$( get_extension "${testname}" )

  for f in $( __extract_value 'EXTENSION_TYPES' )
  do
    #typeset varname="$( __define_internal_variable "EXTENSION_${f}" )"
    typeset result="$( __extract_value "EXTENSION_${f}" )"
    #eval "result=\${${varname}}"
    typeset known_extensions="$( __select_element "${result}" 1 | \tr ':' ' ' )"
    typeset ke
    for ke in ${known_extensions}
    do
      if [ "${ke}" == "${ext}" ]
      then
        typeset wrapper="${std_driver_dir}/$( __select_element "${result}" 3 ).sh"
        printf "%s\n" "${wrapper}"
        break
      fi
    done
  done
  return "${PASS}"
}

__generate_map_testname()
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

  typeset extmrk="$( __extract_value 'EXTENSION_MARKER' )"
  printf "%s\n" "${testname}" | \sed -e "s#\.#${extmrk}#g"
  return "${PASS}"
}

__generate_filemap_name()
{
  typeset ts=
  typeset tn=

  OPTIND=1
  while getoptex "s: suite: t: test:" "$@"
  do
    case "${OPTOPT}" in
    's'|'suite'  ) ts="${OPTARG}";;
    't'|'test'   ) tn="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${ts}" ) -eq "${YES}" ] || [ $( is_empty --str "${tn}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset mapdiv="$( __extract_value 'MAP_DIVIDER' )"
  printf "%s\n" "TEST_${ts}${mapdiv}${tn}"
  return "${PASS}"
}

__get_known_extension_types_for_language()
{
  typeset lang_exttypes=
  typeset f
  for f in $( __extract_value 'EXTENSION_TYPES' )
  do
    #typeset varname="${__PROGRAM_VARIABLE_PREFIX}_EXTENSION_${f}"
    typeset result="$( __extract_value "EXTENSION_${f}" )"
    #typeset result=
    #eval "result=\${${varname}}"
    typeset known_extensions="$( __select_element "${result}" 1 | \tr ':' ' ' )"
    typeset ke
    for ke in ${known_extensions}
    do
      lang_exttypes+=" ${ke}:${f}"
    done
  done
  
  printf "%s\n" "${lang_exttypes}"
  return "${PASS}"
}

__get_associated_language()
{
  typeset language=
  typeset f
  
  for f in $( __extract_value 'EXTENSION_TYPES' )
  do
    #typeset varname="${__PROGRAM_VARIABLE_PREFIX}_EXTENSION_${f}"
    typeset result="$( __extract_value "EXTENSION_${f}" )"
    #typeset result=
    #eval "result=\${${varname}}"
    typeset known_extensions="$( __select_element "${result}" 1 | \tr ':' ' ' )"
    typeset ke
    for ke in ${known_extensions}
    do
      if [ "${ke}" == "$1" ]
      then
        language="${f}"
        break
      fi
    done
  done
  
  [ -n "${language}" ] && printf "%s\n" "${language}" || printf "%s\n" 'SHELL'
  return "${PASS}"
}

__handle_dependency_push()
{
  typeset key=$( get_element --data "$1" --id 1 --separator '|' )
  typeset ext=$( get_extension "${key}" )
  typeset val=$( get_element --data "$1" --id 2 --separator '|' | \sed -e 's# ##g' )

  [ "${key}" == "${val}" ] && return "${PASS}"

  typeset spmrk="$( __extract_value 'SPACE_MARKER' )"
  
  key="$( remove_extension "${key}" )"
  typeset maptype="$( __convert_extension_to_key "${ext}" )"
  if [ "${maptype}" != 'UNKNOWN' ]
  then
    hadd_item --map "${__PROGRAM_VARIABLE_PREFIX}_TEST_DEPENDENCY_MAP_${maptype}" --key "$2${spmrk}${key}" --value "${val}"
    #hadd_item_via_file --filename "<>" --key "$2${spmrk}${key}" --value "${val}"
  else
    return "${FAIL}"
  fi
  
  typeset latestval="$( hget --map "${__PROGRAM_VARIABLE_PREFIX}_TEST_DEPENDENCY_MAP_${maptype}" --key "$2${spmrk}${key}" )"
  #typeset latestval="$( haccess_item_via_file --filename "<>" --key "$2${spmrk}${key}" )"
  latestval=$( printf "%s\n" "${latestval}" | sed -e 's# #,#g' )

  typeset allkeys="$( hkeys --map "${__PROGRAM_VARIABLE_PREFIX}_TEST_DEPENDENCY_MAP_${maptype}" )"
  #typeset allkeys="$( haccess_keys_via_file --filename "<>" )"
  
  ###
  ### This needs to be re-written using the IO access functions to make it easier
  ###
  typeset depfile="$( __extract_value 'DEPENDENCY_FILE' )"
  if [ -f "${depfile}" ]
  then
    \cat "${depfile}" | \grep -v "${__PROGRAM_VARIABLE_PREFIX}_TEST_DEPENDENCY_MAP_${maptype}$2${spmark}${key}" | \grep -v "${__PROGRAM_VARIABLE_PREFIX}_TEST_DEPENDENCY_MAP_${maptype}keys" > "${depfile}.rmv"
    mv -f "${depfile}.rmv" "${depfile}"
  fi
  
  __import_variable --key "KEYS:${__PROGRAM_VARIABLE_PREFIX}_TEST_DEPENDENCY_MAP_${maptype}keys" --value "${allkeys}" --use-memory "${NO}" --file "${depfile}"
  __import_variable --key "ENTRY:${__PROGRAM_VARIABLE_PREFIX}_TEST_DEPENDENCY_MAP_${maptype}$2${spmrk}${key}" --value "${latestval}" --use-memory "${NO}" --file "${depfile}"
  return "${PASS}"
}

__print_harness_header()
{
  typeset key
  typeset data
  typeset prefix="$( __extract_value 'HARNESS_HEADER_PREFIX' )"
  typeset tablevel=0
  
  OPTIND=1
  while getoptex "p: prefix: k: key: d: data: t: tab-level:" "$@"
  do
    case "${OPTOPT}" in
    'k'|'key'       ) key="${OPTARG}";;
    'd'|'data'      ) data="${OPTARG}";;
    'p'|'prefix'    ) prefix="${OPTARG}";;
    't'|'tab-level' ) tablevel="${OPTARG:-0}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "${tablevel}" -lt 0 ] && tablevel=0
  [ -z "${key}" ] && return "${FAIL}"

  typeset hdtm="$( __extract_value 'HARNESS_DISPLAY_TAB_MARKER' )"
  printf "%s\n" "$( __make_tab_level --level "${tab_level}" )${prefix} ${key} : ${data}" | \sed -e "s#${hdtm}#    #g"
  return "${PASS}"
}

__select_element()
{
  typeset input="$1"
  typeset id="$2"
  
  [ -z "${input}" ] || [ -z "${id}" ] || [ "${id}" -lt 1 ] && return "${FAIL}"
  
  get_element --data "${input}" --id "${id}" --separator ':'
  return "${PASS}"
}

__verify_language_to_file()
{
  typeset input_lang
  typeset input_ext
  
  OPTIND=1
  while getoptex "l: lang: language: f: file-type:" "$@"
  do
    case "${OPTOPT}" in
    'l'|'lang'|'language' ) input_lang="$( to_upper "${OPTARG}" )";;
    'f'|'file-type'       ) input_ext="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  if [ $( is_empty --str "${input_lang}" ) -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi
  
  if [ $( is_empty --str "${input_ext}" ) -eq "${YES}" ]
  then
    if [ "${input_lang}" != 'SHELL' ]
    then
      print_no
    else
      print_yes
    fi
  else  
    #typeset extension_field="$( __define_internal_variable "EXTENSION_${input_lang}" )"
    typeset extension_class="$( __extract_value "EXTENSION_${input_lang}" )"
    #eval "extension_class=\${${extension_field}}"
  
    if [ $( is_empty --str "${extension_class}" ) -eq "${YES}" ]
    then
      print_no
    else
      typeset extension="$( __select_element "${extension_class}" 1 )"
      if [ "${extension}" != "${input_ext}" ]
      then
        print_no
      else
        print_yes
      fi
    fi
  fi
  
  return "${PASS}"
}

build_cmdline()
{
  typeset max_units=$( __get_word_count "$( __extract_value 'INPUT_TXT_PARSING_KEYWORDS' )" )
  typeset test_num_id=1
  typeset suite_num_id=1
  
  typeset cmdline_interpret="$@"
  typeset n
  typeset p
  for n in ${cmdline_interpret}
  do
    p=
    typeset numparts=$( count_items --data "${n}" --separator ':' )

    ###
    ### Verify the input from the command line is bounded by the min/max range of components that can be separated
    ###
    [ "${numparts}" -gt "${max_units}" ] || [ "${numparts}" -lt 1 ] && continue
    
    ###
    ### First element component is ALWAYS the suite path.  This is the absolute minimum entry
    ###
    typeset suitepath=$( __select_element "${n}" 1 )
    if [ -n "${suitepath}" ]
    then
      ###
      ### If ONLY the suitepath is defined, then we want to run all tests from this suite path using the
      ###   internal library rules.  We will provide the minimum necessary information so that the argument
      ###   management and grouping facility can use it.
      ###
      if [ -d "${suitepath}" ] && [ "${numparts}" -eq 1 ]
      then
        typeset suiteclass="$( \basename "${suitepath}" )"
        typeset test_setup_drv="${suitepath}/__setup_${suiteclass}.sh"
        [ ! -f "${test_setup_drv}" ] && test_setup_drv=
        p="$( ${__REALPATH} ${__REALPATH_OPTS} "${suitepath}" ):${suiteclass}:$( to_upper ${suiteclass} )::::${suite_num_id}:::${test_setup_drv}::::"
        suite_num_id=$( increment ${suite_num_id} )
        numparts="${max_units}"
      else
        ###
        ### If we are using the shorthand for the SLCF testing, then we need to ensure we have the
        ###   minimum amount of data present
        ###
        if [ -d "${SLCF_SHELL_TOP}/test/${suitepath}" ]
        then
          typeset test_setup_drv="${SLCF_SHELL_TOP}/test/${suitepath}/__setup_${suitepath}.sh"
          [ ! -f "${test_setup_drv}" ] && test_setup_drv=
          
          if [ "${numparts}" -eq 1 ]
          then
            p="${SLCF_SHELL_TOP}/test/${suitepath}:${suitepath}:$( to_upper ${suitepath} )::${SLCF_SHELL_TOP}/test/${suitepath}/test_${suitepath}.sh:${suite_num_id}::::${test_setup_drv}::::"
            suite_num_id=$( increment ${suite_num_id} )
          fi
          if [ "${numparts}" -eq 2 ]
          then
            typeset testname="$( __handle_spaced_output "$( __select_element "${n}" 2 )" )"
            [ ! -f "${SLCF_SHELL_TOP}/test/${suitepath}/${testname}" ] && continue
            ###
            ### Need to keep track of which directories I've seen to be sure I have the right suite_ID
            ###
            typeset matching_idx=$( list_find --object 'suite_list' --match "${suitepath}" )
            if [ -n "${matching_idx}" ]
            then
              p="${SLCF_SHELL_TOP}/test/${suitepath}:${suitepath}:$( to_upper ${suitepath} )::${SLCF_SHELL_TOP}/test/${suitepath}/test_${suitepath}.sh:${matching_idx}:${testname}:${test_num_id}::${test_setup_drv}:::::"
            else
              list_add --object 'suite_list' --data "${suitepath}"
              p="${SLCF_SHELL_TOP}/test/${suitepath}:${suitepath}:$( to_upper ${suitepath} )::${SLCF_SHELL_TOP}/test/${suitepath}/test_${suitepath}.sh:${suite_num_id}:${testname}:${test_num_id}::${test_setup_drv}:::::"              
              suite_num_id=$( increment ${suite_num_id} )
            fi
            test_num_id=$( increment ${test_num_id} )
          fi
        fi
      fi
    else
      continue
    fi
    
    [ -n "${p}" ] && printf "%s\n" "$( trim ${p} )"
  done
  return "${PASS}"
}

collect_tags()
{
  typeset allowance="${NO}"
  [ "$( __check_for --key 'ALLOW_NO_TAGS' --success )" -eq "${YES}" ] && allowance="${YES}"
  
  typeset test=
  typeset alltags=
  
  OPTIND=1
  while getoptex "t: test:" "$@"
  do
    case "${OPTOPT}" in
    't'|'test' ) test="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${test}" ) -eq "${YES}" ] && return "${FAIL}"
  
  typeset test_tags=
  
  ###
  ### Collect tag definitions from file to see if they "conform"
  ###   to defined global tags
  ###
  typeset tag_aliases=$( use_tag_aliases --filename "${test}" )
  if [ -z "${tags}" ] && [ "${allowance}" -eq "${YES}" ]
  then
    typeset tal
    for tal in ${tag_aliases}
    do
      typeset tagline_entries=$( \cat "${test}" | \sed -n "/#\+[ \t]*${tal}[ \t]*:/p" | \sed -e 's/#\+/# /g' -e 's/:[ \t]*/: /g' | \awk -F'#' '{print $2}' | \tr -s ' ' | \awk -F ': ' '{print $2}' | \sed -e 's# *##g' | \tr ',' ' ' )
      typeset tgl
      for tgl in ${tagline_entries}
      do
        test_tags+=" ${tgl}"
      done
    done
  fi
  
  printf "%s\n" "${test_tags}"
  return "${PASS}"
}

compute_percentage()
{
  typeset part="$1"
  typeset whole="$2"
  
  if [ -z "${part}" ] || [ -z "${whole}" ]
  then
    printf "%s\n" '0.0'
    return "${FAIL}"
  else
    typeset result=$( printf "%s\n" "scale=3; ( ${part}/${whole} + 0.00005 ) * 100.0" | \bc )
    printf "%.1f" "${result}"
    return "${PASS}"
  fi
}

display_files_in_build_system()
{
  typeset outputdir="$1"
  typeset return_code="$2"
  typeset display_files=

 if [ -n "$( __extract_value 'MANAGE_BUILD_SYSTEM' )" ]
 then
    printf "%s\n\n"
    display_files="${outputdir}/cmds_run.log ${outputdir}/RESULTS/outputs/subsystem_results.txt.final"
    #display_files+="$( \find "${outputdir}" -type f -exec printf "%s " '"{}"' \; )"
    #typeset dfl=
    #for dfl in ${display_files}
    #do
    #  dfl="$( printf "%s\n" "${dfl}" | \sed -e 's/^"//' -e 's/"$//' )"
      #### Should rewrite this to be an AND to make it short-circuit the loop
    #  typeset showfl="${NO}"
    #  if [ "${RC}" -eq "${PASS}" ]
    #  then
    #    printf "%s\n" "${dfl}" | \grep -q '.log$'  ### Grab log files
    #    typeset islg=$?

    #    printf "%s\n" "${dfl}" | \grep -q '.data$'  #### Grab result data files...
    #    typeset isdt=$?

    #    printf "%s\n" "${dfl}" | \grep -q 'subsystem_results' ### Grab data collection reports
    #    typeset istxt=$?

    #    if [ "${islg}" -eq "${PASS}" ] || [ "${isdt}" -eq "${PASS}" ] || [ "${istxt}" -eq "${PASS}" ]
    #    then
    #      showfl="${YES}"
    #    fi
    #  else
    #    showfl="${YES}"
    #  fi
    #  if [ "${showfl}" -eq "${YES}" ]
    #  then
    #    print_btf_detail --msg "File : ${dfl}" --newline-count 2
    #    \cat "${dfl}"
    #  fi
    #done
    typeset dfl=
    for dfl in ${display_files}
    do
      print_btf_detail --msg "${dfl}" --prefix "[OUTPUT_FILE]"
      \cat "${dfl}"
      printf "%s\n\n"
    done
  fi

  return "${PASS}"
}

find_tests()
{
  typeset path=
  
  OPTIND=1
  while getoptex "p: path:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path'  ) path="${OPTARG}";;
   esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${path}" ] || [ ! -d "${path}" ] && return "${PASS}"
  
  typeset testfiles=$( get_test_suite_files --path "${path}" )
  printf "%s\n" ${testfiles}

  return "${PASS}"
}

get_class_map_files()
{
  typeset path=
  typeset remove_path="${NO}"
  
  OPTIND=1
  while getoptex "p: path: r remove-path" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path'         ) path="${OPTARG}";;
    'r'|'remove-path'  ) remove_path="${YES}";;
   esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${path}" ] || [ ! -d "${path}" ] && return "${PASS}"

  typeset maplist="$( \find "${path}" -maxdepth 1 -name "*_class.map" )"
  if [ "${remove_path}" -eq "${YES}" ]
  then
    printf "%s\n" "${maplist}" | \sed -e "s#${path}\/##g"
  else
    printf "%s\n" "${maplist}"
  fi
  return "${PASS}"
}

group_tests()
{
  [ ! -f "$( __extract_value 'ARGUMENT_FILE' )" ] && return "${FAIL}"

  typeset t

  ###
  ### Field 1  : class path
  ### Field 2  : class ID
  ### Field 3  : subject name
  ### Field 4  : language specification
  ### Field 5  : global driver
  ### Field 6  : suite id
  ### Field 7  : test name
  ### Field 8  : test id
  ### Field 9  : test driver
  ### Field 10 : test_setup_driver
  ### Field 11 : test args
  ### Field 12 : test dependencies
  ### Field 13 : test tags
  ### Field 14 : test result expectation
  ###
  
  typeset classmap
  typeset current_class_id=
  typeset all_global_tags=
  
  typeset previous_error_warn_marker=$( __calculate_filesize "$( __extract_value 'LOGFILE' )" )
  
  ###
  ### Check to see if tagging is enabled.  If so, only allow tests to run which satisfy
  ### the requisite tags ( or no tags at all with selective switch )
  ###
  if [ $( __check_for --key 'USE_TAGS' --success ) -eq "${YES}" ]
  then
    all_global_tags="$( printf "%s\n" "$( __extract_value 'TAG' )" | \awk '{$1=$1;print}' | \tr ' ' ',' )"
    
    [ $( __check_for --key 'IGNORE_TAG_CASE' --success ) -eq "${YES}" ] && all_global_tags="$( printf "%s\n" "${all_global_tags}" | \tr "[:upper:]" "[:lower:]" )"

    all_global_tags="$( printf "%s\n" "${all_global_tags}" | \tr -s ' ' | \awk -F',' '{for(i=1;i<=NF;i++) a[$i]++} END{for(i in a) printf i",";print ""}' | \sed -e 's#,$##' -e 's#^,##' )"
  fi

  #typeset global_class_mapfile="$( __extract_value 'RESULTS_DIR' )/all_classes.map"
  
  ###
  ### Does it make sense to use a temporary file to play with to help make this part faster?
  ###
  typeset classmap_keys="$( hkeys --map 'classmap' )"
  #typeset classmap_keys="$( haccess_keys_in_file --filename "${global_class_mapfile}" )"
  if [ $( is_empty --str "${classmap_keys}" ) -eq "${YES}" ]
  then
    hput --map 'classmap' --key 'global_tags' --value "${all_global_tags}"
    #hadd_item_via_file --filename "${global_class_mapfile}" --key 'global_tags' --value "${all_global_tags}"
    [ $( __check_for --key 'TAG_DEPENDENCE' --success ) -eq "${YES}" ] && hput --map 'classmap' --key 'tag_dependence' --value "$( __extract_value 'TAG_DEPENDENCE' )"
    [ $( __check_for --key 'TAG_ALIAS' --success ) -eq "${YES}" ] && hput --map 'classmap' --key 'tag_aliases' --value "$( __extract_value 'TAG_ALIAS' )"
    #[ -n "$( __extract_value 'TAG_DEPENDENCE' )" ] && hadd_item_via_file --filename "${global_class_mapfile}" --key 'tag_dependence' --value "$( __extract_value 'TAG_DEPENDENCE' )"
    #[ -n "$( __extract_value 'TAG_ALIAS' )" ] && hadd_item_via_file --filename "${global_class_mapfile}" --key 'tag_aliases' --value "$( __extract_value 'TAG_ALIAS' )"
  fi
  
  typeset skip_class_id="${NO}"

  ###
  ### Used when we auto-discover tests
  ###
  typeset test_id=1
  
  typeset grouping_datamap=
  
  while read -r -u 9 t
  do
    append_output --data "Processing data input : ${t}" --channel "$( __define_internal_variable 'INFO' )" --raw
    ###
    ### Interpret data for each line of argument file
    ###
    typeset temp_path="$( __select_element "${t}" 1 )"
    [ $( is_empty --str "${temp_path}" ) -eq "${YES}" ] && continue
    
    if [ ! -d "${temp_path}" ]
    then
      typeset predefined_badpath=$( hcontains --map 'grouping_datamap' --key 'bad_paths' --match "${temp_path}" )
      if [ "${predefined_badpath}" -eq "${NO}" ]
      then
        if [ -n "${suite_class_id}" ]
        then
          print_btf_detail --msg "Found non-existent location  << ${temp_path} >> for suite << ${suite_class_id} >>.  Skipping!" --prefix "$( __extract_value 'PREFIX_ERROR' )"
          log_warning "Found non-existent location  << ${temp_path} >> for suite << ${suite_class_id} >>.  Skipping!"
        else
          print_btf_detail --msg "Found non-existent location  << ${temp_path} >> for suite.  Skipping!" --prefix "$( __extract_value 'PREFIX_ERROR' )"
          log_warning "Found non-existent location  << ${temp_path} >> for suite.  Skipping!"
        fi          
        hadd_item --map 'grouping_datamap' --key 'bad_paths' --value "${temp_path}"
      fi
      continue
    fi
    
    typeset suite_class_id="$( trim "$( __select_element "${t}" 2 )" )"
    
    ###
    ### Determine actual suite path by resolving with ${__REALPATH}
    ###
    typeset suite_path="$( ${__REALPATH} ${__REALPATH_OPTS} "${temp_path}" )"

    [ $( is_empty --str "${current_class_id}" ) -eq "${YES}" ] && current_class_id="${suite_class_id}"
    
    typeset already_seen_suite="${FAIL}"
    typeset seen_suites="$( hget --map 'classmap' --key 'known_suites' )"
    #typeset seen_suites="$( haccess_entry_via_file --filename "${global_class_mapfile}" --key 'known_suites' )"

    if [ $( is_empty --str "${seen_suites}" ) -eq "${NO}" ]
    then
      printf "%s\n" ${seen_suites} | \grep -q "${suite_class_id}"
      already_seen_suite=$?
    fi
    if [ "${already_seen_suite}" -eq "${FAIL}" ]
    then
      [ "$( __check_for --key 'DETAIL' --success )" -eq "${YES}" ] && print_btf_detail --msg "Test grouping in progress for << ${suite_class_id} >>" --prefix "$( __extract_value 'PREFIX_DETAIL' )"
    fi
    
    ###
    ### Keep separate map for each suite class
    ###
    if [ $( is_empty --str "${current_class_id}" ) -eq "${NO}" ] && [ "${current_class_id}" != "${suite_class_id}" ]
    then
      skip_class_id="${NO}"
      
      typeset suite_keys="$( hget --map "${current_class_id}" --key 'suite_tests' )"      
      typeset storage_suite_dir="$( __extract_value 'TEST_SUITES' )/${current_class_id}"
      \mkdir -p "${storage_suite_dir}"
      
      hpersist --map "${current_class_id}" --filename "$( __extract_value 'TEST_SUITES' )/${current_class_id}_class.map"
      typeset mpt
      for mpt in ${suite_keys}
      do
        typeset filemap="$( __generate_filemap_name --suite "${current_class_id}" --test "${mpt}" )"
        hpersist --map "${filemap}" --filename "${storage_suite_dir}/${mpt}.map"
        hclear --map "${filemap}"
      done
      
      hclear --map "${current_class_id}"
      current_class_id="${suite_class_id}"
    else
      ###
      ### Skip a suite if requested to do so ( insufficient information or non-consistent information )
      ###
      [ "${skip_class_id}" -eq "${YES}" ] && continue
    fi
    
    record_step ${HOTSPOT_FLAGS} --header 'suite deciphering' --start --overhead 'DYNAMIC'
    typeset suite_subject="$( trim "$( __select_element "${t}" 3 )" )"
    typeset suite_language="$( to_upper "$( trim "$( __select_element "${t}" 4 )" )" )"
    typeset suite_driver="$( __select_element "${t}" 5 )"
    typeset suite_num_id="$( __select_element "${t}" 6 )"
    record_step ${HOTSPOT_FLAGS} --header 'suite deciphering' --stop --overhead 'DYNAMIC'
    
    ###
    ### Start recording the information necessary for stage manipulation
    ###
    if [ $( __check_for --key 'WORKFLOW' --success ) -eq "${YES}" ]
    then
      hadd_entry_via_file --filename "$( __extract_value 'WORKFLOW_MAPFILE' )" --key "${suite_class_id}" --value "STAGE_${suite_num_id}" --mapname "$( __extract_value 'WORKFLOW_MAPNAME' )"
      hadd_entry_via_file --filename "$( __extract_value 'WORKFLOW_MAPFILE' )" --key "STAGE_${suite_num_id}" --value "${suite_class_id}"
      hadd_entry_via_file --filename "$( __extract_value 'WORKFLOW_MAPFILE' )" --key "STAGE_${suite_num_id}_OUTPUT" --value "$( __extract_value 'RESULTS_DIR' )/RESULTS/${suite_class_id}"
      hadd_entry_via_file --filename "$( __extract_value 'WORKFLOW_MAPFILE' )" --key "STAGE_${suite_num_id}_BYPASS_FAILURE_FLAGS" --value "${NO}"
    fi
    
    typeset test_file="$( trim "$( __select_element "${t}" 7 )" )"

    if [ $( is_empty --str "${test_file}" ) -eq "${NO}" ]
    then
      if [ ! -f "${suite_path}/${test_file}" ]
      then
        log_warning "Requested test file << ${test_file} >> can NOT be found under << ${suite_path} >>"
        continue
      fi
    fi
    
    typeset test_num_id="$( trim "$( __select_element "${t}" 8 )" )"
    typeset test_driver="$( trim "$( __select_element "${t}" 9 )" )"
    typeset test_setupdrv="$( trim "$( __select_element "${t}" 10 )" )"

    ###
    ### Remove individually defined tests if all tests are expected to run
    ### This will automatically choose proper driver and scans for args and deps
    ###
    if [ $( is_empty --str "${test_file}" ) -eq "${YES}" ] || [ "${test_file}" == "$( __extract_value 'EMPTY_TEST_MARKER' )" ]
    then
      hadd_item --map 'classmap' --key 'known_suites' --value "${suite_class_id}"
      #hadd_entry_via_file --filename "${global_class_mapfile}" --key 'known_suites' --value "${suite_class_id}"
      
      typeset tmap
      for tmap in $( hget --map "${current_class_id}" --key 'suite_tests' )
      do
        hclear --map "${tmap}"
      done
      hdel --map "${current_class_id}" --key 'suite_tests'
      hdel --map "${current_class_id}" --key 'suite_language'
      #hdelete_entry_via_file --filename "<>" --key 'suite_tests'
      #hdelete_entry_via_file --filename "<>" --key 'suite_language'
      
      record_step ${HOTSPOT_FLAGS} --header "find_tests_${suite_num_id}" --start --msg "find for tests at location << ${suite_path} >>" --overhead 'DYNAMIC'
      typeset discovered_tests="$( find_tests --path "${suite_path}" | tr '\n' ' ' )"
      record_step ${HOTSPOT_FLAGS} --header "find_tests_${suite_num_id}" --stop --msg "find for tests at location << ${suite_path} >>" --overhead 'DYNAMIC'

      hput --map "${current_class_id}" --key 'autodiscovery' --value "${YES}"
      #hadd_entry_via_file --filename "<>" --key 'autodiscovery' --value "${YES}"
      
      ###
      ### Define a global suite driver and check to see if it exists before assigning it...
      ###
      [ $( is_empty --str "${suite_driver}" ) -eq "${YES}" ] && suite_driver="${suite_path}/${suite_class_id}/test_${suite_class_id}.sh"
      [ ! -f "${suite_driver}" ] && suite_driver=
            
      hupdate --map "${current_class_id}" --key 'suite_subject' --value "${suite_subject}"
      hupdate --map "${current_class_id}" --key 'suite_path' --value "${suite_path}"
      hupdate --map "${current_class_id}" --key 'suite_id' --value "${suite_num_id}"
      [ -n "${suite_driver}" ] && hupdate --map "${current_class_id}" --key 'global_driver' --value "${suite_driver}"

      #hchange_entry_via_file --filename "<>" --key 'suite_subject' --value "${suite_subject}"
      #hchange_entry_via_file --filename "<>" --key 'suite_path' --value "${suite_path}"
      #hchange_entry_via_file --filename "<>" --key 'suite_id' --value "${suite_num_id}"
      #[ -n "${suite_driver}" ] && hchange_entry_via_file --filename "<>" --key 'global_driver' --value "${suite_driver}"
      
      typeset dt_cnt=1
      typeset dt
      record_step ${HOTSPOT_FLAGS} --header "autodiscovery_${suite_num_id}" --start --msg "processing of autodiscovery [ ${suite_subject} ]" --overhead 'DYNAMIC'
      for dt in ${discovered_tests}
      do
        append_output --data "Processing discovered test < ${dt} > for suite < ${suite_subject} >" --channel "$( __define_internal_variable 'INFO' )" --raw
        ###
        ### Use test embedded information to provide for running
        ###
        [ $( is_empty --str "${test_driver}" ) -eq "${YES}" ] || [ ! -f "${test_driver}" ] && test_driver="$( __discover_driver_for_test --test "${dt}" )"
        
        test_args="$( __discover_arguments_for_test --test "${dt}" )"
        test_deps="$( __discover_dependencies_for_test --test "${dt}" )"
        test_tags="$( collect_tags --test "${suite_path}/${dt}" )"
        
        ###
        ### Possibly get this one written to file directly using access_via_file calls [ might save a little time per test ]
        ###
        typeset reduced_tfn="$( __generate_map_testname --test "${dt}" )"
        hadd_item --map "${current_class_id}" --key 'suite_tests' --value "${dt_cnt}_ID_${reduced_tfn}"
        #hadd_entry_via_file --filename "<>" --key 'suite_tests' --value "${dt_cnt}_ID_${reduced_tfn}"
        
        typeset filemap="$( __generate_filemap_name --suite "${current_class_id}" --test "${dt_cnt}_ID_${reduced_tfn}" )"
        
        [ $( is_empty --str "$( hkeys --map "${filemap}" )" ) -eq "${YES}" ] && eval "${filemap}="
        
        [ $( is_empty --str "${test_setupdrv}") -eq "${NO}" ] && hupdate --map "${filemap}" --key 'test_setupdrv' --value "${test_setupdrv}"
        hupdate --map "${filemap}" --key 'full_testname' --value "${dt}"
        hupdate --map "${filemap}" --key 'test_id' --value "${dt_cnt}"
        hupdate --map "${filemap}" --key 'suite_path' --value "${suite_path}"
        hupdate --map "${filemap}" --key 'local_driver' --value "${test_driver}"
        hupdate --map "${filemap}" --key 'expected_result' --value "$( __discover_expected_result_for_test --test "${suite_path}/${dt}" )"
        
        [ $( is_empty --str "${test_args}" ) -eq "${NO}" ] && hupdate --map "${filemap}" --key 'executable_arguments' --value "A${test_args}"
        [ $( is_empty --str "${test_deps}" ) -eq "${NO}" ] && hupdate --map "${filemap}" --key 'dependencies' --value "${test_deps}"
        [ "$( __check_for --key 'USE_TAGS' --success )" -eq "${YES}" ] && [ -n "${test_tags}" ] && hupdate --map "${filemap}" --key 'local_tags' --value "${test_tags}"
 
        #hchange_entry_via_file --filename "<>" --key 'full_testname' --value "${dt}"
        #hchange_entry_via_file --filename "<>" --key 'test_id' --value "${dt_cnt}"
        #hchange_entry_via_file --filename "<>" --key 'suite_path' --value "${suite_path}"
        #hchange_entry_via_file --filename "<>" --key 'local_driver' --value "${test_driver}"
        #hchange_entry_via_file --filename "<>" --key 'expected_result' --value "$( __discover_expected_result_for_test --test "${suite_path}/${dt}" )"
        
        #[ -n "${test_args}" ] && hchange_entry_via_file --filename "<>" --key 'executable_arguments' --value "A${test_args}"
        #[ -n "${test_deps}" ] && hchange_entry_via_file --filename "<>" --key 'dependencies' --value "${test_deps}"
        #[ "$( __check_for --key 'USE_TAGS' --success )" -eq "${YES}" ] && [ -n "${test_tags}" ] && hchange_entry_via_file --filename "<>" --key 'local_tags' --value "${test_tags}"

        dt_cnt=$( increment "${dt_cnt}" )
      done
      record_step ${HOTSPOT_FLAGS} --header "autodiscovery_${suite_num_id}" --stop --msg "processing of autodiscovery [ ${suite_subject} ]" --overhead 'DYNAMIC'
      continue
    fi

    hput --map "${current_class_id}" --key 'autodiscovery' --value "${NO}"
    
    if [ $( is_empty --str "${suite_driver}" ) -eq "${YES}" ]
    then
      if [ $( is_empty --str "${test_file}" ) -eq "${NO}" ]
      then
        test_driver="$( __discover_driver_for_test --test "${test_file}" )"
      else
        log_warning "Reached a condition which should NOT have happened if all corner cases were accounted.  Empty test_file entry at this point"
        continue
      fi
    fi
    
    ###
    ### If the suite language is set then additional checks wil be done for the driver and the tests
    ###   in question.  If there are intended to be multiple languages supported, leave out the
    ###   test_lang specification to allow the system to automatically determine the language when running the tests
    ###
    record_step ${HOTSPOT_FLAGS} --header "suite_verification_${suited_num_id}" --start --msg "verification of suite language" --overhead 'DYNAMIC'
    if [ -n "${suite_language}" ]
    then
      if [ -n "${suite_driver}" ]
      then
        typeset td_base="$( \basename "${suite_driver}" )"
        if [ $( __verify_language_to_file --language "${suite_language}" --file-type "$( get_extension "${td_base}" )" ) -ne "${YES}" ]
        then
          log_warning "Global Driver << ${suite_driver} >> specified does NOT match requested Language << ${suite_language} >>.  Skipping this section!"
          skip_class_id="${YES}"
          continue
        #else
        #  if [ $( __verify_language_to_file --language "${suite_language}" --file-type "$( get_extension "${test_file}" )" ) -ne "${YES}" ]
        #  then
        #    log_warning "Test File << ${test_file} >> specified does NOT match requested Language << ${suite_language} >>.  Skipping this file!"
        #    continue
        #  fi
        fi
      else
        if [ $( __verify_language_to_file --language "${suite_language}" --file-type "$( get_extension "${test_file}" )" ) -ne "${YES}" ]
        then
          log_warning "Test File << ${test_file} >> specified does NOT match requested Language  << ${suite_language} >>.  Skipping this file!"
          skip_class_id="${YES}"
          continue
        fi
      fi
    #else      
    #  if [ -n "${suite_driver}" ] && [ -n "${test_file}" ]
    #  then
    #    typeset td_base="$( basename "${suite_driver}" )"
    #    typeset driver_lang="$( __get_associated_language --extension "$( get_extension "${td_base}" )" )"
    #    if [ $( __verify_language_to_file --language "${driver_lang}" --file-type "$( get_extension "${test_file}" )" ) -ne "${YES}" ]
    #    then
    #      log_warning "Global Driver << ${suite_driver} >> not supported for test << ${test_file} >> due to language mismatch.  Skipping this test!"
    #      continue
    #    fi
    #  fi
    fi
    record_step ${HOTSPOT_FLAGS} --header "suite_verification_${suited_num_id}" --stop --msg "verification of suite language" --overhead 'DYNAMIC'

    record_step ${HOTSPOT_FLAGS} --header 'test deciphering' --start --overhead 'DYNAMIC'
    typeset test_args="$( __select_element "${t}" 11 )"
    typeset test_deps="$( trim "$( __select_element "${t}" 12 | \tr ',' ' ' )" )"                 # List of dependences (space separated)
    typeset test_tags="$( to_lower "$( trim "$( __select_element "${t}" 13 | \tr ',' ' ' )" )" )" # List of tags ( space separated )
    typeset test_result="$( __discover_expected_result_for_test --test "${suite_path}/${test_file}" )"
    [ $( is_empty --str "${test_result}" ) -eq "${YES}" ] && test_result="$( __select_element "${t}" 14 )"
    record_step ${HOTSPOT_FLAGS} --header 'test deciphering' --stop --overhead 'DYNAMIC'
    
    ###
    ### Need to see if "tags" are defined in the test itself which should be collected
    ###
    record_step ${HOTSPOT_FLAGS} --header "tag_collection_${test_num_id}" --start --msg "tag collection for test << ${suite_path}/${test_file} >>" --overhead 'DYNAMIC'
    test_tags+=" $( collect_tags --test "${suite_path}/${test_file}" )"
    record_step ${HOTSPOT_FLAGS} --header "tag_collection_${test_num_id}" --stop --msg "tag collection for test << ${suite_path}/${test_file} >>" --overhead 'DYNAMIC'
    
    ###
    ### "Weed" out tests which do not fit the tagging requirements (if defined)
    ###
    record_step ${HOTSPOT_FLAGS} --header "tag_matching_${test_num_id}" --start --overhead 'DYNAMIC'
    typeset tt
    typeset tag_match_found=
    typeset tag_matched_count=0
    typeset test_tag_pass="${NO}"
    
    for tt in ${all_global_tags}
    do
      printf "%s\n" ${test_tags} | \grep -q "${tt}"
      typeset RC=$?
      
      ###
      ### Need to check is SLCF_TAG_DEPENDENCE is one which means ALL tags must be found
      ###
      if [ "$( __check_for --key 'TAG_DEPENDENCE' --success )" -eq "${YES}" ]
      then
        if [ "${RC}" -eq "${PASS}" ]
        then
          tag_matched_count=$( increment ${tag_matched_count} )
        else
          break
        fi
      else
        if [ "${RC}" -eq "${PASS}" ]
        then
          test_tag_pass="${YES}"
          break
        fi
      fi
    done
    
    if [ "$( __check_for --key 'USE_TAGS' --success )" -eq "${YES}" ]
    then
      if [ "$( __check_for --key 'TAG_DEPENDENCE' --success )" -eq "${YES}" ]
      then
        [ "${tag_matched_count}" -ge "$( __get_count_of_items words "${all_global_tags}" )" ] && test_tag_pass="${YES}"
      else
        [ "${test_tag_pass}" -eq "${NO}" ] && continue
      fi
    fi
    record_step ${HOTSPOT_FLAGS} --header "tag_matching_${test_num_id}" --stop --overhead 'DYNAMIC'
    
    append_output --data "Processing individual test : ${test_file}" --channel "$( __define_internal_variable 'INFO' )" --raw

    typeset reduced_tfn="$( __generate_map_testname --test "${test_file}" )"
    
    typeset classmap_keys="$( hkeys --map 'classmap' )"
    typeset filemap="$( __generate_filemap_name --suite "${current_class_id}" --test "${test_num_id}_ID_${reduced_tfn}" )"

    if [ $( is_empty --str "${classmap_keys}" ) -eq "${YES}" ]
    then
      hadd_item --map 'classmap' --key 'known_suites' --value "${suite_class_id}"
      hupdate --map 'classmap' --key 'global_tags' --value "${all_global_tags}"
      [ $( is_empty --str "$( __extract_value 'TAG_DEPENDENCE' )" ) -eq "${NO}" ] && hupdate --map 'classmap' --key 'tag_dependence' --value "$( __extract_value 'TAG_DEPENDENCE' )"
      [ $( is_empty --str "$( __extract_value 'TAG_ALIAS' )" ) -eq "${NO}" ] && hupdate --map 'classmap' --key 'tag_aliases' --value "$( __extract_value 'TAG_ALIAS' )"
      
      [ $( hexists_map --map "${suite_class_id}" ) -eq "${YES}" ] && eval "${suite_class_id}="
      
      hupdate --map "${suite_class_id}" --key 'suite_subject' --value "${suite_subject}"
      hupdate --map "${suite_class_id}" --key 'suite_path' --value "${suite_path}"
      hupdate --map "${suite_class_id}" --key 'suite_id' --value "${suite_num_id}"
      
      [ $( is_empty --str "${suite_driver}" ) -eq "${NO}" ] && hupdate --map "${suite_class_id}" --key 'global_driver' --value "${suite_driver}"
      [ $( is_empty --str "${suite_language}" ) -eq "${NO}" ] && hupdate --map "${current_class_id}" --key 'suite_language' --value "${suite_language}"
      hadd_item --map "${suite_class_id}" --key 'suite_tests' --value "${test_num_id}_ID_${reduced_tfn}"
      hput --map "${suite_class_id}" --key 'autodiscovery' --value "${NO}"
            
      if [ "${test_file}" != "$( __extract_value 'EMPTY_TEST_MARKER' )" ]
      then
        [ $( is_empty --str "$( hkeys --map "${filemap}" )" ) -eq "${YES}" ] && eval "${filemap}="
        
        [ $( is_empty --str "${test_setupdrv}") -eq "${NO}" ] && hupdate --map "${filemap}" --key 'test_setupdrv' --value "${test_setupdrv}"
        hupdate --map "${filemap}" --key 'full_testname' --value "${test_file}"
        hupdate --map "${filemap}" --key 'suite_path' --value "${suite_path}"
        hupdate --map "${filemap}" --key 'test_id' --value "${test_num_id}"
        hupdate --map "${filemap}" --key 'expected_result' --value "${test_result}"
        
        [ $( is_empty --str "${test_driver}" ) -eq "${YES}" ] && test_driver="$( __discover_driver_for_test --test "${test_file}" )"
        
        [ $( is_empty --str "${test_driver}" ) -eq "${NO}" ] && hupdate --map "${filemap}" --key 'local_driver' --value "${test_driver}"
        [ "${test_args}" != 'A' ] && hupdate --map "${filemap}" --key 'executable_arguments' --value "${test_args}"
        [ $( is_empty --str "${test_deps}" ) -eq "${NO}" ] && hupdate --map "${filemap}" --key 'dependencies' --value "${test_deps}"
        [ "$( __check_for --key 'USE_TAGS' --success )" -eq "${YES}" ] && [ $( is_empty --str "${test_tags}" ) -eq "${NO}" ] && hupdate --map "${filemap}" --key 'local_tags' --value "${test_tags}"
      else
        ###
        ### Collect all the files in the suite path variable
        ### Possibly select based by language and then add each one as its own filemap
        ###
        hput --map "${suite_class_id}" --key 'autodiscovery' --value "${YES}"
        
        typeset ft_cnt=1
        typeset found_tests=$( find_tests --path "${suite_path}" )
        typeset ft=
        for ft in ${found_tests}
        do
          append_output --data "Processing discovered test : ${ft}" --channel "$( __define_internal_variable 'INFO' )" --raw
          reduced_tfn="$( __generate_map_testname --test "${ft}" )"
          typeset ad_filemap="$( __generate_filemap_name --suite "${current_class_id}" --test "${ft_cnt}_ID_${reduced_tfn}" )"
          
          [ $( is_empty --str "${test_setupdrv}") -eq "${NO}" ] && hupdate --map "${ad_filemap}" --key 'test_setupdrv' --value "${test_setupdrv}"
          hupdate --map "${ad_filemap}" --key 'full_testname' --value "${ft}"
          hupdate --map "${ad_filemap}" --key 'suite_path' --value "${suite_path}"
          hupdate --map "${ad_filemap}" --key 'test_id' --value "${ft_cnt}"
          hupdate --map "${ad_filemap}" --key 'expected_result' --value "$( __discover_expected_result_for_test --test ""${suite_path}/${dt}"" )"
          
          test_driver="$( __discover_driver_for_test --test "${ft_cnt}")"
          
          [ $( is_empty --str "${test_driver}" ) -eq "${NO}" ] && hupdate --map "${ad_filemap}" --key 'local_driver' --value "${test_driver}"
          
          hupdate --map "${ad_filemap}" --key 'executable_arguments' --value "A$( __discover_arguments_for_test --test "${test_file}" )"
          hupdate --map "${ad_filemap}" --key 'dependencies' --value "$( __discover_dependencies_for_test --test "${test_file}" )"
          [ "$( __check_for --key 'USE_TAGS' --success )" -eq "${YES}"] && [ $( is_empty --str "${test_tags}" ) -eq "${NO}" ] && hupdate --map "${ad_filemap}" --key 'local_tags' --value "$( check_for_test_tags --test "${test_path}/${test_file}" )"
          ft_cnt=$( increment ${ft_cnt} )
        done
      fi
    else
      typeset new_map_added="${NO}"
      if [ $( hcontains --map 'classmap' --key 'known_suites' --match "${current_class_id}" ) -eq "${NO}" ]
      then
        eval "${suite_class_id}="
        hadd_item --map 'classmap' --key 'known_suites' --value "${suite_class_id}" --unique
        hupdate --map "${suite_class_id}" --key 'suite_subject' --value "${suite_subject}"
        hupdate --map "${suite_class_id}" --key 'suite_path' --value "${suite_path}"
        hupdate --map "${suite_class_id}" --key 'suite_id' --value "${suite_num_id}"
        [ $( is_empty --str "${suite_driver}" ) -eq "${NO}" ] && hupdate --map "${suite_class_id}" --key 'global_driver' --value "${suite_driver}"
        new_map_added="${YES}"
      fi
    
      if [ "${new_map_added}" -eq "${NO}" ]
      then
        if [ $( hcontains --map "${suite_class_id}" --key 'suite_subject' --match "${suite_subject}" ) -eq "${NO}" ]
        then
          log_warning "Found contradictory Subject name associated to class << ${suite_class_id} >>.  Skipping entry..."
          continue
        fi   
      fi
      
      new_map_added="${NO}"
      if [ "${test_file}" != "$( __extract_value 'EMPTY_TEST_MARKER' )" ]
      then
        if [ $( hcontains --map "${suite_class_id}" --key 'suite_tests' --match "${test_num_id}_ID_${reduced_tfn}" ) -eq "${NO}" ]
        then
          hadd_item --map "${suite_class_id}" --key 'suite_tests' --value "${test_num_id}_ID_${reduced_tfn}"
          eval "${filemap}=\"\$( __generate_filemap_name --suite "${suite_class_id}" --test "${test_num_id}_ID_${reduced_tfn}" )\""
          new_map_added="${YES}"
        fi

        if [ "${new_map_added}" -eq "${YES}" ]
        then
          hupdate --map "${filemap}" --key 'full_testname' --value "${test_file}"
          hupdate --map "${filemap}" --key 'suite_path' --value "${suite_path}"
          hupdate --map "${filemap}" --key 'test_id' --value "${test_num_id}"
          hupdate --map "${filemap}" --key 'expected_result' --value "${test_result}"
          
          [ $( is_empty --str "${test_setupdrv}") -eq "${NO}" ] && hupdate --map "${filemap}" --key 'test_setupdrv' --value "${test_setupdrv}"
          [ $( is_empty --str "${test_driver}" ) -eq "${YES}" ] && test_driver="$( __discover_driver_for_test --test "${test_file}" )"
          [ $( is_empty --str "${test_driver}" ) -eq "${NO}" ] && hupdate --map "${filemap}" --key 'local_driver' --value "${test_driver}"
          [ $( is_empty --str "${suite_setupdrv}") -eq "${NO}" ] && hupdate --map "${filemap}" --key 'suite_setupdrv' --value "${suite_setupdrv}"

          [ "${test_args}" != 'A' ] && hupdate --map "${filemap}" --key 'executable_arguments' --value "${test_args}"
          [ $( is_empty --str "${test_deps}" ) -eq "${NO}" ] && hupdate --map "${filemap}" --key 'dependencies' --value "${test_deps}"
          [ $( is_empty --str "${test_tags}" ) -eq "${NO}" ] && hupdate --map "${filemap}" --key 'local_tags' --value "${test_tags}"
        else
          log_warning "Found duplicate test name << ${test_file} >> associated to class id << ${current_class_id} >>.  Skipping entry..."
          continue
        fi   
      fi
    fi
  done 9< "$( __extract_value 'ARGUMENT_FILE' )"
  
  hpersist --map 'grouping_datamap' --filename "$( __extract_value 'GROUPING_STATS_FILE' )"
  
  if [ -n "${current_class_id}" ]
  then
    typeset suite_keys="$( hget --map "${current_class_id}" --key 'suite_tests' )"
    #if [ $( is_empty --str "${suite_keys}" ) -eq "${YES}" ]
    #then
    #  print_btf_detail --msg "No viable tests found for << ${suite_class_id} >>" --prefix "${SLCF_PREFIX_DETAIL}"
    #else
      typeset storage_suite_dir="$( __extract_value 'TEST_SUITES' )/${suite_class_id}"
      mkdir -p "${storage_suite_dir}"
      hpersist --map "${current_class_id}" --filename "$( __extract_value 'TEST_SUITES' )/${current_class_id}_class.map"
      typeset mpt
      for mpt in ${suite_keys}
      do
       typeset filemap="$( __generate_filemap_name --suite "${current_class_id}" --test "${mpt}" )"
       hpersist --map "${filemap}" --filename "${storage_suite_dir}/${mpt}.map"
       hclear --map "${filemap}"
      done
      hclear --map "${current_class_id}"
      unset 'current_class_id'
    #fi
  fi
  
  ###
  ### Check to see if consistency of information recorded is found
  ###
  record_step ${HOTSPOT_FLAGS} --header 'consistency_check' --start --overhead 'DYNAMIC'
  typeset classmap_files="$( get_class_map_files --path "$( __extract_value 'TEST_SUITES' )" )"
  typeset clmf=
  for clmf in ${classmap_files}
  do
    typeset class="$( printf "%s\n" "$( \basename "${clmf}" )" | \sed -e 's#_class\.map##' )"
    hread_map --filename "${clmf}"
    typeset mapname="$( hget_mapname --filename "${clmf}" )"
    typeset mapkeys="$( hkeys --map "${mapname}" )"
    
    [ $( is_empty --str "${mapkeys}" ) -eq "${YES}" ] && continue
    
    typeset runnable_tests="$( hget --map "${mapname}" --key 'suite_tests' )"
    typeset rt
    for rt in ${runnable_tests}
    do
      if [ ! -f "$( __extract_value 'TEST_SUITES' )/${class}/${rt}.map" ]
      then
        log_error "Test File existence condition found when it doesn't exist.  This should have not happened!"
        return "${FAIL}"
      fi
    done
    hclear --map "${mapname}"
    unset "${mapname}"
  done
  record_step ${HOTSPOT_FLAGS} --header 'consistency_check' --stop --overhead 'DYNAMIC'
  
  ###
  ### Check to see if sorted testing or random testing is requested
  ### Need to sort/randomize the classmap section and classmap subsection representing
  ###   the section which contains tests
  ###
  typeset allclasses="$( hget --map 'classmap' --key 'known_suites' )"
  if [ -n "${allclasses}" ]
  then
    printf "%s\n" ${allclasses} > "$( __extract_value 'GROUP_SUITEFILE' )"
  else
    log_error "No suites/stages to process.  See << $( __extract_value 'RESULTS_DIR_STDOUT' ) >> for details..."
    print_btf_detail --msg "No suites/stages to process.  See << $( __extract_value 'RESULTS_DIR_STDOUT' ) >> for details..." --prefix "$( __extract_value 'PREFIX_ERROR' )"
    return "${FAIL}"
  fi
  
  ###
  ### If a workflow is enabled, do not change the order of the suites/stages or tests within the suites/stages
  ### Otherwise, let harness SORT by suite then by tests in suites, likewise for SLCF_RANDOM
  ###   Will work on capability of selecting SORT for suite or test level [ TBD ]
  ###   Will work on capability of selecting RANDOM for suite or test level [ TBD ]
  ###
  typeset made_change="${NO}"
  
  if [ "$( __check_for --key 'WORKFLOW' --failure )" -eq "${YES}" ]
  then
    record_step ${HOTSPOT_FLAGS} --header 'sorting' --start --overhead 'DYNAMIC'
    if [ "$( __check_for --key 'SORT' --success )" -eq "${YES}" ]
    then
      \sort "$( __extract_value 'GROUP_SUITEFILE' )" | \uniq > "$( __extract_value 'GROUP_SUITEFILE' ).sorted"
      \mv -f "$( __extract_value 'GROUP_SUITEFILE' ).sorted" "$( __extract_value 'GROUP_SUITEFILE' )"

      typeset ac=
      for ac in ${allclasses}
      do
        typeset classmap_file="$( __extract_value 'TEST_SUITES' )/${ac}_class.map"
        hread_map --filename "${classmap_file}" --mapname 'CLASSMAP'
        typeset mapname="$( hget_mapname --filename "${classmap_file}" )"
        typeset scheduled_tests="$( hget --map "${mapname}" --key 'suite_tests' )"
        
        printf "%s\n" ${scheduled_tests} > "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata"
        \sort "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata" | \uniq > "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata.sorted"
        \mv -f "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata.sorted" "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata"
        
        scheduled_tests="$( \cat "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata" | \tr '\n' ' ' )"
        hdel --map "${mapname}" --key 'suite_tests'
        hput --map "${mapname}" --key 'suite_tests' --value "${scheduled_tests}"
        hpersist --map "${mapname}" --filename "$( __extract_value 'TEST_SUITES' )/${ac}_class.map"
        hclear --map "${mapname}"
        unset 'mapname'
      done
      made_change="${YES}"
    fi
    record_step ${HOTSPOT_FLAGS} --header 'sorting' --stop --overhead 'DYNAMIC'
  
    record_step ${HOTSPOT_FLAGS} --header 'randomness' --start --overhead 'DYNAMIC'
    if [ "$( __check_for --key 'RANDOM' --success )" -eq "${YES}" ]
    then
      \awk 'BEGIN{srand()}{print rand(),$0}' "$( __extract_value 'GROUP_SUITEFILE' )" | \sort -n | \cut -d ' ' -f2- > "$( __extract_value 'GROUP_SUITEFILE' ).random"
      \mv -f "$( __extract_value 'GROUP_SUITEFILE' ).random" "$( __extract_value 'GROUP_SUITEFILE' )" 
      typeset ac
      for ac in ${allclasses}
      do
        typeset classmap_file="$( __extract_value 'TEST_SUITES' )/${ac}_class.map"
        hread_map --filename "${classmap_file}"
        typeset mapname="$( hget_mapname --filename "${classmap_file}" )"
        typeset scheduled_tests="$( hget --map "${mapname}" --key 'tests' )"
        
        printf "%s\n" ${scheduled_tests} > "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata"
        \awk 'BEGIN{srand()}{print rand(),$0}' "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata" | \sort -n | \cut -d ' ' -f2- > "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata.random"
        \mv -f "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata.random" "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata"
        
        scheduled_tests="$( \cat "$( __extract_value 'TEST_SUITES' )/${ac}_class.testdata" | \tr '\n' ' ' )"
        hdel --map "${mapname}" --key 'suite_tests'
        hput --map "${mapname}" --key 'suite_tests' --value "${scheduled_tests}"
        hpersist --map "${mapname}" --filename "$( __extract_value 'TEST_SUITES' )/${ac}_class.map"
        hclear --map "${mapname}"
        unset 'mapname'
      done
      made_change="${YES}"
    fi
    record_step ${HOTSPOT_FLAGS} --header 'randomness' --stop --overhead 'DYNAMIC'
  fi

  if [ "${made_change}" -eq "${YES}" ]
  then
    allclasses="$( \cat "$( __extract_value 'GROUP_SUITEFILE' )" | \tr '\n' ' ' )"
    hdel --map 'classmap' --key 'known_suites'
    hput --map 'classmap' --key 'known_suites' --value "${allclasses}"
  fi
  
  hpersist --map 'classmap' --filename "$( __extract_value 'GROUP_SUITEFILE' )" --clobber

  ###
  ### Check issue detection to see if something needs to be reported
  ###
  typeset current_error_warn_marker=$( __calculate_filesize "$( __extract_value 'LOGFILE' )" )
  if [ "${current_error_warn_marker}" -gt "${previous_error_warn_marker}" ]
  then
    printf "\n"
    print_btf_detail --msg "One or more tests/sections were found to be defective.  Please review the logfile before continuing..." --newline-count 2 --prefix "${SLCF_PREFIX_WARN}"
    print_btf_detail --msg "$( __extract_value 'DBL_DIVIDER' )" --newline-count 2 --no-prefix

    [ -f "$( __extract_value 'LOGFILE' )" ] && \cat "$( __extract_value 'LOGFILE' )"

    printf "\n"
    print_btf_detail --msg "$( __extract_value 'DBL_DIVIDER' )" --newline-count 2 --no-prefix
 
    if [ -z "${AUTOMATED_TESTING}" ]
    then
      printf "\n"
    else
      pause
    fi
  fi
}

load_interpreted_datafile()
{
  typeset filename=
  typeset prefix="$( __extract_value '__PROGRAM_VARIABLE_PREFIX' )"

  OPTIND=1
  while getoptex "f: filename: p: prefix:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'  ) filename="${OPTARG}";;
    'p'|'prefix'    ) prefix="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${filename}" ] && [ ! -f "${filename}" ] && return "${FAIL}"

  typeset RC="${PASS}"
  typeset new_options="$( process_data --use-memory "${YES}" --filename "${filename}" --prefix "${prefix}" )"
  RC=$?

  printf "%s\n" "${new_options}"
  return "${RC}"
}

parse_dependency_file()
{
  typeset filename=  

  OPTIND=1
  while getoptex "f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'  ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${filename}" ] && return "${PASS}"
  [ ! -f "${filename}" ] && return "${FAIL}"
  
  typeset result="${PASS}"
  
  typeset extension=$( get_extension "${filename}" )
  case "${extension}" in
  'xml'           )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/xml_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_xml_dependency_input "${filename}" $@; result=$?;;
  'json'          )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/json_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_json_dependency_input "${filename}" $@;;
  'txt' | 'text'  )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/text_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_txt_dependency_input "${filename}" $@; result=$?;;
  'yaml'          )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/json_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && typeset tmpjson=$( __convert_yaml_to_json "${filename}" ); [ "${result}" -eq "${PASS}" ] && __handle_json_dependency_input "${tmpjson}" $@; result=$?;; 
  *               )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/text_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_txt_dependency_input "${filename}" $@; result=$?;;
  esac

  [ "${result}" -ne "${PASS}" ] && print_btf_detail --prefix "$( __extract_value 'PREFIX_ERROR' )" --msg "Parsing dependency input file failed.  Return code = ${result}"
  return "${result}"
}

parse_driver_file()
{
  typeset filename=  

  OPTIND=1
  while getoptex "f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'  ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${filename}" ] && return "${PASS}"
  [ ! -f "${filename}" ] && return "${FAIL}"
  
  typeset result="${PASS}"
  
  typeset extension=$( get_extension "${filename}" )
  case "${extension}" in
  'xml'           )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/xml_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_xml_test_input "${filename}"; result=$?;;
  'json'          )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/json_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_json_test_input "${filename}"; result=$?;;
  'txt' | 'text'  )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/text_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_txt_test_input "${filename}"; result=$?;;
  'yaml'          )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/json_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && typeset tmpjson=$( __convert_yaml_to_json --filename "${filename}" ); [ "${result}" -eq "${PASS}" ] && USE_YAML="${YES}"; __handle_json_test_input "${tmpjson}"; USE_YAML="${NO}"; result=$?;; 
  *               )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/text_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_txt_test_input "${filename}"; result=$?;;
  esac

  [ "${result}" -ne "${PASS}" ] && print_btf_detail --prefix "$( __extract_value 'PREFIX_ERROR' )" --msg "Parsing input file failed.  Return code = ${result}"
  return "${result}"
}

prepare_copy_back()
{
  typeset contact_ip=$( get_element --data "$( __extract_value 'COPY_BACK' )" --id 1 --separator ':' )
  typeset r_username=$( get_element --data "$( __extract_value 'COPY_BACK' )" --id 2 --separator ':' )
  typeset pwd=$( get_element --data "$( __extract_value 'COPY_BACK' )" --id 3 --separator ':' )

  typeset l_username=$( get_user_id )
  
  load_program_library "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
  load_program_library "${SLCF_SHELL_TOP}/lib/compression.sh"

  typeset local_ip=$( get_machine_ip )
  [ -z "${local_ip}" ] && return "${FAIL}"

  typeset netadpt=$( get_network_adapter --ipv 4 --address "${local_ip}" )
  [ -z "${netadpt}" ] && return "${FAIL}"
  
  [ $( is_network_disabled --adapter "${netadpt}" ) --eq "${YES}" ] && return "${FAIL}"
  [ $( is_host_alive --host "${contact_ip}" ) --eq "${NO}" ] && return "${FAIL}"
  
  check_for_passwordless_connection --ip "${contact_ip}" --local-user "${l_username}" --remote-user "${r_username}"
  if [ $? -ne "${PASS}" ]
  then
    make_passwordless_connection --ip "${contact_ip}" --passwd "${pwd}" --local-user "${l_username}" --remote-user "${r_username}"
    [ $? -ne "${PASS}" ] && return "${FAIL}"
    
    check_for_passwordless_connection --ip "${contact_ip}" --local-user "${l_username}" --remote-user "${r_username}"
    [ $? -ne "${PASS}" ] && return "${FAIL}"
  fi
  
  compress --input "$( __extract_value 'TEST_RESULTS_TOPLEVEL' )" --compress-file "$( __extract_value 'TEST_SUMMARY_PATH' )/RESULTS/$( __extract_value 'START_TIME' ).tar"
  if [ -f "$( __extract_value 'TEST_SUMMARY_PATH' )/RESULTS/$( __extract_value 'START_TIME' ).tar" ]
  then
    \scp "$( __extract_value 'TEST_SUMMARY_PATH' )/RESULTS/$( __extract_value 'START_TIME' ).tar" "${r_username}@${contact_ip}:/"
  else
    return "${FAIL}"
  fi
  return "${PASS}"
}

###
### Display harness header information
###
print_harness_header()
{
  typeset tablevel=0

  eval "$( __extract_value 'BLANK_LINE' )"  ### NEEDS TO BE FIXED
  
  [ -z "$( __extract_value 'PROGRAM_BUILD_TYPE' )" ] && __set_internal_value 'PROGRAM_BUILD_TYPE' 'UNKNOWN'
  
  print_btf_detail --msg "$( __extract_value 'DIVIDER' )" --no-prefix --tab-level "${tablevel}"
  __print_harness_header --key 'Hostname                 ' --data "$( \hostname )" --tab-level "${tablevel}"
  __print_harness_header --key 'Date                     ' --data "$( __change_time_to_UTC "$( __extract_value 'START_TIME' )" "+%F %r" )" --tab-level "${tablevel}"
  __print_harness_header --key 'Test Framework Version   ' --data "$( __extract_value 'PROGRAM_VERSION' ).$( __extract_value 'PROGRAM_VERSION_BUILD' ) ($( __extract_value 'PROGRAM_BUILD_TYPE' ))" --tab-level "${tablevel}"

  typeset library_version='UNKNOWN'
  [ -f "${SLCF_SHELL_TOP}/version" ] && library_version="$( \cat ${SLCF_SHELL_TOP}/version )"

  __print_harness_header --key 'Library Framework Version' --data "${library_version}" --tab-level "${tablevel}"
  __print_harness_header --key 'SLCF_SHELL_TOP           ' --data "${SLCF_SHELL_TOP}" --tab-level "${tablevel}"
  __print_harness_header --key 'Harness Top              ' --data "${__HARNESS_TOPLEVEL}" --tab-level "${tablevel}"
  print_btf_detail --msg "$( __extract_value 'DIVIDER' )" --no-prefix --tab-level "${tablevel}"

  eval "$( __extract_value 'BLANK_LINE' )"

  return "${PASS}"
}

process_tag_selection()
{
  typeset filename="$( get_element --data "$( __extract_value 'TAG_FILE_SELECT' )" --id 1 --separator ':' )"
  typeset startpt="$( get_element --data "$( __extract_value 'TAG_FILE_SELECT' )" --id 2 --separator ':' )"
  
  [ "${startpt}" == "${filename}" ] && return "${FAIL}"
  if [ -z "${startpt}" ] || [ ! -f "${filename}" ]
  then
    return "${FAIL}"
  fi
  
  typeset result="${PASS}"
  
  typeset extension=$( get_extension "${filename}" )
  case "${extension}" in
  'xml'           )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/xml_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_xml_tagselect_input "${filename}" "${startpt}"; result=$?;;
  'json'          )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/json_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_json_tagselect_input "${filename}" "${startpt}"; result=$?;;
  'txt' | 'text'  )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/text_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_txt_tagselect_input "${filename}" "${startpt}"; result=$?;;
  'yaml'          )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/json_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && USE_YAML="${YES}"; __handle_json_tagselect_input "${filename}" "${startpt}"; USE_YAML="${NO}"; result=$?;; 
  *               )  . "${__HARNESS_TOPLEVEL}/utilities/inputs/text_parser.sh"; result=$?; [ "${result}" -eq "${PASS}" ] && __handle_txt_tagselect_input "${filename}" "${startpt}"; result=$?;;
  esac

  if [ "${result}" -ne "${PASS}" ]
  then
    print_btf_detail --prefix "$( __extract_value 'PREFIX_ERROR' )" --msg "Parsing tag selection file failed.  Return code = ${result}"
  else
    print_btf_detail --prefix "$( __extract_value 'PREFIX_INFO' )" --msg "Parsing tag selection file completed.  Global tags set for test filtration..."
  fi
  return "${result}"
}

run_suite()
{
  typeset suite_start="$( __today_as_seconds )"
  hput --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_START_TIME' --value "${suite_start}"
  
  typeset RC="${PASS}"
  typeset subject=
  typeset class=

  OPTIND=1
  while getoptex "s: subject: c: class:" "$@"
  do
    case "${OPTOPT}" in
    's'|'subject'   ) subject="${OPTARG}";;
    'c'|'class'     ) class="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ $( is_empty --str "${class}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_empty --str "${subject}" ) -eq "${YES}" ] && subject="$( to_upper "${class}" )"
  
  ###
  ### Already in the requested test directory
  ###
  print_btf_detail --msg "Subject of Testing : $( __convert_parameter --param "${subject}" )" --prefix "$( __extract_value 'PREFIX_SELECT' )"

  record_step ${HOTSPOT_FLAGS} --header "launch ${class}" --start
  . "${__HARNESS_TOPLEVEL}/lib/launch.sh" "${class}"
  RC=$?
  record_step ${HOTSPOT_FLAGS} --header "launch ${class}" --stop
  
  typeset suite_stop="$( __today_as_seconds )"
  hput --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_END_TIME' --value "${suite_stop}"
  
  typeset suite_time=$( calculate_run_time --start "${suite_start}" --end "${suite_stop}" --decimals 0 )
  
  hput --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TIME' --value "${suite_time}"

  typeset outfmt=
  for outfmt in $( __extract_value 'OUTPUT_FORMATS' )
  do
    eval "complete_${outfmt}_test_suite"
    eval "complete_${outfmt}"
    eval "update_${outfmt}_testsuite_stats"
  done

  typeset suite_runtime=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_RUNTIME' )
  hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_RUNTIME' --incr "${suite_runtime}"

  return "${RC}"
}

###
### Define other "keywords" to use as tags in the individual test files
###
use_tag_aliases()
{
  typeset filename=
  
  OPTIND=1
  while getoptex "f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'  ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset tagfile="$( __extract_value 'RESULTS_DIR' )/.tagging"
  typeset tag_aliases="$( __extract_value 'TAG_ALIAS' ) tag"
  typeset local_test_tags
  typeset tga
  for tga in ${tag_aliases}
  do
    \grep -i "${tga}" "${filename}" > "${tagfile}"
    typeset gt=
    while read -r -u 6 gt
    do
      gt="$( printf "%s\n" "${gt}" | \tr -s '#' | \awk -F'#' '{print $1}' )"
      [ "${gt:0:1}" != '#' ] && continue
      ###
      ### Do I need to write a generic "join" function to alleviate repetitive actions like this???
      ###
      local_test_tags+="$( printf "%s\n" "${gt}" | \tr -s '#' | \sed -e "s/^#[ $( printf "\t" )]*${tga}[ $( printf "\t" )]*:[ $( printf "\t" )]*(\w*)/\1/" ) | \tr '\n' ' ' | \tr '\t' ' ' | \sed -e 's# #,#' )"
    done 6< "${tagfile}"
    [ -f "${tagfile}" ] && \rm -f "${tagfile}"
  done
  
  printf "%s\n" "${local_test_tags}"
  return "${PASS}"
}
