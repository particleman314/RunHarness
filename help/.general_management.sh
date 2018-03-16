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

__usage_general_management()
{
  typeset newline_marker="$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
  typeset tab_marker="$( __extract_value 'DISPLAY_TAB_MARKER' )"
  typeset divider=$( printf "%s" "$( __extract_value 'DIVIDER' )${newline_marker}" )

  typeset menu=$( help_banner 'General Options' )

  menu+="${divider}"
  menu+="${newline_marker}"

  #typeset dblnewline="${newline_marker}${newline_marker}"
  typeset dblnewline="${newline_marker}"

  menu+=$( printf "%s" "${tab_marker}-c|--copy-back <>           --> [TBD] Determine location for deposition of results [ IP:user:pwd:dir ]${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}-D|--define <>              --> Allow user defines to be set on commandline.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --dryrun                 --> Run as normal but don't exercise any tests.${dblnewline}" )

  menu+=$( printf "%s" "${tab_marker}-h|--help                   --> Show the front page usage screen.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --load-userdata <>       --> Allow reading of user data for initialization.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --manage-build-system    --> Designate the build system in use for file retrieval.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}-q|--quiet                  --> Suppress some normal output to be less chatty.${dblnewline}" )
  #menu+=$( printf "%s" "${tab_marker}   --silent                 --> Suppress most output.  Useful within scripted environments.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}-v|--verbose                --> Expand output from harness for detailed tracing.${dblnewline}" )
  #menu+=$( printf "%s" "${tab_marker}   --delay-summary          --> Show pass/fail/skip summary at end of all test processing${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}   --show-summary           --> Show summary breakdown for results${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --usage                  --> Show the front page usage screen.${dblnewline}" )

  menu+="${newline_marker}"
  printf "%s\n" "${menu}"
  return "${PASS}"
}
