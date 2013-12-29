#!/bin/bash

# Pulseaudio linux command-line recorder
# https://github.com/freznicek/freznicek-main/tree/master/pulseaudio_recorder
# by freznicek

function myexit ()
{
  echo "ERROR:$1"
  exit $2
}


echo "Initial checks:"
# check presence of parec / pactl / sox

which pactl &>/dev/null || myexit ".pactl not found, cannot recover!" 1
echo ".pactl ok $(which pactl 2>/dev/null | head -1)"
which parec &>/dev/null || myexit ".parec not found, cannot recover!" 1
echo ".parec ok $(which parec 2>/dev/null | head -1)"
which sox &>/dev/null || myexit ".sox not found, cannot recover!" 1
echo ".sox ok $(which sox 2>/dev/null | head -1)"
which lame &>/dev/null || myexit ".lame not found, cannot recover!" 1
echo ".lame ok $(which lame 2>/dev/null | head -1)"


# assign the output filename
out_fn="out.$(date +%Y%m%d_%H%M%S).wav"
[ -n "$1" ] && out_fn=$1
echo "Output filename: ${out_fn}"



# check that default monitor is correct
echo "Pulseaudio default sink and monitor checks:"
default_sink=$(pactl stat | grep 'Default Sink:' | awk '{print $NF}')
default_monitor="${default_sink}.monitor"

pactl list | grep -q "${default_monitor}" || \
  myexit ".pulseaudio monitor not found, cannot recover!" 2
echo ".default sink: ${default_sink}"
echo ".default monitor: ${default_monitor}"

echo "Start playback... (hit enter to start recording)"
read x

echo "Recording... (press CTRL-C to exit)"
parec -d "${default_monitor}" | sox -t raw -r 44100 -sLb 16 -c 2 - ${out_fn}

ls -lah ${out_fn}

echo "WAV to MP3 Conversion..."
#lame -h -b 192 "${out_fn}" "$(echo ${out_fn} | sed 's/wav$/mp3/g')"
lame -V 3 "${out_fn}" "$(echo ${out_fn} | sed 's/wav$/mp3/g')"

echo "Summary:"
ls -lah ${out_fn} $(echo ${out_fn} | sed 's/wav$/mp3/g')

#eof
