#!/bin/bash

# pkg_deplist.sh
#   lists all installed packages on your rpm based linux system including dependencies
#
#  Usage:
#    ./pkg_deplist.sh > pkgs.db
#


# sort_uniq ( <word> [word] )
#  sorts and uniques the list of words
function sort_uniq ()
{
  local i_par=
  for i_par in $*; do
    echo ${i_par}
  done | sort -u | awk '{printf $1 " "}'
}

# cache_lookup ( <pkg-name> )
#  searches the pkg cache for package <pkg-name>
#  returns 0/1 ~ found / not found
function cache_lookup ()
{
  local i=0
  local found=
  for((i=0;i<${#qarr[*]};i++)); do
    if [ "$1" == "${qarr[${i}]}" ]; then
      found=${aarr[${i}]}
      break
    fi
  done
  echo ${found}
  [ -n "${found}" ] && return 0 || return 1
}

# cache arrays
qarr=()
aarr=()

pkgs=$(rpm -qa --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n')

for i_pkg in ${pkgs}; do
  # browse packages
  dep_list=$(rpm -qR ${i_pkg} | \
             awk '{if(($1 ~ /^(lib|ld-linux)/)&&($1 ~ /so/)){i=index($1,"(");if(i>0){print substr($1,1,i-1)}else{print $1}}else{print $1}}' | \
             awk '{if($1 ~ /^rpmlib/){print "rpm"}else{print $1}}' | sort -u)
  #dep_list=$(sort_uniq ${dep_list})
  dep_str=""
  i_pkg_short="$(rpm -q --queryformat '%{NAME}' ${i_pkg})"
  
  #echo "DEBUG:${i_pkg},${i_pkg_short},${dep_list}"
  
  # print package name
  echo -n "${i_pkg} :"
  
  for i_dep in ${dep_list}; do
    # check package
    r_dep=
    
    # check cache
    c_out=$(cache_lookup ${i_dep})
    c_ecode=$?
    if [ "${c_ecode}" != "0" ]; then
      # not found in cache
      rpm -q "${i_dep}" &> /dev/null
      if [ $? == "0" ]; then
        # package add
        r_dep="${i_dep}"
      else
        if [ -e "${i_dep}" ]; then
          # file detected
          str=$(rpm -qf --queryformat '%{NAME}' "${i_dep}" 2>/dev/null)
          if [ "$?" == "0" ]; then
            r_dep="${str}"
          fi
        else
          if [[ "${i_dep}" =~ "^lib" && "${i_dep}" =~ "\.so" ]]; then
            # library found - locate library
            lib_fn=$(locate "${i_dep}" 2>/dev/null | head -1)
            locate "${i_dep}" &>/dev/null
            if [ "$?" == "0" -a -e "${lib_fn}" ]; then
              r_dep="$(rpm -qf --queryformat '%{NAME}' ${lib_fn})"
            fi
          fi
        fi
      fi
    else
      # found in cache - use it
      r_dep=${c_out}
    fi
    
    # apend to the array
    if [ -n "${r_dep}" ]; then
      dep_str="${dep_str} ${r_dep}"
      # add to cache
      if [ "${c_ecode}" != "0" ]; then
        qarr[${#qarr[*]}]="${i_dep}"
        aarr[${#aarr[*]}]="${r_dep}"
      fi
    else
      dep_str="${dep_str} [${i_dep}]"
      # add to cache
      if [ "${c_ecode}" != "0" ]; then
        qarr[${#qarr[*]}]="${i_dep}"
        aarr[${#aarr[*]}]="[${i_dep}]"
      fi
    fi
    
  done
  
  #echo "DEBUG2:${dep_str}"
  
  echo " $(sort_uniq ${dep_str})"
#  echo "${i_pkg} : $(sort_uniq ${dep_str})"
done

# eof