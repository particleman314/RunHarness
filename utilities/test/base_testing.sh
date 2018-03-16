#! /bin/sh

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
# Software Package : Shell Automated Testing -- Test Framework
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __add_trap_callback
#    __find_wrapper_function
#    add_trap_callback
#    augment_testmap
#    compute_reduced_pulse_index
#    compute_pulse_index
#    demolish
#    detail
#    get_test_suites
#    get_test_suite_files
#    loop_over_testfiles
#    run
#    schedule_for_demolition
#    setup_test_suite
#
###############################################################################

. "${SLCF_SHELL_TOP}/utilities/common/program_utilities.sh"
. "${__HARNESS_TOPLEVEL}/utilities/test/test_framework.sh"
. "${__HARNESS_TOPLEVEL}/utilities/inputs/.basic_parser_functions.sh"

. "${SLCF_SHELL_TOP}/lib/base_setup.sh"
[ $? -ne 0 ] && return 1

__add_trap_callback()
{
  typeset known_signals

  while [ $# -gt 0 ]
  do
    typeset trapcb="$1"
    typeset sigs=$( printf "%s" "${trapcb}" | \cut -f 2- -d ':' | \tr '{' ' ' | \tr '}' ' ' | \tr ',' ' ' | \tr "'" ' ' )
    if [ -z "${sigs}" ]
    then
      shift
      sigs=$( printf "%s" "$1" | \tr '{' ' ' | \tr '}' ' ' | \tr ',' ' ' | \tr "'" ' ' )
    else
      trapcb=$( printf "%s" "${trapcb}" | cut -f 1 -d ':' )
    fi

    typeset s=
    for s in ${sigs}
    do
      eval "signal_${s}_callbacks+=\" ${trapcb}\""
      known_signals+=" ${s}"
    done
    shift
  done

  [ -n "${known_signals}" ] && known_signals=$( printf "%s\n" ${known_signals} | \sort | \uniq )
  eval "CHECK_SIGNALS=${known_signals}"
  return "${PASS}"
}

__find_wrapper_function()
{
  typeset ext=
  
  OPTIND=1
  while getoptex "e: extension:" "$@"
  do
    case "${OPTOPT}" in
    'e'|'extension'   ) ext="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${ext}" ] && return "${FAIL}"
  
  typeset known_ext=
  for known_ext in $( __extract_value 'EXTENSION_KNOWN' )
  do
    typeset defined_ext="$( get_element --data "${known_ext}" --id 1 --separator ':' )"
    if [ "${defined_ext}" == "${ext}" ]
    then
      typeset prep="$( get_element --data "${known_ext}" --id 2 --separator ':' )"
      
      typeset compiler=
      typeset linker=
      typeset executor=
      
      if [ -n "${prep}" ]
      then
        compiler="$( get_element --data "${prep}" --id 1 --separator '|' )"
        linker="$( get_element --data "${prep}" --id 2 --separator '|' )"
        executor="$( get_element --data "${prep}" --id 3 --separator '|' )"
      fi
      
      typeset wrapper="$( get_element --data "${known_ext}" --id 3 --separator ':' )"
      if [ -z "${wrapper}" ]
      then
        [ "${defined_ext}" != 'sh' ] && wrapper="${executor}_wrapper.sh"
      else
        wrapper="$( printf "%s\n" "${wrapper}" | \sed -e 's#\.sh##' ).sh"
      fi
      
      printf "${compiler}|${linker}|${executor}|${wrapper}"
      return "${PASS}"
    fi
  done
  return "${FAIL}"
}

add_trap_callback()
{
  [ $# -lt 1 ] && return

  typeset vectorize=
  typeset traphnd=
  typeset sigs=
  
  OPTIND=1
  while getoptex "c: traphandler: s: signal: v: vectorize:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'type'        ) traphnd="${OPTARG}";;
    's'|'signal'      ) sigs+=" ${OPTARG}";;
    'v'|'vectorize'   ) vectorize="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset known_signals

  if [ -z "${vectorize}" ]
  then
    __add_trap_callback "${traphnd}:{${sigs}}"
  else
    __add_trap_callback "${vectorize}"
  fi
  return "${PASS}"
}

