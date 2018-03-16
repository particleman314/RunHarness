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

__usage_harness_management()
{
  typeset newline_marker="$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
  typeset tab_marker="$( __extract_value 'DISPLAY_TAB_MARKER' )"
  typeset divider=$( printf "%s" "$( __extract_value 'DIVIDER' )${newline_marker}" )

  typeset menu=$( help_banner 'Specific Harness Options' )

  menu+="${divider}"
  menu+="${newline_marker}"

  #typeset dblnewline="${newline_marker}${newline_marker}"
  typeset dblnewline="${newline_marker}"

  menu+=$( printf "%s" "${tab_marker}   --debug                            --> [ TBD ] Enable debugging for tests${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --detail                           --> Enable detail statements to print to screen during testing.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --disallow-return-code-checking    --> Disallow return codes from acting as a separate assertion.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --exclude-dir-patt <>              --> Define exclusion pattern for test directories.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --exclude-file-patt <>             --> Define exclusion pattern for test files.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}-i|--input-file <>                    --> Enable driver file for tests/suite grouping.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --internal-display                 --> Allow the options file to be displayed before running the Canopus Test Harness${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --insert-ext <>                    --> ${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --load-userdata <>                 --> Allow user defined key/value pair(s) file to be added to startup conditions.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --precheck <>                      --> Allow pre-setup script to run before Canopus Test Harness starts processing.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --postcheck <>                     --> Allow post-teardown script to run after Canopus Test Harness finishes processing.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}-r|--random                           --> Randomize determined tests and suites when executing.${dblnewline}" )
  #menu+=$( printf "%s" "${tab_marker}   --redirect <>                      --> Allow user specified redirection of output to file${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --select-ext <>                    --> ${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --setup-check <>                   --> ${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --suite-stop-on-fail               --> Fail the current running suite (and all remaining tests) and bypass running any additional suites.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --sort                             --> Sort groups/files to be launched via alphanumerics${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}   --test-stop-on-fail                --> Fail the current running suite (and all remaining tests) and continue to next suite.${dblnewline}" )
  menu+=$( printf "%s" "${tab_marker}-w|--workflow                         --> Disable sorting/randomizing, by processing all suites in order scanned.${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}                                             Adds capability of determining information about last \"stage\".${dblnewline}" )

  menu+="${newline_marker}"
  printf "%s\n" "${menu}"
  return "${PASS}"
}
