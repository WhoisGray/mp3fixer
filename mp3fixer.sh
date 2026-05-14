#!/usr/bin/env bash

set -euo pipefail

VERSION="1.1.0"

SUPPORTED_EXTENSIONS=(
  mp3 m4a flac wav aac ogg
)

# -------------------------
# HELP
# -------------------------
print_help() {
  cat <<EOF
mp3fixer v${VERSION}

Rename audio files using metadata tags.

USAGE:
  mp3fixer [options] <file-or-folder>

OPTIONS:
  -y    Auto confirm all renames
  -n    Dry run mode
  -v    Verbose output
  -h    Show help
EOF
}

# -------------------------
# LOGGING
# -------------------------
log() {
  [[ "${VERBOSE}" == true ]] && echo "$1"
}

warn() {
  echo "⚠️  $1"
}

error() {
  echo "❌ $1" >&2
}

success() {
  echo "✅ $1"
}

# -------------------------
# CLEAN STRING (IMPORTANT FIX)
# -------------------------
clean() {
  echo "$1" | tr -d '\r\n' | xargs
}

sanitize_filename() {
  local name="$1"

  name=$(echo "$name" | sed 's#[/:*?"<>|]#-#g')
  name=$(echo "$name" | tr -s ' ')
  name=$(echo "$name" | sed 's/^ *//;s/ *$//')

  echo "$name"
}

# -------------------------
# CHECK EXTENSION
# -------------------------
is_supported_extension() {
  local ext="$1"

  for e in "${SUPPORTED_EXTENSIONS[@]}"; do
    [[ "$ext" == "$e" ]] && return 0
  done

  return 1
}

# -------------------------
# METADATA SAFE FETCH
# -------------------------
get_metadata() {
  local field="$1"
  local file="$2"

  ffprobe -v error \
    -show_entries "format_tags=${field}" \
    -of default=noprint_wrappers=1:nokey=1 \
    "$file" 2>/dev/null || true
}

# -------------------------
# PROCESS FILE
# -------------------------
process_file() {
  local file="$1"

  [[ ! -f "$file" ]] && return

  local ext="${file##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

  is_supported_extension "$ext" || return

  local dir current_name artist title new_name new_path

  dir=$(dirname "$file")
  current_name=$(basename "$file")

  artist=$(clean "$(get_metadata artist "$file")")
  title=$(clean "$(get_metadata title "$file")")

  # -------------------------
  # FIX: INVALID METADATA GUARD
  # -------------------------
  if [[ -z "$artist" || -z "$title" ]]; then
    warn "Missing metadata → skipping: $current_name"
    return
  fi

  if [[ "$artist" == "Unknown Artist" && "$title" == "Unknown Title" ]]; then
    warn "Unknown metadata → skipping: $current_name"
    return
  fi

  new_name="$(sanitize_filename "$artist - $title").$ext"
  new_path="${dir}/${new_name}"

  if [[ "$current_name" == "$new_name" ]]; then
    log "⏭️ Already correct: $current_name"
    return
  fi

  echo
  echo "🎵 Current : $current_name"
  echo "✨ Rename  : $new_name"

  # prevent overwrite
  if [[ -e "$new_path" ]]; then
    warn "Target exists → skipping: $new_name"
    return
  fi

  # dry run
  if [[ "${DRY_RUN}" == true ]]; then
    echo "🧪 Dry-run: no changes"
    return
  fi

  # confirm
  if [[ "${AUTO_YES}" == false ]]; then
    printf "Apply rename? [Y/n]: "
    local confirm
    IFS= read -r confirm </dev/tty

    [[ -n "$confirm" && ! "$confirm" =~ ^[Yy]$ ]] && {
      echo "❌ Cancelled"
      return
    }
  fi

  mv -- "$file" "$new_path"
  success "Renamed"
}

# -------------------------
# PROCESS TARGET (FIXED FIND)
# -------------------------
process_target() {
  local target="$1"

  if [[ -f "$target" ]]; then
    process_file "$target"
    return
  fi

  if [[ -d "$target" ]]; then

    # FIX: filter only audio extensions (prevents junk + speed boost)
    find "$target" -type f \( \
      -iname "*.mp3" -o \
      -iname "*.m4a" -o \
      -iname "*.flac" -o \
      -iname "*.wav" -o \
      -iname "*.aac" -o \
      -iname "*.ogg" \
    \) -print0 | while IFS= read -r -d '' file; do
      process_file "$file"
    done

    return
  fi

  error "Invalid path: $target"
  exit 1
}

# -------------------------
# MAIN
# -------------------------
main() {
  AUTO_YES=false
  DRY_RUN=false
  VERBOSE=false

  while getopts ":ynvh" opt; do
    case "$opt" in
      y) AUTO_YES=true ;;
      n) DRY_RUN=true ;;
      v) VERBOSE=true ;;
      h)
        print_help
        exit 0
        ;;
      *)
        error "Invalid option"
        print_help
        exit 1
        ;;
    esac
  done

  shift $((OPTIND - 1))

  local target="${1:-}"

  [[ -z "$target" ]] && {
    print_help
    exit 1
  }

  command -v ffprobe >/dev/null 2>&1 || {
    error "ffprobe not found (install ffmpeg)"
    exit 1
  }

  process_target "$target"
}

main "$@"