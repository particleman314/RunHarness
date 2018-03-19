#!/usr/bin/env bash

XML_GIT_REPO='git://xmlstar.git.sourceforge.net/gitroot/xmlstar/xmlstar'

DOWNLOAD_FILE='download.txt'
CONFIGURE_FILE='configure.txt'
BUILD_FILE='build.txt'

download_xmlstarlet()
{
  typeset tmpbuild="$1"
  typeset RC=1

  \mkdir -p "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  typeset needs_git_update=0

  cd "${tmpbuild}" >/dev/null 2>&1

  if [ ! -d "${tmpbuild}/xmlstar" ]
  then
    print_btf_detail --msg "Downloading 'xml' src code" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
    \date > "${DOWNLOAD_FILE}"
    \git clone --verbose "${XML_GIT_REPO}" >> "${DOWNLOAD_FILE}" 2>&1
    RC=$?
    if [ "${RC}" -ne 0 ]
    then
      cd "${current_dir}" > /dev/null 2>&1
      return "${RC}"
    fi
  else
    needs_git_update=1
  fi

  cd xmlstar >/dev/null 2>&1
  if [ "${needs_git_update}" -eq 1 ]
  then
    print_btf_detail --msg "Updating 'xml' src code" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
    \date > "../${DOWNLOAD_FILE}"
    \git pull >> "../${DOWNLOAD_FILE}" 2>&1
    RC=$?
    if [ "${RC}" -ne 0 ]
    then
      cd "${current_dir}" > /dev/null 2>&1
      return "${RC}"
    fi
 fi
  cd - > /dev/null 2>&1
  return "${RC}"
}

configure_xmlstarlet()
{
  print_btf_detail --msg "Configuring 'xml' build system" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
  typeset tmpbuild="$1"
  typeset RC=1

  cd xmlstar >/dev/null 2>&1

  \date > "../${CONFIGURE_FILE}"
  \autoreconf -sif >> "../${CONFIGURE_FILE}" 2>&1 >> "../${CONFIGURE_FILE}" 2>&1
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  ./configure >> "../${CONFIGURE_FILE}" 2>&1
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  ./configure >> "../${CONFIGURE_FILE}" 2>&1
  RC=$?
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
  print_btf_detail --msg "Compiling/Linking 'xml' " --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
  typeset tmpbuild="$1"
  typeset RC=1

  cd xmlstar >/dev/null 2>&1
  \make > "../${BUILD_FILE}" 2>&1
  RC=$?
  printf "%s\n" "Error condition at end of make = ${RC}" >> "../${BUILD_FILE}"

  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi
  cd - >/dev/null 2>&1
  return 0
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
    print_btf_detail --msg "Building 'xml' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 >&2
    return "${RC}"
  fi

  configure_xmlstarlet "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'xml' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 >&2
    return "${RC}"
  fi

  make_xmlstarlet "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'xml' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 >&2
    return "${RC}"
  fi

  print_btf_detail --msg "Building 'xml' application completed --> (see ${tmpbuild} for details)" --prefix "${__INFO_PREFIX}" --tab-level 1 >&2
  printf "%s\n" "${tmpbuild}/xmlstar:xml"
  cd "${current_dir}" > /dev/null 2>&1
  return 0
}

[ "$( find_application 'git' 1 )" -eq 0 ] && return 1
[ "$( find_application 'make' 1 )" -eq 0 ] && return 1

current_dir="$( \pwd -L )"
build_xmlstarlet
