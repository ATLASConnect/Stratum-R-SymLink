#!/bin/bash

_cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${_cwd}/lib/libRepo.sh" "atlas-condb.cern.ch"

# Directory to work on
_rootBase="/"

# Build the full path to the directory
_rootPath="${_repoPath}/${_rootBase}"

# Loop on all files in the directory
for _x in $(find "${_rootPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do
  _rootTree="${_rootBase}/${_x}"

  if [[ "${_x}" == "repo" ]]; then
    f_directory_tree "${_rootTree}"
  else
    f_directory "${_rootTree}"
  fi

done

f_root_tree "${_rootBase}"
