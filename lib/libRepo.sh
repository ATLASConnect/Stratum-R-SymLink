#!/bin/bash

# The embedded cvmfs root to be replaced by the local cvmfs root
_cvmfsRoot="/cvmfs"
_QcvmfsRoot="${_cvmfsRoot//\//\/}"
#_QcvmfsRoot=$(echo ${_cvmfsRoot} | sed -e 's/[\/&]/\\&/g')

# Root of all cvmfs repositories
#_repoRoot="$HOME/cvmfs"
_repoRoot="/mnt/c/scratch/sciteam/ddl/stratum-r/cvmfs"
_QrepoRoot="${_repoRoot//\//\/}"
#_QrepoRoot=$(echo ${_repoRoot} | sed -e 's/[\/&]/\\&/g')


# Get the path to this script
_repoCWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# The scripts whch do all the fix'n
_RepoFixRoot="${_repoCWD}/RepoFixRoot.sh"
_RepoFixPath="${_repoCWD}/RepoFixPath.sh"

#################################################################

# What repository are we working on
_repoName="${1}"

# Full path to the repository
_repoPath="${_repoRoot}/${_repoName}"

# CVMFS SymLink file location
_repoSymLinkHome="${_repoPath}/.symlink"

# Temp root for working files
_tmpRoot="/tmp/$(id -un)/symlink.${_repoName}"

# Meke certain the path exists
mkdir -p "${_tmpRoot}"

# The full and working symlink files
_repoFullSymLink="${_repoSymLinkHome}/symlink.${_repoName}"
_repoWorkSymSource="${_tmpRoot}/symlink.${_repoName}-S-$$"
_repoWorkSymTarget="${_tmpRoot}/symlink.${_repoName}-T-$$"
_repoWorkSymUpdate="${_tmpRoot}/symlink.${_repoName}-C-$$"
_repoWorkSymDelete="${_tmpRoot}/symlink.${_repoName}-D-$$"


#################################################################


function f_update_symlink () {

  local _symlinkRoot
  local _symlinkName
  local _symlinkValue
  local _symlinkPath
  local _symlinkRoot
  local _symlinkStatus

  # The root of the symlink to update, strip off the leading and trailing "
  _symlinkRoot="${1}"
  _symlinkRoot="${_symlinkRoot#\"}"
  _symlinkRoot="${_symlinkRoot%\"}"

  # The name of the symlink to update, strip off the leading and trailing "
  _symlinkName="${2}"
  _symlinkName="${_symlinkName#\"}"
  _symlinkName="${_symlinkName%\"}"

  # What is the expected value of this symlink
  _symlinkValue="${3}"
  _symlinkValue="${_symlinkValue#\"}"
  _symlinkValue="${_symlinkValue%\"}"


  # Build the full path to the symlink ignoring null roots
  if [[ "${_symlinkRoot}" == "/" ]]; then
    _symlinkPath="${_repoPath}/${_symlinkName}"
  else
    _symlinkPath="${_repoPath}/${_symlinkRoot}${_symlinkName}"
  fi


  # Remove any trailing /
  _symlinkPath="${_symlinkPath%/}"

  # Get to the root of the symlink
  _symlinkRoot=$(dirname "${_symlinkPath}")


  # Does the source exists as a file, directory or symlink
  if [[ -h "${_symlinkPath}" ]]; then

    # Translate the symlink
    _symlinkReadLink=$(readlink "${_symlinkPath}")

    # Is the symlink already what we want
    if [[ "${_symlinkValue}" == "${_symlinkReadLink}" ]]; then
#     echo "Existing symlink ${_symlinkPath} for ${_symlinkReadLink} is correct"
      return 0
    else
      echo "Removing symlink ${_symlinkPath}"
      echo "   Old target ${_symlinkReadLink}"
      echo "   New target ${_symlinkValue}"
      rm -f "${_symlinkPath}"
    fi

  elif [[ -f "${_symlinkPath}" ]]; then
    echo "Removing existing file      ${_symlinkPath}"
    rm -f  "${_symlinkPath}"

  elif [[ -d "${_symlinkPath}" ]]; then
    echo "Removing existing directory ${_symlinkPath}"
    rm -rf "${_symlinkPath}"

  fi



  # Make certain the path exists where we will create this symlink
  mkdir -p "${_symlinkRoot}"

# echo "Creating symlink ${_symlinkPath} ---> ${_symlinkValue}"
  ln -s "${_symlinkValue}" "${_symlinkPath}" &> /dev/null
  _symlinkStatus=$?

  if [[ ${_symlinkStatus} -ne 0 ]]; then
    echo "Failed to created symlink (${_symlinkStatus}) for ${_symlinkPath} ---> ${_symlinkValue}"
  fi

  return ${_symlinkStatus}

}


