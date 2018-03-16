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

__usage_dependency_management()
{
  typeset newline_marker="$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
  typeset tab_marker="$( __extract_value 'DISPLAY_TAB_MARKER' )"
  typeset divider=$( printf "%s" "$( __extract_value 'DIVIDER' )${newline_marker}" )

  typeset menu=$( help_banner 'Supported Dependency Selection Flags' )

  menu+="${divider}"
  menu+="${newline_marker}"

  #typeset dblnewline="${newline_marker}${newline_marker}"
  typeset dblnewline="${newline_marker}"

  menu+=$( printf "%s" "${tab_marker}    --dependency-file       --> Allow user to specify the dependency file to interrogate for test organization.${dblnewline}" )  
  menu+="${newline_marker}"
  
  printf "%s\n" "${menu}"
  return 0 
}
