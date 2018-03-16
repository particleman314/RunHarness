#!/usr/bin/env bash

__check_for_preexistence
assert_failure $?

__check_for_preexistence --key 'MY_KEY'
assert_failure "${answer}"

__addto_internal_variable 'MY_KEY' 'MY_VALUE'
__check_for_preexistence --key 'MY_KEY' --value 'MY_VALUE'
assert_success $?

__check_for_preexistence --key 'MY_S_KEY' --value 'MY_S_VALUE'
assert_success $?