#################################################################


function f_delete_symlink () {

  local _symlinkRoot
  local _symlinkName
  local _symlinkPath
  local _symlinkValue
  local _symlinkReadLink
  local _symlinkStatus


  # The root of the symlink to remove, strip off the leading and trailing "
  _symlinkRoot="${1}"
  _symlinkRoot="${_symlinkRoot#\"}"
  _symlinkRoot="${_symlinkRoot%\"}"

  # The name of the symlink to remove, strip off the leading and trailing "
  _symlinkName="${2}"
  _symlinkName="${_symlinkName#\"}"
  _symlinkName="${_symlinkName%\"}"

  # What is the expected value of this symlink
  _symlinkValue="${3}"
  _symlinkValue="${_symlinkValue#\"}"
  _symlinkValue="${_symlinkValue%\"}"


  # Build the full path to the symlink ignoring null roots
  if [[ "${_symlinkRoot}" == "/" ]]; then
    _symlinkPath="${_repoPath}/${_symlinkName}"
  else
    _symlinkPath="${_repoPath}/${_symlinkRoot}${_symlinkName}"
  fi


  # Remove any trailing /
  _symlinkPath="${_symlinkPath%/}"


  # Make certain this is a symlink before we toast it
  if [[ -h "${_symlinkPath}" ]]; then
#   _symlinkReadLink=$(readlink "${_symlinkPath}")
#   echo "Removing symlink ${_symlinkPath} ---> ${_symlinkValue} (${_symlinkReadLink})"
    rm -f "${_symlinkPath}"
    _symlinkStatus=$?
  else
    echo "Attempt to remove a non-symlink ${_symlinkPath}"
    _symlinkStatus=1
  fi

  return ${_symlinkStatus}

}


#############################################


# Fix the symlinks and permissions on files in the root of a given path

