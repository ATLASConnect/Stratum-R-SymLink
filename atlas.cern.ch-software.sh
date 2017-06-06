#!/bin/bash

_cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${_cwd}/lib/libRepo.sh" "atlas.cern.ch"


# Directory to work on
_rootBase="repo/sw/software"

# Build the full path to the directory
_rootPath="${_repoPath}/${_rootBase}"


# Find each directory in the root and submit separately
for _x in $(find "${_rootPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do

  _xTree="${_rootBase}/${_x}"
  _xPath="${_rootPath}/${_x}"

  # Ignore some directories
  if   [[ "${_x}" == "AthAnalysisBase"        ]]; then
    if [[ -d "${_xPath}" ]]; then
      for _y in $(find "${_xPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%P\n" | sort); do
        _yTree="${_xTree}/${_y}"
        f_directory_tree "${_yTree}"
      done
    else
      f_directory_tree "${_xTree}"
    fi
  elif [[ "${_x}" == "AthAnalysisSUSY"        ]]; then
    f_directory_tree "${_xTree}"
  elif [[ "${_x}" == "AthSimulationBase"      ]]; then
    f_directory_tree "${_xTree}"
  elif [[ "${_x}" == "AthSimulationBase:21.0" ]]; then
    f_directory_tree "${_xTree}"
  elif [[ "${_x}" == "i686-slc5-gcc43-opt"    ]]; then
    :
  elif [[ "${_x}" == "x86_64-slc5-gcc43-opt"  ]]; then
    :
  elif [[ "${_x}" == "x86_64-slc6-gcc46-opt"  ]]; then
    :
  elif [[ "${_x}" == "x86_64-slc6-gcc47-opt"  ]]; then
    :
  elif [[ "${_x}" == "x86_64-slc6-gcc48-opt"  ]]; then
    :
  elif [[ "${_x}" == "x86_64-slc6-gcc49-opt"  ]]; then
    :
  else
    f_directory_tree "${_xTree}"
  fi

done

f_root_tree "${_rootBase}"
