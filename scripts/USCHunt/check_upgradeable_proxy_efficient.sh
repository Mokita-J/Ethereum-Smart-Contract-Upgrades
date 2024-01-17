#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <path_to_csv_file> <path_to_output_dir> <Etherscan_API_KEY>"
  exit 1
fi

csv_file="$1"
output_dir="$2"
output_file="$output_dir/upgradeable_proxies.csv"
api_key="$3"

# Check if the file exists
if [ ! -f "$csv_file" ]; then
  echo "Error: File not found - $csv_file"
  exit 1
fi

# Check if the output file exists
if [ -e "$output_file" ]; then
  rm "$output_file"
fi

touch "$output_file"

while IFS= read -r row; do
  slither_output=$(slither "$row" --detect proxy-patterns --etherscan-apikey "$api_key" 2>&1)
  if [[ "$slither_output" == *"is an upgradeable proxy"* ]]; then
    echo "$row" >> "$output_file"
  fi
  sleep 0.2
done < "$csv_file"
