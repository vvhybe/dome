#!/bin/bash

detect_distro() {
  local distro_id=$(grep -Ei "^ID=([a-z]+)" /etc/os-release | cut -d= -f2 | tr -d '"')
  case $distro_id in
    ubuntu|pop|linuxmint) echo "debian" ;;
    *) echo "$distro_id" ;;
  esac
}

get_config_value() {
  yq "$1" ~/.config/dome/config.yaml
}

get_packages() {
  yq ".packages.$(detect_distro)" dome.yaml
}

