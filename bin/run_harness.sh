#!/usr/bin/env bash

###############################################################################
# Copyright (c) 2016-2017.  All rights reserved.  
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
# Canopus:
# Also known as Alpha Carinae, this white giant is the brightest star in the
#   southern constellation of Carina and the second brightest star in the
#   nighttime sky. Located over 300 light-years away from Earth, this star
#   is named after the mythological Canopus, the navigator for king Menelaus
#   of Sparta in The Iliad. 
#
# Thought it was not visible to the ancient Greeks and Romans, the star was
#   known to the ancient Egyptians, as well as the Navajo, Chinese and ancient
#   Indo-Aryan people. In Vedic literature, Canopus is associated with
#   Agastya, a revered sage who is believed to have lived during the 6th or
#   7th century BCE. To the Chinese, Canopus was known as the “Star of the Old Man”,
#   and was charted by astronomer Yi Xing in 724 CE.
#
# It is also referred to by its Arabic name Suhayl (Soheil in persian), which
#   was given to it by Islamic scholars in the 7th Century CE. To the Bedouin
#   people of the Negev and Sinai, it was also known as Suhayl, and used along
#   with Polaris as the two principal stars for navigation at night.
#
# It was not until 1592 that it was brought to the attention of European
#   observers, once again by Robert Hues who recorded his observations of it
#   alongside Achernar and Alpha Centauri in his Tractatus de Globis (1592).
#
# As he noted of these three stars, “Now, therefore, there are but three Stars
#   of the first magnitude that I could perceive in all those parts which are
#   never seene here in England. The first of these is that bright Star in the
#   sterne of Argo which they call Canobus. The second is in the end of
#   Eridanus. The third is in the right foote of the Centaure.”
#
# This star is commonly used for spacecraft to orient themselves in space,
#   since it is so bright compared to the stars surrounding it.
#
###############################################################################

NO_EXECUTABLE_FOUND=10
NO_LIBRARY_SYSTEM_FOUND=250
BAD_LIBRARY_FILE=249

if [ "$( printf "%s\n" "${BASH_VERSINFO[0]}" )" -lt 4 ]
then
  printf "%s\n" "Need to use Bash Version 4.x.  Exiting."
  exit ${BAD_LIBRARY_FILE}
fi

###
### If debugging requested...
###
if [ -n "${SLCF_BASH_DEBUG}" ] && [ "${SLCF_BASH_DEBUG}" -gt 0 ]
then
  if [ -n "${SLCF_BASH_DEBUGGER_PROGRAM}" ] && [ -f "${SLCF_BASH_DEBUGGER_PROGRAM}" ]
  then
    source "${SLCF_BASH_DEBUGGER_PROGRAM}" "${SLCF_BASH_DEBUGGER_OPTIONS}"
    [ -n "${SLCF_BASH_DEBUGGER_SETTINGS}" ] && eval "${SLCF_BASH_DEBUGGER_SETTINGS}"
  fi
fi

###
### Validate that SLCF_SHELL_TOP is defined and points to a directory
###
if [ -z "${SLCF_SHELL_TOP}" ]
then
  printf "\n%s\n\n" "Please define SLCF_SHELL_TOP to the top of the Shell Library Component Framework!"
  exit "${NO_LIBRARY_SYSTEM_FOUND}"
fi

if [ ! -d "${SLCF_SHELL_TOP}" ] || [ ! -d  "${SLCF_SHELL_TOP}/lib" ]
then
  printf "\n%s\n\n" "$0 -- No support library system found.  Exiting!  RC=${NO_LIBRARY_SYSTEM_FOUND}"
  exit "${NO_LIBRARY_SYSTEM_FOUND}"
fi

###
### Pull in the path functionality to be able to resolve paths
###
. "${SLCF_SHELL_TOP}/utilities/common/.define_pather.sh"
[ $? -ne 0 ] && exit "${BAD_LIBRARY_FILE}"

###
### Load the bootstrap libraries
###
. "${SLCF_SHELL_TOP}/lib/numerics.sh"
[ $? -ne "${PASS}" ] && exit "${BAD_LIBRARY_FILE}"

. "${SLCF_SHELL_TOP}/lib/timemgt.sh"
[ $? -ne "${PASS}" ] && exit "${BAD_LIBRARY_FILE}"

. "${SLCF_SHELL_TOP}/lib/stringmgt.sh"
[ $? -ne "${PASS}" ] && exit "${BAD_LIBRARY_FILE}"

###
### Define the basic functionality for hotspot analysis and dynamic/static overhead collection
###
HOTSPOT_FLAGS=
RECORD_STEPS="${CANOPUS_RECORD_STEPS:-${NO}}"
RECORD_OVERHEAD="${CANOPUS_RECORD_OVERHEAD:-${NO}}"

[ "${RECORD_STEPS}" -eq "${YES}" ] && HOTSPOT_FLAGS+=" --channel CANOPUS_HOTSPOT"

###
### Define the harness bindir so it can be used as a differentiator
###
HARNESS_BINDIR="$( \dirname "$( ${__REALPATH} ${__REALPATH_OPTS} "$0" )" )"

__handle_option_management()
{
  ###
  ### Define the program options for this executable
  ###
  typeset CANOPUS_SHORT_SINGLE_OPTIONS='a c: f i: n p: q r t: u v w'
  typeset CANOPUS_SHORT_MULTI_OPTIONS='o:'
  
  typeset CANOPUS_SHORT_OPTION_MATCHES='a:allow-no-tags c:copy-back f:fail-on-error i:input-file n:dryrun p:parallel q:quiet o:output r:random t:tag-file-select u:use-tags v:verbose w:workflow'

  typeset CANOPUS_SINGLE_OPTIONS='allow-no-tags copy-back: debug delay-summary dependency-file: description: detail disallow-return-code-checking dryrun fail-on-error group-dir: ignore-tag-case input-file: manage-build-system no-tag-recursion parallel: postcheck: precheck: profile-name: quiet random results-dir: setup-check: show-summary sort suite-stop-on-fail test-stop-on-fail tag-file-select: unit-test use-tags verbose verbose-build-system workflow'
  typeset CANOPUS_MULTI_OPTIONS='tag: tag-alias: exclude-dir-patt: exclude-file-patt: insert-extension: output: output-option: select-extension: stage-skip-fail-tags:'
  
  typeset CANOPUS_SO=
  [ -n "${CANOPUS_SHORT_SINGLE_OPTIONS}" ] && [ "${CANOPUS_SHORT_SINGLE_OPTIONS}" != '[]' ] && CANOPUS_SO+=" ${CANOPUS_SHORT_SINGLE_OPTIONS}"
  [ -n "${CANOPUS_SHORT_MULTI_OPTIONS}" ] && [ "${CANOPUS_SHORT_MULTI_OPTIONS}" != '[]' ] && CANOPUS_SO+=" ${CANOPUS_SHORT_MULTI_OPTIONS}"
  
  typeset CANOPUS_LO=
  [ -n "${CANOPUS_SINGLE_OPTIONS}" ] && [ "${CANOPUS_SINGLE_OPTIONS}" != '[]' ] && CANOPUS_LO+=" ${CANOPUS_SINGLE_OPTIONS}"
  [ -n "${CANOPUS_MULTI_OPTIONS}" ] && [ "${CANOPUS_MULTI_OPTIONS}" != '[]' ] && CANOPUS_LO+=" ${CANOPUS_MULTI_OPTIONS}"
  
  __import_variable --key 'CANOPUS_RECORDER_STARTING' --value 'Starting' --file "${CANOPUS_OPTION_FILE}"
  __import_variable --key 'CANOPUS_RECORDER_STOPPING' --value 'Completed' --file "${CANOPUS_OPTION_FILE}"
  __import_variable --key 'CANOPUS_SHORT_OPTIONS' --value "${CANOPUS_SO}" --file "${CANOPUS_OPTION_FILE}"
  __import_variable --key 'CANOPUS_LONG_OPTIONS' --value "${CANOPUS_LO}" --file "${CANOPUS_OPTION_FILE}"
  __import_variable --key 'CANOPUS_PROGRAM_OPTIONS' --value "${CANOPUS_SO} ${CANOPUS_LO}" --file "${CANOPUS_OPTION_FILE}"
  
  __import_variable --key 'CANOPUS_SHORT_SINGLE_OPTIONS' --value "${CANOPUS_SHORT_SINGLE_OPTIONS}" --file "${CANOPUS_OPTION_FILE}"
  __import_variable --key 'CANOPUS_SHORT_MULTI_OPTIONS' --value "${CANOPUS_SHORT_MULTI_OPTIONS}" --file "${CANOPUS_OPTION_FILE}"
  __import_variable --key 'CANOPUS_SINGLE_OPTIONS' --value "${CANOPUS_SINGLE_OPTIONS}" --file "${CANOPUS_OPTION_FILE}"
  __import_variable --key 'CANOPUS_MULTI_OPTIONS' --value "${CANOPUS_MULTI_OPTIONS}" --file "${CANOPUS_OPTION_FILE}"
  __import_variable --key 'CANOPUS_SHORT_OPTION_MATCHES' --value "${CANOPUS_SHORT_OPTION_MATCHES}" --file "${CANOPUS_OPTION_FILE}"

  __import_variable --key 'CANOPUS_STATIC_OVERHEAD' --value 0 --file "${CANOPUS_OPTION_FILE}"
  __import_variable --key 'CANOPUS_DYNAMIC_OVERHEAD' --value 0 --file "${CANOPUS_OPTION_FILE}"
  
  ###
  ### Hack to ensure all commandline args get passed
  ###
  typeset args="$@"
  __setup_program "${CANOPUS_SHORT_SINGLE_OPTIONS}" "${CANOPUS_SHORT_MULTI_OPTIONS}" "${CANOPUS_SINGLE_OPTIONS}" "${CANOPUS_MULTI_OPTIONS}" "${CANOPUS_SHORT_OPTION_MATCHES}" ${args}
  return "${PASS}"
}

