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

XML_GIT_REPO='git://xmlstar.git.sourceforge.net/gitroot/xmlstar/xmlstar'
XML_SOURCEFORGE_REPO='git://git.code.sf.net/p/xmlstar/code'

download_xmlstarlet()
{
  __download_git "$1" 'xml' "${XML_GIT_REPO}"
  typeset RC=$?
  __record_command_2_file "${tmpbuild}/${DOWNLOAD_FILE}" "Return Code : ${RC}"
  if [ "${RC}" -ne 0 ]
  then
    __download_git "$1" 'xml' "${XML_SOURCEFORGE_REPO}"
    RC=$?
    __record_command_2_file "${tmpbuild}/${DOWNLOAD_FILE}" "Return Code : ${RC}"
  fi
  return "${RC}"
}

configure_xmlstarlet()
{
  print_btf_detail --msg "Configuring 'xml' build system" --prefix "${__INFO_PREFIX}" --tab-level 2 --use-color '\033[1;33m' >&2
  typeset tmpbuild="$1"
  typeset RC=1

  cd 'xmlstar' >/dev/null 2>&1

  \date > "${tmpbuild}/${CONFIGURE_FILE}"
  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" "autoreconf -sif"
  \autoreconf -sif >> "${tmpbuild}/${CONFIGURE_FILE}" 2>&1 >> "../${CONFIGURE_FILE}" 2>&1
  RC=$?
  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" "Return Code : ${RC}"
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" './configure'
  ./configure >> "${tmpbuild}/${CONFIGURE_FILE}" 2>&1
  RC=$?
  __record_command_2_file "${tmpbuild}/${CONFIGURE_FILE}" "Return Code : ${RC}"
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  cd - > /dev/null 2>&1
  return "${RC}"
}

make_xmlstarlet()
{
  __make_with_args "$1/xmlstar" 'xml' 1
  typeset RC=$?
  __record_command_2_file "${tmpbuild}/${BUILD_FILE}" "Return Code : ${RC}"
  return "${RC}"
}

build_xmlstarlet()
{
  print_btf_detail --msg "Building 'xml' application started" --prefix "${__INFO_PREFIX}" --tab-level 1 >&2
  typeset tmpbuild="${HOME}/tmp/xmlstarlet"
  typeset RC=1

  download_xmlstarlet "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'xml' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
    return "${RC}"
  fi

  configure_xmlstarlet "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'xml' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
    return "${RC}"
  fi

  make_xmlstarlet "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'xml' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
    return "${RC}"
  fi

  print_btf_detail --msg "Building 'xml' application completed --> (see ${tmpbuild} for details)" --prefix "${__INFO_PREFIX}" --tab-level 1 --use-color '\033[1;32m' >&2
  printf "%s\n" "${tmpbuild}/xmlstar:xml"
  cd "${current_dir}" > /dev/null 2>&1
  return 0
}

[ "$( find_application 'git' 1 )" -eq 0 ] && return 1
[ "$( find_application 'make' 1 )" -eq 0 ] && return 1

current_dir="$( \pwd -L )"
build_xmlstarlet