augment_testmap()
{
  typeset file_extension=
  typeset mapname=
  typeset mapfile=
  
  OPTIND=1
  while getoptex "e: extension: m: map: f: mapfile:" "$@"
  do
    case "${OPTOPT}" in
    'e'|'extension'  ) file_extension="${OPTARG}";;
    'm'|'map'        ) mapname="${OPTARG}";;
    'f'|'mapfile'    ) mapfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset need_wrapper_definition="${NO}"
  
  [ $( is_empty --str "${mapname}" ) -eq "${YES}" ] && [ $( is_empty --str "${mapfile}" ) -eq "${YES}" ] && return "${FAIL}"
  
  ###
  ### This is how we can allow for easy switching from memory versus file access
  ###
  typeset hopts=
  typeset rhook=
  typeset whook=
  if [ -n "${mapname}" ]
  then
    hopts=" --map ${mapname}"
    rhook='hget'
    whook='hupdate'
  else
    hopts=" --filename ${mapfile}"
    rhook='haccess_entry_via_file'
    whook='hadd_entry_via_file'
  fi
  
  typeset has_lcldrv=$( ${rhook} ${hopts} --key 'local_driver' )
  if [ $( is_empty --str "${has_lcldrv}" ) -eq "${NO}" ]
  then
    if [ $( is_empty --str "${file_extension}" ) -eq "${YES}" ]
    then
      eval "${whook} ${hopts} --key 'local_driver' --value \"${__HARNESS_TOPLEVEL}/utilities/wrappers/standard_wrapper.sh\""
    else
      need_wrapper_definition="${YES}"
    fi
  fi
  
  typeset testmanagement="$( __find_wrapper_function --extension "${testext}" --map "${mapname}" )"
  [ -z "${testmanagement}" ] && testmanagement='|||'

  typeset compiler="$( default_value --def '<NONE>' $( get_element --data "${testmanagement}" --id 1 --separator '|' ) )"
  [ "${compiler}" == '<NONE>' ] && compiler=
  typeset linker="$( default_value --def '<NONE>' $( get_element --data "${testmanagement}" --id 2 --separator '|' ) )"
  [ "${linker}" == '<NONE>' ] && linker=
  typeset executable="$( default_value --def '<NONE>' $( get_element --data "${testmanagement}" --id 3 --separator '|' ) )"
  [ "${executable}" == '<NONE>' ] && executable=
  
  typeset has_compiler=$( ${rhook} ${hopts} --key 'compiler' )
  typeset has_linker=$( ${rhook} ${hopts} --key 'linker' )
  typeset has_executable=$( ${rhook} ${hopts} --key 'executable' )
  
  [ $( is_empty --str "${has_compiler}" ) -eq "${YES}" ] && [ -n "${compiler}" ] && eval "${whook} ${hopts} --key 'compiler' --value '${compiler}'"
  [ $( is_empty --str "${has_linker}" ) -eq "${YES}" ] && [ -n "${linker}" ] && eval "${whook} ${hopts} --key 'linker' --value '${linker}'"
  [ $( is_empty --str "${has_executable}" ) -eq "${YES}" ] && [ -n "${executable}" ] && eval "${whook} ${hopts} --key 'executable' --value '${executable}'"

  typeset wrapper="$( default_value --def '<NONE>' $( get_element --data "${testmanagement}" --id 4 --separator '|' ) )"
  [ "${wrapper}" == '<NONE>' ] && wrapper=
  [ "${need_wrapper_definition}" -eq "${YES}" ] && [ -n "${wrapper}" ] && eval "${whook} ${hopts} --key 'local_driver' --value \"${__HARNESS_TOPLEVEL}/utilities/wrappers/${wrapper}\""
  
  return "${PASS}"
}

compute_reduced_pulse_index()
{
  typeset passcnt=
  typeset failcnt=
  typeset skipcnt=
  typeset scale=3
  typeset format='%.1f'

  OPTIND=1
  while getoptex "p: pass: f: fail: s: skip: scale: format:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'pass'   ) passcnt="${OPTARG}";;
    'f'|'fail'   ) failcnt="${OPTARG}";;
    's'|'skip'   ) skipcnt="${OPTARG}";;
        'scale'  ) scale="${OPTARG}";;
        'format' ) format="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_numeric_data --data "${scale}" ) -eq "${NO}" ] && scale=3
  scale=$( __range_limit "${scale}" 0 3 )
  
  if [ -z "${passcnt}" ]
  then
    passcnt=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_PASS' )
    [ -z "${passnct}" ] && passcnt=0
  fi
  if [ -z "${failcnt}" ]
  then
    failcnt=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_FAIL' )
    [ -z "${failcnt}" ] && failcnt=0
  fi
  if [ -z "${skipcnt}" ]
  then
    skipcnt=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_SKIP' )
    [ -z "${skipcnt}" ] && skipcnt=0
  fi

  if [ "${passcnt}" -eq 0 ] && [ "${failcnt}" -eq 0 ]
  then
    printf "%s\n" '0.0'
  else
    typeset total=$(( passcnt + failcnt ))
    typeset pulse=$( printf "%s\n" "scale=${scale}; ${passcnt}/${total}*100" | \bc )
    printf "${format}\n" "${pulse}"
  fi
  return "${PASS}"
}

compute_pulse_index()
{
  typeset passcnt=
  typeset failcnt=
  typeset skipcnt=
  typeset scale=3
  typeset format='%.1f'
  
  OPTIND=1
  while getoptex "p: pass: f: fail: s: skip: scale: format:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'pass'   ) passcnt="${OPTARG}";;
    'f'|'fail'   ) failcnt="${OPTARG}";;
    's'|'skip'   ) skipcnt="${OPTARG}";;
        'scale'  ) scale="${OPTARG}";;
        'format' ) format="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_numeric_data --data "${scale}" ) -eq "${NO}" ] && scale=3
  scale=$( __range_limit "${scale}" 0 3 )
  
  if [ -z "${passcnt}" ]
  then
    passcnt=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_PASS' )
    [ -z "${passnct}" ] && passcnt=0
  fi
  if [ -z "${failcnt}" ]
  then
    failcnt=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_FAIL' )
    [ -z "${failcnt}" ] && failcnt=0
  fi
  if [ -z "${skipcnt}" ]
  then
    skipcnt=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_SKIP' )
    [ -z "${skipcnt}" ] && skipcnt=0
  fi

  if [ "${passcnt}" -eq 0 ] && [ "${failcnt}" -eq 0 ] && [ "${skipcnt}" -eq 0 ]
  then
    printf "%s\n" '0.0'
  else
    typeset total=$(( passcnt + failcnt + skipcnt ))
    typeset pulse=$( printf "%s\n" "scale=${scale}; ${passcnt}/${total}*100" | \bc )
    printf "${format}\n" "${pulse}"
  fi
  return "${PASS}"
}

