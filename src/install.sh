#!/bin/bash

install_package() {
  local pkg=$1
  local distro=$(detect_distro)
  local managers=$(get_config_value ".profiles.$distro | join(\" \")")
  
  for manager in $managers; do
    case $manager in
      "script")
        run_install_script "$pkg"
        return $?
        ;;
      *)
        run_pkg_manager "$manager" "$pkg" && return 0
        ;;
    esac
  done
}

generate_lock() {
  local distro=$(detect_distro)
  echo "packages:" > dome-lock.yaml
  
  while read -r pkg; do
    case $1 in
      arch)
        version=$(pacman -Q "$pkg" | awk '{print $2}') 
        ;;
      debian)
        version=$(dpkg -s "$pkg" | grep Version | cut -d: -f2 | xargs)
        ;;
    esac
    echo "  $pkg: $version" >> dome-lock.yaml
  done < <(yq eval ".packages.$distro.[].name" dome.yaml)
}

run_install_script() {
  [ -f "scripts/$1.sh" ] || return 1
  DOME_DISTRO=$distro VERSION=$(get_package_version "$1") ./scripts/$1.sh
}
