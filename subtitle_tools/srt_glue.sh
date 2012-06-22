#!/bin/bash

# srt_glue.sh [options] <input-srt-file>
#   [-h|--help]                   # this help
#   [-d|--debug|-v|--verbose]     # be verbose and print debug messages
#   [--mod-scale=<scale-float>]   # modify floating scale            [def:1.000]
#   [--mod-offset=<offset-float>] # modify offset movement           [def: 0.00]
#   [--mod-begin=<new-begin>]     # new 1st subtitle start time         [def: -]
#   [--mod-end=<new-end>]         # new last subtitle end time          [def: -]
#   [--mod-ts-a=<ts>@<new-ts>]    # old timestamp <ts> -> new <new-ts>  [def: -]
#   [--mod-ts-a=<nr>@<new-ts>]    # subtitle <nr> move to time <new-ts> [def: -]
#   [--mod-ts-b=<ts>@<new-ts>]    # old timestamp <ts> -> new <new-ts>  [def: -]
#   [--mod-ts-b=<nr>@<new-ts>]    # subtitle <nr> move to time <new-ts> [def: -]
#   <input-srt-file>
#
# srt_glue.sh modifies input srt subtitle file timing. Modified srt file
# is provided on stdout.
# There are three ways of subtitle modification:
# a] providing precise scale and offset floats (--scale=S, --offset=O)
# b] enlarging / shrinking subtitle providing new begin and end
#    (--mod-begin=NB, --mod-end=NE)
# c] enlarging / shrinking subtitle by sticking two timestamps to their new
#    timestamps (--mod-ts-a=..., --mod-ts-b=...)
# At least one of modification method needs to be supplied otherwise modified
# output subtitle file will be identical.
#
# by F_II

# used variables
# ###########################################################################
ifile=
sw_scale=
sw_offset=
sw_mod_begin=
sw_mod_end=
sw_mod_ts_a_old=
sw_mod_ts_a_new=
sw_mod_ts_b_old=
sw_mod_ts_b_new=
sw_debug=0
AWK="gawk"

# local functions
# ###########################################################################
# time_reformat ( <input-time-stamp> [debug-mode] [--out-float] )
function time_reformat ()
{
  local ecode=0
  local out_str=""
  
  if [[ "$1" =~ "([0-9]+):([0-5]?[0-9]):([0-5]?[0-9])[\.,]([0-9]+)" ]]; then
    # hour:min:sec,fract
    out_str="$(( (60*60*${BASH_REMATCH[1]}) + (60*${BASH_REMATCH[2]}) + \
                 ${BASH_REMATCH[3]} )).${BASH_REMATCH[4]}"
  elif [[ "$1" =~ "([0-9]+):([0-5]?[0-9]):([0-5]?[0-9])[\.,]?" ]]; then
    # hour:min:sec[,]
    out_str="$(( (60*60*${BASH_REMATCH[1]}) + (60*${BASH_REMATCH[2]}) + \
                 ${BASH_REMATCH[3]} )).0"
  elif [[ "$1" =~ "([0-9]+):([0-5]?[0-9])[\.,]([0-9]+)" ]]; then
    # min:sec,fract
    out_str="$(( (60*${BASH_REMATCH[1]}) + ${BASH_REMATCH[2]} )).${BASH_REMATCH[3]}"
  elif [[ "$1" =~ "([0-9]+):([0-5]?[0-9])[\.,]?" ]]; then
    # min:sec,fract
    out_str="$(( (60*${BASH_REMATCH[1]}) + ${BASH_REMATCH[2]} )).0"
  elif [[ "$1" =~ "([0-9]+)[\.,]([0-9]+)" ]]; then
    # min:sec,fract
    out_str="$(( ${BASH_REMATCH[1]} )).${BASH_REMATCH[2]}"
  elif [[ "$1" =~ "([0-9]+)[\.,]" ]]; then
    # min:sec,fract
    out_str="$(( ${BASH_REMATCH[1]} )).0"
  elif [[ "$1" =~ "[0-9]+" ]]; then
    # no change
    if [[ "$*" =~ "--out-float" ]]; then
      out_str="$1.0"
    else
      out_str="$1"
    fi
    
  else
    # warning invalid syntax
    ecode=1
  fi
  
  # debug info
  [ "$2" == "1" ] && echo "DEBUG>time_reformat($1)>${out_str}<" 1>&2
  
  echo "${out_str}"
  return ${ecode}
}