__handle_outputs()
{
  typeset hout=
  for hout in $( __extract_value 'OUTPUT' )
  do
    hout="$( printf "%s\n" "${hout}" | \tr "[:lower:]" "[:upper:]" )"
    __set_internal_value "${hout}" 1
  done
  
  unset "$( __define_internal_variable 'OUTPUT')"
  return "${PASS}"
}

__pre_commandline_processing()
{
  __set_internal_value 'TEST_DEPENDENCY_MAP_SHELL'
  __set_internal_value 'TEST_DEPENDENCY_MAP_PYTHON'
  __set_internal_value 'TEST_DEPENDENCY_MAP_PERL'
  __set_internal_value 'TEST_DEPENDENCY_MAP_TCL'
  __set_internal_value 'TEST_DEPENDENCY_MAP_WISH'
  __set_internal_value 'TEST_DEPENDENCY_MAP_JAVA'
  
  return "${PASS}"
}

__post_commandline_processing()
{
  typeset outfmt=
  for outfmt in $( __extract_value 'OUTPUT_FORMATS' )
  do
    typeset varname="${__PROGRAM_VARIABLE_PREFIX}_$( to_upper "${outfmt}" | \tr '-' '_' )_OUTPUT"
    eval "${varname}=${YES}"
  done
  
  [ $( __check_for --key 'WORKFLOW' --success ) -eq "${YES}" ] && __set_internal_value 'RANDOM' "${NO}" && __set_internal_value 'SORT' "${NO}"
  return "${PASS}"

  typeset depfile="$( __extract_value 'DEPENDENCY_FILE' )"
  if [ -f "${depfile}" ]
  then
    \sort -u "${depfile}" > "${depfile}.srt"
    \mv -f "${depfile}.srt" > "${depfile}"
  fi
}

__reset_all_parent_settings()
{
  typeset matched_vars="${!CANOPUS*}"

  ###
  ### Use these variables to try to "re-center" the recursive call...
  ###
  typeset mainpath="${CANOPUS_TEST_SUMMARY_PATH}"
  typeset tsubpath="${CANOPUS_TEST_SUBSYSTEM}"
  
  typeset relocation="${mainpath}/RESULTS/${tsubpath}"
  
  typeset special_vars=
  typeset mo=
  for mo in ${matched_vars}
  do
    typeset found="${NO}"
    typeset sv=
    for sv in ${special_vars}
    do
      if [ "${sv}" == "${mo}" ]
      then
        found="${YES}"
        special_vars="$( printf "%s\n" ${special_vars} | \grep -v "${sv}" )"
        break
      fi
    done
    [ "${found}" -eq "${NO}" ] && eval "unset '${mo}'"  ### Erase all variables NOT found in special_vars list
  done
  
  ###
  ### Need to figure out why this isn't placing the value into memory...
  ###
  typeset memopts="${__PROGRAM_VARIABLE_PREFIX}_POSSIBLE_RESULTS_DIR=\"${relocation}\"; export ${__PROGRAM_VARIABLE_PREFIX}_POSSIBLE_RESULTS_DIR"
  eval "${memopts}"
  return "${PASS}"
}

###
### Bootstrap to get basic pathing installed
###
__setup_basic_functional_paths()
{
  [ $# -lt 1 ] || [ -z "$1" ] && return 1   

  ###
  ### Determine true path from which this script is called from
  ###
  typeset __startup_path=$( ${__REALPATH} ${__REALPATH_OPTS} "$1" )
  typeset __levels_up="${2:-0}"
  
  typeset count=0
  __harness_toplevel="${__startup_path}"
  typeset __toplevel="${SLCF_SHELL_TOP}"
  
  ###
  ### Handle symlink possibility for the "executable"
  ###
  if [ -L "$0" ]
  then
    typeset binary_path=$( ${__REALPATH} ${__REALPATH_OPTS} "$0" )
    [ "${binary_path}" != "${__harness_toplevel}" ] && __harness_toplevel=$( \dirname "${binary_path}" )
  fi

  ###
  ### Prepare to find top installation location
  ###
  while [ "${count}" -lt "${__levels_up}" ]
  do
    __harness_toplevel=$( dirname "${__harness_toplevel}" )
    count=$( increment "${count}" )
  done
  
  [ ! -d "${__harness_toplevel}" ] && return "${FAIL}"
  
  ###
  ### Be sure to define the "TOP"
  ###
  . "${__toplevel}/utilities/common/program_utilities.sh"
  __set_program_variable_prefix 'CANOPUS'
 
  ###
  ### Preparing remaining paths for rest of installation to be complete system
  ###
  __setup_paths "${__toplevel}" "$3" "${__harness_toplevel}/lib/run_harness_program.sh"
  return $?
}

__snapshot_processtable()
{
  __debug $@
  
  typeset ptchan="$( __define_internal_variable 'PT' )"
  
  typeset cmd='ps'
  \which "${cmd}" 2>&1 | \grep -q "no ${cmd}"
  RC=$?
  [ "${RC}" -eq "${PASS}" ] && return "${PASS}"
  
  cmd+=' -eaf'
  [ $( is_windows_machine ) -eq "${YES}" ] && cmd+='W'
  
  typeset processtable
  typeset pt_tablefile="$( __extract_value 'RESULTS_DIR' )/process_table_$( __extract_value 'START_TIME' ).log"
  
  eval "processtable=\$( ${cmd} )"
  append_output --data "${cmd} >> ${pt_tablefile}" --channel "$( __define_internal_variable 'CMD' )"
  
  associate_file_to_channel --channel "${ptchan}" --file "${pt_tablefile}" --ignore-file-existence --persist
  append_output --data "${processtable}" --channel "${ptchan}" --raw
  append_output --data "$( get_repeated_char_sequence -r '-' -c '60' )" --channel "${ptchan}" --raw
  
  __register_cleanup "${pt_tablefile}" inputs
  
  typeset uptime_data
  
  cmd='uptime'
  \which "${cmd}" 2>&1 | \grep -q "no ${cmd}"
  RC=$?
  [ "${RC}" -eq "${PASS}" ] && return "${PASS}"

  eval "uptime_data=\$( ${cmd} )"
  append_output --data "${cmd} >> ${pt_tablefile}" --channel "$( __define_internal_variable 'CMD' )"
  append_output --data "UPTIME data --> ${uptime_data}" --channel "${ptchan}" --raw
  
  return "${PASS}"
}

###
### All these write functions will be placed into a separate function support file
###   to naturally allow for using the xmlmgt and jsonmgt libraries...
###
__write_recursive_file()
{
  typeset RC="${PASS}"
  typeset styles='txt'
  typeset passes=0
  typeset fails=0
  typeset skips=0
  typeset dfiles=
  typeset files=0
  typeset location=
  typeset ftemplate=
  
  OPTIND=1
  while getoptex "style: p: passes: fails: skips: datafiles: dir-location: files: r: return-code: file-template:" "$@"
  do
    case "${OPTOPT}" in
        'style'         ) styles+=" ${OPTARG}";;
    'p'|'passes'        ) passes="${OPTARG}";;
        'fails'         ) fails="${OPTARG}";;
        'skips'         ) skips="${OPTARG}";;
        'datafiles'     ) datafiles="${OPTARG}";;
        'dir-location'  ) location="${OPTARG}";;
        'files'         ) files="${OPTARG}";;
    'r'|'return-code'   ) RC="${OPTARG}";;
        'file-template' ) ftemplate="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${ftemplate}" ) -eq "${YES}" ] && return "${FAIL}"
  [ ! -d "${location}" ] && \mkdir -p "${location}"
  [ ! -d "${location}" ] && return "${FAIL}"
    
  styles="$( printf "%s\n" ${styles} | \sort | \uniq )"
  
  typeset sty=
  for sty in ${styles}
  do
    typeset cmd="__write_recursive_file_${sty} '${location}' '${ftemplate}' ${passes} ${fails} ${skips} ${files} ${RC} '${datafiles}'"
    eval "${cmd}"
    if [ $? -ne "${PASS}" ]
    then
      log_warning "Unable to write recursive information for format << ${sty} >>"
      print_btf_detail --msg "Unable to write recursive information for format << ${sty} >>" --prefix "$( __extract_value 'PREFIX_WARN' )"
    fi
  done
  return "${PASS}"
}

