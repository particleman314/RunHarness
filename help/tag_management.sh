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

__usage_tag_management()
{
  typeset newline_marker="$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
  typeset tab_marker="$( __extract_value 'DISPLAY_TAB_MARKER' )"
  typeset divider=$( printf "%s" "$( __extract_value 'DIVIDER' )${newline_marker}" )

  typeset menu=$( help_banner 'Supported Tag Selection Flags' )

  menu+="${divider}"
  menu+="${newline_marker}"

  #typeset dblnewline="${newline_marker}${newline_marker}"
  typeset dblnewline="${newline_marker}"
  
  menu+=$( printf "%s" "${tab_marker}-a|--allow-no-tags         --> Allow test selection without tag definitions in tests when${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}                                   < --use-tags > flag is operational.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --tag <>                --> Define global tag to use for test selection.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --tag-alias <>          --> Define global tag aliases when parsing test selection criteria.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --tag-dependence        --> [ TBD ] Force all global tags to match for test selection (AND operation).${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --tag-file-select <>    --> [ TBD ] Read tag selection file for test selection matching.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}-u|--use-tags              --> Allow for test tags and commandline tagging to be in force.${dblnewline}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "Multiple command line tag arguments can be used concurrently.  Tag dependence is currently${newline_marker}" )
  menu+=$( printf "%s" "experimental (TBD) and likely not to produce the expected results at this time.${newline_marker}" )
  
  menu+="${newline_marker}"
  menu+=$( help_banner 'Examples using command line flags' )
  menu+=$( printf "%s" "--> Example to allow non-tagged tests to be executed.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}--allow-no-tags${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "--> Example to specify multiple tags for test selection.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}--tag Linux --tag x64${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "--> Example to define a tag-alias for test selection search.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}--tag-alias OS=Platform --tag-alias BIT=OSsize${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "--> Example to enforce the use of tags to select tests for execution.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}--use-tags${newline_marker}" )
  menu+="${newline_marker}"
  
  printf "%s\n" "${menu}"
  return "${PASS}"
}
