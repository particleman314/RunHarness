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
#    __find_caller
#    __find_matching_test_cases
#    __init
#    __reset
#    __reset_overall_map
#    __reset_subsystem_map
#    __show_pass
#    __show_fail
#    __show_skip
#    __show_pulse_index
#    __show_stats
#    __show_summary
#    clear_force_fail
#    clear_force_skip
#    complete_registration
#    force_fail
#    force_skip
#    increment_registered_tests
#    register_subsystem
#    snap_directory_listing
#
###############################################################################

[ -z "${PASS}" ] && . "${SLCF_SHELL_FUNCTIONDIR}/hashmaps.sh"

. "${SLCF_SHELL_TOP}/utilities/common/program_utilities.sh"

if [ -z "$( __extract_value 'UNKNOWN_SUBSYSTEM_ID' )" ]
then
  __SKIP=2
  __UNDEFINED=3
  __POSITIVE='positive'
  __NEGATIVE='negative'
  
  SLCF_UNKNOWN_SUBSYSTEM_ID=0
  SLCF_UNKNOWN_ASSERTION_ID=0
fi

__find_caller()
{
  typeset count=1
  typeset caller=

  typeset skip_prefixes='assert __show_ source'
  typeset found="${NO}"

  while [ -z "${caller}" ] && [ "${count}" -lt 10 ]
  do
    found=0
    # This only works for Bash and will likely need to be managed different!
    typeset possible_caller="${FUNCNAME[${count}]}"
    typeset sp=
    for sp in ${skip_prefixes}
    do
      typeset len=${#sp}
      [ -z "${len}" ] || [ ${len} -lt 1 ] && continue

      if [ "${possible_caller:0:${len}}" == "${sp}" ]
      then
        found="${YES}"
        break
      fi
    done
    if [ "${found}" -eq "${NO}" ]
    then
      caller="${possible_caller}"
      break
    fi
    count=$(( count + 1 ))
  done
  printf "%s" "${caller}"
}

__find_matching_test_cases()
{
  typeset fn=
  typeset matchfld=

  OPTIND=1
  while getoptex "f: filename: m: match:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'match'     ) match="${OPTARG}";;
    'f'|'filename'  ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${match}" ] && return
  [ -z "${filename}" ] || [ ! -f "${filename}" ] && return
  
  \grep "${match}" "${filename}" | \cut -f 2 -d ':' | \cut -f 1 -d ')'
  return "${PASS}"
}

__init()
{
  if [ -z "${initialized}" ] || [ "${initialized}" -eq "${NO}" ]
  then
    initialized="${YES}"

    . "${SLCF_SHELL_TOP}/lib/timemgt.sh"
    . "${SLCF_SHELL_TOP}/lib/hashmaps.sh"
    
    typeset subsysid=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'SUBSYSTEM_ID' )
    if [ -n "${subsysid}" ] && [ "${subsysid}" -ge 1 ]
    then
      __reset_overall_map
      __reset_subsystem_map
    fi
       
    [ -z "$( __extract_value 'REGISTERED_SUBSYSTEM' )" ] && __set_internal_value 'REGISTERED_SUBSYSTEM' "${NO}"
    
    __set_internal_value 'RUNTIME_UNIT' 'seconds'
    
    __reset
    
    __set_internal_value 'LAST_TEST_RESULT' "${__UNDEFINED}"
    
    . "${__HARNESS_TOPLEVEL}/utilities/workflow/workflow.sh"
  fi
}

__reset()
{
  if [ -n "${initialized}" ] && [ "${initialized}" -eq "${YES}" ]
  then
    __reset_subsystem_map

    __set_internal_value 'REGISTERED_SUBSYSTEM' "${NO}"    
  fi
  
  clear_force_fail
  clear_force_skip
  
  __set_internal_value 'TEST_PREVIOUS_SUBSYSTEM' "${SLCF_TEST_SUBSYSTEM}"
  __set_internal_value 'TEST_SUBSYSTEM'
}

