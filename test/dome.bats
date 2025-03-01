#!/usr/bin/env bats

# Load the script to be tested
load '/home/whybe/dome/dome'

# Test truncate_path function
@test "truncate_path short path" {
  run truncate_path "/home/user/file.txt" 20
  [ "$status" -eq 0 ]
  [ "$output" = "/home/user/file.txt" ]
}

@test "truncate_path long path" {
  run truncate_path "/home/user/very/long/path/to/file.txt" 20
  [ "$status" -eq 0 ]
  [ "$output" = ".../path/to/file.txt" ]
}

# Test spinner function
@test "spinner function" {
  run spinner $$ "Loading"
  [ "$status" -eq 0 ]
}

# Test resolve_path function
@test "resolve_path function" {
  run resolve_path "~/test"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/test" ]
}

# Test yaml_get function
@test "yaml_get function" {
  run yaml_get ".meta.repo" "/home/whybe/dome/test/config.yaml"
  [ "$status" -eq 0 ]
  [ "$output" = "https://github.com/<yourusername>/dotfiles" ]
}

# Test yaml_set function
@test "yaml_set function" {
  run yaml_set ".meta.repo = 'https://github.com/new/repo'" "/home/whybe/dome/test/config.yaml"
  [ "$status" -eq 0 ]
}

# Test get_repo_root function
@test "get_repo_root function" {
  run get_repo_root
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.dotfiles" ]
}

# Test detect_distro function
@test "detect_distro function" {
  run detect_distro
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^(arch|debian|fedora|generic)$ ]]
}

# Test run_hook function
@test "run_hook function" {
  run run_hook "pre_sync"
  [ "$status" -eq 0 ]
}

# Test initialize_dome function
@test "initialize_dome function" {
  run initialize_dome
  [ "$status" -eq 0 ]
}

# Test perform_sync function
@test "perform_sync function" {
  run perform_sync
  [ "$status" -eq 0 ]
}

# Test dome_pull function
@test "dome_pull function" {
  run dome_pull
  [ "$status" -eq 0 ]
}

# Test dome_push function
@test "dome_push function" {
  run dome_push
  [ "$status" -eq 0 ]
}