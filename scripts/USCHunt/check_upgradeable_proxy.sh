#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <path>"
  exit 1
fi

path=$1

if [ ! -d "$path" ]; then
  echo "Error: The specified path does not exist."
  exit 1
fi

for dir in "$path"/*/; do
  dir_name=$(basename "$dir")
  
  echo "Entering directory: $dir_name"
  
  cd $dir

  version=$(head -n 1 *.version)

  solc-select install $version
  solc-select use $version

  for file in *.sol; do

    slither $file --detect proxy-patterns 2>"$file-report".txt
    # Check if the string is present in the file
    if grep -q 'is an upgradeable proxy' "$file-report".txt; then
      touch "upgradeable"
    else
      touch "proxy-not-upgrade"
    fi
  done

  cd -
done
