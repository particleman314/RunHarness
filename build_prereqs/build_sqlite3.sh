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

SQLITE3_DOWNLOAD_ADDR='https://www.sqlite.org/src/zip/sqlite.zip'

download_sqlite3()
{
  __download_remote "$1" 'sqlite3' "${SQLITE3_DOWNLOAD_ADDR}"
  typeset RC=$?
  __record_command_2_file "${tmpbuild}/${DOWNLOAD_FILE}" "Return Code : ${RC}"
  return "${RC}"
}

configure_sqlite3()
{
  print_btf_detail --msg "Configuring 'sqlite3' build system" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
  typeset tmpbuild="$1"
  typeset RC=1

  cd "${tmpbuild}" > /dev/null 2>&1

  \date > "${tmpbuild}/${CONFIGURE_FILE}"
  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" "mkdir ${tmpbuild}/sqlite3/bld"
  \mkdir "${tmpbuild}/bld" >> "${tmpbuild}/${CONFIGURE_FILE}" 2>&1
  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" "Return Code : ${RC}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  cd "${tmpbuild}/bld" > /dev/null 2>&1

  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" "${tmpbuild}/sqlite/configure"
  "${tmpbuild}/sqlite/configure" >> "${tmpbuild}/${CONFIGURE_FILE}" 2>&1
  RC=$?
  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" "Return Code : ${RC}"
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  printf "\n%s\n" "See ${tmpbuild}/bld/config.log for more details..." >> "${tmpbuild}/${CONFIGURE_FILE}" 2>&1
  cd "${tmpbuild}" > /dev/null 2>&1
  return "${RC}"
}


make_sqlite3()
{
  __make_with_args "$1" 'sqlite3' 0 'bld'
  typeset RC=$?
  __record_command_2_file "${tmpbuild}/${BUILD_FILE}" "Return Code : ${RC}"
  return "${RC}"
}

build_sqlite3()
{
  print_btf_detail --msg "Building 'sqlite3' application started" --prefix "${__INFO_PREFIX}" --tab-level 1 >&2
  typeset tmpbuild="${HOME}/tmp/sqlite3"
  typeset RC=1

  download_sqlite3 "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'sqlite3' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
    return "${RC}"
  fi

  configure_sqlite3 "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'sqlite3' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
    return "${RC}"
  fi

  make_sqlite3 "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'sqlite3' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
    return "${RC}"
  fi

  print_btf_detail --msg "Building 'sqlite3' application completed --> (see ${tmpbuild} for details)" --prefix "${__INFO_PREFIX}" --tab-level 1 --use-color '\033[1;33m' >&2
  printf "%s\n" "${tmpbuild}/bld:sqlite3"
  cd "${current_dir}" > /dev/null 2>&1
  return 0
}

if [ "$( find_application 'wget' 1 )" -eq 0 ]
then
  [ "$( find_application 'curl' 1 )" -eq 0 ] && return 1
  download_application='curl'
else
  download_application='wget'
fi

[ "$( find_application 'make' 1 )" -eq 0 ] && return 1

current_dir="$( \pwd -L )"
build_sqlite3
