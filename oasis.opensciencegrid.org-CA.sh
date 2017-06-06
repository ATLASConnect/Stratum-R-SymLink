#!/bin/bash

_cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${_cwd}/lib/libRepo.sh" "oasis.opensciencegrid.org"

# Directory to work on
_rootBase="mis"

# Build the full path to the directory
_rootPath="${_repoPath}/${_rootBase}"

# Loop on all files in the directory
for _x in $(find "${_rootPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do

  _xTree="${_rootBase}/${_x}"
  _xPath="${_rootPath}/${_x}"

  # Handle some areas at one level
  if   [[ "${_x:0:12}" == "certificates" ]]; then
    f_directory      "${_xTree}"
  else
    :
  fi
done

f_root "mis"
