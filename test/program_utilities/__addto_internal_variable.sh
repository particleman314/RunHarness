#!/usr/bin/env bash

__addto_internal_variable
assert_failure $?

__addto_internal_variable MY_KEY
assert_failure $?

if [ -z "${__PROGRAM_VARIABLE_PREFIX}" ]
then
  __addto_internal_variable MY_KEY MY_VALUE
  assert_failure $?
else
  __addto_internal_variable MY_KEY MY_VALUE
  assert_success $?
  assert_equals "$( __extract_value 'MY_KEY' )" 'MY_VALUE'
fi

__addto_internal_variable MY_SPECIAL_KEY MY_SPECIAL_VALUE SPECIAL
assert_success $?
assert_equals "$( __extract_value 'MY_SPECIAL_KEY' )" 'MY_SPECIAL_VALUE'
assert_equals "${SPECIAL_MY_SPECIAL_KEY}" 'MY_SPECIAL_VALUE'