function f_fix_root () {

  local _symlink
  local _symlinkName
  local _symlinkPath
  local _symlinkRoot
  local _symlinkStatus
  local _chmodStatus

  echo

  # The name to extract
  _symlinkName="${1}"

  # Fix a couple of variations we might see as a top level request
  [[ "${_symlinkName}" == "/" ]] && _symlinkName=""
  [[ "${_symlinkName}" == "." ]] && _symlinkName=""


  # Are we doing part of a full repository
  if [[ -z "${_symlinkName}" ]]; then
    _symlinkPath="${_repoPath}"
    _symlinkRoot="${_repoPath}"
    echo "ROOT Create/Update/Delete symlinks in ...  \"${_symlinkPath}\""
  else
    _symlinkPath="${_repoPath}/${_symlinkName}"
    _symlinkRoot="$(dirname ${_symlinkPath})"
    echo "ROOT Create/Update/Delete symlinks in ...  \"${_symlinkPath}\""
  fi


  # Extract only those symlinks which match the path we are working on
  if [[ -f "${_symlinkPath}" ]]; then
    echo "Skipping symlink search since path ......  \"${_symlinkPath}\"  ...  is a file"
  else
    echo -n "Searching source file ...................  \"${_symlinkPath}\"  ...  for symlinks  ...  "
    grep "^\"${_symlinkName}/\"" "${_repoFullSymLink}" > "${_repoWorkSymSource}"
    echo "Found $(echo $(wc -l ${_repoWorkSymSource}) | cut -f1 -d ' ') symlinks"
  fi

  # Process the symlinks only if we created a file
  if [[ -f "${_repoWorkSymSource}" ]]; then

    # Replace any cvmfs roots to the new location on this file system
    echo "Replacing symlink target root of  .......  \"${_cvmfsRoot}\"  ...  with  ...  \"${_repoRoot}\""
    sed -i -e "s/\"${_QcvmfsRoot}\//\"${_QrepoRoot}\//g" "${_repoWorkSymSource}"

    # Sort the file insitu so comm will work properly
    sort -o "${_repoWorkSymSource}" "${_repoWorkSymSource}"

    # Find all existing symlinks which reside down the path we are working on
    echo -n "Searching target path  ..................  \"${_symlinkPath}\"  ...  for symlinks  ...  "
    find ${_symlinkPath} -maxdepth 1 -mindepth 1 -type l -printf "\"%h/\" \"%f\" \"%l\"\n" > "${_repoWorkSymTarget}"
    sed -i -e "s/^\"${_repoPath//\//\/}\//\"/" "${_repoWorkSymTarget}"
    sed -i -e "s/^\"\"/\"\/\"/" "${_repoWorkSymTarget}"

    # Sort the file insitu so comm will work properly
    sort -o "${_repoWorkSymTarget}" "${_repoWorkSymTarget}"

    # How many links did we find
    echo "Found $(echo $(wc -l ${_repoWorkSymTarget}) | cut -f1 -d ' ') symlinks"

    # Find all symlinks we should delete
    echo -n "Searching for symlinks to delete  .......  "
    comm -13 "${_repoWorkSymSource}" "${_repoWorkSymTarget}" > "${_repoWorkSymDelete}"
    echo "Found $(echo $(wc -l ${_repoWorkSymDelete}) | cut -f1 -d ' ') symlinks"

    # The remove must come before the update as this will remove any symlinks with incorrect values
    cat "${_repoWorkSymDelete}" | while read _symlink; do
      _s1=${_symlink%% \"*}
      _s2=${_symlink#*\" }; _s2=${_s2% \"*}
      _s3=${_symlink##*\" }
      f_delete_symlink "$_s1" "$_s2" "$_s3"
    done

    # Find all symlinks we should create/update
    echo -n "Searching for symlinks to update  .......  "
    comm -23 "${_repoWorkSymSource}" "${_repoWorkSymTarget}" > "${_repoWorkSymUpdate}"
    echo "Found $(echo $(wc -l ${_repoWorkSymUpdate}) | cut -f1 -d ' ') symlinks"

    # First remove any symlinks that exist at the target but not at the source
    # Create/update any symlinks that do not exist on the target or have a different value than the source
    cat "${_repoWorkSymUpdate}" | while read _symlink; do
      _s1=${_symlink%% \"*}
      _s2=${_symlink#*\" }; _s2=${_s2% \"*}
      _s3=${_symlink##*\" }
      f_update_symlink "$_s1" "$_s2" "$_s3"
    done

    # Remove the temporary working symlink file
    rm -f "${_repoWorkSymSource}"
    rm -f "${_repoWorkSymTarget}"
    rm -f "${_repoWorkSymUpdate}"
    rm -f "${_repoWorkSymDelete}"

  fi

  # Make certain we did not remove this link/file/directory
  [[ ! -a "${_symlinkPath}" ]] && return 0


  # Fix the permissions on the files in the root of the path
  if [[ -d "${_symlinkPath}" ]]; then
    echo -n "chmod 775 to files in directory  ........  \"${_symlinkPath}\"  ...  "
    find "${_symlinkPath}" -maxdepth 1 -mindepth 1 \! -perm 775 \! -type l -exec chmod 775 {} \;
    _chmodStatus=$?

    if [[ ${_chmodStatus} -eq 0 ]]; then
      echo "done"
    else
      echo "error ${_chmodStatus}"
      return ${_chmodStatus}
    fi
  fi


  # Fix the permissions on the root of the path
  if [[ -d "${_symlinkPath}" ]]; then
    echo -n "chmod 775 to directory  .................  \"${_symlinkPath}\"  ...  "

    if [[ $(stat -c '%a' "${_symlinkPath}") == '775' ]]; then
      _chmodStatus=0
    else
      echo -n "chmod  ...  "
      chmod 775 "${_symlinkPath}"
      _chmodStatus=$?
    fi

    if [[ ${_chmodStatus} -eq 0 ]]; then
      echo "done"
    else
      echo "error ${_chmodStatus}"
      return ${_chmodStatus}
    fi
  fi

  return 0

}


#############################################


# Fix the symlinks and permissions on files in a repository down the given path

function f_fix_path () {

  local _symlink
  local _symlinkName
  local _symlinkPath
  local _symlinkRoot
  local _symlinkStatus
  local _chmodStatus

  echo

  # The name to extract
  _symlinkName="${1}"

  # Fix a couple of variations we might see as a top level request
  [[ "${_symlinkName}" == "/" ]] && _symlinkName=""
  [[ "${_symlinkName}" == "." ]] && _symlinkName=""

  # Are we doing part of a full repository
  if [[ -z "${_symlinkName}" ]]; then
    _symlinkPath="${_repoPath}"
    _symlinkRoot="${_repoPath}"
    echo "PATH Create/Update/Delete symlinks in ...  \"${_symlinkPath}\""
    rm -f "${_repoWorkSymSource}"
    echo -n "Searching repository source file ........  \"${_repoPath}\'  ...  for symlinks ...  "
    sort "${_repoFullSymLink}" > "${_repoWorkSymSource}"
    echo "Found $(echo $(wc -l ${_repoWorkSymSource}) | cut -f1 -d ' ') symlinks"
  else

    # The full path to directory for which we will handle symlinks
    _symlinkPath="${_repoPath}/${_symlinkName}"

    # The parent directory of this path
    _symlinkRoot="$(dirname ${_symlinkPath})"

    echo "PATH Create/Update/Delete symlinks in ...  \"${_symlinkPath}\""

    # Extract only those symlinks which match the path we are working on
    if [[ -f "${_symlinkPath}" ]]; then
      echo "Skipping symlink search since path ......  \"${_symlinkPath}\"  ...  is a file"
    else
      echo -n "Searching source file ...................  \"${_symlinkPath}\"  ...  for symlinks  ...  "
      grep "^\"${_symlinkName}/" "${_repoFullSymLink}" > "${_repoWorkSymSource}"
      echo "Found $(echo $(wc -l ${_repoWorkSymSource}) | cut -f1 -d ' ') symlinks"
    fi
  fi

  # Process the symlinks only if we created a file
  if [[ -f "${_repoWorkSymSource}" ]]; then

    # Replace any cvmfs roots to the new location on this file system
    echo "Replacing symlink target root of  .......  \"${_cvmfsRoot}\"  ...  with  ...  \"${_repoRoot}\""
    sed -i -e "s/\"${_QcvmfsRoot}\//\"${_QrepoRoot}\//g" "${_repoWorkSymSource}"

    # Sort the file insitu so comm will work properly
    sort -o "${_repoWorkSymSource}" "${_repoWorkSymSource}"

    # Find all existing symlinks which reside down the path we are working on
    echo -n "Searching target path  ..................  \"${_symlinkPath}\"  ...  for symlinks  ...  "
    find ${_symlinkPath} -type l -printf "\"%h/\" \"%f\" \"%l\"\n" > "${_repoWorkSymTarget}"
    sed -i -e "s/^\"${_repoPath//\//\/}\//\"/" "${_repoWorkSymTarget}"
    sed -i -e "s/^\"\"/\"\/\"/" "${_repoWorkSymTarget}"

    # Sort the file insitu so comm will work properly
    sort -o "${_repoWorkSymTarget}" "${_repoWorkSymTarget}"

    # How many links did we find
    echo "Found $(echo $(wc -l ${_repoWorkSymTarget}) | cut -f1 -d ' ') symlinks"

    # Find all symlinks we should delete
    echo -n "Searching for symlinks to delete  .......  "
    comm -13 "${_repoWorkSymSource}" "${_repoWorkSymTarget}" > "${_repoWorkSymDelete}"
    echo "Found $(echo $(wc -l ${_repoWorkSymDelete}) | cut -f1 -d ' ') symlinks"

    # The remove must come before the update as this will remove any symlinks with incorrect values
    cat "${_repoWorkSymDelete}" | while read _symlink; do
      _s1=${_symlink%% \"*}
      _s2=${_symlink#*\" }; _s2=${_s2% \"*}
      _s3=${_symlink##*\" }
      f_delete_symlink "$_s1" "$_s2" "$_s3"
    done

    # Find all symlinks we should create/update
    echo -n "Searching for symlinks to update  .......  "
    comm -23 "${_repoWorkSymSource}" "${_repoWorkSymTarget}" > "${_repoWorkSymUpdate}"
    echo "Found $(echo $(wc -l ${_repoWorkSymUpdate}) | cut -f1 -d ' ') symlinks"

    # First remove any symlinks that exist at the target but not at the source
    # Create/update any symlinks that do not exist on the target or have a different value than the source
    cat "${_repoWorkSymUpdate}" | while read _symlink; do
      _s1=${_symlink%% \"*}
      _s2=${_symlink#*\" }; _s2=${_s2% \"*}
      _s3=${_symlink##*\" }
      f_update_symlink "$_s1" "$_s2" "$_s3"
    done

    # Remove the temporary working symlink file
    rm -f "${_repoWorkSymSource}"
    rm -f "${_repoWorkSymTarget}"
    rm -f "${_repoWorkSymUpdate}"
    rm -f "${_repoWorkSymDelete}"

  fi


  # Fix the permissions on all files in this path
  if [[ "${_symlinkName}" == "/" ]]; then
    echo -n "chmod 775 to files in path  .............  \"${_repoPath}\"  ...  repository  ...  "
    find "${_repoPath}" \! -perm 775 \! -type l -exec chmod 775 {} \;
    _chmodStatus=$?
  else

    # Make certain we did not remove this link/file/directory
    [[ ! -a "${_symlinkPath}" ]] && return 0

    echo -n "chmod 775 to files in path  .............  \"${_symlinkPath}\"  ...  "

    if   [[ -h "${_symlinkPath}" ]]; then
      echo -n "link  ...  "
      _chmodStatus=0
    elif [[ -d "${_symlinkPath}" ]]; then
      echo -n "directory  ...  "
      find "${_symlinkPath}" \! -perm 775 \! -type l -exec chmod 775 {} \;
      _chmodStatus=$?
    elif [[ -f "${_symlinkPath}" ]]; then
      echo -n "file  ...  "
      if [[ $(stat -c '%a' "${_symlinkPath}") == '775' ]]; then
        _chmodStatus=0
      else
        echo -n "chmod  ...  "
        chmod 775 "${_symlinkPath}"
        _chmodStatus=$?
      fi
    else
      echo -n "UNKNOWN  ... "
      _chmodStatus=254
    fi
  fi

  # How did the chmod finish
  if [[ ${_chmodStatus} -eq 0 ]]; then
    echo "done"
  else
    echo "error ${_chmodStatus}"
    return ${_chmodStatus}
  fi


  # Fix the permissions on the directory of root of the path
  if [[ -d "${_symlinkPath}" ]]; then
    echo -n "chmod 775 to directory  .................  \"${_symlinkPath}\"  ...  "

    if [[ $(stat -c '%a' "${_symlinkPath}") == '775' ]]; then
      _chmodStatus=0
    else
      echo -n "chmod  ...  "
      chmod 775 "${_symlinkPath}"
      _chmodStatus=$?
    fi

    if [[ ${_chmodStatus} -eq 0 ]]; then
      echo "done"
    else
      echo "error ${_chmodStatus}"
      return ${_chmodStatus}
    fi
  fi

  return 0

}


#################################################################


function f_repository () {

  # The directory path to update
  _path="${1}"

  if [[ -z "${_path}" ]]; then
    "${_RepoFixPath}" "${_repoName}"
  else
    f_directory "${_path}"
  fi

}


#################################################################


function f_directory () {

  # The directory path to update
  _path="${1}"

  # If path is the root of all, we dont need it
  [[ "${_path}" == "/" ]] && _path=""
  [[ "${_path}" == "." ]] && _path=""

  # Remove any leading // or /
  _path=${_path##//}
  _path=${_path##/}

  "${_RepoFixPath}" "${_repoName}" "${_path}"

}


#################################################################


function f_directory_tree () {

  # The directory path to update
  _path="${1}"

  # If path is the root of all, we dont need it
  [[ "${_path}" == "/" ]] && _path=""
  [[ "${_path}" == "." ]] && _path=""

  # Remove any leading // or /
  _path=${_path##//}
  _path=${_path##/}


  # Get a list of directories and files to update
  if [[ -z "${_path}" ]]; then
    _fileList=$(find "${_repoPath}" -maxdepth 1 -mindepth 1 ! -type l -printf "%f\n")
    _fileStatus=$?
  else
    if [[ -d "${_repoPath}/${_path}" ]]; then
      _fileList=$(find "${_repoPath}/${_path}" -maxdepth 1 -mindepth 1 ! -type l -printf "%f\n")
      _fileStatus=$?
    else
      _fileList=""
      _fileStatus=0
    fi
  fi

  # Did the find succeed
  if [[ ${_fileStatus} -ne 0 ]]; then
    echo "Unable to get a listing of files in ${_repoPath}/${_path}"
    return ${_fileStatus}
  fi

  # Update each directory or file which we found
  if [[ -z "${_path}" ]]; then
    for _x in ${_fileList}; do
      "${_RepoFixPath}" "${_repoName}" "${_x}"
    done
    "${_RepoFixRoot}" "${_repoName}" ""
  else  
    if [[ -z "${_fileList}" ]]; then
      "${_RepoFixPath}" "${_repoName}" "${_path}"
    else
      for _x in ${_fileList}; do
        "${_RepoFixPath}" "${_repoName}" "${_path}/${_x}"
      done
      "${_RepoFixRoot}" "${_repoName}" "${_path}"
    fi
  fi

  return $?

}


#################################################################


function f_root () {

  # The directory path to update
  _path="${1}"

  # If path is the root of all, we dont need it
  [[ "${_path}" == "/" ]] && _path=""
  [[ "${_path}" == "." ]] && _path=""

  # Remove any leading // or /
  _path=${_path##//}
  _path=${_path##/}

  "${_RepoFixRoot}" "${_repoName}" "${_path}"

}


#################################################################


function f_root_tree () {

  # The directory path to update
  _path="${1}"

  # If path is the root of all, we dont need it
  [[ "${_path}" == "/" ]] && _path=""
  [[ "${_path}" == "." ]] && _path=""

  # Remove any leading // or /
  _path=${_path##//}
  _path=${_path##/}

  # Get a list of directories and files to update
  if [[ -z "${_path}" ]]; then
    "${_RepoFixRoot}" "${_repoName}" ""
  else 
    "${_RepoFixRoot}" "${_repoName}" "${_path}"
    f_root_tree "$(dirname ${_path})"
  fi

  return $?

}


#################################################################
