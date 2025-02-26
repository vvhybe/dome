#!/bin/bash

run_sync() {
  run_hook "pre_sync"
  
  local repo_path=$(get_config_value ".meta.local_path" | sed "s|~|$HOME|")
  local ignore_file="$repo_path/.domeignore"

  # Repo -> Home (preserve permissions, handle hidden files)
  rsync -rlptD --filter="merge $ignore_file" "$repo_path/" "$HOME/"

  # Home -> Repo (reverse sync with conflict detection)
  rsync -rlptD --filter="merge $ignore_file" --dry-run "$HOME/" "$repo_path/" | grep -q "^*deleting\|^>f\+"
  
  if [ $? -eq 0 ]; then
    echo "Conflict detected! Use 'dome resolve' to review changes"
  else
    rsync -rlptD --filter="merge $ignore_file" "$HOME/" "$repo_path/"
  fi

  run_hook "post_sync"
}