__write_recursive_file_json()
{
  typeset recursive_toplevel="$( ${__REALPATH} ${__REALPATH_OPTS} $1 )"
  typeset recursive_datafile="$2.json"
  shift 2
  
  typeset fullpathfile="$( ${__REALPATH} ${__REALPATH_OPTS} ${recursive_toplevel}/../../${recursive_datafile} )"
  
  __register_cleanup "${fullpathfile}" outputs
  
  printf "%s\n" '{' >> "${fullpathfile}"
  printf "%s\n" "  \"summary\": {" >> "${fullpathfile}"
  if [ -n "$6" ]
  then
    printf "%s\n" "    \"datafiles\": {" >> "${fullpathfile}"
    printf "%s\n" "      \"datafile\": [" >> "${fullpathfile}"
    typeset numdfl=$( __get_word_count "${datafiles}" )
    typeset count=0
    typeset dfl
    for dfl in ${datafiles}
    do
      count=$(( count + 1 ))
      if [ "${count}" -eq "${numdfl}" ]
      then
        printf "%s\n" "        \"${dfl}\"" >> "${fullpathfile}"
      else
        printf "%s\n" "        \"${dfl}\"," >> "${fullpathfile}"
      fi
    done
    printf "%s\n" "      ]" >> "${fullpathfile}"
    printf "%s\n" "    }," >> "${fullpathfile}"
  fi
  
  ###
  ### The file is registered for cleanup so we need to be sure the paths are accurate
  ###
  printf "%s\n" "    \"summaryfile\": \"${recursive_toplevel}/outputs/${recursive_datafile}\"," >> "${fullpathfile}"
  printf "%s\n" "    \"recursive\": \"1\"," >> "${fullpathfile}"
  printf "%s\n" "    \"stats\": {" >> "${fullpathfile}"
  printf "%s\n" "      \"-passes\": \"$1\"," >> "${fullpathfile}"
  printf "%s\n" "      \"-failures\": \"$2\"," >> "${fullpathfile}"
  printf "%s\n" "      \"-skips\": \"$3\"," >> "${fullpathfile}"
  printf "%s\n" "      \"-seen_files\": \"$4\"" >> "${fullpathfile}"
  printf "%s\n" "    }," >> "${fullpathfile}"
  printf "%s\n" "    \"return_code\": \"$5\"" >> "${fullpathfile}"
  printf "%s\n" "  }" >> "${fullpathfile}"
  printf "%s\n" "}" >> "${fullpathfile}"
  
  return "${PASS}"  
}

__write_recursive_file_txt()
{
  typeset recursive_toplevel="$( ${__REALPATH} ${__REALPATH_OPTS} $1 )"
  typeset recursive_datafile="$2.txt"
  shift 2
  
  typeset fullpathfile="$( ${__REALPATH} ${__REALPATH_OPTS} ${recursive_toplevel}/../../${recursive_datafile} )"
  
  __register_cleanup "${fullpathfile}" outputs
  
  typeset dfl=
  for dfl in $6
  do
    printf "%s\n" "DataFile:${dfl}" >> "${fullpathfile}"
  done
  
  ###
  ### The file is registered for cleanup so we need to be sure the paths are accurate
  ###
  printf "%s\n" "SummaryFile:${recursive_toplevel}/outputs/${recursive_datafile}" >> "${fullpathfile}"
  printf "%s\n" "Recursive:1" >> "${fullpathfile}"
  printf "%s\n" "Passes:$1" >> "${fullpathfile}"
  printf "%s\n" "Fails:$2" >> "${fullpathfile}"
  printf "%s\n" "Skips:$3" >> "${fullpathfile}"
  printf "%s\n" "Files:$4" >> "${fullpathfile}"
  printf "%s\n" "ReturnCode:$5" >> "${fullpathfile}"
  
  return "${PASS}"
}

__write_recursive_file_xml()
{
  typeset recursive_toplevel="$( ${__REALPATH} ${__REALPATH_OPTS} $1 )"
  typeset recursive_datafile="$2.xml"
  shift 2
  
  typeset fullpathfile="$( ${__REALPATH} ${__REALPATH_OPTS} ${recursive_toplevel}/../../${recursive_datafile} )"
  
  __register_cleanup "${fullpathfile}" outputs
 
  printf "%s\n" "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" >> "${fullpathfile}"
  printf "%s\n" "<summary>" >> "${fullpathfile}"
  if [ -n "$6" ]
  then
    printf "%s\n" "   <datafiles>" >> "${fullpathfile}"
    typeset dfl=
    for dfl in ${datafiles}
    do
      printf "%s\n" "      <datafile>${dfl}</datafile>" >> "${fullpathfile}"
    done
    printf "%s\n" "   </datafiles>" >> "${fullpathfile}"
  fi
  
  ###
  ### The file is registered for cleanup so we need to be sure the paths are accurate
  ###
  printf "%s\n" "   <summaryfile>${recursive_toplevel}/outputs/${recursive_datafile}</summaryfile>" >> "${fullpathfile}"
  printf "%s\n" "   <recursive>1</recursive>" >> "${fullpathfile}"
  printf "%s\n" "   <stats passes=\"$1\" failures=\"$2\" skips=\"$3\" seen_files=\"$4\"/>" >> "${fullpathfile}"
  printf "%s\n" "   <return_code>$5</return_code>" >> "${fullpathfile}"
  printf "%s\n" "</summary>" >> "${fullpathfile}"
  
  return "${PASS}"
}

allow_selective_stages()
{
  if [ -n "$( __extract_value 'WORKFLOW_MAPFILE' )" ] && [ -f "$( __extract_value 'WORKFLOW_MAPFILE' )" ]
  then
    hread_map --filename "$( __extract_value 'WORKFLOW_MAPFILE' )"
  else
    return "${FAIL}"
  fi
  
  typeset selective_suites="$( __extract_value 'STAGE_SKIP_FAIL_TAGS' )"
  typeset ss=
  for ss in ${selective_suites}
  do
    typeset match=$( __request_workflow_stage_id "${ss}" )
    if [ $( is_empty --str "${match}" ) -eq "${YES}" ]
    then
      log_warning "Unable to find stage << ${ss} >> for failure flag bypass"
      continue
    fi
    
    hput --map "$( __extract_value 'WORKFLOW_MAPNAME' )" --key "STAGE_${match}_BYPASS_FAILURE_FLAGS" --value "${YES}"
    #hchange_entry_via_file --filename "$( __extract_value 'RESULTS_DIR' )/workflow.data" --key "STAGE_${match}_BYPASS_FAILURE_FLAGS" --value "${YES}"
  done
  
  hpersist --map "$( __extract_value 'WORKFLOW_MAPNAME' )" --filename "$( __extract_value 'WORKFLOW_MAPFILE' )" --clobber
  return "${PASS}"
}

###
### Cleanup of commandline
###
cleanup_options()
{
  typeset outlog="$1"
  shift
  
  typeset final_args="$@"
  
  ###
  ### Handle conflicting options
  ###
  if [ $( contains_option 'sort' "${final_args}" ) -eq "${YES}" ] && [ $( contains_option 'random' "${final_args}" ) -eq "${YES}" ]
  then
    print_btf_detail --msg "Contradictory options [ sort|random ].  Keeping <random> option." --prefix "$( __extract_value 'PREFIX_WARN' )" >> "${outlog}"
    final_args=$( remove_option 1 'sort:0:1' $final_args )
  fi
  
  if [ $( contains_option 'quiet' "${final_args}" ) -eq "${YES}" ] && [ $( contains_option 'verbose' "${final_args}" ) -eq "${YES}" ]
  then
    print_btf_detail --msg "Contradictory options [ quiet|verbose ].  Keeping <verbose> option." --prefix "$( __extract_value 'PREFIX_WARN' )" >> "${outlog}"
    final_args=$( remove_option 1 'quiet:0:1' $final_args )
  fi

  ###
  ### Begin the reordering process to support getoptex
  ###
  typeset reorder_args1
  typeset reorder_args2
  typeset r=
  typeset found_marker="${NO}"
  
  for r in ${final_args}
  do
    if [ "${r:0:1}" != '-' ] && [ "${found_marker}" -eq "${NO}" ]
    then
      reorder_args1+="${r} "
    else
      found_marker="${YES}"
      reorder_args2+="${r} "
    fi
  done

  final_args="${reorder_args2} ${reorder_args1}"
  
  printf "%s\n" "${final_args}" | \sed -e 's#[[:space:]]*$##'
  return "${PASS}"
}

###
### Collect all subsystems and generate a rollup report
###
combine_all_outputs()
{
  typeset fmt="$1"
  [ -z "${fmt}" ] && return "${FAIL}"
  
  typeset outputfile=
  eval "outputfile=\$( get_${fmt}_filename )"
  [ -z "${outputfile}" ] && return "${FAIL}"

  typeset toplevel="$( __extract_value 'TEST_RESULTS_TOPLEVEL' )"
  
  typeset finalfile="${toplevel}/${outputfile}"
  typeset tmpfile="${finalfile}.tmp"
  
  ###
  ### Need to be sure the stage ordering from the group file is indeed
  ###   preserved based on the input order
  ###
  typeset stage_order_file="${toplevel}/stage_order.txt"
  
  typeset combined_outfile=$( make_output_file --channel "${fmt}" )
  typeset fmtfiles=$( \find "${toplevel}" -type f -name "${outputfile}" -print | \sort )
  
  typeset f=
  for f in ${fmtfiles}
  do
    printf "%s\n" "$( get_subsystem_id_code_${fmt} "${f}" ) ${f}" >> "${stage_order_file}"
  done
  
  record_step ${HOTSPOT_FLAGS} --header 'combine_all_outputs_merge' --start --msg "output format [ ${fmt} ]"
  typeset stage_order_files=$( s\ort -n -k 1,1 "${toplevel}/stage_order.txt" | \cut -f 2 -d ' ' )
  typeset f=
  for f in ${stage_order_files}
  do
    eval "merge_${fmt} \"${f}\" \"${tmpfile}\""
  done
  record_step ${HOTSPOT_FLAGS} --header 'combine_all_outputs_merge' --stop --msg "output format [ ${fmt} ]"

  [ -f "${stage_order_file}" ] && \rm -f "${stage_order_file}"

  record_step ${HOTSPOT_FLAGS} --header 'combine_all_outputs_wrapup' --start --msg "wrapup for format [ ${fmt} ]"
  ###
  ### Collect all outputs and wrap it up...
  ###
  eval "set_${fmt}_filename \"${finalfile}\""
  
  eval "initiate_${fmt}"
  \cat "${tmpfile}" >> "${finalfile}"
  eval "complete_${fmt} rollup"

  record_step ${HOTSPOT_FLAGS} --header 'combine_all_outputs_wrapup' --stop --msg "wrapup for format [ ${fmt} ]"
  
  [ -f "${tmpfile}" ] && \rm -f "${tmpfile}"

  __register_cleanup "${finalfile}" outputs
  return "${PASS}"
}

