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

__usage_output_management()
{
  typeset newline_marker="$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
  typeset tab_marker="$( __extract_value 'DISPLAY_TAB_MARKER' )"
  typeset divider=$( printf "%s" "$( __extract_value 'DIVIDER' )${newline_marker}" )
  
  typeset menu=$( help_banner 'Supported Output Formatting Flags' )

  menu+="${divider}"
  menu+="${newline_marker}"

  menu+=$( printf "%s" "${tab_marker}-o|--output <>         --> Write test results into requested format${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "${tab_marker}   : email_output           --> Email format${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}   : html_output            --> HTML format [ TBD ] ${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}   : junit_xml_output       --> JUnit XML format${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}   : text_output            --> Textual format${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "${tab_marker}   --output-option <>  --> Define option to be utilized by corresponding output formatter${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "${tab_marker}   : <FORMATTER>:<OPTION>:<VALUE>   --> can be applied to any of the above output formatters${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "${tab_marker}   : full_details [ 0 | 1 ]  --> [text/email]${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}   : use_io       [ 0 | 1 ]  --> [text/email]${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "${tab_marker}   --output-format <>  --> [ TBD ] Define non-standard output formatter${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "Multiple command line outputs can be used concurrently. Personal formats can be${newline_marker}" )
  menu+=$( printf "%s" "provided (TBD) as a means to install or utilize a non-standard formatter for${newline_marker}" )
  menu+=$( printf "%s" "output digestion of results.${newline_marker}" )

  menu+="${newline_marker}"
  menu+=$( help_banner 'Examples using command line flags' )
  menu+=$( printf "%s" "--> Example to include email output generation of results.${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}--output email${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "--> Example to include email output generation and junit-xml style output generation of results.${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}--output email --output junit_xml_output${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "--> Example to request full details for textual output generation of results.${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}--output-option text_output:full_details:1${newline_marker}" )
  menu+="${newline_marker}"
  menu+=$( printf "%s" "--> Example to include non-standard formatter to process generation of results${newline_marker}" )
  menu+=$( printf "%s" "--> This will find the formatter shell file \"/path/to/my/formatter.sh\" and associate${newline_marker}" )
  menu+=$( printf "%s" "--> it with this output type name \"myformat\".${newline_marker}${newline_marker}" )
  menu+=$( printf "%s" "${tab_marker}--output-format \"/path/to/my/formatter.sh|myformat\"${newline_marker}" )
  menu+="${newline_marker}"
  
  printf "%s\n" "${menu}"
  return "${PASS}"
}
