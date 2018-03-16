#!/usr/bin/env bash

__check_for
assert_failure $?

answer=$( __check_for --key 'MY_KEY' --failure )
assert_false "${answer}"

__addto_internal_variable MY_KEY MY_VALUE
assert_success $?
answer=$( __check_for --key 'MY_KEY' --success )
assert_true "${answer}"

answer=$( __check_for --key 'MY_KEY' --success --prefix 'SPECIAL' )
assert_failure $?

__addto_internal_variable MY_KEY MY_VALUE SPECIAL
answer=$( __check_for --key 'MY_KEY' --success --prefix 'SPECIAL' )
assert_success $?
assert_true "${answer}"
