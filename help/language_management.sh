#!/usr/bin/env bash

###############################################################################
# Copyright (c) 2017.  All rights reserved. 
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

__usage_language_management()
{
  typeset newline_marker="$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
  typeset tab_marker="$( __extract_value 'DISPLAY_TAB_MARKER' )"
  
  typeset divider=$( printf "%s" "$( __extract_value 'DIVIDER' )${newline_marker}" )

  typeset menu=$( help_banner 'Supported Language Selection Flags' )

  menu+="${divider}"
  menu+="${newline_marker}"

  menu+=$( printf "%s" "${tab_marker}      --display-extensions    --> [ TBD ] Display to the screen the known extension support and exit.${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}      --insert-extension <>   --> Add extension type with associated driver program${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}                                      for test file(s) [ ext:<comp>|<link>|<exe>:<wrapper> ]${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}      --select-extension <>   --> Select extension(s) type with associated driver program${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}                                      for test file(s) [ ext:<comp>|<link>|<exe>:<wrapper> ]${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}      --remove-extension <>   --> [ TBD ] Delete extension type with associated driver program${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}                                      for test file(s) [ ext ]${newline_marker}${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "Multiple command line arguments can be used concurrently to support combinations of languages${newline_marker}" )
  
  menu+="${newline_marker}"
  menu+=$( help_banner 'Examples using command line flags' )
  menu+=$( printf "%s" "--> Example to add a new extension wrapper for the harness.  This provides${newline_marker}" )
  menu+=$( printf "%s" "--> a means to support files with <.abc> extension via the use the \"abccomp\" compiler${newline_marker}" )
  menu+=$( printf "%s" "--> the \"abclink\" for the linker and the \"abcexe\" executable.  The fullpath to the${newline_marker}" )
  menu+=$( printf "%s" "--> supporting shell wrapper is also needed to launch matching tests.${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}--insert-extension \"abc:abcomp|abclink|abcexe:<path/to/abc_wrapper.sh>\"${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "--> Example to only allow tests of a particular extension type (\".py\" in this example) to run.${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}--select-extension 'py:||python:python_wrapper'${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "--> Example to remove a pre-existing supported extension type to deselect tests${newline_marker}" )
  menu+=$( printf "%s" "--> (\".java\" in this example) from running.${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}--remove-extension 'java'${newline_marker}${newline_marker}" )
  menu+="${newline_marker}"
  
  printf "%s\n" "${menu}"
  return 0 
}
