#!/usr/bin/env bash

set -euo pipefail

VERSION="1.0.0"

SUPPORTED_EXTENSIONS=(
  mp3
  m4a
  flac
  wav
  aac
  ogg
)

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

EXAMPLES:
  mp3fixer song.mp3
  mp3fixer ~/Music
  mp3fixer -n ~/Music
  mp3fixer -y ~/Music

EOF
}

log() {
  local message="$1"

  if [[ "${VERBOSE}" == true ]]; then
    echo "$message"
  fi
}

error() {
  echo "❌ $1" >&2
}

success() {
  echo "✅ $1"
}

warn() {
  echo "⚠️  $1"
}

sanitize_filename() {
  local name="$1"

  name=$(echo "$name" | sed 's#[/:*?"<>|]#-#g')
  name=$(echo "$name" | tr -s ' ')
  name=$(echo "$name" | sed 's/^ *//;s/ *$//')

  echo "$name"
}

is_supported_extension() {
  local ext="$1"

  for supported in "${SUPPORTED_EXTENSIONS[@]}"; do
    if [[ "$ext" == "$supported" ]]; then
      return 0
    fi
  done

  return 1
}

get_metadata() {
  local field="$1"
  local file="$2"

  ffprobe \
    -v error \
    -show_entries "format_tags=${field}" \
    -of default=noprint_wrappers=1:nokey=1 \
    "$file" 2>/dev/null || true
}

process_file() {
  local file="$1"

  [[ ! -f "$file" ]] && return

  local ext="${file##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

  if ! is_supported_extension "$ext"; then
    log "⏭️ Skipped unsupported file: $file"
    return
  fi

  local dir
  dir=$(dirname "$file")

  local current_name
  current_name=$(basename "$file")

  local artist
  local title

  artist=$(get_metadata artist "$file")
  title=$(get_metadata title "$file")

  [[ -z "$artist" ]] && artist="Unknown Artist"
  [[ -z "$title" ]] && title="Unknown Title"

  local new_name
  new_name="$(sanitize_filename "$artist - $title").$ext"

  if [[ "$current_name" == "$new_name" ]]; then
    log "⏭️ Already correct: $current_name"
    return
  fi

  local new_path="${dir}/${new_name}"

  echo
  echo "🎵 Current : $current_name"
  echo "✨ Rename  : $new_name"

  if [[ -e "$new_path" ]]; then
    warn "Target already exists: $new_name"
    return
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    echo "🧪 Dry run mode: skipped"
    return
  fi

  if [[ "${AUTO_YES}" == false ]]; then
    printf "Apply rename? [Y/n]: "

    local confirm
    IFS= read -r confirm </dev/tty

    if [[ -n "$confirm" && ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "❌ Cancelled"
      return
    fi
  fi

  mv "$file" "$new_path"

  success "Renamed successfully"
}

process_target() {
  local target="$1"

  if [[ -f "$target" ]]; then
    process_file "$target"
    return
  fi

  if [[ -d "$target" ]]; then
    while IFS= read -r -d '' file; do
      process_file "$file"
    done < <(find "$target" -type f -print0)

    return
  fi

  error "Invalid path: $target"
  exit 1
}

main() {
  AUTO_YES=false
  DRY_RUN=false
  VERBOSE=false

  while getopts ":ynvh" opt; do
    case "$opt" in
      y)
        AUTO_YES=true
        ;;
      n)
        DRY_RUN=true
        ;;
      v)
        VERBOSE=true
        ;;
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

  if [[ -z "$target" ]]; then
    print_help
    exit 1
  fi

  if ! command -v ffprobe >/dev/null 2>&1; then
    error "ffprobe not found. Install ffmpeg first."
    exit 1
  fi

  process_target "$target"
}

main "$@"