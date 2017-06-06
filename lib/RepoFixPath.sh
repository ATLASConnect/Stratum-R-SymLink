#!/bin/bash

# Get the path to this script
_repoCWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load up the library with the given repository
source "${_repoCWD}/libRepo.sh"    "${1}"

# The path to fix
_SymlinkName="${2}"

# Fix up the given path
f_fix_path "${_SymlinkName}"
