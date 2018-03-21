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

JQ_GIT_REPO='https://github.com/stedolan/jq.git'

download_jq()
{
  __download_git "$1" 'jq' "${JQ_GIT_REPO}"
  typeset RC=$?
  __record_command_2_file "${tmpbuild}/${DOWNLOAD_FILE}" "Return Code : ${RC}"
  return "${RC}"
}

configure_jq()
{
  print_btf_detail --msg "Configuring 'jq' build system" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
  typeset tmpbuild="$1"
  typeset RC=1

  cd 'jq' >/dev/null 2>&1
  \date > "${tmpbuild}/${CONFIGURE_FILE}"
  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" 'autoreconf -i'
  \autoreconf -i >> "${tmpbuild}/${CONFIGURE_FILE}" 2>&1
  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" "Return Code : ${RC}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" './configure --disable-maintainer-mode'
  ./configure --disable-maintainer-mode >> "${tmpbuild}/${CONFIGURE_FILE}" 2>&1
  RC=$?
  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" "Return Code : ${RC}"
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi
  cd "${tmpbuild}" > /dev/null 2>&1
  return "${RC}"
}

make_jq()
{
  __make_with_args "$1/jq" 'jq' 0
  typeset RC=$?
  __record_command_2_file "${tmpbuild}/${BUILD_FILE}" "Return Code : ${RC}"
  return "${RC}"
}

build_jq()
{
  print_btf_detail --msg "Building 'jq' application started" --prefix "${__INFO_PREFIX}" --tab-level 1 >&2
  typeset tmpbuild="${HOME}/tmp/jq"
  typeset RC=1

  download_jq "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'jq' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
    return "${RC}"
  fi

  configure_jq "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'jq' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
    return "${RC}"
  fi

  make_jq "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'jq' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
    return "${RC}"
  fi

  print_btf_detail --msg "Building 'jq' application completed --> (see ${tmpbuild} for details)" --prefix "${__INFO_PREFIX}" --tab-level 1 --use-color '\033[1;33m' >&2
  printf "%s\n" "${tmpbuild}/jq:jq"
  cd "${current_dir}" > /dev/null 2>&1
  return 0
}

[ "$( find_application 'git' 1 )" -eq 0 ] && return 1
[ "$( find_application 'autoreconf' 1 )" -eq 0 ] && return 1
[ "$( find_application 'make' 1 )" -eq 0 ] && return 1

current_dir="$( \pwd -L )"
build_jq
