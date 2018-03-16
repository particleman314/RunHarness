#!/usr/bin/env bash

$( return >/dev/null 2>&1 )
[ $? -eq 0 ] && SOURCED=1 || SOURCED=0

INVOCATION_DIR=

if [ ${0#${SHELL}} ]
then
  INVOCATION_DIR="$( \pwd -L )/${BASH_SOURCE[0]}"
  RL_INVOCATION_DIR="$( \readlink "${INVOCATION_DIR}" )"
  LAUNCH_DIR="$( \pwd -L )"
else
  INVOCATION_DIR="$0"
  RL_INVOCATION_DIR="$( \readlink "$0" )"
  LAUNCH_DIR="$( \dirname "${INVOCATION_DIR}" )"
fi
[ -n "${RL_INVOCATION_DIR}" ] && INVOCATION_DIR="${RL_INVOCATION_DIR}"

if [ -z "${SLCF_SHELL_TOP}" ]
then
  SLCF_STARTUP_DIR=$( printf "%s\n" "${INVOCATION_DIR}" | \sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' | \cut -d / -f 2- | \sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' )
  cd "${SLCF_STARTUP_DIR}" > /dev/null

  SLCF_STARTUP_DIR=$( \pwd -L )
  SLCF_SHELL_TOP=$( \dirname "${SLCF_STARTUP_DIR}" )
fi

SLCF_SHELL_BINDIR="${SLCF_SHELL_TOP}/bin"
SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
SLCF_SHELL_LIBDIR="${SLCF_SHELL_TOP}/lib"
SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
SLCF_SHELL_TESTDIR="${SLCF_SHELL_TOP}/test"
SLCF_SHELL_TEMPDIR='/tmp'

SLCF_BASH_DEBUGGER_PROGRAM="${BASH_DEBUGGER_PROGRAM:-'/usr/share/share/bashdb/bashdb-trace'}"
SLCF_BASH_DEBUGGER_OPTIONS="${BASE_DEBUGGER_OPTIONS:-' -L /usr/share/share/bashdb'}"
SLCF_BASH_DEBUGGER_SETTINGS="${BASH_DEBUGGER_SETTINGS:-'_Dbg_linetrace_on _dbg_debugger'}"

. "${SLCF_SHELL_TOP}/lib/base_machinemgt.sh"
__add_support_binaries

MANUAL_TESTING="${YES}"

cd "${LAUNCH_DIR}" > /dev/null

if [ -n "${SETUP_SHOW_DETAILS}" ]
then
  printf "%s\n" "Root Directory (SLCF_SHELL_TOP)             = ${SLCF_SHELL_TOP}"
  printf "%s\n" "Resource Directory (SLCF_SHELL_RESOURCEDIR) = ${SLCF_SHELL_RESOURCEDIR}"
  printf "%s\n" "Binary Directory (SLCF_SHELL_BINDIR)        = ${SLCF_SHELL_BINDIR}"
  printf "%s\n" "Library Directory (SLCF_SHELL_FUNCTIONDIR)  = ${SLCF_SHELL_FUNCTIONDIR}"
  printf "%s\n" "Utility Directory (SLCF_SHELL_UTILDIR)      = ${SLCF_SHELL_UTILDIR}"
  printf "%s\n" "Test Directory (SLCF_SHELL_TESTDIR)         = ${SLCF_SHELL_TESTDIR}"
fi
