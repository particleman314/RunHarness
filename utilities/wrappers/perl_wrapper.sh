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
# Author           : Mike Klusman
# Software Package : Shell Automated Testing -- Perl Wrapper
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

# --------------------------------------------------------------------
[ -z "${SLCF_SHELL_TOP}" ] && return "${FAIL}"

###
### Pull in the path functionality to be able to resolve paths
###
. "${SLCF_SHELL_TOP}/utilities/common/.define_pather.sh"
[ $? -ne "${PASS}" ] && return "${FAIL}"

if [ -z "${HARNESS_BINDIR}" ]
then
  #[ -z "${REALPATH}" ] && source "${SLCF_SHELL_TOP}/utilities/common/.define_pather.sh"
  
  #SLCF_TEST_SUITE_DIR=$( ${__REALPATH} ${__REALPATH_OPTS} "$( \dirname '$0' )" )

  . "${__HARNESS_TOPLEVEL}/bin/setup.sh"
  
  . "${__HARNESS_TOPLEVEL}/test/base_testing.sh"
  . "${__HARNESS_TOPLEVEL}/test/test_framework.sh"
fi
  
. "${SLCF_SHELL_TOP}/lib/assertions.sh"
[ $? -ne "${PASS}" ] && return "${FAIL}"

. "${__HARNESS_TOPLEVEL}/utilities/wrappers/wrapper_common.sh"

if [ -n "$( __extract_value 'DETAIL' )" ] && [ "$( __extract_value 'DETAIL' )" -eq "${YES}" ]
then
  __stdout '----------------------------------------------------------------'
  __stdout 'This is the bash wrapper script for Perl'
  __stdout '----------------------------------------------------------------'
fi

__result_file="$( run_wrapper $@ )"
__RC=$?

return "${__RC}"
