#!/usr/bin/env bats

setup() {
  # Create temporary directories and files
  export TEMP_DIR=$(mktemp -d)
  export HOME="$TEMP_DIR/home"
  export REPO_DIR="$TEMP_DIR/repo"
  mkdir -p "$HOME"
  mkdir -p "$REPO_DIR"

  # Create fake git repo
  cd "$REPO_DIR"
  git init --quiet
  # Add required git config
  git config user.email "test@example.com"
  git config user.name "Test User"
  mkdir -p .config/sway .config/wofi
  echo "test config" >.config/sway/config
  echo "styles" >.config/wofi/styles.css
  echo "alias ls='ls -lha'" >.bash_aliases.arch
  echo "alias ll='ls -l'" >.bash_aliases.debian
  echo "PS1='\$ '" >.bashrc
  git add .
  git commit -m "Initial commit" --quiet

  # Create .domeignore
  cat >.domeignore <<EOF
.git/
README.md
LICENSE
EOF
}

teardown() {
  rm -rf "$TEMP_DIR"
}

mock_distro() {
  echo "arch"
}

@test "Initialize dome configuration" {
  run dome init -p .dotfiles "file://$REPO_DIR"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/dome/config.yaml" ]

  run yq eval '.meta.local_path' "$HOME/.config/dome/config.yaml"
  [ "$output" = "~/.dotfiles" ]
}

@test "Sync in symlink mode" {
  dome init -p .dotfiles "file://$REPO_DIR"
  run dome sync -v

  [ "$status" -eq 0 ]
  [ -L "$HOME/.bashrc" ]
  [ -L "$HOME/.config/sway" ]
  [ "$(readlink -f $HOME/.bash_aliases)" = "$REPO_DIR/.bash_aliases.arch" ]

  # Verify ignored files not synced
  [ ! -e "$HOME/.domeignore" ]
  [ ! -e "$HOME/README.md" ]
}

@test "Sync in snapshot mode with backups" {
  dome init -p .dotfiles "file://$REPO_DIR"

  # Create existing files
  echo "old config" >"$HOME/.bashrc"
  mkdir -p "$HOME/.config/sway"
  echo "old sway" >"$HOME/.config/sway/config"

  run dome sync -sv
  [ "$status" -eq 0 ]

  # Verify backups
  local backup_dir="$HOME/.config/dome/backups/arch/bak_"*
  [ -d "$backup_dir" ]
  [ -f "$backup_dir/.bashrc" ]
  [ -f "$backup_dir/.config/sway/config" ]

  # Verify copies
  [ -f "$HOME/.bashrc" ]
  [ ! -L "$HOME/.bashrc" ]
  [ "$(cat $HOME/.bashrc)" = "PS1='\$ '" ]
}

@test "Revert from backup" {
  dome init -p .dotfiles "file://$REPO_DIR"

  # Initial sync with snapshot
  echo "original content" >"$HOME/.bashrc"
  dome sync -s

  # Modify after sync
  echo "broken content" >"$HOME/.bashrc"

  # Revert
  run dome revert
  [ "$status" -eq 0 ]
  [ "$(cat $HOME/.bashrc)" = "original content" ]
}

@test "Handle new files in repo" {
  dome init -p .dotfiles "file://$REPO_DIR"
  dome sync

  # Add new file to repo
  echo "new file" >"$REPO_DIR/.config/wofi/newfile.css"
  (cd "$REPO_DIR" && git add . && git commit -m "Add new file" --quiet)

  run dome sync
  [ "$status" -eq 0 ]
  [ -L "$HOME/.config/wofi/newfile.css" ]
}

@test "Respect .domeignore" {
  dome init -p .dotfiles "file://$REPO_DIR"
  dome sync

  [ ! -e "$HOME/.git" ]
  [ ! -e "$HOME/README.md" ]
}

@test "Handle directory symlinking" {
  dome init -p .dotfiles "file://$REPO_DIR"
  dome sync

  # Verify directory symlink
  [ -L "$HOME/.config/sway" ]
  [ "$(readlink -f $HOME/.config/sway)" = "$REPO_DIR/.config/sway" ]

  # Add file to repo directory
  echo "test" >"$REPO_DIR/.config/sway/newfile"
  dome sync

  # Verify new file appears through symlink
  [ -f "$HOME/.config/sway/newfile" ]
}

@test "Snapshot mode backup structure" {
  dome init -p .dotfiles "file://$REPO_DIR"

  # Create existing files
  mkdir -p "$HOME/.config/wofi"
  echo "existing styles" >"$HOME/.config/wofi/styles.css"

  run dome sync -s
  [ "$status" -eq 0 ]

  local backup_dir="$HOME/.config/dome/backups/arch/bak_"*
  [ -f "$backup_dir/.config/wofi/styles.css" ]
  [ "$(cat $backup_dir/.config/wofi/styles.css)" = "existing styles" ]
}

@test "Distro-specific file mapping" {
  dome init -p .dotfiles "file://$REPO_DIR"
  dome sync

  [ "$(readlink -f $HOME/.bash_aliases)" = "$REPO_DIR/.bash_aliases.arch" ]
  [ ! -e "$HOME/.bash_aliases.debian" ]
}