###
### Settings for premature exiting
###
handle_premature_exit()
{
  __set_internal_value 'PREMATURE_EXIT' 1
  store_generated_output $@
  return "${PASS}"
}

process_output_formatters()
{
  ###
  ### Output definitions to incorporate (text is on by defaults)
  ###
  record_step ${HOTSPOT_FLAGS} --header 'output determination' --start --overhead-type 'STATIC'

  __set_internal_value 'OUTPUT_FORMATS' 'text_output'  # Always ensure the text outputter mechanism is available'
  
  typeset output_formats=$( \find "${__HARNESS_TOPLEVEL}/utilities/outputs" -maxdepth 1 -type f -name "*output.sh" | \sed -e "s#${__HARNESS_TOPLEVEL}/utilities/outputs/##" | grep '_output' | sed -e 's#\.sh##' )
  typeset outfmt=
  typeset outfmt_cnt=2
  for outfmt in ${output_formats}
  do
    typeset isactive="${NO}"
    typeset outvar="${__PROGRAM_VARIABLE_PREFIX}_$(printf "%s\n" "${outfmt}" | \tr [:lower:] [:upper:] )"
    eval "isactive=\${${outvar}}"
    if [ -n "${isactive}" ] && [ "${isactive}" -eq "${YES}" ]
    then
      . "${__HARNESS_TOPLEVEL}/utilities/outputs/${outfmt}.sh"
      if [ $? -ne "${PASS}" ]
      then
        printf_btf_detail --msg "Unable to instantiate << ${outfmt} >> output formatter.." --prefix "$( __extract_value 'PREFIX_WARN' )"
        continue
      fi
      
      __addto_internal_variable 'OUTPUT_FORMATS' "${outfmt}"
      
      typeset outfmt_options="$( printf "%s\n" $( __extract_value 'OUTPUT_OPTION' ) | \grep ${outfmt} )"
      typeset out_opt=
      for out_opt in ${outfmt_options}
      do
        typeset outfunc="__handle_${outfmt}_option"
        eval "${outfunc} \"${out_opt}\""
      done
    fi
  done
  
  ###
  ### Make sure text_output is handled first and give other formatters an option to
  ###   bootstrap settings from text_output to simplify work
  ###
  __set_internal_value 'OUTPUT_FORMATS' "$( printf "%s\n" $( __extract_value 'OUTPUT_FORMATS' ) | \sort | \uniq | \tr '\n' ' ' | \sed -e 's#text_output##' )"
  __set_internal_value 'OUTPUT_FORMATS' "text_output $( __extract_value 'OUTPUT_FORMATS' )"
  
  for outfmt in $( __extract_value 'OUTPUT_FORMATS' )
  do
    typeset outfmt_hdlr="__prepare_${outfmt}_management"
    eval "${outfmt_hdlr}"
  done
  
  record_step ${HOTSPOT_FLAGS} --header 'output determination' --stop --overhead-type 'DYNAMIC'
  return "${PASS}"
}

