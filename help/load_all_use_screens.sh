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

HELP_TOP="${__harness_toplevel}"
[ -z "${__harness_toplevel}" ] && HELP_TOP="${__HARNESS_TOPLEVEL}"

usage_files=$( \find "${HELP_TOP}/help" -type f -name "*.sh" -exec printf "%s " '"{}"' \; )

for f in ${usage_files}
do
  f="$( printf "%s\n" "${f}" | \sed -e 's/^"//' -e 's/"$//' )"
  [ "${f}" == "${HELP_TOP}/help/.load_all_usage_screens.sh" ] && continue
  . "${f}" >/dev/null 2>&1
  [ $? -ne 0 ] && exit 1
done

