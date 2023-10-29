#!/bin/bash

# Define the base path
BASE_PATH="/home/ovos/.config/files"

# List of sound types
declare -a sound_types=("start_listening" "end_listening" "acknowledge" "error")

# Loop over each sound type
for sound_type in "${sound_types[@]}"
do
  # Generate the path for the specific sound type
  SOUND_TYPE_PATH="$BASE_PATH/$sound_type"
  
  # Count the number of available mp3 files for this sound type
  num_files=$(ls $SOUND_TYPE_PATH/${sound_type}*.mp3 2>/dev/null | wc -l)

  # If at least one file exists, create a random symlink
  if [[ $num_files -gt 0 ]]; then
    rand_file=$(( ( RANDOM % $num_files ) + 1 ))
    ln -sfn "$SOUND_TYPE_PATH/${sound_type}${rand_file}.mp3" "$BASE_PATH/${sound_type}.mp3"
  fi
done