###
### Run the harnessand let the magic happen
###
run_harness()
{ 
  typeset RC="${PASS}"
  typeset arguments="$@"
  typeset optfile=$( printf "%s\n" "${arguments}" | \cut -f 1 -d '@' )
  arguments=$( printf "%s\n" "${arguments}" | \cut -f 2 -d '@' )
  
  typeset memopts=
      
  ###
  ### Source the generated option file and pull into program
  ###   utilities along with some of the basic library handlers
  ###
  [ -n "${optfile}" ] && [ -f "${optfile}" ] && . "${optfile}"
  
  . "${SLCF_SHELL_TOP}/utilities/common/program_utilities.sh"
  RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to properly source shell library component << program_utilities.sh >>.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi
  
  [ "$( __check_for --key 'VERBOSE_BUILD_SYSTEM' --success )" -eq "${YES}" ] && set -x

  load_program_library "${SLCF_SHELL_TOP}/lib/base_machinemgt.sh" "${optfile}"
  load_program_library "${SLCF_SHELL_TOP}/lib/list.sh" "${optfile}"
  load_program_library "${SLCF_SHELL_TOP}/lib/execaching.sh" "${optfile}" 
  
  __add_support_binaries
  
  ###
  ### Need to determine if we are attempting to handle parallelism across the suites [ TBD ]...
  ###
  if [ $( __check_for --key 'PARALLEL' --success ) -eq "${YES}" ]
  then
    __set_internal_value 'SUBSYSTEM_ACCOUNTING' 'parallel'
  fi
  
  ###
  ### Define the toplevel "temporary" directory based on OS type
  ###
  typeset sttm="$( __extract_value 'START_TIME' )"
  typeset tpdir="$( __extract_value 'RESULTS_DIR' )"
  
  if [ -z "${tpdir}" ]
  then
    if [ -n "${RECURSIVE}" ] && [ "${RECURSIVE}" -gt 0 ]
    then
      tpdir="$( __extract_value 'POSSIBLE_RESULTS_DIR' )"
      if [ -n "${tpdir}" ]
      then
        tpdir+="/${sttm}"
        memopts=$( __import_variable --key "$( __define_internal_variable 'RESULTS_DIR' )" --value "${tpdir}" --use-memory "${YES}" )
      else
        memopts=$( __import_variable --key "$( __define_internal_variable 'RESULTS_DIR' )" --value "$( get_temp_dir )/$( get_user_id )/HARNESS/${sttm}" --use-memory "${YES}" )
      fi
    else
      typeset grpdir="$( __extract_value 'GROUP_DIR' )"
      if [ -z "${grpdir}" ]
      then
        memopts=$( __import_variable --key "$( __define_internal_variable 'RESULTS_DIR' )" --value "$( get_temp_dir )/$( get_user_id )/HARNESS/${sttm}" --use-memory "${YES}" )
      else
        memopts=$( __import_variable --key "$( __define_internal_variable 'RESULTS_DIR' )" --value "$( get_temp_dir )/$( get_user_id )/${grpdir}/${sttm}" --use-memory "${YES}" )
      fi
    fi
  else
    memopts=$( __import_variable --key "$( __define_internal_variable 'RESULTS_DIR' )" --value "${tpdir}" --use-memory "${YES}" )
  fi
  
  memopts+=$( __import_variable --key "$( __define_internal_variable 'HARNESS_ACTIVE' )" --value "${YES}" --use-memory "${YES}" )
  eval "${memopts}"

  tpdir="$( __extract_value 'RESULTS_DIR' )"
  [ ! -d "${tpdir}" ] && \mkdir -p "${tpdir}"
  [ ! -d "${tpdir}" ] && exit "$( __extract_value 'EXIT' )"      

  ###
  ### Define CMD channel for any commands wished to be echoed for diagnosis
  ###
  associate_file_to_channel --channel "$( __define_internal_variable 'CMD' )" --file "${tpdir}/cmds_run.log" --ignore-file-existence --persist

  [ -z "${RECURSIVE}" ] && __snapshot_processtable 
  __handle_outputs
  
  ###
  ### Associate another test harness variable to the top level of the output location
  ###
  if [ -z "$( __extract_value 'TEST_SUMMARY_PATH' )" ]
  then
    memopts=$( __import_variable --key "$( __define_internal_variable 'TEST_SUMMARY_PATH' )" --value "${tpdir}" --use-memory "${YES}" )
    eval "${memopts}"
  fi

  ###
  ### Setup the test_suites area for test mapping
  ###
  memopts=$( __import_variable --key "$( __define_internal_variable 'TEST_SUITES' )" --value "${tpdir}/test_suites" --use-memory "${YES}" )
  eval "${memopts}"
  
  ###
  ### Load necessary work horse functionality for this executable
  ###
  . "${__HARNESS_TOPLEVEL}/lib/run_harness_support.sh"
  RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to properly source testing component infrastructure << run_harness_support.sh >>.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi

  . "${__HARNESS_TOPLEVEL}/utilities/test/base_testing.sh"
  RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to properly source testing component infrastructure << base_testing.sh >>.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi
  
  ###
  ### Define the test harness stdout/stderr location files
  ###
  typeset harness_name="$( remove_extension "$( \basename "$0" )" )"
  memopts=$( __import_variable --key "$( __define_internal_variable 'RESULTS_DIR_STDOUT' )" --value "${tpdir}/${harness_name}.stdout" --use-memory "${YES}" )
  memopts+=$( __import_variable --key "$( __define_internal_variable 'RESULTS_DIR_STDERR' )" --value "${tpdir}/${harness_name}.stderr" --use-memory "${YES}" )
  eval "${memopts}"

  ###
  ### Define the workflow mapfile if this is a workflow...
  ###
  if [ $( __check_for --key 'WORKFLOW' --success ) -eq "${YES}" ]
  then
    __set_internal_value 'WORKFLOW_MAPFILE' "$( __extract_value 'RESULTS_DIR' )/workflow.data"
    __set_internal_value 'WORKFLOW_MAPNAME' 'workflow'
  fi
  
  ###
  ### Associate various channels to access the test harness stdout
  ###
  associate_file_to_channel --channel 'JSON' --file "${tpdir}/cmds_run.log" --ignore-file-existence
  associate_file_to_channel --channel 'XML' --file "${tpdir}/cmds_run.log" --ignore-file-existence
  associate_file_to_channel --channel "$( __define_internal_variable 'INFO' )" --file "$( __extract_value 'RESULTS_DIR_STDOUT' )" --ignore-file-existence --persist
  __register_cleanup "$( __extract_value 'RESULTS_DIR_STDOUT' )" '<SKIP>'
  
  ###
  ### Add the invocation arguments to the test harness stdout file...
  ###
  record_step ${HOTSPOT_FLAGS} --header 'BEGIN_PRG' --msg "Invocation arguments : $( __extract_value 'INPUT_ARGS' )" --overhead-type 'STATIC'
  
  ###
  ### Display the program header
  ###
  print_program_version "Canopus Test Harness" "$( __extract_value 'PROGRAM_VERSION' ).$( __extract_value 'PROGRAM_VERSION_BUILD' ) ($( __extract_value 'PROGRAM_BUILD_TYPE' ))" "$( __extract_value 'PROGRAM_BUILD_DATE' )"

  ###
  ### Check to be sure necessary binaries are available to use
  ###
  record_step ${HOTSPOT_FLAGS} --header 'binary validation' --start --overhead-type 'STATIC'
  validate_basic_binaries $( __extract_value 'BASIC_BINARIES' )
  RC=$?
  record_step ${HOTSPOT_FLAGS} --header 'binary validation' --stop --overhead-type 'DYNAMIC'

  if [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to validate necessary base binaries.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi
  
  ### TODO : Check to see if this is caching the executables...
  record_step ${HOTSPOT_FLAGS} --header 'binary caching' --start --overhead-type 'STATIC'
  cache_executables $( __extract_value 'BASIC_BINARIES' )
  RC=$?
  record_step ${HOTSPOT_FLAGS} --header 'binary caching' --stop --overhead-type 'STATIC'

  if [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to cache necessary base binary executable(s).  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi

  [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ] && display_cached_executables $( __extract_value 'BASIC_BINARIES' )

  ###
  ### Display harness header
  ###
  print_harness_header

  __register_cleanup "${__FILEMGRFILE}"
  __register_cleanup "$( __extract_value 'LOGFILE' )"
  
  ###
  ### Define the error and warn channels to point to the pre-determined error/warning logfile
  ###
  associate_file_to_channel --channel ERROR --file "$( __extract_value 'LOGFILE' )" --ignore-file-existence --persist
  associate_file_to_channel --channel WARN --file "$( __extract_value 'LOGFILE' )" --ignore-file-existence --persist
  
  [ -n "${optfile}" ] && __register_cleanup "${optfile}" inputs
  
  ###
  ### Check to see if the pre-setup requirements are necessary to fail the process...
  ###
  preprocess_determined="${NO}"
  postprocess_determined="${NO}"
  
  record_step ${HOTSPOT_FLAGS} --header 'pre-process' --start --msg 'pre-processing determination' --overhead-type 'STATIC'
  typeset prechk="$( __extract_value 'PRECHECK' )"
  if [ -n "${prechk}" ]
  then
    if [ -f "${prechk}" ]
    then
      . "./${prechk}"
      RC=$?
      [ "${RC}" -eq "${PASS}" ] && preprocess_determined="${YES}"
    fi
    if [ "${preprocess_determined}" -ne "${YES}" ]
    then
      __set_internal_value 'PREMATURE_EXIT_MSG' "Setup for testing failed!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
      handle_premature_exit "${optfile}"
      return "$( __extract_value 'EXIT' )"
    fi      
  else
    preprocess_determined=2
  fi    

  if [ "${preprocess_determined}" -eq "${YES}" ]
  then
    [ -f "$( __extract_value 'SETUP_OPTIONS_FILE' )" ] && . "$( __extract_value 'SETUP_OPTIONS_FILE' )"
    printf "\n"
    print_btf_detail --msg "Preprocessing completed." --prefix "$( __extract_value 'PREFIX_INFO' )"
    __register_cleanup "$( __extract_value 'SETUP_OPTIONS_FILE' )" inputs
  fi
  record_step ${HOTSPOT_FLAGS} --header 'pre-process' --stop --msg 'pre-processing determination' --overhead-type 'DYNAMIC'

  ###
  ### Define the argument file, group test file, group suite file, and dependency file
  ###
  memopts=$( __import_variable --key "$( __define_internal_variable 'GROUP_SUITEFILE' )" --value "${tpdir}/group_suitefile_${sttm}" --use-memory "${YES}" )
  memopts+=$( __import_variable --key "$( __define_internal_variable 'GROUPING_STATS_FILE' )" --value "${tpdir}/group_stats_${sttm}" --use-memory "${YES}" )
  memopts+=$( __import_variable --key "$( __define_internal_variable 'ARGUMENT_FILE' )" --value "${tpdir}/arguments_${sttm}" --use-memory "${YES}" )
  memopts+=$( __import_variable --key "$( __define_internal_variable 'DEPENDENCY_FILE' )" --value "${tpdir}/dependency_matrix_${sttm}" --use-memory "${YES}" )
  eval "${memopts}"

  ###
  ### Register these files for cleanup when completed
  ###
  __register_cleanup "$( __extract_value 'ARGUMENT_FILE' )" inputs
  __register_cleanup "$( __extract_value 'GROUP_SUITEFILE' )" inputs
  __register_cleanup "$( __extract_value 'DEPENDENCY_FILE' )" inputs
  __register_cleanup "$( __extract_value 'GROUPING_STATS_FILE' )" inputs
  
  ###
  ### Use a hash map to set up the extension types
  ###
  update_extension_patterns
  memopts=$( __import_variable --key "$( __define_internal_variable 'EXTENSION_KNOWN' )" --value "$( __extract_value 'EXTENSION_KNOWN' )" --use-memory "${YES}" )
  eval "${memopts}"

  ###
  ### Basic startup information
  ###
  printf "\n%s\n" "Starting (UTC)      : $( __change_time_to_UTC ${sttm} )"
  printf "%s\n" "Temporary Directory : ${tpdir}"
  
  [ -n "$( __extract_value 'INPUT_FILE' )" ] && printf "%s\n" "Input Driver File   : $( __extract_value 'INPUT_FILE' )"
  printf "\n"
  
  ###
  ### Pre commandline processing
  ###
  record_step ${HOTSPOT_FLAGS} --header 'pre-process_cmdline' --start --overhead-type 'STATIC'
  __pre_commandline_processing
  record_step ${HOTSPOT_FLAGS} --header 'pre-process_cmdline' --stop --overhead-type 'STATIC'

  ###
  ### Build cmdline representation for the running of tests
  ###
  record_step ${HOTSPOT_FLAGS} --header 'process_cmdline' --start --overhead-type 'STATIC'
  [ -n "${arguments}" ] && arguments="$( build_cmdline "${arguments}" ) "

  record_step ${HOTSPOT_FLAGS} --header 'process_cmdline' --stop --overhead-type 'DYNAMIC'

  record_step ${HOTSPOT_FLAGS} --header 'process_inputfile' --start --overhead-type 'STATIC'
  
  typeset inpfl="$( __extract_value 'INPUT_FILE' )"
  if [ -z "${inpfl}" ]
  then
    if [ $( __check_for --key 'UNIT_TEST' --success ) -eq "${YES}" ]
    then
      inpfl="${__HARNESS_TOPLEVEL}/drivers/unit_testing.txt"
    fi
  fi

  if [ -n "${inpfl}" ] && [ -f "${inpfl}" ]
  then
    ###
    ### Parse an input file if requested
    ###
    arguments+=$( parse_driver_file --filename "${inpfl}" )
    RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to parse expected driver file << ${inpfl} >>.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
      handle_premature_exit "${optfile}"
      return "$( __extract_value 'EXIT' )"
    fi
    print_btf_detail --msg "Argument parsing completed." --prefix "$( __extract_value 'PREFIX_INFO' )"
  else
    if [ -z "${arguments}" ]
    then
      __set_internal_value 'PREMATURE_EXIT_MSG' "$( __extract_value 'DISPLAY_NEWLINE_MARKER' )Defined driver file << ${inpfl} >> does not exist.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
      handle_premature_exit "${optfile}"
      return "$( __extract_value 'EXIT' )"
    fi
  fi

  record_step ${HOTSPOT_FLAGS} --header 'process_inputfile' --stop --overhead-type 'DYNAMIC'
  
  ###
  ### Dump the arguments to a file to be read in and processed to help
  ###   remove restrictions on shell commandline sizes
  ###
  if [ -n "${arguments}" ] && [ "${arguments}" != ' ' ]
  then
    printf "%s\n" ${arguments} >> "$( __extract_value 'ARGUMENT_FILE' )"
  else
    print_btf_detail --msg 'No test processing arguments provided.  Nothing to do!' --prefix "$( __extract_value 'PREFIX_WARN' )" --newline-count 2
    return "$( __extract_value 'EXIT' )"
  fi
  
  ###
  ### Post commandline processing
  ###
  record_step ${HOTSPOT_FLAGS} --header 'post-process_cmdline' --start --overhead-type 'STATIC'
  __post_commandline_processing
  record_step ${HOTSPOT_FLAGS} --header 'post-process_cmdline' --stop --overhead-type 'STATIC'
  
  ###
  ### Pull in the dependency mapfile
  ###
  [ -f "$( __extract_value 'DEPENDENCY_FILE' )" ] && hread_map --filename "$( __extract_value 'DEPENDENCY_FILE' )"
  
  process_output_formatters
  
  ###
  ### Handle the tagging if on the command line [ these are global tags !!! ]
  ###
  [ -n "$( __extract_value 'TAG' )" ] && __set_internal_value 'USE_TAGS' "${YES}"
  
  ###
  ### If the logfile has any information up to this point, display it before continuing...
  ###
  if [ -f "$( __extract_value 'LOGFILE' )" ]
  then
    printf "\n"
    \cat "$( __extract_value 'LOGFILE' )"
    printf "\n"
  fi

  ###
  ### If the argument file has nothing in it, then there is nothing to do...
  ###
  if [ ! -s "$( __extract_value 'ARGUMENT_FILE' )" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "No information given to process.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi
  
  if [ -n "$( __extract_value 'TAG_FILE_SELECT' )" ]
  then
    process_tag_selection
    RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      print_btf_detail --msg "Failure to provide selection tags.  Skipping any tags!" --prefix "$( __extract_value 'PREFIX_WARN' )"
      RC="${PASS}"
    fi
  fi

  ###
  ### Group the tests under a same directory to allow for better batch processing
  ###   This will allow for tag selection if requested or to skip tag definition
  ###
  print_btf_detail --msg "Collection Toplevel --> ${tpdir}" --newline-count 2 --prefix "$( __extract_value 'PREFIX_INFO' )"
  
  if [ $( __check_for --key 'DETAIL' --success ) -eq "${YES}" ]
  then
    print_btf_detail --msg "Test grouping underway." --prefix "$( __extract_value 'PREFIX_DETAIL' )"
  else
    printf "$( __extract_value 'PREFIX_INFO' ) %s\r" "Test grouping underway..."
  fi
  
  record_step ${HOTSPOT_FLAGS} --header 'grouping' --start --overhead-type 'STATIC'
  group_tests
  RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "Grouping process failed.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi
  record_step ${HOTSPOT_FLAGS} --header 'grouping' --stop --overhead-type 'DYNAMIC'
  
  [ $( __check_for --key 'WORKFLOW' --success ) -eq "${YES}" ] && allow_selective_stages
  
  if [ $( __check_for --key 'DETAIL' --success ) -eq "${YES}" ]
  then
    print_btf_detail --msg "Test grouping completed." --prefix "$( __extract_value 'PREFIX_DETAIL' )" --newline-count 2 --clear-line
  else
    printf "$( __extract_value 'PREFIX_INFO' ) %s\n" "Test grouping completed."
  fi
  
  __register_cleanup "$( __extract_value 'TEST_SUITES' )" inputs

  if [ ! -f "$( __extract_value 'GROUP_SUITEFILE' )" ] || [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "No matching tests found to execute.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi

  ###
  ### Show information necessary for command line processing
  ###
  printf "\n"
  display_cmdline_flags "$( __extract_value 'PROGRAM_OPTIONS' )"

  ###
  ### Prepare the overall test stats collection map
  ###
  record_step ${HOTSPOT_FLAGS} --header 'globalmap' --start --msg "reset of global map [ $( __extract_value 'OVERALL_MAP' ) ]" --overhead-type 'STATIC'
  __reset_overall_map
  record_step ${HOTSPOT_FLAGS} --header 'globalmap' --stop --msg "reset of global map [ $( __extract_value 'OVERALL_MAP' ) ]" --overhead-type 'STATIC'

  ###
  ### Move to the appropriate TEST DIRECTORY for each line in the group test file
  ###  since this has laready been grouped to make processing easier
  ###
  __set_internal_value 'START_ALL_SUITETIME' "$( __today_as_seconds )"

  if [ $( __check_for --key 'WORKFLOW' --success ) -eq "${YES}" ]
  then
    hread_map --filename "$( __extract_value 'RESULTS_DIR' )/workflow.data"
    __set_internal_value 'WORKFLOW_MAP' "$( hget_mapname --filename "$( __extract_value 'RESULTS_DIR' )/workflow.data" )"
    load_program_library "${__HARNESS_TOPLEVEL}/utilities/workflow/workflow.sh"
  fi
  
  if [ -f "$( __extract_value 'GROUP_SUITEFILE' )" ]
  then
    record_step ${HOTSPOT_FLAGS} --header 'group_mapfile' --start --msg 'read of group map' --overhead-type 'STATIC'
    typeset suites="$( haccess_entry_via_file --filename "$( __extract_value 'GROUP_SUITEFILE' )" --key 'known_suites' )"
    record_step ${HOTSPOT_FLAGS} --header 'group_mapfile' --stop --msg 'read of group map' --overhead-type 'STATIC'
    
    if [ -n "${suites}" ]
    then
      . "${SLCF_SHELL_TOP}/lib/assertions.sh"
      RC=$?
      if [ "${RC}" -ne "${PASS}" ]
      then
        __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to load basic assertions library.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
        handle_premature_exit "${optfile}"
        return "$( __extract_value 'EXIT' )"
      fi
    fi
    
    record_step ${HOTSPOT_FLAGS} --header 'process_suites' --start --msg 'processing of suites' --overhead-type 'DYNAMIC'
    typeset s=
    for s in ${suites}
    do
      ###
      ### Prepare the per suite test stats collection map
      ###
      record_step ${HOTSPOT_FLAGS} --header 'localmap' --start --msg "reset of stats for local map [ $( __extract_value 'SUBSYSTEM_MAP' ) ]" --overhead-type 'DYNAMIC'
      __reset_subsystem_map
      record_step ${HOTSPOT_FLAGS} --header 'localmap' --stop --msg "reset of stats for local map [ $( __extract_value 'SUBSYSTEM_MAP' ) ]" --overhead-type 'STATIC'

      ###
      ### Update fields with information based on groupings
      ###
      record_step ${HOTSPOT_FLAGS} --header "classmap_${s}" --start --msg "read of << ${s} >> class map" --overhead-type 'STATIC'
      hput --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TRUE_NAME' --value "${s}"
      
      typeset suitesubj="$( haccess_entry_via_file --filename "$( __extract_value 'TEST_SUITES' )/${s}_class.map" --key 'suite_subject' | sed -e "s#$( __extract_value 'SPACE_MARKER' )# #g" )"
      typeset fulltestpath="$( haccess_entry_via_file --filename "$( __extract_value 'TEST_SUITES' )/${s}_class.map" --key 'suite_path' )"
      record_step ${HOTSPOT_FLAGS} --header "classmap_${s}" --stop --msg "read of << ${s} >> class map"--overhead-type 'STATIC'
 
      [ $( is_empty --str "${fulltestpath}" ) -eq "${YES}" ] && continue
      
      ###
      ### Move to the location of the test suite
      ###
      __set_internal_value 'JUMP_POINT' "$( \pwd -L )"
      # pushd "${fulltestpath}"
      if [ ! -d "${fulltestpath}" ]
      then
        print_btf_detail --msg "Unable to locate << ${fulltestpath} >> for schedule tests(s)" --prefix "$( __extract_value 'PREFIX_WARN' )"
        continue
      fi
      cd "${fulltestpath}" >/dev/null 2>&1

      __set_internal_value 'CURRENT_TEST_LOCATION' "${fulltestpath}"
      [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ] && __set_internal_value 'SHOW_RUNNING_TESTNAME' "${YES}"
      
      printf "%s\n" "$( __extract_value 'DBL_DIVIDER' )"
      print_btf_detail --msg "Moving to ${fulltestpath}" --prefix "$( __extract_value 'PREFIX_START' )"
      printf "\n"
      
      ###
      ### Call into each "suite" of tests to run.  Afterwards, cleanup anything
      ###   left behind in the process
      ###
      record_step ${HOTSPOT_FLAGS} --header "testing_${s}" --start --msg "tests for class << ${s} >> [ subject ${suitesubj} ]" --overhead-type 'STATIC'
      run_suite --subject "${suitesubj}" --class "${s}"
      RC=$?
      record_step ${HOTSPOT_FLAGS} --header "testing_${s}" --stop --msg "tests for class << ${s} >> [ subject ${suitesubj} ]" --overhead-type 'DYNAMIC'
      
      if [ "${RC}" -eq "${PASS}" ]
      then
        demolish
      else
        ###
        ### Allow for stopping of any additional testing based on 'suite-fail-on-error' flag set...
        ### Why is this if-block here???
        ###
        hadd_item --map "$( __extract_value 'WORKFLOW_MAPNAME' )" --key 'failed_stages' --value "$( __extract_value 'CURRENT_STAGE_ID' )"
        
        if [ "${RC}" -ne "${PASS}" ]
        then
          if [ "$( __check_for --key 'SUITE_STOP_ON_FAIL' --success )" -eq "${YES}" ]
          then
            typeset ALLOW_BYPASS="${NO}"
            if [ $( __check_for --key 'WORKFLOW' --success ) -eq "${YES}" ]
            then
              ALLOW_BYPASS=$( default_value --def "${ALLOW_BYPASS}" $( haccess_entry_via_file --filename "$( __extract_value 'WORKFLOW_MAPFILE' )" --key "STAGE_$( __extract_value 'CURRENT_STAGE_ID' )_BYPASS_FAILURE_FLAGS" ) )
            fi
            
            if [ "${ALLOW_BYPASS}" -eq "${NO}" ]
            then
              log_error --msg "Error detection specified at suite execution level.  Suite << ${s} >> encountered a failure.  Stopping!"
              print_btf_detail --msg "Error detection specified at suite execution level.  Suite << ${s} >> encountered a failure.  Stopping!" --prefix "$( __extract_value 'PREFIX_ERROR' )"
              unset 'suitemap'
              printf "\n"
              print_btf_detail --msg "Moving back to $( __extract_value 'STARTUP_DIR' )" --prefix "$( __extract_value 'PREFIX_END' )"
              printf "%s\n\n" "$( __extract_value 'DBL_DIVIDER' )"
              cd "$( __extract_value 'JUMP_POINT' )" >/dev/null 2>&1
              break
            fi
          fi
        else
          break
        fi
      fi
    
      ###
      ### Return to launch directory
      ###
      print_btf_detail --msg "Moving back to $( __extract_value 'STARTUP_DIR' )" --prefix "$( __extract_value 'PREFIX_END' )"
      printf "%s\n\n" "$( __extract_value 'DBL_DIVIDER' )"
      
      # popd
      cd "$( __extract_value 'JUMP_POINT' )" >/dev/null 2>&1
    done
    
    record_step ${HOTSPOT_FLAGS} --header 'process_suites' --stop --msg 'processing of suites' --overhead-type 'DYNAMIC'
    
    #hclear --map "${classmap}"
    #unset classmap
    ###
    ### Final cleanup of any and all remnants
    ###
    demolish
  fi
  __set_internal_value 'END_ALL_SUITETIME' "$( __today_as_seconds )"
  
  hput --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_SUITETIME' --value "$(( $( __extract_value 'END_ALL_SUITETIME' ) - $( __extract_value 'START_ALL_SUITETIME' ) ))"
  
  ###
  ### Check to see if the pre-setup requirements are necessary to fail the process...
  ###
  record_step ${HOTSPOT_FLAGS} --header 'post-process' --start --overhead-type 'STATIC'
  typeset postchk="$( __extract_value 'POSTCHECK' )"
  if [ -n "${postchk}" ]
  then
    if [ -f "${postchk}" ]
    then
      . "./${postchk}"
      RC=$?
      [ "${RC}" -eq "${PASS}" ] && postprocess_determined="${YES}"
    fi
  else
    postprocess_determined=2
  fi    

  if [ "${postprocess_determined}" -eq "${YES}" ]
  then
    printf "\n"
    print_btf_detail --msg "Postprocessing completed." --prefix "$( __extract_value 'PREFIX_INFO' )"
  fi
  record_step ${HOTSPOT_FLAGS} --header 'post-process' --stop --overhead-type 'DYNAMIC'

  ###
  ### Record the completion time of the test harness
  ###
  typeset program_end_time=$( __today_as_seconds )
  __set_internal_value 'END_TIME' "${program_end_time}"
  
  hput --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_TIME' --value "$(( $( __extract_value 'END_TIME' ) - $( __extract_value 'START_TIME' ) ))"
  
  record_step ${HOTSPOT_FLAGS} --header 'final output management' --start --overhead-type 'STATIC'

  ###
  ### Prepare all output formatters based on collected test data statistics
  ###
  for outfmt in $( __extract_value 'OUTPUT_FORMATS' )
  do
    combine_all_outputs "${outfmt}"
    eval "release_${outfmt}"
  done
  record_step ${HOTSPOT_FLAGS} --header 'final output management' --stop --overhead-type 'DYNAMIC'

  ###
  ### Allow copy back of results toplevel to another location [ TBD ]
  ###
  typeset toplevel="$( __extract_value 'TEST_RESULTS_TOPLEVEL' )"

  [ -n "$( __extract_value 'COPY_BACK' )" ] && [ -n "${toplevel}" ] && [ -d "${toplevel}" ] && prepare_copy_back

  ###
  ### Move all necessary external generated files into appropriate destination directory
  ###   to keep all components together and allow for better bookkeeping of the contents
  ###
  record_step ${HOTSPOT_FLAGS} --header 'END_PRG' --overhead-type 'STATIC'
  
  if [ -n "${RECURSIVE}" ]
  then
    ###
    ### Need to scan the output and prepare information to be passed back to parent
    ###   from recursive calling/invocation
    ###
    typeset tpaas=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_PASS' )
    typeset tfaas=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_FAIL' )
    typeset tsaas=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_SKIP' )
    typeset tflaas=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_TESTS_RUN' )
    
    typeset subdatafiles="$( \find "${toplevel}" -type f -name "*.data" | \tr '\n' ' ' )"
    RC="$( __range_limit "${tfaas}" 0 1 )"
    
    __write_recursive_file --style 'xml' --style 'json' --datafiles "${subdatafiles}" --passes "${tpaas}" --fails "${tfaas}" --skips "${tsaas}" --files "${tflaas}" --return-code "${RC}" --dir-location "$( ${__REALPATH} ${__REALPATH_OPTS} ${toplevel} )" --file-template "recursive_run_results_${sttm}"
  else
    RC="${PASS}"
  fi
  
  store_generated_output --output-dir "${toplevel}"

  display_files_in_build_system "${tpdir}" "${RC}"

  return "${RC}"
}

###
### Setup
###
setup()
{
  typeset program_start_time=$( __today_as_seconds )
  OPTALLOW_ALL="${YES}"

  ###
  ### Determine locations of all necessary paths especially from where we are starting
  ###
  typeset CANOPUS_STARTUP_DIR=$( printf "%s\n" "$0" | \sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' | \cut -d '/' -f 2- | \sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' )
  CANOPUS_LAUNCH_DIR="$( \pwd -L )"
  cd "${CANOPUS_STARTUP_DIR}" > /dev/null
  CANOPUS_STARTUP_DIR="$( \pwd -L )"
  cd "${CANOPUS_LAUNCH_DIR}" > /dev/null

  ###
  ### Get basic paths defined to help the bootstrap mechanism [ program utilities are now available ]
  ###
  __setup_basic_functional_paths "${CANOPUS_STARTUP_DIR}" 1 "${program_start_time}"
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    printf "\n"
    print_btf_detail --msg "Unable to find support files for the Canopus Test Harness.  Exiting!" --prefix '[ERROR    ]' --newline-count 2
    return "${RC}"
  fi

  ###
  ### System-wide, harness independent settings
  ###
  typeset optfile="$( __extract_value 'OPTION_FILE' )"
  
  __import_variable --key 'LC_ALL' --value 'C' --file "${optfile}"
  __import_variable --key '__PROGRAM_VARIABLE_PREFIX' --value 'CANOPUS' --file "${optfile}"
  __import_variable --key '__PROGRAM_OPTION_FILE' --value "${optfile}" --file "${optfile}"
  __import_variable --key '__harness_toplevel' --value "${__harness_toplevel}" --file "${optfile}"

  ###
  ### Define some basic properties
  ###
  __import_variable --key "$( __define_internal_variable 'STARTUP_DIR' )" --value "$( __extract_value 'STARTUP_DIR' )" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable 'LOGFILE' )" --value "${__harness_toplevel}/.error_warn_${program_start_time}.log" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable 'SETUP_OPTIONS_FILE' )" --value "$( __extract_value 'STARTUP_DIR' )/.user_options_${program_start_time}" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable 'DRYRUN' )" --value "${NO}" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable 'TEXT_OUTPUT' )" --value "${YES}" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable 'INPUT_ARGS' )" --value "$( printf "%s " $@ )" --file "${optfile}"

  ###
  ### Allow for the SLCF library to be tested naturally
  ###
  SLCF_SHELL_TESTDIR="${SLCF_SHELL_TESTDIR:-${SLCF_SHELL_TOP}/test}"
  __import_variable --key 'SLCF_SHELL_TESTDIR' --value "${SLCF_SHELL_TESTDIR}" --file "${optfile}"
  
  ###
  ### Reorder command line options as necessary to support getoptex
  ###
  typeset cleaned_options=$( cleanup_options "${__harness_toplevel}/.error_warn_${program_start_time}.log" $@ )

  . "${__harness_toplevel}/lib/run_harness_support.sh"
  [ $? -ne "${PASS}" ] && return "${FAIL}"
  
  ###
  ### Gain access to all help screens for the Canopus Test Harness system
  ###
  . "${__harness_toplevel}/help/load_all_usage_screens.sh"
  
  DEFAULT_CANOPUS_TEST_FILE_EXCLUDE_PATTERNS='^test_ ^__setup'
  DEFAULT_CANOPUS_TEST_DIR_EXCLUDE_PATTERNS='lib'

  update_exclude_patterns
  
  __import_variable --key "$( __define_internal_variable 'TEST_FILE_EXCLUDE_PATTERNS' )" --value "$( __extract_value 'TEST_FILE_EXCLUDE_PATTERNS' )" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable 'TEST_DIR_EXCLUDE_PATTERNS' )" --value "$( __extract_value 'TEST_DIR_EXCLUDE_PATTERNS' )" --file "${optfile}"

  ###
  ### Read in system specific file data to import into environment
  ###
  __set_internal_value 'SYSTEM_DATA_FILE' "${__harness_toplevel}/bin/data/harness_system_data"
  __set_internal_value 'SETTINGS' "$( __handle_option_management ${cleaned_options} )"

  ###
  ### Separate options to be eval'd into memory (from string/file) and those which should be passed along
  ###
  typeset errmsg=$( printf "%s\n" "$( __extract_value 'SETTINGS' )" | \cut -f 4 -d '@' )
  typeset show_usage=$( printf "%s\n" "$( __extract_value 'SETTINGS' )" | \cut -f 3 -d '@' | \cut -f 1 -d '|' )
  typeset help_screens=$( printf "%s\n" "$( __extract_value 'SETTINGS' )" | \cut -f 3 -d '@' | \cut -f 2 -d '|' | \sed -e 's#^[[:blank:]]##' )
  
  typeset option_preparation=$( printf "%s\n" "$( __extract_value 'SETTINGS' )" | \cut -f 1 -d '@' )
  [ -n "${option_preparation}" ] && eval "${option_preparation}"

  __set_internal_value 'SETTINGS' "$( printf "%s\n" "$( __extract_value 'SETTINGS' )" | \cut -f 2 -d '@' | \tr '|' ' ' )"

  [ -z "$( __extract_value 'CURRENT_USER' )" ] && __set_internal_value 'CURRENT_USER' 'CA_UIM_BCI_Tester'
  
  ###
  ### Source the options file while in this function (we are in a subshell)
  ###
  [ -f "${optfile}" ] && . "${optfile}"
  if [ $( __check_for --key 'VERBOSE' --success ) -eq "${YES}" ]
  then
    if [ -n "${optfile}" ] && [ -f "${optfile}" ]
    then
      printf "\n%s\n\n%s\n" "RUNTIME OPTIONS FILE" "$( __extract_value 'DIVIDER' )" >> "$( __extract_value 'STARTUP_DIR' )/.error_warn_${program_start_time}.log"
      \cat "${optfile}" >> "$( __extract_value 'STARTUP_DIR' )/.error_warn_${program_start_time}.log"
      printf "%s\n\n" "$( __extract_value 'DIVIDER' )" >> "$( __extract_value 'STARTUP_DIR' )/.error_warn_${program_start_time}.log"
    fi
  fi

  ###
  ### Check to see if the help screen should be shown and exit
  ###
  if [ "${show_usage}" -ne "${PASS}" ]
  then
    if [ "${show_usage}" -eq "${YES}" ] || [ "${show_usage}" -eq "${HELP}" ]
    then
      [ -n "${errmsg}" ] && printf "\n%s\n" "${errmsg}" 1>&2
      usage ${help_screens}
      return "${show_usage}"
    fi
  fi

  printf "%s@%s\n" "${optfile}" "$( __extract_value 'SETTINGS' )"
  return "${PASS}"
}