__reset_overall_map()
{
  typeset mapname="$( __extract_value 'OVERALL_MAP' )"
  
  hassign --map "${mapname}" --key 'TOTAL_TESTS_RUN'             --value 0     # Total number of test files run
  hassign --map "${mapname}" --key 'TOTAL_TESTS_COUNTED'         --value 0     # Total number of test files which may have been run
  hassign --map "${mapname}" --key 'TOTAL_TESTS_EXPECTED'        --value 0
  hassign --map "${mapname}" --key 'TOTAL_TESTS_ERROR_EXECUTION' --value 0     # Total number of test files which failed to execute
  hassign --map "${mapname}" --key 'TOTAL_ASSERTIONS_PASS'       --value 0
  hassign --map "${mapname}" --key 'TOTAL_ASSERTIONS_FAIL'       --value 0
  hassign --map "${mapname}" --key 'TOTAL_ASSERTIONS_SKIP'       --value 0
  hassign --map "${mapname}" --key 'TOTAL_ASSERTIONS_EXPECTED'   --value 0
  hassign --map "${mapname}" --key 'TOTAL_ASSERTIONS'            --value 0
  hassign --map "${mapname}" --key 'TOTAL_TIME'                  --value 0     # Time from when start_time is set to when end_tim is declared
  hassign --map "${mapname}" --key 'TOTAL_SUITETIME'             --value 0     # Time from when start_time is set to when end_tim is declared
  hassign --map "${mapname}" --key 'TOTAL_RUNTIME'               --value 0     # Time from starting to run tests to completing all tests
  hassign --map "${mapname}" --key 'SUBSYSTEM_ID'                --value 0
}

__reset_subsystem_map()
{
  typeset mapname="$( __extract_value 'SUBSYSTEM_MAP' )"

  hassign --map "${mapname}" --key 'SUBSYSTEM_TESTS_RUN'             --value 0   # Total number of test files run in suite/stage
  hassign --map "${mapname}" --key 'SUBSYSTEM_TESTS_COUNTED'         --value 0   # Total number of test files which may have been run in suite/stage
  hassign --map "${mapname}" --key 'SUBSYSTEM_TESTS_EXPECTED'        --value 0
  hassign --map "${mapname}" --key 'SUBSYSTEM_TESTS_ERROR_EXECUTION' --value 0
  hassign --map "${mapname}" --key 'SUBSYSTEM_ASSERTIONS_PASS'       --value 0   # Number of assertions which pass in suite/stage
  hassign --map "${mapname}" --key 'SUBSYSTEM_ASSERTIONS_FAIL'       --value 0   # Number of assertions which fail in suite/stage
  hassign --map "${mapname}" --key 'SUBSYSTEM_ASSERTIONS_SKIP'       --value 0   # Number of assertions which are skipped in suite/stage
  hassign --map "${mapname}" --key 'SUBSYSTEM_ASSERTIONS_EXPECTED'   --value 0   # If planned N assertions, keep tally in suite/stage
  hassign --map "${mapname}" --key 'SUBSYSTEM_ASSERTIONS'            --value 0   # Total number of assertions in suite/stage
  hassign --map "${mapname}" --key 'SUBSYSTEM_TIME'                  --value 0
  hassign --map "${mapname}" --key 'SUBSYSTEM_RUNTIME'               --value 0
  hassign --map "${mapname}" --key 'SUBSYSTEM_START_TIME'            --value 0
  hassign --map "${mapname}" --key 'SUBSYSTEM_END_TIME'              --value 0
  hassign --map "${mapname}" --key 'SUBSYSTEM_TRUE_NAME'             --value ''
}

