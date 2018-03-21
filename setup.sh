#!/usr/bin/env bash
###############################################################################
# Copyright (c) 2018.  All rights reserved. 
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

# Add necessary support programs to this list and then add a handler
#   to the build_prereqs directory for support

__need_app_builds='jq sqlite3 xml'
__additional_paths=

# Import support functionality

. "./build_prereqs/setup_support.sh"

# Handle the -y option (force installation/non-interactive)
#   and the -d option for the ShellLibrary directory

# Verify SLCF_SHELL_TOP is defined.  If not, we exit now and request
#   the user to setup this ENV variable

SLCF_SHELL_TOP="${1-${SLCF_SHELL_TOP}}"
if [ -z "${SLCF_SHELL_TOP}" ] || [ ! -d "${SLCF_SHELL_TOP}" ]
then
  printf "%s\n" "Need to specify SLCF_SHELL_TOP environment variable as input!"
  exit 1
fi

# Load the internal absolute path manager

. "${SLCF_SHELL_TOP}/utilities/common/define_pather.sh"

# Ensure it is absolutely defined and exported into the current invocation

SLCF_SHELL_TOP=$( realpath_internal "${SLCF_SHELL_TOP}" )
export SLCF_SHELL_TOP

# Load in some back functionality from the Shell Library
#   Bring in argparsing to assist with support functionality ( implicitly )

. "${SLCF_SHELL_TOP}/utilities/common/program_utilities.sh"

print_btf_detail --msg "Looking for tool prerequesites requested to utilize the Shell Library Component Framework..." --prefix "${__INFO_PREFIX}"

for nab in ${__need_app_builds}
do
  print_btf_detail --msg "${nab}" --prefix "${__INFO_PREFIX}" --tab-level 1 --use-color '\033[1;34m'
done

printf "\n"
\sleep 1

# Attempt to see if any prebuilt apps are available which match requests

__need_app_builds="$( import_old_prebuilts "${__need_app_builds}" )"

preconfigured_paths=

# Attempt to "build" the requested applications (separate build_<>.sh file in buildprereqs)
for nab in ${__need_app_builds}
do 
  __additional_paths+=" $( handle_application ${nab} )"
done

# Prepare to store the prebuilt information so it expedites future invocation
if [ -n "${__additional_paths}" ]
then
  for adp in ${__additional_paths}
  do
    __addpath="$( printf "%s\n" "${adp}" | \cut -f 1 -d ':' )"
    __appname="$( printf "%s\n" "${adp}" | \cut -f 2 -d ':' )"

    [ -d "${__addpath}" ] && export PATH="${__addpath}:${PATH}" 
    [ -x "${__addpath}/${__appname}" ] && preconfigured_paths+="|${adp}"
  done
fi

# Return to where we initiated this script
cd "${topdir}" >/dev/null 2>&1

[ -f "${SLCF_SHELL_TOP}/.preconfigured_paths.txt" ] && preconfigured_paths+="$( \cat "${SLCF_SHELL_TOP}/.preconfigured_paths.txt" | \tr '\n' '|' )"
preconfigured_paths="$( printf "%s\n" ${preconfigured_paths} | \sort | \uniq | \tr '|' '\n' )"

printf "%s\n" ${preconfigured_paths} > "${SLCF_SHELL_TOP}/.preconfigured_paths.txt"

if [ "${__SETUP_COMPLETE_SUCCESSFULLY}" -lt 1 ]
then
  print_btf_detail --msg "Unable to complete full setup for use of RunHarness." --prefix "${__ERROR_PREFIX}" --use-color '\033[1;31m'
  exit 1
else
  print_btf_detail --msg "Setup completed.  RunHarness and SLCF information determined." --prefix "${__INFO_PREFIX}"
fi