demolish()
{
  [ -z "$( __extract_value 'DEMOLITION_ELEMENTS' )" ] || [ ! -f "$( __extract_value 'DEMOLITION_ELEMENTS' )" ] && return "${PASS}"

  printf "\n$( __extract_value 'PREFIX_CLEANUP' ) %s\n" "Attempting to demolish files and directories..."

  \cat "$( __extract_value 'DEMOLITION_ELEMENTS' )" | \sort | \uniq > "$( __extract_value 'DEMOLITION_ELEMENTS' )".srt
  \mv -f "$( __extract_value 'DEMOLITION_ELEMENTS' )".srt "$( __extract_value 'DEMOLITION_ELEMENTS' )"

  typeset demo_items=$( \cat "$( __extract_value 'DEMOLITION_ELEMENTS' )" | \tr '\n' ' ' )
  typeset dl=
  for dl in ${demo_items}
  do
    printf "$( __extract_value 'PREFIX_CLEANUP' )   %s\n" "<${dl}>"
    if [ -f "${dl}" ]
    then
      [ "$( __check_for --key 'DETAIL' --success )" -eq "${YES}" ] && printf "$( __extract_value 'PREFIX_CLEANUP' ) %s\n" "Removing file : ${dl}"
      \rm -f "${dl}"
      continue
    fi
    
    if [ -d "${dl}" ]
    then
      [ "$( __check_for --key 'DETAIL' --success )" -eq "${YES}" ] && printf "$( __extract_value 'PREFIX_CLEANUP' ) %s\n" "Removing directory : ${dl}"
      \rm -rf "${dl}"
      continue
    fi
  done

  [ -n "$( __extract_value 'DEMOLITION_ELEMENTS' )" ] && [ -f "$( __extract_value 'DEMOLITION_ELEMENTS' )" ] && \rm -f "$( __extract_value 'DEMOLITION_ELEMENTS' )"
  printf "\n"
  return "${PASS}"
}

detail()
{
  typeset use_multi_line="${NO}"

  OPTIND=1
  while getoptex "m multi multiline" "$@"
  do
    case "${OPTOPT}" in
    'm'|'multi'|'multiline'   ) use_multi_line="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( __check_for --key 'DETAIL' --success )" -eq "${YES}" ]
  then
    if [ "$( __check_for --key 'TEST_IN_PROGRESS' --success )" -eq "${YES}" ]
    then
      if [ "${use_multi_line}" -eq "${NO}" ]
      then
        printf "[DETAIL   ]\t %s\n" "$@"
      else
        printf "%s\t %s\n" "$( __extract_value 'PREFIX_DETAIL' )" $@
      fi
    else
      if [ "${use_multi_line}" -eq "${NO}" ]
      then
        printf "[DETAIL   ] %s\n" "$@"
      else
        printf "%s %s\n" "$( __extract_value 'PREFIX_DETAIL' )" $@
      fi
    fi
  fi
  return "${PASS}"
}

get_test_suites()
{
  typeset suites=
  typeset mydir=$( \pwd -L )

  OPTIND=1
  while getoptex "p: path:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path'   ) mydir="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -n "${suites}" ] && [ -d "${suites}" ] && suites=$( \find . -type d \( ! -iname ".*" \) | \sed -e 's#^\./##' -e 's#${mydir}##' )

  typeset tdep=
  for tdep in $( __extract_value 'TEST_DIR_EXCLUDE_PATTERNS' )
  do
    suites=$( printf "%s\n" "${suites}" | \grep -v "${tdep}" )
  done

  [ "$( __check_for --key 'SORT' --success )" -eq "${YES}" ] && suites=$( printf "%s\n" "${suites}" | \sort | \uniq )
  if [ "$( __check_for --key 'RANDOM' --success )" -eq "${YES}" ]
  then
    suites=$( printf "%s\n" ${suites} | \sort | \uniq )
    suites=$( printf "%s\n" ${suites} | \awk 'BEGIN{srand()}{print rand(),$0}' | \sort -n | \cut -d ' ' -f2- )
  fi

  [ -z "${suites}" ] && return "${PASS}"

  printf "%s " ${suites}
  return "${PASS}"
}

get_test_suite_files()
{
  typeset files=
  typeset path="$( __extract_value 'CURRENT_TEST_LOCATION' )"
  typeset driver=
  
  OPTIND=1
  while getoptex "p: path: d. driver." "$@"
  do
    case "${OPTOPT}" in
    'p'|'path'   ) path="${OPTARG}";;
    'd'|'driver' ) driver="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -n "${path}" ] && [ -d "${path}" ]
  then
    typeset extr=
    for extr in $( __extract_value 'EXTENSION_KNOWN' )
    do
      typeset extension="$( get_element --data "${extr}" --id 1 --separator ':' )"
      files+=" $( \find "${path}" -maxdepth 1 -name "*.${extension}" | \sed -e "s#${path}\/##g" )"
      files=$( printf "%s\n" ${files} )
    done
  fi
  
  typeset tfep=
  for tfep in $( __extract_value 'TEST_FILE_EXCLUDE_PATTERNS' )
  do
    files=$( printf "%s\n" "${files}" | \grep -v "${tfep}" )
  done

  [ -n "${driver}" ] && files=$( printf "%s\n" "${files}" | \grep -v "${driver}" )
  
  [ "$( __check_for --key 'SORT' --success )" -eq "${YES}" ] && files=$( printf "%s\n" "${files}" | \sort | \uniq )
  if [ "$( __check_for --key 'RANDOM' --success )" -eq "${YES}" ]
  then
    files=$( printf "%s\n" "${files}" | \sort | \uniq )
    files=$( printf "%s\n" "${files}" | \awk 'BEGIN{srand()}{print rand(),$0}' | \sort -n | \cut -d ' ' -f2- )
  fi

  [ -z "${files}" ] && return "${PASS}"

  printf "%s " ${files}
  return "${PASS}"
}

