#!/usr/bin/env bash

JQ_GIT_REPO='https://github.com/stedolan/jq.git'

DOWNLOAD_FILE='download.txt'
CONFIGURE_FILE='configure.txt'
BUILD_FILE='build.txt'

download_jq()
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

  if [ ! -d "${tmpbuild}/jq" ]
  then
    print_btf_detail --msg "Downloading 'jq' src code" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
    \date > "${DOWNLOAD_FILE}"
    \git clone --verbose "${JQ_GIT_REPO}" >> "${DOWNLOAD_FILE}" 2>&1
    RC=$?
    if [ "${RC}" -ne 0 ]
    then
      cd "${current_dir}" > /dev/null 2>&1
      return "${RC}"
    fi
  else
    needs_git_update=1
  fi

  cd jq >/dev/null 2>&1
  if [ "${needs_git_update}" -eq 1 ]
  then
    print_btf_detail --msg "Updating 'jq' src code" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
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

configure_jq()
{
  print_btf_detail --msg "Configuring 'jq' build system" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
  typeset tmpbuild="$1"
  typeset RC=1

  cd jq >/dev/null 2>&1
  \date > "../${CONFIGURE_FILE}"
  \autoreconf -i >> "../${CONFIGURE_FILE}" 2>&1
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  ./configure --disable-maintainer-mode >> "../${CONFIGURE_FILE}" 2>&1
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi
  cd - > /dev/null 2>&1
  return "${RC}"
}

make_jq()
{
  print_btf_detail --msg "Compiling/Linking 'jq' " --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
  typeset tmpbuild="$1"
  typeset RC=1

  cd jq >/dev/null 2>&1
  \make > "../${BUILD_FILE}" 2>&1
  RC=$?
  printf "%s\n" "Error condition at end of make = ${RC}" >> "../${BUILD_FILE}"

  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi
  cd - >/dev/null 2>&1
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
    print_btf_detail --msg "Building 'jq' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 >&2
    return "${RC}"
  fi

  configure_jq "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'jq' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 >&2
    return "${RC}"
  fi

  make_jq "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    print_btf_detail --msg "Building 'jq' application failed --> (see ${tmpbuild} for details)" --prefix "${__WARN_PREFIX}" --tab-level 1 >&2
    return "${RC}"
  fi

  print_btf_detail --msg "Building 'jq' application completed --> (see ${tmpbuild} for details)" --prefix "${__INFO_PREFIX}" --tab-level 1 >&2
  printf "%s\n" "${tmpbuild}/jq:jq"
  cd "${current_dir}" > /dev/null 2>&1
  return 0
}

[ "$( find_application 'git' 1 )" -eq 0 ] && return 1
[ "$( find_application 'autoreconf' 1 )" -eq 0 ] && return 1
[ "$( find_application 'make' 1 )" -eq 0 ] && return 1

current_dir="$( \pwd -L )"
build_jq
