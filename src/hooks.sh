#!/bin/bash

run_hook() {
  local hook_cmd=$(get_config_value ".hooks.$1")
  [ -n "$hook_cmd" ] && eval "$hook_cmd"
}