loop_over_testfiles()
{
  typeset RC="${PASS}"
  typeset suite=

  OPTIND=1
  while getoptex "s: suite:" "$@"
  do
    case "${OPTOPT}" in
    's'|'suite' ) suite="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset ts="$( __extract_value 'TEST_SUITES' )"

  [ ! -d "${ts}/${suite}" ] && return "${FAIL}"
  [ ! -f "${ts}/${suite}_class.map" ] && return "${FAIL}"
  
  typeset suite_class_mapfile="${ts}/${suite}_class.map"

  hread_map --filename "${suite_class_mapfile}"
  typeset testsuitemap="$( hget_mapname --filename "${ts}/${suite}_class.map" )"

  typeset testglbdriver="$( hget --map "${testsuitemap}" --key 'global_driver'  )"
  testglbdriver=$( printf "%s\n" "${testglbdriver}" | \sed -e "s#$( __extract_value 'SPACE_MARKER' )# #g" )
  #typeset testglbdriver="$( haccess_entry_via_file --filename "${suite_class_mapfile}" --key 'global_driver'  )"
  
  ###
  ### Capability of running a command before the suite is started... [ TBD in input parsing ]
  ###
  typeset testglbcmd="$( hget --map "${testsuitemap}" --key 'global_cmd' )"
  testglbcmd=$( printf "%s\n" "${testglbcmd}" | \sed -e "s#$( __extract_value 'SPACE_MARKER' )# #g" )
  #typeset testglbcmd="$( haccess_entry_via_file --filename "${suite_class_mapfile}" --key 'global_cmd' )"

  [ -n "${testglbcmd}" ] && ${testglbcmd}
  
  typeset glbdriver_args=
  if [ $( __get_word_count "${testglbdriver}" ) -gt 1 ]
  then
    glbdriver_args=$( printf "%s\n" "${testglbdriver}" | \cut -f 2- -d ' ' )
    testglbdriver=$( printf "%s\n" "${testglbdriver}" | \cut -f 1 -d ' ' )
  fi

  ###
  ### Allows for setup of library components to properly run or gives toplevel inclusion
  ###   control to user for global sourcing
  ###
  if [ -n "${testglbdriver}" ] && [ -f "${testglbdriver}" ]
  then
    . "${testglbdriver}" "${glbdriver_args}"
    RC=$?
  fi
  
  typeset libissue="$( __extract_value 'LIBRARY_ISSUE' 'SLCF' )"
  if [ -n "${libissue}" ] && [ "${libissue}" -ne "${NO}" ]
  then
    print_btf_detail --msg "Failure found in startup of ${suite}.  Library source file issue detected..." --prefix "$( __extract_value 'PREFIX_FAILURE' )"
    log_error "Failure found in startup of ${suite}.  Library source file issue detected..."
    __set_internal_value 'LIBRARY_ISSUE' "${NO}" 'SLCF'
    hclear --map "${testsuitemap}"
    return "${FAIL}"
  fi

  if [ "${RC}" -ne "${PASS}" ]
  then
    print_btf_detail --msg "Problem running global driver << ${testglbdriver} >> -- associated tests are skipped..." --prefix "$( __extract_value 'PREFIX_FAILURE' )"
    log_error "Problem running global driver << ${testglbdriver} >>.  Associated tests are skipped..."
    hclear --map "${testsuitemap}"
    return "${FAIL}"
  fi

  typeset test_failure=0
  typeset requested_tests="$( hget --map "${testsuitemap}" --key 'suite_tests' )"
  
  hput --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_EXPECTED' --value "$( __get_word_count "${requested_tests}" )"
  hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_TESTS_EXPECTED' --incr "$( __get_word_count "${requested_tests}" )"
  
  typeset spmrk="$( __extract_value 'SPACE_MARKER' )"
  typeset tf=
  for tf in ${requested_tests}
  do
    typeset memopts=
    
    hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_COUNTED'
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_TESTS_COUNTED'
    
    typeset mapfile="$( __extract_value 'TEST_SUITES' )/${suite}/${tf}.map"
   
    typeset test_id="$( haccess_entry_via_file --filename "${mapfile}" --key 'test_id' )"
    typeset testname_fullname="$( haccess_entry_via_file --filename "${mapfile}" --key 'full_testname' )"
    typeset testext="$( get_extension "${testname_fullname}" )"
    testname="$( remove_extension "${testname_fullname}" )"

    record_step ${HOTSPOT_FLAGS} --header "test_augment ${test_id}_ID_${testname_fullname}" --start --msg "augmentation of test map << ${testmap} >> for test : ${testname}" --overhead 'DYNAMIC'
    augment_testmap --extension "${testext}" --mapfile "${mapfile}"
    record_step ${HOTSPOT_FLAGS} --header "test_augment ${test_id}_ID_${testname_fullname}" --stop --msg "augmentation of test map << ${testmap} >> for test : ${testname}" --overhead 'DYNAMIC'
    
    typeset testlclcmd="$( haccess_entry_via_file --filename "${mapfile}" --key 'local_cmd' )"
    typeset testlcldriver="$( haccess_entry_via_file --filename "${mapfile}" --key 'local_driver' )"
    
    typeset testsetupdrv="$( haccess_entry_via_file --filename "${mapfile}" --key 'test_setupdrv' )"
    [ $( is_empty --str "${testsetupdrv}" ) -eq "${NO}" ] && [ -f "${testsetupdrv}" ] && . "${testsetupdrv}"

    typeset testresult_expected="$( haccess_entry_via_file --filename "${mapfile}" --key 'expected_result' | sed -e "s#${spmrk}# #" )"
    typeset comp_operator=$( get_element --data "${testresult_expected}" --id 1 --separator ' ' )
    typeset comp_value=$( get_element --data "${testresult_expected}" --id 2 --separator ' ' )
    
    [ "${testlcldriver}" == "${__HARNESS_TOPLEVEL}/utilities/wrappers/standard_wrapper.sh" ] && hadd_entry_via_file --filename "${mapfile}" --key 'executable' --value 'shell'
    
    typeset runtime=
    typeset tnf=0
    typeset tnp=0
    typeset tns=0
      
    __debug "${tf} ---- ${testname} -- ${testlcldriver}"
    
    hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_RUN'
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_TESTS_RUN'  ## Can this be done outside the loop???
      
    [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ] && [ $( __check_for --key 'DETAIL' --success ) -eq "${YES}" ] && print_btf_detail --msg "Starting test for method : ${testname_fullname}" --prefix "$( __extract_value 'PREFIX_DETAIL' )"
            
    memopts="$( __check_for_preexistence --key "$( __define_internal_variable 'STDOUT' )" --value "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )/${tf}.stdout" )"
    memopts+="$( __check_for_preexistence --key "$( __define_internal_variable 'STDERR' )" --value "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )/${tf}.stderr" )"
    memopts+="$( __check_for_preexistence --key "$( __define_internal_variable 'RETURN_ERROR' )" --value "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )/${tf}.error_return" )"
    [ -n "${memopts}" ] && eval "${memopts}"

    typeset pnf=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_FAIL' )
    typeset pnp=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_PASS' )
    typeset pns=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_SKIP' )

    ###
    ### Capability of running a command before the test is started... [ TBD in input parsing ]
    ###
    [ -n "${testlclcmd}" ] && ${testlclcmd}
  
    typeset test_starttime
    typeset test_endtime
    
    typeset args="$( __convert_argument_list --input "$( haccess_entry_via_file --filename "${mapfile}" --key 'executable_arguments' )" )"
    args="$( __evaluate_variable "${args}" 3 )"
    [ "${testlcldriver}" != "${__HARNESS_TOPLEVEL}/utilities/wrappers/standard_wrapper.sh" ] && print_btf_detail --msg "Using wrapper function   : ${testlcldriver}" --prefix "$( __extract_value 'PREFIX_DETAIL' )"
    
    [ "$( __extract_value 'SHOW_RUNNING_TESTNAME' )" -eq "${YES}" ] && print_btf_detail --msg "Running test method      : ${testname_fullname} ${args}" --prefix "$( __extract_value 'PREFIX_DETAIL' )"
    
    record_step ${HOTSPOT_FLAGS} --header "running ${test_id}_ID_${testname_fullname}" --start --msg "test : ${testname_fullname}"
    record_step ${HOTSPOT_FLAGS} --msg "Full command : ${testlcldriver} ${testname_fullname} ${args}"
    
    typeset already_counted="${NO}"
    __TESTNAME_ID_DEFINED="${testname_fullname}"
    __TEST_ID_DEFINED="${test_id}"
    
    ###
    ### Start a timer for each file that gets run but not every assertion within a testfile
    ###
    test_starttime="$( __today_as_seconds )"

    typeset OLD_RC="${PASS}"
    typeset NEW_RC="${PASS}"

    __set_internal_value 'TEST_IN_PROGRESS' "${YES}"
    
    if [ "$( __check_for --key 'DRYRUN' --failure )" -eq "${YES}" ]
    then
      . "${__HARNESS_TOPLEVEL}/utilities/wrappers/wrapper_common.sh"
      . "${testlcldriver}" "${mapfile}"
      OLD_RC=$?
      
      test_endtime="$( __today_as_seconds )"
      
      [ -s "$( __extract_value 'STDOUT' )" ] && [ $( __check_for --key 'DETAIL' --success ) -eq "${YES}" ] && \cat "$( __extract_value 'STDOUT' )"   ### Get output from script to show to screen
      [ -f "$( __extract_value 'RETURN_ERROR' )" ] && OLD_RC="$( \cat "$( __extract_value 'RETURN_ERROR' )" | \tail -n 1 )"  ### Allow override of RC if explicit file written
      [ -z "${OLD_RC}" ] && OLD_RC="${PASS}"
      
      ###
      ### Process the return code to see if it complies with any expectations
      ###
      if [ "$( __check_for --key 'DISALLOW_RETURN_CODE_CHECKING' --failure )" -eq "${YES}" ]
      then
        if [ -n "${testresult_expected}" ]
        then
          typeset last_aid="$( \tail -n 1 "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )" | \grep "TID:${test_id}" )"
          [ -n "${last_aid}" ] && last_aid=$( printf "%s\n" "${last_aid}" | \awk '{print $1}' | \tr '(' ' ' | \tr ')' ' ' | \cut -f 2 -d '|' | \cut -f 2 -d ':' )
          assert_comparison --comparison "${comp_operator}" --aid "$( increment "${last_aid}" )" --title "Return Code Testing" "${comp_value}" "${OLD_RC}"
          NEW_RC="$( __get_last_result )"
          OLD_RC="${NEW_RC}"  ### Resync the RC contents...
        else
          NEW_RC="${OLD_RC}"
        fi
      else
        NEW_RC="${OLD_RC}"
      fi
    else
      test_endtime="${test_starttime}"
      __record_success --expect "${PASS}" --actual "${PASS}" --title 'Dryrun Pass' --ast 'PASS' --aid 1
      printf "%d\n" "${RC}" > "$( __extract_value 'RETURN_ERROR' )"
    fi

    __set_internal_value 'TEST_IN_PROGRESS' "${NO}"
    record_step ${HOTSPOT_FLAGS} --header "running ${test_id}_ID_${testname_fullname}" --stop --msg "test : ${testname_fullname}"
    
    ###
    ### Compute the runtime for the test
    ###
    runtime=$( calculate_run_time --start "${test_starttime}" --end "${test_endtime}" --decimals 0 )
    #append_output --data "Calculated runtime for test : ${testname_fullname} = ${test_starttime} - ${test_endtime} --> ${runtime}" --channel "$( __define_internal_variable 'INFO' )" --raw

    ###
    ### Output information regarding the runtime calculation and the expected return code
    ###
    [ -s "$( __extract_value 'STDERR' )" ] && record_step ${HOTSPOT_FLAGS} --msg "$( \cat "$( __extract_value 'STDERR' )" )"
    record_step ${HOTSPOT_FLAGS} --header 'return_code' --msg "Expected Return Code (${comp_operator} ${comp_value}) :: Return code = ${OLD_RC}"
    if [ "${NEW_RC}" -eq "${PASS}" ]
    then
      record_step "PASS"
    else
      record_step "FAIL"
    fi
    
    ###
    ### Update the individual test information regarding pass/fail, runtime for this test, etc...
    ###
    record_step ${HOTSPOT_FLAGS} --header "update testdata ${test_id}_ID_${testname_fullname}" --start --msg "testmap << ${testmap} >> updating for test < ${testname_fullname} >" --overhead 'DYNAMIC'
    hadd_entry_via_file --filename "${mapfile}" --key 'result' --value "${NEW_RC}"
    hadd_entry_via_file --filename "${mapfile}" --key 'start_time' --value "${test_starttime}"
    hadd_entry_via_file --filename "${mapfile}" --key 'end_time' --value "${test_endtime}"
    hadd_entry_via_file --filename "${mapfile}" --key 'runtime' --value "${runtime}"
    hadd_entry_via_file --filename "${mapfile}" --key 'stdout_file' --value "$( __extract_value 'STDOUT' )"
    hadd_entry_via_file --filename "${mapfile}" --key 'stderr_file' --value "$( __extract_value 'STDERR' )"
    hadd_entry_via_file --filename "${mapfile}" --key 'was_run' --value "${YES}"
    hadd_entry_via_file --filename "${mapfile}" --key 'exe_cmd' --value "${testlcldriver}"
    record_step ${HOTSPOT_FLAGS} --header "update testdata ${test_id}_ID_${testname_fullname}" --stop --msg "testmap << ${testmap} >> updating for test < ${testname_fullname} >" --overhead 'DYNAMIC'
        
    if [ -n "${runtime}" ]
    then
      hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_RUNTIME' --incr "${runtime}"
    else
      runtime=0
    fi

    ###
    ### Process the results for pass/failures/skips...
    ###
    record_step ${HOTSPOT_FLAGS} --header "process testdata ${test_id}_ID_${testname_fullname}" --start --msg "processing of test results for test < ${testname_fullname} > : $( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )"
    [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ] && [ "$( __check_for --key 'DETAIL' --success )" -eq "${YES}" ] && print_btf_detail --msg "Ending test for method   : ${testname_fullname}" --prefix "$( __extract_value 'PREFIX_DETAIL' )"

    typeset newfailures="$( default_value --def 0 "$( \grep 'FAILED' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )" | \sed -n '$=' )" )"
    typeset newpasses="$( default_value --def 0 "$( \grep 'PASSED' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )" | \sed -n '$=' )" )"
    typeset newskips="$( default_value --def 0 "$( \grep 'SKIPPED' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )" | \sed -n '$=' )" )"
    
    if [ "${newfailures}" -gt 0 ]
    then
      hput --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_FAIL' --value "${newfailures}"
      if [ "${newfailures}" -ne "${pnf}" ]
      then
        tnf=$(( newfailures - pnf ))
        print_btf_detail --msg "        ''${testname}'' test has assertion failures (${tnf})" --prefix "$( __extract_value 'PREFIX_FAILURE' )"
        NEW_RC="${FAIL}"
      fi
    fi
    
    if [ "${newpasses}" -gt 0 ]
    then
      hput --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_PASS' --value ${newpasses}
      tnp=$(( newpasses - pnp ))
    fi
    
    if [ "${newskips}" -gt 0 ]
    then
      hput --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_SKIP' --value ${newskips}
      tns=$(( newskips - pns ))
    fi
    
    hput --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS' --value $(( newskips + newpasses + newfailures ))

    record_step ${HOTSPOT_FLAGS} --header "process testdata ${test_id}_ID_${testname_fullname}" --stop --msg "processing of test results for test < ${testname_fullname} >" --overhead 'DYNAMIC'
    
    ###
    ### Complete the recording of information so that each test keeps an accurate record
    ###
    record_step ${HOTSPOT_FLAGS} --header "finalize testdata ${test_id}_ID_${testname_fullname}" --start --msg "finalization of testmap << ${testmap} >>" --overhead 'DYNAMIC'
    hadd_entry_via_file --filename "${mapfile}" --key 'num_assertions_pass' --value "${tnp}"
    hadd_entry_via_file --filename "${mapfile}" --key 'num_assertions_fail' --value "${tnf}"
    hadd_entry_via_file --filename "${mapfile}" --key 'num_assertions_skip' --value "${tns}"
    record_step ${HOTSPOT_FLAGS} --header "finalize testdata ${test_id}_ID_${testname_fullname}" --stop --msg "finalization of testmap << ${testmap} >>" --overhead 'DYNAMIC'

    if [ "${already_counted}" -eq "${NO}" ]
    then
      hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_FAIL' --incr ${tnf}
      hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_PASS' --incr ${tnp}
      hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_SKIP' --incr ${tns}
    fi
    
    ###
    ### Write the output from the results of testing this file from specified subsystem
    ###
    typeset known_output_options="--testname \"${testname_fullname}\" --runtime \"${runtime}\" --test-id \"${test_id}\" --data \"${tnp}:${tnf}:${tns}\""

    if [ "${OLD_RC}" -ne "${PASS}" ]
    then
      #echo "$OLD_RC -- ${NEW_RC} -- ${testname_fullname}"
      hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_ERROR_EXECUTION'
    else
      [ "${tnf}" -eq 0 ] && [ "${tnp}" -eq 0 ] && [ "${tns}" -eq 0 ] && hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_ERROR_EXECUTION'
    fi
    
    ###
    ### Allow output formatters to process results
    ###
    record_step ${HOTSPOT_FLAGS} --header "record ${test_id}_ID_${testname_fullname}" --start --msg "output for << ${testname_fullname} >>" --overhead 'DYNAMIC'
    typeset outfmt=
    for outfmt in $( __extract_value 'OUTPUT_FORMATS' )
    do
      ###
      ### Manage results by allowing the output formatter(s) to work
      ###
      if [ "${OLD_RC}" -ne "${PASS}" ]
      then
        eval "record_${outfmt}_testfile_result_4_suite --type 'error' ${known_output_options}"
      else
        typeset evalcmd="record_${outfmt}_testfile_result_4_suite ${known_output_options} "
        if [ "${tnf}" -eq 0 ] && [ "${tnp}" -eq 0 ] && [ "${tns}" -eq 0 ]
        then
          eval "${evalcmd} --type 'error' --cause \"No assertions exercised\""
          continue
        fi
        if [ "${tns}" -ge 1 ]
        then
          eval "${evalcmd} --type 'skip'"
        else
          [ "${tnf}" -eq 0 ] && [ "${tnp}" -ge 1 ] && eval "${evalcmd} --type 'pass'"
          [ "${tnf}" -ge 1 ] && eval "${evalcmd} --type 'fail' --cause \"One or more failed assertions\""
        fi
      fi
      
      ###
      ### Manage the output and error files as well by allowing the output formatter(s) to work
      ###
      if [ $( can_record_stdout_stderr_${outfmt} ) -eq "${YES}" ]
      then
        typeset stdout="$( __extract_value 'STDOUT' )"
        [ -n "${stdout}" ] && [ -f "${stdout}" ] && eval "record_${outfmt}_testfile_output_4_suite \"${stdout}\""
        
        typeset stderr="$( __extract_value 'STDERR' )"
        [ -n "${stderr}" ] && [ -f "${stderr}" ] && eval "record_${outfmt}_testfile_error_4_suite \"${stderr}\""
      fi
    done
    ###
    ### Reset all test associated counters in the assertions.sh file to ensure each test
    ###   has proper and unique information
    ###
    __reset_assertion_counters
    
    #append_output --data "OVERALL MAP = $( hprint --map "$( __extract_value 'OVERALL_MAP' )" )" --channel "$( __define_internal_variable 'INFO' )" --raw
    #append_output --data "SUBSYSTEM MAP = $( hprint --map "$( __extract_value 'SUBSYSTEM_MAP' )" )" --channel "$( __define_internal_variable 'INFO' )" --raw

    record_step ${HOTSPOT_FLAGS} --header "record ${test_id}_ID_${testname_fullname}" --stop --msg "output for << ${testname_fullname} >>" --overhead 'DYNAMIC'
    
    hclear --map "${testmap}"
    eval "unset '$( __define_internal_variable 'STDOUT' )'"
    eval "unset '$( __define_internal_variable 'STDERR' )'"
    eval "unset '$( __define_internal_variable 'RETURN_ERROR' )'"
    
    record_step ${HOTSPOT_FLAGS} --header "complete_test ${test_id}_ID_${testname_fullname}" --start --overhead 'DYNAMIC'
    ###
    ### Keep track of overall test failures as well as expected return code test failures...
    ###
    test_failure=$(( test_failure + tnf ))
    
    ###
    ### Allow for fail on error to occur with test-stop-on-fail option
    ###
    if [ "$( __check_for --key 'TEST_STOP_ON_FAIL' --success )" -eq "${YES}" ] && [ "${test_failure}" -gt 0 ]
    then
      log_error "Error detection specified at test execution level.  Test << ${testname_fullname} >> encountered a failure ( RC = ${OLD_RC}|${NEW_RC} ).  Stopping!"
      print_btf_detail --msg "Error detection specified at test execution level.  Test << ${testname_fullname} >> encountered a failure ( RC = ${OLD_RC}|${NEW_RC} ).  Stopping!" --prefix "$( __extract_value 'PREFIX_ERROR' )"
      hclear --map "${testsuitemap}"
      record_step ${HOTSPOT_FLAGS} --header "complete_test ${test_id}_ID_${testname_fullname}" --stop --overhead 'DYNAMIC'

      return "${NEW_RC}"
    fi
    record_step ${HOTSPOT_FLAGS} --header "complete_test ${test_id}_ID_${testname_fullname}" --stop --overhead 'DYNAMIC'
  done
  
  hclear --map "${testsuitemap}"
  if [ "${test_failure}" -eq 0 ]
  then
    return "${PASS}"
  else
    return "${FAIL}"
  fi
}

