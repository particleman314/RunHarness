#!/usr/bin/env bash

###
### This is a sample pre-testing setup script where the user
### has the capability of running commands which need to be
### processed in preparation before any testing can proceed
###

\which git >/dev/null 2>&1
[ $? -ne 0 ] && return 1

git ls-remote --exit-code -h "git@sig-gitlab.internal.synopsys.com:klusman/ShellLibrary.git" 1>>"${SLCF_TEMPDIR_STDOUT}" 2>>"${SLCF_TEMPDIR_STDERR}"
[ $? -ne 0 ] && return 1

MY_REPO_AREA="${SLCF_TEMPDIR}/SETUP"

memopts=$( __import_variable --key 'MY_REPO_AREA' --value "${MY_REPO_AREA}" --use-memory "${NO}" --file "${SLCF_SETUP_OPTIONS_FILE}" )
eval "${memopts}"

git clone --progress "git@sig-gitlab.internal.synopsys.com:klusman/ShellLibrary.git" "${MY_REPO_AREA}" 1>>"${SLCF_TEMPDIR_STDOUT}" 2>>"${SLCF_TEMPDIR_STDERR}"
return $?
