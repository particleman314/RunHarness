#!/usr/bin/env bash

find_application()
{
  typeset application="$1"
  if [ -z "$1" ]
  then
    printf "%d\n" 0
    return 1
  fi

  \which "$1" >/dev/null 2>&1
  if [ $? -eq 0 ]
  then
    printf "%d\n" 1
  else
    printf "%s\n" 0
  fi
  return 0
}

handle_application()
{
  typeset application="$1"
  [ -z "$1" ] && return 1

  typeset found_app="$( find_application "$1" )"
  if [ "${found_app}" -eq 0 ]
  then
    buildapp=$( request_build_support_application "${application}" )

    if [ "${buildapp}" -eq 'YES' ]
    then
      eval "source build_${application}.sh"
      if [ $? -ne 0 ]
      then
        printf "%s\n" "Unable to properly build ${application}"
        return 1
      fi
    fi
  fi
  return 0
}

request_build_support_application()
{
  typeset application="$1"
  [ -z "${application}" ] && return 1
  typeset buildapp='NO'

  printf "%s\n" "No '${application}' program found..."
  read -p "Do you want to build '${application}' [ YES/NO ]? " buildapp
  [ -z "${buildapp}" ] && buildapp='NO'
  buildapp="$( printf "%s\n" "${buildapp}" | tr [:lower:] [:upper:] )"
  printf "%s\n" "${buildapp}"
}

# Add necessary support programs to this list and then add a handler
#   to the build_prereqs directory for support

__need_app_builds='jq sqlite3 xmlstarlet'
__additional_paths=

SLCF_SHELL_TOP="$( pwd -L )"
export SLCF_SHELL_TOP

. ${SLCF_SHELL_TOP}/utilities/common/define_pather.sh
. ${SLCF_SHELL_TOP}/utilities/common/program_utilities.sh

if [ -f "${SLCF_SHELL_TOP}/.preconfigured_paths.txt" ]
then
  while read -r line 
  do
    __addpath="$( printf "%s\n" "${line}" | \cut -f 2 -d ':' )"
    __appname="$( printf "%s\n" "${line}" | \cut -f 1 -d ':' )"

    if [ -d "${__addpath}" ]
    then
      export PATH="${__addpath}:${PATH}"
      printf "%s\n" "${line}" >> "${SLCF_SHELL_TOP}/.preconfigured_paths.txt.new"
      __need_app_builds=$( printf "%s\n" "${__need_app_builds}" | grep -v ${__appname}" )"
    else
      __need_app_builds+=" ${__appname}"
    fi
  done < "${SLCF_SHELL_TOP}/.preconfigured_paths.txt"

  mv "${SLCF_SHELL_TOP}/.preconfigured_paths.txt.new" "${SLCF_SHELL_TOP}/.preconfigured_paths.txt"
  __need_app_builds="$( printf "%s\n" "${__need_app_builds}" | \sort | \uniq )"
fi

for nab in ${__need_app_builds}
do 
  __additional_paths+=" $( handle_application ${nab} )"
done

if [ -n "${__additional_paths}" ]
then
  for adp ${__additional_paths}
  do
    __addpath="$( printf "%s\n" "${adp}" | \cut -f 1 -d ':' )"
    __appname="$( printf "%s\n" "${adp}" | \cut -f 2 -d ':' )"

    [ -d "${__addpath}" ] && export PATH="${__addpath}:${PATH}" 
    [ -f "${__addpath}/${__appname}" ] && printf "%s\n" "${__appname}:${__addpath}" >> "${SLCF_SHELL_TOP}/.preconfigured_paths.txt"
  done
fi

