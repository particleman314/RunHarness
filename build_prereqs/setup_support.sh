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

__SETUP_COMPLETE_SUCCESSFULLY=1

__INFO_PREFIX='[ INFO  ]'
__WARN_PREFIX='[ WARN  ]'
__ERROR_PREFIX='[ ERROR ]'

DOWNLOAD_FILE='download.txt'
CONFIGURE_FILE='configure.txt'
BUILD_FILE='build.txt'

FORCE_INSTALL="${FORCE_INSTALL:-0}"

topdir="$( \pwd -L )"

__decompose_download()
{
  typeset absfilename="$1"
  typeset outputdir="$2"
  typeset RC=0

  typeset try_again=1
  typeset retries=4
  while [ "${try_again}" -eq 1 ] && [ "${retries}" -gt 0 ]
  do
    typeset filextension="${absfilename##*.}"
    if [ -z "${filextension}" ] || [ "${absfilename}" == "${filextension}" ]
    then
      try_again=0
      continue
    fi

    case "${filextension}" in
    'zip'   )  [ "$( find_application 'unzip' 1 )" -eq 0 ] && return 1;
               \unzip "${absfilename}" >> "${outputdir}/${DOWNLOAD_FILE}" 2>&1; RC=$?;;

    'gz'    )  [ "$( find_application 'gunzip' 1 )" -eq 0 ] && return 1;
               \gunzip "${absfilename}" >> "${outputdir}/${DOWNLOAD_FILE}" 2>&1; RC=$?;;

    'tar'   )  [ "$( find_application 'tar' 1 )" -eq 0 ] && return 1;
               \tar xvf "${absfilename}" >> "${outputdir}/${DOWNLOAD_FILE}" 2>&1; RC=$?;;

    'bz2'   )  [ "$( find_application 'bunzip' 1 )" -eq 0 ] && return 1;
               \bunzip "${absfilename}" >> "${outputdir}/${DOWNLOAD_FILE}" 2>&1; RC=$?;;

    *       )  try_again=0; continue;;
    esac

    absfilename="${absfilename%.*}"
    retries=$(( retries - 1 ))
  done
  return "${RC}"
}

__download_remote()
{
  typeset tmpbuild="$1"
  typeset application="$2"
  typeset inetaddr="$3"
  typeset deposition="$4"

  [ -z "${download_application}" ] && download_application='<none>'
  [ -d "${tmpbuild}/${application}" ] && \rm -rf "${tmpbuild}/${application}"

  typeset RC=1

  \mkdir -p "${tmpbuild}"
  RC=$?
  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  cd "${tmpbuild}" >/dev/null 2>&1

  typeset outfile="${tmpbuild}/$( \basename "${inetaddr}" )"

  print_btf_detail --msg "Downloading '${application}' from address ( ${inetaddr} )" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
  \date > "${tmpbuild}/${DOWNLOAD_FILE}"

  case "${download_application}" in 
  'wget'  ) 
            __record_command_2_file "${tmpbuild}/${DOWNLOAD_FILE}" "wget \"${inetaddr}\" -O \"${outfile}\""
            \wget "${inetaddr}" -O "${outfile}" >> "${tmpbuild}/${DOWNLOAD_FILE}" 2>&1;
            RC=$?;;
  'curl'  )
            __record_command_2_file "${tmpbuild}/${DOWNLOAD_FILE}" "curl -s -X GET \"${inetaddr}\" -o \"${outfile}\""
            \curl -s -X GET "${inetaddr}" -o "${outfile}" >> "${tmpbuild}/${DOWNLOAD_FILE}" 2>&1;
            RC=$?;;
  *       ) RC=1;;
  esac

  if [ "${RC}" -ne 0 ]
  then
    cd "${current_dir}" > /dev/null 2>&1
    return "${RC}"
  fi

  __decompose_download "${outfile}" "${tmpbuild}"
  RC=$?
  [ "${RC}" -ne 0 ] && cd "${current_dir}" > /dev/null 2>&1
  return "${RC}"
}

