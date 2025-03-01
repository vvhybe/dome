#!/usr/bin/env bash
# shellcheck disable=SC2155

# --- Theming Setup ---
declare -A COLORS=(
  [reset]="\033[0m"
  [bold]="\033[1m"
  [red]="\033[31m"
  [green]="\033[32m"
  [yellow]="\033[33m"
  [blue]="\033[34m"
  [magenta]="\033[35m"
)

declare -A SYMBOLS=(
  [check]="✓"
  [cross]="✗"
  [arrow]="➜"
  [info]="ℹ"
  [warn]="⚠"
)

print_status() {
  local color="$1" symbol="$2" msg="$3"
  if [[ -t 1 ]]; then
    echo -e "${COLORS[bold]}${COLORS[$color]}${SYMBOLS[$symbol]} ${msg}${COLORS[reset]}"
  else
    echo "${SYMBOLS[$symbol]} ${msg}"
  fi
}

print_success() { print_status "green" "check" "$1"; }
print_error() { print_status "red" "cross" "$1"; }
print_info() { print_status "blue" "arrow" "$1"; }
print_warning() { print_status "yellow" "warn" "$1"; }

# --- Spinner Function ---
spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while kill -0 "$pid" 2>/dev/null; do
    for ((i = 0; i < ${#spinstr}; i++)); do
      printf "\r%s %s" "${spinstr:$i:1}" "Downloading dome..."
      sleep "$delay"
    done
  done
  printf "\r"
}

# --- Installer Settings ---
readonly DEST="$HOME/bin"
readonly DESTFILE="$DEST/dome"

SILENT='false'
TAG='star-dust'

# --- Process Command-Line Arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
  -s | --silent)
    SILENT='true'
    ;;
  -t | --tag)
    if [[ -n "$2" ]] && [[ "$2" != -* ]]; then
      TAG="$2"
      shift
    else
      print_error "Option --tag requires an argument"
      exit 1
    fi
    ;;
  --tag=?*)
    TAG="${1#*=}"
    ;;
  *)
    print_error "Invalid argument: $1"
    exit 1
    ;;
  esac
  shift
done

if [[ "$TAG" != "main" && ! "$TAG" =~ ^v0\.[1-9]\.[0-9]+$ ]]; then
  print_error "Tag $TAG does not exist."
  exit 1
fi

[[ "$SILENT" == "true" ]] || print_info "Installing dome..."

# --- Create Destination Directory ---
mkdir -p "$DEST"

# --- Download dome Script with Custom TUI Loader ---
if [[ "$SILENT" == "true" ]]; then
  curl -fsSL "https://raw.githubusercontent.com/vvhybe/dome/$TAG/dome" --output dome.tmp
  curl_exit=$?
else
  # Launch curl in the background with silent progress.
  curl -fL "https://raw.githubusercontent.com/vvhybe/dome/$TAG/dome" --silent --output dome.tmp &
  curl_pid=$!
  spinner "$curl_pid"
  wait "$curl_pid"
  curl_exit=$?
fi

if [ "$curl_exit" -ne 0 ]; then
  print_error "Download failed. Please check your internet connection."
  exit 1
fi

mv -f dome.tmp "$DESTFILE"
chmod 755 "$DESTFILE"

[[ "$SILENT" == "true" ]] || print_success "Installation finished."

# --- Check if Destination is in PATH ---
if ! echo "$PATH" | grep -q "$DEST"; then
  print_warning "Warning: $DEST is not in your PATH. Please add it to your PATH."
fi