###
### Update default exclusion settings
###
update_exclude_patterns()
{
  __set_internal_value 'TEST_FILE_EXCLUDE_PATTERNS' "${DEFAULT_CANOPUS_TEST_FILE_EXCLUDE_PATTERNS}"
  [ -n "$( __extract_value 'EXCLUDE_FILE_PATT' )" ] && CANOPUS_TEST_FILE_EXCLUDE_PATTERNS+=" $( __extract_value 'EXCLUDE_FILE_PATT' )"

  __set_internal_value 'TEST_DIR_EXCLUDE_PATTERNS' "${DEFAULT_CANOPUS_TEST_DIR_EXCLUDE_PATTERNS}"
  [ -n "$( __extract_value 'EXCLUDE_DIR_PATT' )" ] && CANOPUS_TEST_DIR_EXCLUDE_PATTERNS+=" $( __extract_value 'EXCLUDE_DIR_PATT' )"
  
  return "${PASS}"
}

update_extension_patterns()
{
  typeset known_extension_vars=$( set | \cut -d '=' -f 1 | \grep "${__PROGRAM_VARIABLE_PREFIX}_EXTENSION" | \grep -v 'TYPES' | \grep -v 'MARKER' )
  
  typeset kev=
  for kev in ${known_extension_vars}
  do
    typeset run_ext=
    eval "run_ext=\${$kev}"
    [ -n "${run_ext}" ] && __addto_internal_variable 'EXTENSION_KNOWN' "${run_ext}"
  done
  
  [ -n "$( __extract_value 'INSERT_EXTENSION' )" ] && __addto_internal_variable 'EXTENSION_KNOWN' " $( __extract_value 'INSERT_EXTENSION' )"

  typeset exttype
  if [ -n "$( __extract_value 'SELECT_EXTENSION' )" ]
  then
    __set_internal_value 'SELECT_EXTENSION' "$( printf "%s\n" $( __extract_value 'SELECT_EXTENSION' ) | \sort | \uniq )"
    __set_internal_value 'EXTENSION_KNOWN' "$( __extract_value 'SELECT_EXTENSION' )"
  fi
  
  __set_internal_value 'INSERT_EXTENSION'
  __set_internal_value 'SELECT_EXTENSION'
  
  typeset prev_known_exts="$( __extract_value 'EXTENSION_KNOWN' )"
  typeset known_extensions=
  typeset seen=
  
  typeset exttype=
  for exttype in ${prev_known_exts}
  do
    typeset ext=$( get_element --data "${exttype}" --id 1 --separator ':' )
    
    printf "%s\n" ${seen} | \grep -q "${ext}\\b"
    typeset RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      typeset entries=$( printf "%s\n" ${prev_known_exts} | \grep -n "^${ext}:" | \cut -f 1 -d ':' )
      typeset num_entries=$( __get_line_count --non-file "${entries}" )
      if [ "${num_entries}" -gt 1 ]
      then
        typeset kept_pattern="$( printf "%s\n" "${prev_known_exts}" | \grep "^${ext}:" | \tail -n 1 )"
        known_extensions+=" ${kept_pattern}"
      else
        known_extensions+=" ${exttype}"
      fi
      seen+=" ${ext}"
    fi
  done
  seen="$( printf "%s\n" ${seen} )"
  
  [ -n "${known_extensions}" ] && __set_internal_value 'EXTENSION_KNOWN' "${known_extensions}"
  [ -n "$( __extract_value 'EXTENSION_KNOWN' )" ] && __set_internal_value 'EXTENSION_KNOWN' "$( printf "%s\n" $( __extract_value 'EXTENSION_KNOWN' ) | \sort | \uniq )"
  return "${PASS}"
}