# parse the parameters
# ###########################################################################
while [ -n "$1" ]; do

  if   [[ "$1" =~ "^(--debug|-d|--debug-mode)$" ]]; then
    sw_debug=1
  elif [[ "$1" =~ "^(--help|-h)" ]]; then
    awk '{if((NR>2)&&(NF==0)){d=1} if((d!=1)&&(NR>2)){print substr($0,2)}}' $0
    exit 0
  elif [[ "$1" =~ "^(--scale=|--mod-scale=)([+\-]*[0-9.]+)" ]]; then
    sw_scale=${BASH_REMATCH[2]}
  elif [[ "$1" =~ "^(--offset=|--mod-offset=)([+\-]*[0-9.]+)" ]]; then
    sw_offset=${BASH_REMATCH[2]}
  elif [[ "$1" =~ "^(--mod-begin=)([0-9.,:]+)" ]]; then
    sw_mod_begin=${BASH_REMATCH[2]}
    sw_mod_begin=$(time_reformat ${sw_mod_begin} ${sw_debug})
  elif [[ "$1" =~ "^(--mod-end=)([0-9.,:]+)" ]]; then
    sw_mod_end=${BASH_REMATCH[2]}
    sw_mod_end=$(time_reformat ${sw_mod_end} ${sw_debug})
  elif [[ "$1" =~ "^(--mod-ts-a=)([0-9.,:]+)@([0-9.,:]+)" ]]; then
    sw_mod_ts_a_old=${BASH_REMATCH[2]}
    sw_mod_ts_a_old=$(time_reformat ${sw_mod_ts_a_old} ${sw_debug})
    sw_mod_ts_a_new=${BASH_REMATCH[3]}
    sw_mod_ts_a_new=$(time_reformat ${sw_mod_ts_a_new} ${sw_debug} --out-float)
  elif [[ "$1" =~ "^(--mod-ts-b=)([0-9.,:]+)@([0-9.,:]+)" ]]; then
    sw_mod_ts_b_old=${BASH_REMATCH[2]}
    sw_mod_ts_b_old=$(time_reformat ${sw_mod_ts_b_old} ${sw_debug})
    sw_mod_ts_b_new=${BASH_REMATCH[3]}
    sw_mod_ts_b_new=$(time_reformat ${sw_mod_ts_b_new} ${sw_debug} --out-float)
  elif [ -r "$1" ]; then
    ifile=$1
  fi
  
  shift
done

# switch to profiler/debugger in debug mode
if [ "${sw_debug}" == "1" ]; then
  which pgawk &>/dev/null && AWK="pgawk"
fi

# logging to stderr
echo "input-file:${ifile}" 1>&2
#echo "scale:${sw_scale}, offset:${sw_offset}" 1>&2
#echo "mod_begin:${sw_mod_begin}, mod_end:${sw_mod_end}" 1>&2
#echo "mod_ts_a:${sw_mod_ts_a_old} -> ${sw_mod_ts_a_new}" 1>&2
#echo "mod_ts_b:${sw_mod_ts_b_old} -> ${sw_mod_ts_b_new}" 1>&2

# main processing
# ###########################################################################
core_params="-v mod_offset=${sw_offset} -v mod_scale=${sw_scale} \
  -v debug=${sw_debug} -v mod_begin=${sw_mod_begin} -v mod_end=${sw_mod_end} \
  -v mod_ts_a_old=${sw_mod_ts_a_old} -v mod_ts_a_new=${sw_mod_ts_a_new} \
  -v mod_ts_b_old=${sw_mod_ts_b_old} -v mod_ts_b_new=${sw_mod_ts_b_new}"

[ "${sw_debug}" == "1" ] && echo "DEBUG>${core_params}<" 1>&2


if [ -z "${ifile}" ]; then
  # stdin read
  ${AWK} ${core_params} -f $(dirname $0)/subtitle_tools_funcs.awk \
                        -f $(dirname $0)/srt_glue.awk
else
  # file read
  ${AWK} ${core_params} -f $(dirname $0)/subtitle_tools_funcs.awk \
                        -f $(dirname $0)/srt_glue.awk ${ifile}
fi


# ###########################################################################
# eof
# ###########################################################################