run()
{
  typeset suite=
  
  OPTIND=1
  while getoptex "s: suite:" "$@"
  do
    case "${OPTOPT}" in
    's'|'suite'  ) suite="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${suite}" ] && return "${FAIL}"
  
  #typeset sectiontype=$( printf "%s" "${suite}" | \tr "[:lower:]" "[:upper:]" )
  typeset sectiontype=$( to_upper "${suite}" )

  ###
  ### Need to load the assertions library for access to write functionality for recording...
  ###
  . "${SLCF_SHELL_TOP}/lib/assertions.sh"
  
  ###
  ### Register the subsystem and prepare location in temporary FS for output
  ###
  register_subsystem --section "${sectiontype}"

  ###
  ### Compare all known tests found and those requested to match only
  ###   those request and found in the proper location
  ###
  loop_over_testfiles --suite "${suite}"
  typeset RC=$?

  ###
  ### Complete the registration of the subsystem
  ###
  complete_registration

  if [ -n "${RECURSIVE}" ] && [ "${RECURSIVE}" -eq "${YES}" ]
  then
    typeset recursive_files=$( \find "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )" -maxdepth 4 -type f -name "recursive_run_results*.txt" )
    typeset subsysmap=$"( __extract_value 'SUBSYSTEM_MAP' )" 
    typeset rf=
    for rf in ${recursive_files}
    do
      ###
      ### Check to see if this file has already be processed...
      ###
      \grep -q "Processed:${YES}" "${rf}"
      [ $? -eq "${PASS}" ] && continue
    
      ###
      ### Allow for parsing summary file of recursive call.
      ###
      typeset subpasses=$( \grep "^Passes:" "${rf}" | \cut -f 2 -d ':' )
      typeset subfails=$( \grep "^Fails:" "${rf}" | \cut -f 2 -d ':' )
      typeset subskips=$( \grep "^Skips:" "${rf}" | \cut -f 2 -d ':' )
      typeset subfiles=$( \grep "^Files:" "${rf}" | \cut -f 2 -d ':' )
      typeset inputfiles=$( \grep "^DataFile:" "${rf}" | \cut -f 2- -d ':' | \tr '\n' ' ' )
    
      typeset inpfl=
      for inpfl in ${inputfiles}
      do
        printf "%s\n" "#### ---- FILE ARGUMENT : < ${inpfl} >" >> "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )"
        \cat "${inpfl}" >> "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )"
      done
    
      hinc --map "${subsysmap}" --key 'SUBSYSTEM_ASSERTIONS_PASS' --incr "${subpasses}"
      hinc --map "${subsysmap}" --key 'SUBSYSTEM_ASSERTIONS_FAIL' --incr "${subfails}"
      hinc --map "${subsysmap}" --key 'SUBSYSTEM_ASSERTIONS_SKIP' --incr "${subskips}"
      hinc --map "${subsysmap}" --key 'SUBSYSTEM_TESTS_RUN' --incr "${subfiles}"
      hinc --map "${subsysmap}" --key 'SUBSYSTEM_TESTS_COUNTED' --incr "${subfiles}"

      typeset subtotal=$(( subpasses + subfails + subskips ))
      typeset subtotal_with_checking="${subtotal}"
      if [ "$( __check_for --key 'DISALLOW_RETURN_CODE_CHECKING' --failure )" -eq "${YES}" ]
      then
        typeset subRC=$( \grep "^ReturnCode:" "${rf}" | \cut -f 2 -d ':' )
        [ "${subRC}" -ne "${PASS}" ] && hinc --map "${subsysmap}" --key 'SUBSYSTEM_ASSERTIONS_FAIL'
        [ "${subRC}" -eq "${PASS}" ] && hinc --map "${subsysmap}" --key 'SUBSYSTEM_ASSERTIONS_PASS'
        subtotal_with_checking=$( increment "${subtotal_with_checking}" )
      fi

      hinc --map "${subsysmap}" --key 'SUBSYSTEM_ASSERTIONS' --incr "${subtotal_with_checking}"
   
      ###
      ### Make sure once this file is processed, we don't process it again...
      ###
      printf "%s\n" "Processed:${YES}" >> "${rf}"
    done
  fi
  
  ###
  ### TODO: Need to make __show_summary use the subsystem map rather than processing the file for data
  ###
  [ "$( __check_for --key 'DELAY_SUMMARY' --failure )" -eq "${YES}" ] && __show_summary --section "${sectiontype}"
  return "${RC}"
}

schedule_for_demolition()
{
  [ $# -lt 1 ] && return "${PASS}"
  printf "%s\n" $@ >> "$( __extract_value 'DEMOLITION_ELEMENTS' )"
  return "${PASS}"
}

setup_test_suite()
{
  typeset toplevel="$1"
  typeset suite="$2.sh"

  toplevel=$( printf "%s\n" "${toplevel}" | \sed -e "s#'##g" )
  if [ -z "${toplevel}" ] || [ -z "${suite}" ] || [ ! -f "${toplevel}/${suite}" ]
  then
    printf "%s\n" "Unable to setup test suite"
    exit "${FAIL}"
  else
    . "${toplevel}/${suite}"
  fi
  return "${PASS}"
}
