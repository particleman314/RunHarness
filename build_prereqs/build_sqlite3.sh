#!/usr/bin/env bash

[ "$( find_application 'git' )" -eq 0 ] && return 1
[ "$( find_application 'curl' )" -eq 0 ] && return 1
[ "$( find_application 'unzip' )" -eq 0 ] && return 1

current_dir="$( pwd -L )"

build_sqlite3()
{
  typeset tmpbuild="${HOME}/tmp/sqlite3"
  \mkdir -p "${tmpbuild}"
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi

  cd "${tmpbuild}" >/dev/null 2>&1
  \curl -s -X GET "https://www.sqlite.org/2018/sqlite-tools-linux-x86-3220000.zip" -o sqlite3.zip
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi

  \unzip sqlite3.zip
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi
  return 0
}

build_sqlite3
