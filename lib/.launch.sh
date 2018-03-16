#!/usr/bin/env bash

. "${SLCF_SHELL_TOP}/utilities/common/.define_pather.sh"

__set_internal_value 'TEST_SUITE_DIR' "$( ${__REALPATH} ${__REALPATH_OPTS} "$( \dirname '$0' )" )"
if [ -z "${SLCF_SHELL_TOP}" ]
then
  . "${__HARNESS_TOPLEVEL}/bin/setup.sh"
  . "${SLCF_SHELL_TOP}/lib/base_setup.sh"
fi

__testclass="$1"
shift

[ -z "$( __extract_value 'TEST_SUITES' )" ] || [ ! -d "$( __extract_value 'TEST_SUITES' )" ] && return "${FAIL}"
__testmapdir="$( __extract_value 'TEST_SUITES' )/${__testclass}"

if [ ! -d "${__testmapdir}" ]
then
  return "${FAIL}"
else
  run --suite "${__testclass}"
  __RUN_RC=$?
  return "${__RUN_RC}"
fi
