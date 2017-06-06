#!/bin/bash

_cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${_cwd}/lib/libRepo.sh" "atlas.cern.ch"


# Directory to work on
_rootBase="repo/sw/software/i686-slc5-gcc43-opt"

# Build the full path to the directory
_rootPath="${_repoPath}/${_rootBase}"

# Loop on all files in the directory
for _x in $(find "${_rootPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do

  _xTree="${_rootBase}/${_x}"
  _xPath="${_rootPath}/${_x}"

  if [[ -d "${_xPath}" ]]; then
    for _y in $(find "${_xPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do
      _yTree="${_xTree}/${_y}"
      f_directory_tree "${_yTree}"
    done
  else
    f_directory_tree "${_xTree}"
  fi
done

f_root_tree "${_rootBase}"