__show_stats()
{
  typeset pass_rate=0.0

  typeset pass_tests=0
  typeset fail_tests=0
  typeset skip_tests=0
  typeset total_tests=0
  typeset numfiles=0
  typeset datafile=

  OPTIND=1
  while getoptex "p: pass: f: fail: s: skip: t: total: d: datafile: numfiles:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'pass'     ) pass_tests="${OPTARG:-0}";;
    'f'|'fail'     ) fail_tests="${OPTARG:-0}";;
    's'|'skip'     ) skip_tests="${OPTARG:-0}";;
    't'|'total'    ) total_tests="${OPTARG:-0}";;
    'd'|'datafile' ) datafile="${OPTARG}";;
        'numfiles' ) numfiles="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "${numfiles}" -le 0 ] && numfiles=$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_TESTS_RUN' )

  ###
  ### Compute the pass rate
  ###
  if [ "${total_tests}" -gt 0 ]
  then
    typeset non_skips=$( printf "%s\n" "${total_tests} - ${skip_tests}" | \bc )
    [ "${non_skips}" -gt 0 ] && pass_rate=$( printf "%s\n" "scale=3; ${pass_tests}/${non_skips} * 100" | \bc )
  fi

  pass_rate=$( printf "%.1f\n" "${pass_rate}" )

  typeset section_name
  [ -n "${datafile}" ] && section_name=$( \basename "${datafile}" | \sed -e 's#\.data##' )

  if [ "$( __check_for --key 'SHOW_SUMMARY' --success )" -eq "${YES}" ]
  then
    printf "\n"
    printf "$( __extract_value 'PREFIX_SUMMARY' ) %s\n" "Number Passed     : ${pass_tests}" "Number Failed     : ${fail_tests}" "Number Skipped    : ${skip_tests}" "Number Test Files : ${numfiles}" "Pass Rate         : ${pass_rate}%"
  fi

  if [ "${fail_tests}" -gt 0 ]
  then
    printf "\n\n%s\n" "Details of failures in suite..."
    [ -n "${datafile}" ] && \grep 'FAILED' "${datafile}"
    printf "\n"
  fi
}

__show_pulse_index()
{
  typeset pulse_index=0.0
  typeset reduced_pulse_index=0.0
  typeset pass_tests=0
  typeset fail_tests=0
  typeset skip_tests=0
  typeset total_tests=0

  OPTIND=1
  while getoptex "p: pass: f: fail: s: skip: t: total:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'pass'     ) pass_tests="${OPTARG:-0}";;
    'f'|'fail'     ) fail_tests="${OPTARG:-0}";;
    's'|'skip'     ) skip_tests="${OPTARG:-0}";;
    't'|'total'    ) total_tests="${OPTARG:-0}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "${total_tests}" -gt 0 ]
  then
    typeset non_skips=$( printf "%s\n" "${total_tests} - ${skip_tests}" | \bc )
    [ "${non_skips}" -gt 0 ] && pulse_index=$( printf "%s\n" "scale=3; ${pass_tests}/${non_skips} * 100" | \bc )
  fi

  pulse_index=$( printf "%.1f\n" "${pulse_index}" )

  ###
  ### Display the pulse index to the screen before we record this information
  ###   to the various output formatters
  ###
  printf "\n%s\n" "$( __extract_value 'PREFIX_RESULTS' ) Pulse Index --> ${pulse_index}% (P:${pass_tests} S:${skip_tests} F:${fail_tests})"
  printf "%s\n" "$( __extract_value 'PREFIX_RESULTS' ) Total Number of Executed Files : $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_RUN' )"
}

