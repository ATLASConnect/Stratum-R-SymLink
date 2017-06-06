#!/bin/bash

_cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${_cwd}/lib/libRepo.sh" "oasis.opensciencegrid.org"


# Directory to work on
_rootBase="/"

# Build the full path to the directory
_rootPath="${_repoPath}/${_rootBase}"

# Loop on all files in the directory
for _x in $(find "${_rootPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do

  _xTree="${_rootBase}/${_x}"
  _xPath="${_rootPath}/${_x}"

  # Go deep for a few areas
  if [[ "${_x}" == "belle" || "${_x}" == "gm2" ]]; then

    if [[ -d "${_xPath}" ]]; then
      for _y in $(find "${_xPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do
        _yTree="${_xTree}/${_y}"
        _yPath="${_xPath}/${_y}"
  
        if [[ -d "${_yPath}" ]]; then
          for _z in $(find "${_yPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do
            _zTree="${_yTree}/${_z}"
            f_directory_tree "${_zTree}"
          done
        else
          f_directory_tree "${_yTree}"
        fi
      done
    else
      f_directory_tree "${_xTree}"
    fi

  else
    f_directory_tree "${_xTree}"
  fi

done

f_root_tree "${_rootBase}"
