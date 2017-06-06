#!/bin/bash

_cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${_cwd}/lib/libRepo.sh" "sft.cern.ch"


# Directory to work on
_rootBase="lcg"

# Build the full path to the directory
_rootPath="${_repoPath}/${_rootBase}"

# Loop on all files in the directory
for _x in $(find "${_rootPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do

  _xTree="${_rootBase}/${_x}"
  _xPath="${_rootPath}/${_x}"

  if [[ -d "${_xPath}" ]]; then
    # Do not go deep on some trees
    if   [[ "${_x}" == "contrib"    ]]; then
      f_directory_tree "${_xTree}"
    elif [[ "${_x}" == "dev"        ]]; then
      f_directory_tree "${_xTree}"
    elif [[ "${_x}" == "etc"        ]]; then
      f_directory_tree "${_xTree}"
    elif [[ "${_x}" == "git-2.9.3"  ]]; then
      f_directory_tree "${_xTree}"
    elif [[ "${_x}" == "lcgcmake"   ]]; then
      f_directory_tree "${_xTree}"
    elif [[ "${_x}" == "lcgjenkins" ]]; then
      f_directory_tree "${_xTree}"
    else
      # By default, go deep into the remaining trees
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
    fi
  else
    f_directory_tree "${_xTree}"
  fi
done

f_root_tree "${_rootBase}"