__show_summary()
{
  typeset total_pass=0
  typeset total_fail=0
  typeset total_skip=0
  typeset total_count=0
  typeset section=

  OPTIND=1
  while getoptex "s: section:" "$@"
  do
    case "${OPTOPT}" in
    's'|'section'  ) section="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "$( __extract_value 'TEST_SUMMARY_PATH' )" ] || [ ! -d "$( __extract_value 'TEST_SUMMARY_PATH' )" ]
  then
    typeset mapname="$( __extract_value 'OVERALL_MAP' )"
    total_pass=$( hget --map "${mapname}" --key 'TOTAL_ASSERTIONS_PASS' )
    total_fail=$( hget --map "${mapname}" --key 'TOTAL_ASSERTIONS_FAIL' )
    total_skip=$( hget --map "${mapname}" --key 'TOTAL_ASSERTIONS_SKIP' )
    total_count=$( hget --map "${mapname}" --key 'TOTAL_ASSERTIONS' )
    __show_stats --pass ${total_pass} --fail ${total_fail} --skip ${total_skip} --total ${total_count}
  else
    typeset toplvl="$( __extract_value 'TEST_RESULTS_TOPLEVEL' )"
    typeset directories
    if [ -n "${section}" ]
    then
      directories=$( ls -1d "${toplvl}"/* | \grep "${section}" )
    else
      directories=$( ls -1d "${toplvl}"/* )
    fi

    typeset basefiles=$( printf "%s\n" "${directories}" | \sed -e "s#${toplvl}/##" | \grep "^${section}" | \tr '\n' ' ' )

    typeset d=
    for d in ${basefiles}
    do
      [ -z "${d}" ] || [ ! -d "${toplvl}/${d}" ] && continue
      typeset temp_data=
      typeset f="${toplvl}/${d}/${d}.data"

      temp_data=$( __find_matching_test_cases --match 'Test PASSED' --filename "${f}" )
      typeset subsys_pass=$( __get_line_count --non-file "${temp_data}")
      total_pass=$( increment ${total_pass} ${subsys_pass} )

      temp_data=$( __find_matching_test_cases --match 'Test FAILED' --filename "${f}" )
      typeset subsys_fail=$( __get_line_count --non-file "${temp_data}" )
      total_fail=$( increment ${total_fail} ${subsys_fail} )

      temp_data=$( __find_matching_test_cases --match 'Test SKIPPED' --filename "${f}" )
      typeset subsys_skip=$( __get_line_count --non-file "${temp_data}" )
      total_skip=$( increment ${total_skip} ${subsys_skip} )

      typeset total_subsys=$(( subsys_fail + subsys_pass + subsys_skip ))
      total_count=$( increment ${total_count} ${total_subsys} )

      __show_stats --pass ${subsys_pass} --fail ${subsys_fail} --skip ${subsys_skip} --total ${total_subsys} --datafile "${f}"
    done
  fi

  __show_pulse_index --pass ${total_pass} --skip ${total_skip} --fail ${total_fail} --total ${total_count}
  printf "%s\n\n" "$( __extract_value 'PREFIX_RESULTS' ) Total Number of Assertions : ${total_count}"
}

__show_pass()
{
  typeset testname=
  typeset suppression="${NO}"
  typeset dnr="${NO}"

  OPTIND=1
  while getoptex "s: suppress: t: testname: dnr" "$@"
  do
    case "${OPTOPT}" in
    't'|'testname' ) testname="${OPTARG}";;
    's'|'suppress' ) suppression="${OPTARG:-${YES}}";;
        'dnr'      ) dnr="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${testname}" ]
  then
    testname="UNKNOWN$( __extract_value 'UNKNOWN_ASSERTION_ID' )"
    __set_internal_value 'UNKNOWN_ASSERTION_ID' $( increment $( __extract_value 'UNKNOWN_ASSERTION_ID' ) )
  fi
  
  if [ "${dnr}" -eq "${NO}" ]
  then
    hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_PASS'
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_PASS'
    
    hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS'
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS'

    if [ -n "$( __extract_value 'TEST_SUBSYSTEM' )" ]
    then
      typeset inputs=$( printf "%s " -- $@ | \tr '\n' ' ' )
      typeset AID=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS' )
      typeset TID=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_RUN' )
      
      [ "${suppression}" -eq "${NO}" ] && printf "%s\n" "(TID: ${TID}|AID: ${AID}) Test PASSED : Assertion Test passed in <${testname}> for input(s) ${inputs}" >> "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )"
    fi
  fi

  [ $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_EXPECTED' ) -gt 0 ] && hdec --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_EXPECTED'
  __set_internal_value 'LAST_TEST_RESULT' "${PASS}"
  return "${PASS}"
}

__show_fail()
{
  typeset testname=
  typeset actual=
  typeset expect=
  typeset cause=
  typeset dnr="${NO}"
  typeset suppression="${NO}"

  OPTIND=1
  while getoptex "s: suppress: t: testname: e. expect. a. actual. c. cause. dnr." "$@"
  do
    case "${OPTOPT}" in
    'c'|'cause'    ) cause="${OPTARG}";;
    'a'|'actual'   ) actual="${OPTARG}";;
    'e'|'expect'   ) expect="${OPTARG}";;
    't'|'testname' ) testname="${OPTARG}";;
        'dnr'      ) dnr="${YES}";;
    's'|'suppress' ) suppression="${OPTARG:-${YES}}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${cause}" ] && cause='Unknown cause for failure'
  if [ -z "${testname}" ]
  then
    testname="UNKNOWN$( __extract_value 'UNKNOWN_ASSERTION_ID' )"
    __set_internal_value 'UNKNOWN_ASSERTION_ID' $( increment $( __extract_value 'UNKNOWN_ASSERTION_ID' ) )
  fi

  if [ "${dnr}" -eq "${NO}" ]
  then
    hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_FAIL'
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_FAIL'
    
    hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS'
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS'

    typeset AID=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS' )
    typeset TID=$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_TESTS_RUN' )
    [ "${suppression}" -eq "${NO}" ] && printf "%s\n" "(TID: ${TID}|AID: ${AID}) Test FAILED [ ${testname} ] : Expectation = <${expect}> -- Answer = <${actual}> : Cause -- ${cause}" >> "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )"
  else
    [ "${suppression}" -eq "${NO}" ] && printf "%s\n" "Failure in ${testname} : Cause -- ${cause}"
  fi  

  [ $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_EXPECTED' ) -gt 0 ] && hdec --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_EXPECTED'
  __set_internal_value 'LAST_TEST_RESULT' "${FAIL}"
  return "${FAIL}"
}

__show_skip()
{
  typeset testname=
  typeset suppression="${NO}"

  OPTIND=1
  while getoptex "s: suppress: t: testname:" "$@"
  do
    case "${OPTOPT}" in
    't'|'testname' ) testname="${OPTARG}";;
    's'|'suppress' ) suppression="${OPTARG:-${YES}}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${testname}" ]
  then
    testname="UNKNOWN$( __extract_value 'UNKNOWN_ASSERTION_ID' )"
    __set_internal_value 'UNKNOWN_ASSERTION_ID' $( increment $( __extract_value 'UNKNOWN_ASSERTION_ID' ) )
  fi

  if [ "${dnr}" -eq "${NO}" ]
  then
    hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_SKIP'
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS_SKIP'
    
    hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS'
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS'

    if [ -n "$( __extract_value 'TEST_SUBSYSTEM' )" ]
    then
      typeset AID=$( hget --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_ASSERTIONS' )
      typeset TID=$( hget --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_TESTS_RUN' )
      [ "${suppression}" -eq "${NO}" ] && printf "%s\n" "(TID: ${TID}|AID: ${AID}) Test SKIPPED [ ${testname} ]" >> "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )"
    fi
  fi
  
  [ $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_EXPECTED' ) -gt 0 ] && hdec --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_EXPECTED'
  __set_internal_value 'LAST_TEST_RESULT' "${FAIL}"
  return "${__SKIP}"
}

clear_force_fail()
{
  FORCED_FAIL_TEST=
}

clear_force_skip()
{
  FORCED_SKIP_TEST=
}

complete_registration()
{
  #typeset subsystime=$( printf "%s\n" "scale=0; $( hget --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_END_TIME' ) - $( hget --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_START_TIME' )" | bc )
  #hinc --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_OVERALL_TIME' --incr "${subsystime}"

  #[ $( hget --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_RUNTIME' ) -eq 0 ] && hput --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_RUNTIME' --value 1
  #[ $( hget --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_OVERALL_TIME' ) -eq 0 ] && hput --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_TIME' --value 1

  #hinc --map "${SLCF_OVERALL_MAP}" --key 'TOTAL_TIME' --incr $( hget --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_TIME' )
  #hinc --map "${SLCF_OVERALL_MAP}" --key 'TOTAL_RUNTIME' --incr $( hget --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_RUNTIME' )

  #[ $( hget --map "${SLCF_OVERALL_MAP}" --key 'TOTAL_TIME' ) -eq 0 ] && hput --map "${SLCF_OVERALL_MAP}" --key 'TOTAL_TIME' --value 1

  if [ -n "$( __extract_value 'TEST_SUBSYSTEM' )" ]
  then
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS' --incr $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_PASS' )
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS' --incr $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_FAIL' )
    hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'TOTAL_ASSERTIONS' --incr $( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_SKIP' )

    #typeset subsys_registerd_asserts=$( hget --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_ASSERTIONS_EXPECTED' )
    #if [ "${subsys_registerd_asserts}" -gt 0 ]
    #then
      #hinc --map "${SLCF_SUBSYSTEM_MAP}" --key 'SUBSYSTEM_ASSERTIONS_EXPECTED' --incr "${subsys_registerd_asserts}"
      #SLCF_ASSERTION_COUNT=$( increment ${SLCF_ASSERTION_COUNT} ${SLCF_REGISTERED_ASSERTIONS_SUBSYSTEM} )
      #while [ "${subsys_registerd_asserts}" -gt 0 ]
      #do
        #hinc --map "${SLCF_OVERALL_MAP}"  --key 'SUBSYSTEM_ASSERTIONS' --incr 
        #SLCF_COUNT_ASSERTION_SUBSYSTEM=$( increment ${SLCF_COUNT_ASSERTION_SUBSYSTEM} )

        #printf "%s\n" "(AID: ${SLCF_COUNT_ASSERTION_SUBSYSTEM}) Test SKIPPED : Test was NOT exercised" >> "${SLCF_TEST_RESULTS_SUBSYSTEM_OUTPUT}"
        #SLCF_REGISTERED_ASSERTIONS_SUBSYSTEM=$( increment ${SLCF_REGISTERED_ASSERTIONS_SUBSYSTEM} -1 )
      #done
    #fi
    
    __reset_assertion_file
    
    [ "$( __check_for --key 'DETAIL' )" -eq "${YES}" ] && printf "\n"
    printf "%s\n" "$( __extract_value 'PREFIX_COMPLETED' ) $( __extract_value 'TEST_SUBSYSTEM' ) subsystem"
  fi
  
  record_step ${HOTSPOT_FLAGS} --header "suite_$( __extract_value 'TEST_SUBSYSTEM' )" --stop --msg "suite : $( __extract_value 'TEST_SUBSYSTEM' )"
  return "${PASS}"
}

force_fail()
{
  FORCED_FAIL_TEST="${YES}"
}

force_skip()
{
  FORCED_SKIP_TEST="${YES}"
}

increment_registered_tests()
{
  typeset incr_tests="${1:-0}"
  
  hinc --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_ASSERTIONS_EXPECTED' --incr ${incr_tests}
}

register_subsystem()
{
  typeset section=
  
  OPTIND=1
  while getoptex "s: section:" "$@"
  do
    case "${OPTOPT}" in
    's'|'section' ) section="${OPTARG:-${YES}}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -n "${section}" ] && __set_internal_value 'TEST_SUBSYSTEM' "${section}"
  if [ -z "$( __extract_value 'TEST_SUBSYSTEM' )" ]
  then
    __set_internal_value 'TEST_SUBSYSTEM' "UNKNOWN$( __extract_value 'UNKNOWN_SUBSYSTEM_ID' )"
    __set_internal_value 'UNKNOWN_SUBSYSTEM_ID' $( increment $( __extract_value 'UNKNOWN_SUBSYSTEM_ID' ) )
  fi
  
  hinc --map "$( __extract_value 'OVERALL_MAP' )" --key 'SUBSYSTEM_ID'

  ###
  ### This changes w.r.t. when a subsystem runs.  It does NOT
  ###   get affected by the "CANOPUS_START_TIME" (initial start time)
  ###
  __set_internal_value 'DATE_UTC' "$( __change_time_to_UTC "$( hget --map "$( __extract_value 'SUBSYSTEM_MAP' )" --key 'SUBSYSTEM_START_TIME' )" )"
  
  ###
  ### If it hasn't been set by this time, we didn't/couldn't determine
  ###   the OS type and therefore we will use a generic Unix/Linux location
  ###
  [ -z "$( __extract_value 'TEST_SUMMARY_PATH' )" ] || [ ! -d "$( __extract_value 'TEST_SUMMARY_PATH' )" ] && __set_internal_value 'TEST_SUMMARY_PATH' "$( get_temp_dir )"
  
  __set_internal_value 'TEST_RESULTS_TOPLEVEL' "$( __extract_value 'TEST_SUMMARY_PATH' )/RESULTS"
  __set_internal_value 'TEST_TOPLEVEL_TMP' "$( __extract_value 'TEST_RESULTS_TOPLEVEL' )/tmp"
  __set_internal_value 'INGREDIENTS_DIRECTORY' "$( __extract_value 'TEST_TOPLEVEL_TMP' )"
  
  [ ! -d "$( __extract_value 'TEST_TOPLEVEL_TMP' )" ] && \mkdir -p "$( __extract_value 'TEST_TOPLEVEL_TMP' )"
  
  __set_internal_value 'TEST_RESULTS_SUBSYSTEM' "$( __extract_value 'TEST_RESULTS_TOPLEVEL' )/$( __extract_value 'TEST_SUBSYSTEM' )"
  [ -d "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )" ] && \rm -rf "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )"
  
  __set_internal_value 'TEST_SUBSYSTEM_TEMPDIR' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )/tmp"
  [ ! -d "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )" ] && \mkdir -p "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )"

  typeset memopts=$( __import_variable --key 'SUBSYSTEM_TEMPORARY_DIR' --value "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )" --use-memory "${YES}" )
  eval "${memopts}"
  
  __set_internal_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )/$( __extract_value 'TEST_SUBSYSTEM' ).data"
  
  ###
  ### Detail where assertion information is intended to be recorded
  ###
  __setup_assertion_file "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )"
  
  \mkdir -p "$( __extract_value 'TEST_RESULTS_SUBSYSTEM' )" 
  \touch "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' )"

  printf "%s\n\n" "$( __extract_value 'PREFIX_INFO' ) Data Logging Output Directory : $( __extract_value 'TEST_RESULTS_SUBSYSTEM' )"
  printf "%s\n" "$( __extract_value 'PREFIX_RUNNING' ) $( __extract_value 'TEST_SUBSYSTEM' ) subsystem"
  
  
  record_step ${HOTSPOT_FLAGS} --header "suite_$( __extract_value 'TEST_SUBSYSTEM' )" --start --msg "new suite : $( __extract_value 'TEST_SUBSYSTEM' )"

  [ "$( __check_for --key 'DETAIL' --success )" -eq "${YES}" ] && printf "\n"
  
  ###
  ### Initialize output formats to point to proper locations for each subsystem
  ###
  typeset outfmt=
  for outfmt in $( __extract_value 'OUTPUT_FORMATS' )
  do
    eval "set_${outfmt}_filename"
    eval "initiate_${outfmt}"
    eval "initiate_${outfmt}_test_suite"
  done
  
  ###
  ### Location to handle stage manipulation
  ###
  if [ $( __check_for --key 'WORKFLOW' --success ) -eq "${YES}" ]
  then
    __set_internal_value 'CURRENT_STAGE' "${section}"
    __set_internal_value 'CURRENT_STAGE_ID' "$( hget --map "$( __extract_value 'OVERALL_MAP' )" --key 'SUBSYSTEM_ID' )"
  fi
  return "${PASS}"
}

# ---------------------------------------------------------------------------
__init
