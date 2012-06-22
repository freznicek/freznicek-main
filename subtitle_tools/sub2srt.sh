#!/bin/bash

# sub2srt.sh [-h|--help]                # this help
#            [--rate=<rate-float>]      # rate for sub -> srt conversion
#            <input-sub-file>           # input sub subtitle file
#
# sub2srt.sh converts sub subtitle file to srt subtitle file (stdout)
#
# by F_II

ifile=
sw_rate=25

for i_sw in $*; do
  if [[ "${i_sw}" =~ "^(--rate=)([0-9.]+)" ]]; then
    sw_rate=${BASH_REMATCH[2]}
  elif [[ "${i_sw}" =~ "^(--help|-h)" ]]; then
    head -8 $0 | tail -6 | awk '{print substr($0,2)}'
    exit 0
  elif [ -r "${i_sw}" ]; then
    ifile=${i_sw}
  fi
done

# export LANG="en_US.UTF-8"
export LANG=C

# main processing
if [ -z "${ifile}" ]; then
  # stdin read
  gawk -v rate=${sw_rate} -f $(dirname $0)/subtitle_tools_funcs.awk \
                          -f $(dirname $0)/sub2srt.awk
else
  # file read
  gawk -v rate=${sw_rate} -f $(dirname $0)/subtitle_tools_funcs.awk \
                          -f $(dirname $0)/sub2srt.awk ${ifile}
fi


# eof
