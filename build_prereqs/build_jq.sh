#!/usr/bin/env bash

[ "$( find_application 'git' )" -eq 0 ] && return 1
[ "$( find_application 'autoreconf' )" -eq 0 ] && return 1
[ "$( find_application 'make' )" -eq 0 ] && return 1

current_dir="$( pwd -L )"

build_jq()
{
  typeset tmpbuild="${HOME}/tmp/jq"
  \mkdir -p "${tmpbuild}"
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi

  cd "${tmpbuild}" >/dev/null 2>&1

  \git clone https://github.com/stedolan/jq.git > download_jq.txt
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi

  cd jq >/dev/null 2>&1

  \autoreconf -i > reconfigure_jq.txt
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi
  ./configure --disable-maintainer-mode >> reconfigure_jq.txt

  \make > build.txt 2>&1
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi
  return 0
}

build_jq
