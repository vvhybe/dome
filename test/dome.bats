#!/usr/bin/env bats

setup() {
  # Create temporary directories and files
  export TEMP_DIR=$(mktemp -d)
  export HOME="$TEMP_DIR/home"
  export REPO_DIR="$TEMP_DIR/repo"
  mkdir -p "$HOME"
  mkdir -p "$REPO_DIR"
  
  # Create sample dotfiles in repo (no Git needed)
  mkdir -p "$REPO_DIR/.config/sway" "$REPO_DIR/.config/wofi"
  echo "test config" > "$REPO_DIR/.config/sway/config"
  echo "styles" > "$REPO_DIR/.config/wofi/styles.css"
  echo "alias ls='ls -lha'" > "$REPO_DIR/.bash_aliases.arch"
  echo "alias ll='ls -l'" > "$REPO_DIR/.bash_aliases.debian"
  echo "PS1='\$ '" > "$REPO_DIR/.bashrc"

  # Create .domeignore file
  cat > "$REPO_DIR/.domeignore" <<EOF
.git/
README.md
LICENSE
EOF

  # Create dome config directly for testing
  mkdir -p "$HOME/.config/dome"
  cat > "$HOME/.config/dome/config.yaml" <<EOF
meta:
  repo: "test-only-repo"
  branch: "main"
  local_path: "$REPO_DIR"
hooks:
  conflict_resolver: "meld"
  pre_sync: "echo 'hello world'"
  post_sync: "echo 'sync complete'"
  pre_push: ""
  post_push: ""
  pre_pull: ""
  post_pull: ""
distro_files:
  .bash_aliases:
    arch: ".bash_aliases.arch"
    debian: ".bash_aliases.debian"
EOF

  # Override detect_distro function for testing
  export -f detect_distro
  
  # Make dome script available in PATH
  export PATH="$BATS_TEST_DIRNAME/..:$PATH"
}

teardown() {
  rm -rf "$TEMP_DIR"
}

# Override detect_distro for testing
detect_distro() {
  echo "arch"
}

@test "Validate dome configuration" {
  run dome validate
  [ "$status" -eq 0 ]
  [[ "$output" == *"Configuration is valid"* ]]
}

@test "Invalid configuration detection" {
  # Create config with invalid repo path
  cat > "$HOME/.config/dome/config.yaml" <<EOF
meta:
  repo: "test-only-repo"
  branch: "main"
  local_path: "~/non-existent"
EOF

  run dome validate
  [ "$status" -eq 1 ]
  [[ "$output" == *"Repository path doesn't exist"* ]]
}

@test "Sync in symlink mode" {
  run dome sync
  
  [ "$status" -eq 0 ]
  [ -L "$HOME/.bashrc" ]
  [ -L "$HOME/.config/sway" ]
  [ "$(readlink -f $HOME/.bash_aliases)" = "$REPO_DIR/.bash_aliases.arch" ]
  
  # Verify ignored files not synced
  [ ! -e "$HOME/.domeignore" ]
}

@test "Sync in snapshot mode with backups" {
  # Create existing files
  mkdir -p "$HOME/.config/sway"
  echo "old config" > "$HOME/.config/sway/config"
  echo "old bashrc" > "$HOME/.bashrc"
  
  run dome sync -s
  [ "$status" -eq 0 ]
  
  # Verify backups were created
  local backup_dir
  backup_dir=$(ls -d "$HOME/.config/dome/backups/arch/bak_"* | head -1)
  [ -n "$backup_dir" ]
  [ -f "$backup_dir/.bashrc" ]
  [ -f "$backup_dir/.config/sway/config" ]
  
  # Verify files were copied, not linked
  [ -f "$HOME/.bashrc" ]
  [ ! -L "$HOME/.bashrc" ]
  [ "$(cat $HOME/.bashrc)" = "PS1='\$ '" ]
}

@test "Sync with no backups" {
  # Create existing files
  echo "old bashrc" > "$HOME/.bashrc"
  
  run dome sync -n
  [ "$status" -eq 0 ]
  
  # Verify no backups were created
  [ ! -d "$HOME/.config/dome/backups" ]
}

@test "Distro-specific file mapping" {
  run dome sync
  
  [ "$status" -eq 0 ]
  [ "$(readlink -f $HOME/.bash_aliases)" = "$REPO_DIR/.bash_aliases.arch" ]
  # Debian version should not be linked
  [ ! -e "$HOME/.bash_aliases.debian" ]
}

@test "Handle new files in repo" {
  dome sync
  
  # Add new file to repo
  echo "new config" > "$REPO_DIR/.config/new_config"
  
  run dome sync
  [ "$status" -eq 0 ]
  [ -L "$HOME/.config/new_config" ]
}

@test "Revert from backup" {
  # Create existing files
  echo "original content" > "$HOME/.bashrc"
  
  # Sync to create backup
  dome sync -s
  
  # Modify file
  echo "new content" > "$HOME/.bashrc"
  
  # Revert
  run dome revert
  [ "$status" -eq 0 ]
  
  # Verify file was restored
  [ "$(cat $HOME/.bashrc)" = "original content" ]
}

@test "Validate respects .domeignore" {
  # Add new ignore pattern
  echo ".config/wofi/" >> "$REPO_DIR/.domeignore"
  
  run dome sync
  [ "$status" -eq 0 ]
  
  # Verify ignored directory wasn't synced
  [ ! -e "$HOME/.config/wofi" ]
}

@test "Directory symlink propagates changes" {
  dome sync
  
  # Verify directory is symlinked
  [ -L "$HOME/.config/sway" ]
  
  # Add new file to repo directory
  echo "new file" > "$REPO_DIR/.config/sway/new_file"
  
  # No need to sync again for directory symlinks
  [ -f "$HOME/.config/sway/new_file" ]
  [ "$(cat $HOME/.config/sway/new_file)" = "new file" ]
}

@test "Handle parent directory linking" {
  # Create nested directory structure in repo
  mkdir -p "$REPO_DIR/.config/nested/dir"
  echo "nested file" > "$REPO_DIR/.config/nested/dir/file.txt"
  
  dome sync
  
  # Verify .config/nested is linked
  [ -L "$HOME/.config/nested" ]
  
  # Add a file in the nested directory
  echo "another file" > "$REPO_DIR/.config/nested/dir/another.txt"
  
  # Verify it's accessible through the symlink
  [ -f "$HOME/.config/nested/dir/another.txt" ]
}

@test "Verbose output contains expected information" {
  run dome sync -v
  [ "$status" -eq 0 ]
  
  # Check for table headers and files in output
  [[ "$output" == *"File"*"Symlinked"*"Backuped"* ]]
  [[ "$output" == *".bashrc"* ]]
}