###
### Usage screen for this "binary"
###
usage()
{
  typeset newline_marker="$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
  typeset tab_marker="$( __extract_value 'DISPLAY_TAB_MARKER' )"
  typeset divider=$( printf "%s" "$( __extract_value 'DIVIDER' )${newline_marker}" )

  typeset menu="${newline_marker}"
  menu+=$( help_banner 'Canopus Harness Usage' )
  menu+=$( printf "%s" "${tab_marker}Date: $( __extract_value 'PROGRAM_BUILD_DATE' )${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}Version: $( __extract_value 'PROGRAM_VERSION' ).$( __extract_value 'PROGRAM_VERSION_BUILD' )${newline_marker}" )
  menu+="${newline_marker}"
  menu+="${divider}"
  menu+="${newline_marker}"

  if [ $# -lt 1 ]
  then
    menu+=$( printf "%s" "${tab_marker}SubMenus${newline_marker}${newline_marker}" )
    menu+=$( printf "%s" "${tab_marker}   dependency            --> Options to enable dependency capabilities within the  Canopus Harness${newline_marker}" )
    menu+=$( printf "%s" "${tab_marker}   general               --> Basic options usable within the Canopus Harness${newline_marker}" )
    menu+=$( printf "%s" "${tab_marker}   harness               --> Specific options usable within the Canopus Harness${newline_marker}" )
    menu+=$( printf "%s" "${tab_marker}   language              --> Options for language${newline_marker}" )
    menu+=$( printf "%s" "${tab_marker}   output                --> Options to enable output capabilities within the Canopus Harness${newline_marker}" )
    menu+=$( printf "%s" "${tab_marker}   results               --> Options to management results within the Canopus Harness${newline_marker}" )
    menu+=$( printf "%s" "${tab_marker}   tag                   --> Options to enable test tagging capabilities within the Canopus Harness${newline_marker}" )
  else
    typeset submenu=
    for submenu in $@
    do
      __usage_${submenu}_management > /dev/null 2>&1
      [ $? -eq 0 ] && menu+=$( __usage_${submenu}_management )
    done
  fi
  
  printf "%s\n" "${menu}" | \sed -e "s#${newline_marker}#\n#g" -e "s#${tab_marker}#   #g" 1>&2

  [ -z "$( __extract_value 'PREMATURE_EXIT_MSG' )" ] && [ -f "$( __extract_value 'OPTION_FILE' )" ] && \rm -f "$( __extract_value 'OPTION_FILE' )"
  store_generated_output
  return "$( __extract_value 'EXIT' )"
}

###############################################################################
# MAIN PROGRAM
###############################################################################
###
### handle potential recursion...
###
if [ -n "${CANOPUS_RESULTS_DIR}" ]
then
  [ -z "${RECURSIVE}" ] && RECURSIVE=0
  RECURSIVE=$(( RECURSIVE + 1 ))
  __reset_all_parent_settings
fi

user_inputs="$@"

[ -n "${BUILD_SYSTEM}" ] && user_inputs+=" --manage-build-system --verbose-build-system"

args=$( setup ${user_inputs} )
__RC=$?
[ "${__RC}" -ne 0 ] && exit "${__RC}"

run_harness "${args}"
exit $?
