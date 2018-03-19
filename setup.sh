#!/usr/bin/env bash

__SETUP_COMPLETE_SUCCESSFULLY=1

__INFO_PREFIX="[ INFO  ]"
__WARN_PREFIX="[ WARN  ]"
__ERROR_PREFIX='[ ERROR ]'

find_application()
{
  typeset application="$1"
  if [ -z "${application}" ]
  then
    printf "%d\n" 0
    return 1
  fi
  shift 1
  typeset suppress="${1:-0}"

  [ "${suppress}" -eq 0 ] && print_btf_detail --msg "Looking for ${application}..." --prefix "${__INFO_PREFIX}" >&2
  
  \which "${application}" >/dev/null 2>&1
  if [ $? -eq 0 ]
  then
    printf "%d\n" 1
    [ "${suppress}" -eq 0 ] && print_btf_detail --msg 'Found' --tab-level 1 --prefix "${__INFO_PREFIX}" >&2
  else
    [ "${suppress}" -eq 0 ] && print_btf_detail --msg 'Needed' --tab-level 1 --prefix "${__WARN_PREFIX}" --newline-count 2 >&2
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

    if [ "${buildapp}" == 'YES' ]
    then
      eval "source build_prereqs/build_${application}.sh"
      if [ $? -ne 0 ]
      then
        print_btf_detail --msg "Unable to properly build '${application}'" --prefix "${__ERROR_PREFIX}" --tab-level 1 >&2
        __SETUP_COMPLETE_SUCCESSFULLY=$(( __SETUP_COMPLETE_SUCCESSFULLY - 1 ))
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

  printf "%s\n" "No '${application}' program found..." >&2
  read -p "Do you want to build '${application}' [ {YES}/NO ] ? " buildapp
  [ -z "${buildapp}" ] && buildapp='YES'
  buildapp="$( printf "%s\n" "${buildapp}" | \tr [:lower:] [:upper:] )"
  printf "\n" >&2
  printf "%s\n" "${buildapp}"
}

# Add necessary support programs to this list and then add a handler
#   to the build_prereqs directory for support

__need_app_builds='jq sqlite3 xml'
__additional_paths=

SLCF_SHELL_TOP="${1-${SLCF_SHELL_TOP}}"
if [ -z "${SLCF_SHELL_TOP}" ] || [ ! -d "${SLCF_SHELL_TOP}" ]
then
  printf "%s\n" "Need to specify SLCF_SHELL_TOP as input!"
  exit 1
fi

cd "${SLCF_SHELL_TOP}" > /dev/null 2>&1
SLCF_SHELL_TOP="$( \pwd -L )"
cd - > /dev/null 2>&1

export SLCF_SHELL_TOP

. "${SLCF_SHELL_TOP}/utilities/common/define_pather.sh"
. "${SLCF_SHELL_TOP}/utilities/common/program_utilities.sh"

print_btf_detail --msg "Looking for tool prerequesites requested to utilize the Shell Library Component Framework..." --prefix "${__INFO_PREFIX}"
for nab in ${__need_app_builds}
do
  print_btf_detail --msg "${nab}" --prefix "${__INFO_PREFIX}" --tab-level 1
done
printf "\n"

\sleep 1

if [ -f "${SLCF_SHELL_TOP}/.preconfigured_paths.txt" ]
then
  while read -r line 
  do
    __addpath="$( printf "%s\n" "${line}" | \cut -f 1 -d ':' )"
    __appname="$( printf "%s\n" "${line}" | \cut -f 2 -d ':' )"

    print_btf_detail --msg "Looking for ${__appname}..." --prefix "${__INFO_PREFIX}"

    if [ -d "${__addpath}" ]
    then
      export PATH="${__addpath}:${PATH}"
      printf "%s\n" "${line}" >> "${SLCF_SHELL_TOP}/.preconfigured_paths.txt.new"
      __need_app_builds="$( printf "%s\n" ${__need_app_builds} | \grep -v "${__appname}" )"
      print_btf_detail --msg 'Prebuilt' --tab-level 1 --prefix "${__INFO_PREFIX}"
    else
      __need_app_builds+=" ${__appname}"
      #print_btf_detail --msg 'Removed from preconfiguration.  Need rebuild...' --tab-level 1 --prefix "${__WARN_PREFIX}"
    fi
  done < "${SLCF_SHELL_TOP}/.preconfigured_paths.txt"

  [ -f "${SLCF_SHELL_TOP}/.preconfigured_paths.txt.new" ] && \mv -f "${SLCF_SHELL_TOP}/.preconfigured_paths.txt.new" "${SLCF_SHELL_TOP}/.preconfigured_paths.txt"
  __need_app_builds="$( printf "%s\n" ${__need_app_builds} | \sort | \uniq )"
fi

preconfigured_paths=

for nab in ${nab}
do 
  __additional_paths+=" $( handle_application ${nab} )"
done

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

if [ "${__SETUP_COMPLETE_SUCCESSFULLY}" -lt 1 ]
then
  print_btf_detail --msg "Unable to complete setup for use of RunHarness" --prefix "${__ERROR_PREFIX}"
  exit 1
else
  [ -f "${SLCF_SHELL_TOP}/.preconfigured_paths.txt" ] && preconfigured_paths+="$( \cat "${SLCF_SHELL_TOP}/.preconfigured_paths.txt" | \tr '\n' '|' )"
  preconfigured_paths="$( printf "%s\n" ${preconfigured_paths} | \sort | \uniq | \tr '|' '\n' )"

  printf "%s\n" ${preconfigured_paths} > "${SLCF_SHELL_TOP}/.preconfigured_paths.txt"
  print_btf_detail --msg "Setup completed.  RunHarness and SLCF information determined." --prefix "${__INFO_PREFIX}"
fi

