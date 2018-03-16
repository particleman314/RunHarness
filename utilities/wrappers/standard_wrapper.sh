#! /bin/bash

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
# Software Package : Shell Automated Testing -- Program Support
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###
### Pull in the path functionality to be able to resolve paths
###
. "${SLCF_SHELL_TOP}/utilities/common/.define_pather.sh"
[ $? -ne "${PASS}" ] && return "${FAIL}"

# --------------------------------------------------------------------
if [ -z "${HARNESS_BINDIR}" ]
then
  . "${__HARNESS_TOPLEVEL}/bin/setup.sh"
  
  . "${__HARNESS_TOPLEVEL}/test/base_testing.sh"
  . "${__HARNESS_TOPLEVEL}/test/test_framework.sh"
fi

SUBSYSTEM_TEMPORARY_DIR=$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )
export SUBSYSTEM_TEMPORARY_DIR

. "${SLCF_SHELL_FUNCTIONDIR}/base_machinemgt.sh"
[ $? -ne "${PASS}" ] && return "${FAIL}"

. "${SLCF_SHELL_FUNCTIONDIR}/network_assertions.sh"
[ $? -ne "${PASS}" ] && return "${FAIL}"

if [ $( __check_for --key 'DETAIL' ) -eq "${YES}" ]
then
  __stdout '----------------------------------------------------------------'
  __stdout 'This is the bash wrapper script'
  __stdout '----------------------------------------------------------------'
fi

__result_file="$( run_wrapper $@ )"
__RC=$?

return "${__RC}"
