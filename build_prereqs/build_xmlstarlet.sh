#!/usr/bin/env bash

[ "$( find_application 'git' )" -eq 0 ] && return 1
[ "$( find_application 'make' )" -eq 0 ] && return 1

current_dir="$( pwd -L )"

build_xmlstarlet()
{
  typeset tmpbuild="${HOME}/tmp/xmlstarlet"
  \mkdir -p "${tmpbuild}"
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi

  cd "${tmpbuild}" >/dev/null 2>&1

  \git clone git://xmlstar.git.sourceforge.net/gitroot/xmlstar/xmlstar > download_xmlstarlet.txt
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi

  cd xmlstarlet >/dev/null 2>&1

  ./autogen.sh --with-libxml-prefix=/usr --with-libxslt-prefix=/usr > configure_xmlstarlet.txt
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi
  ./configure  >> configure_xmlstarlet.txt

  \make > build.txt 2>&1
  if [ $? -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return 1
  fi
  return 0
}

build_xmlstarlet
