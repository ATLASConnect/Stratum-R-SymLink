#!/bin/bash

_cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${_cwd}/lib/libRepo.sh" "atlas.cern.ch"


# Directory to work on
_rootBase="repo/sw"

# Build the full path to the directory
_rootPath="${_repoPath}/${_rootBase}"


# Find each directory in the root and submit separately
for _x in $(find ${_rootPath} -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do

  _rootTree="${_rootBase}/${_x}"

  # Ignore some directories
  if   [[ "${_x}" == "ASG"      ]]; then
    :
  elif [[ "${_x}" == "software" ]]; then
    :
  else
    f_directory_tree "${_rootTree}"
  fi

done

f_root_tree "${_rootBase}"