# __download_cvs()
# {
#   typeset tmpbuild="$1"
#   typeset application="$2"
#   typeset VCS_repo="$3"
#   typeset cvs_deposition="$4"

#   typeset RC=1
# }

# __download_svn()
# {
#   typeset tmpbuild="$1"
#   typeset application="$2"
#   typeset VCS_repo="$3"
#   typeset svn_deposition="$4"

#   typeset RC=1
# }

__download_git()
{
  typeset tmpbuild="$1"
  typeset application="$2"
  typeset VCS_repo="$3"
  typeset git_deposition="$( printf "%s\n" "$( \basename ${VCS_repo} )" | \sed -e 's#\.git##' )"

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

  if [ ! -d "${tmpbuild}/${application}" ]
  then
    print_btf_detail --msg "Downloading '${application}' src code ( ${VCS_repo} )" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
    \date > "${DOWNLOAD_FILE}"
    __record_command_2_file "${DOWNLOAD_FILE}" "git clone --verbose \"${VCS_repo}\""
    \git clone --verbose "${VCS_repo}" >> "${DOWNLOAD_FILE}" 2>&1
    RC=$?
    if [ "${RC}" -ne 0 ]
    then
      cd "${current_dir}" > /dev/null 2>&1
      return "${RC}"
    fi
  else
    needs_git_update=1
  fi

  cd "${git_deposition}" >/dev/null 2>&1
  if [ "${needs_git_update}" -eq 1 ]
  then
    print_btf_detail --msg "Updating '${application}' src code ( ${VCS_repo} )" --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
    \date > "${tmpbuild}/${DOWNLOAD_FILE}"
    __record_command_2_file "${tmpbuild}/${DOWNLOAD_FILE}" "git pull"
    \git pull >> "${tmpbuild}/${DOWNLOAD_FILE}" 2>&1
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

__make_with_args()
{
  typeset tmpbuild="$1"
  typeset application="$2"
  typeset ignore_failure="${3:-0}"
  typeset subdir="$4"
  shift 4

  typeset markargs="$@"
  print_btf_detail --msg "Compiling/Linking '${application}' " --prefix "${__INFO_PREFIX}" --tab-level 2 >&2
  typeset RC=1

  cd "${tmpbuild}/${subdir}" >/dev/null 2>&1
  \date > "${tmpbuild}/${BUILD_FILE}"
  __record_command_2_file "${tmpbuild}/${BUILD_FILE}" 'make'
  \make >> "${tmpbuild}/${BUILD_FILE}" 2>&1
  RC=$?

  if [ "${ignore_failure}" -eq 0 ]
  then
    printf "%s\n" "Error condition at end of make = ${RC}" >> "../${BUILD_FILE}"

    if [ "${RC}" -ne 0 ]
    then
      cd "${current_dir}" > /dev/null 2>&1
      return "${RC}"
    fi
  fi

  cd "${tmpbuild}" >/dev/null 2>&1

  if [ "${ignore_failure}" -eq 0 ]
  then
    return "${RC}"
  else
  	return 0
  fi
}

__record_command_2_file()
{
  typeset filename="$1"
  shift
  typeset cmd="$@"

  if [ ! -f "${filename}" ]
  then
    print_btf_detail --msg "${cmd}" --prefix "${__INFO_PREFIX}" --tab-level 1 >&2
  else
    printf "%s\n" "${cmd}" >> "${filename}"
  fi
  return 0
}

find_application()
{
  typeset application="$1"
  typeset passthru="$2"

  application="$( printf "%s\n" "${application}" | \tr -s ' ' | \tr -d ' ' )"
  if [ -z "${application}" ]
  then
    printf "%d\n" 0
    return 1
  fi
  shift 1
  typeset suppress="${1:-0}"

  [ "${suppress}" -eq 0 ] && print_btf_detail --msg "Looking for <${application}>..." --prefix "${__INFO_PREFIX}" >&2

  \which "${application}" >/dev/null 2>&1
  if [ $? -eq 0 ]
  then
    printf "%d\n" 1
    [ "${suppress}" -eq 0 ] && print_btf_detail --msg 'Found' --tab-level 1 --prefix "${__INFO_PREFIX}" --use-color '\033[1;32m' --newline-count 1 >&2
  else
    [ "${suppress}" -eq 0 ] && print_btf_detail --msg 'Requested' --tab-level 1 --prefix "${__WARN_PREFIX}" --use-color '\033[1;33m' --newline-count 2 >&2
    printf "%s\n" 0
  fi
  return 0
}

handle_application()
{
  typeset application="$1"
  application="$( printf "%s\n" "${application}" | \tr -s ' ' | \tr -d ' ' )"
  [ -z "$1" ] && return 1

  typeset found_app="$( find_application "$1" )"
  [ -n "${FORCE_APPLICATION_BUILD}" ] && [ "${FORCE_APPLICATION_BUILD}" -eq 1 ] && found_app=0

  if [ "${found_app}" -eq 0 ]
  then
    if [ "${FORCE_INSTALL}" -eq 1 ]
    then
      printf "%s\n\n" "Building '${application}' forced." >&2
      buildapp='YES'
    else
      buildapp=$( request_build_support_application "${application}" )
    fi

    if [ "${buildapp}" == 'YES' ]
    then
      if [ -f "build_prereqs/build_${application}.sh" ]
      then
        eval "source build_prereqs/build_${application}.sh"
        if [ $? -ne 0 ]
        then
          print_btf_detail --msg "Unable to properly build '${application}'" --prefix "${__ERROR_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
          __SETUP_COMPLETE_SUCCESSFULLY=$(( __SETUP_COMPLETE_SUCCESSFULLY - 1 ))
          return 1
        fi
      else
      	print_btf_detail --msg "Unable to properly build '${application}' ( no handler file found )" --prefix "${__ERROR_PREFIX}" --tab-level 1 --use-color '\033[1;31m' >&2
        __SETUP_COMPLETE_SUCCESSFULLY=$(( __SETUP_COMPLETE_SUCCESSFULLY - 1 ))
      fi
    fi
  fi
  return 0
}

import_old_prebuilts()
{
  typeset reqapps="$1"

  if [ -f "${SLCF_SHELL_TOP}/.preconfigured_paths.txt" ]
  then
    while read -r line 
    do
      __addpath="$( printf "%s\n" "${line}" | \cut -f 1 -d ':' )"
      __appname="$( printf "%s\n" "${line}" | \cut -f 2 -d ':' )"

      print_btf_detail --msg "Looking for <${__appname}>..." --prefix "${__INFO_PREFIX}" >&2

      if [ -d "${__addpath}" ]
      then
        export PATH="${__addpath}:${PATH}"
        printf "%s\n" "${line}" >> "${SLCF_SHELL_TOP}/.preconfigured_paths.txt.new"
        reqapps="$( printf "%s\n" ${reqapps} | \grep -v "${__appname}" )"
        print_btf_detail --msg 'Prebuilt' --tab-level 1 --prefix "${__INFO_PREFIX}" --use-color '\033[1;32m' >&2
      else
        reqapps+=" ${__appname}"
        #print_btf_detail --msg 'Removed from preconfiguration.  Need rebuild...' --tab-level 1 --prefix "${__WARN_PREFIX}"
      fi
    done < "${SLCF_SHELL_TOP}/.preconfigured_paths.txt"

    [ -f "${SLCF_SHELL_TOP}/.preconfigured_paths.txt.new" ] && \mv -f "${SLCF_SHELL_TOP}/.preconfigured_paths.txt.new" "${SLCF_SHELL_TOP}/.preconfigured_paths.txt"
    reqapps="$( printf "%s\n" ${reqapps} | \sort | \uniq )"
  fi

  printf "%s\n" "${reqapps}"
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

[ -n "${__need_app_builds}" ] && __need_app_builds="$( printf "%s\n" ${__need_app_builds} | \sort | \uniq )"
