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
  echo "🚀 $1"
}

# -------------------------
# CLEAN
# -------------------------
clean() {
  echo "$1" | tr -d '\r\n' | sed 's/^ *//;s/ *$//'
}

# -------------------------
# SANITIZE FILENAME (FIXED)
# -------------------------
sanitize_filename() {
  local name="$1"

  # replace forbidden chars
  name=$(echo "$name" | sed 's#[/:*?"<>|]#-#g')

  # normalize whitespace
  name=$(echo "$name" | sed 's/[[:space:]]\+/ /g')

  # trim
  name=$(echo "$name" | sed 's/^ *//;s/ *$//')

  echo "$name"
}

# -------------------------
# EXTENSION CHECK
# -------------------------
is_supported_extension() {
  local ext="$1"

  for e in "${SUPPORTED_EXTENSIONS[@]}"; do
    [[ "$ext" == "$e" ]] && return 0
  done
  return 1
}

# -------------------------
# METADATA
# -------------------------
get_metadata() {
  local field="$1"
  local file="$2"

  ffprobe -v error \
    -show_entries "format_tags=${field}" \
    -of default=noprint_wrappers=1:nokey=1 \
    "$file" 2>/dev/null | tr -d '\r\n'
}

# -------------------------
# PROCESS FILE
# -------------------------
process_file() {
  local file="$1"

  [[ -f "$file" ]] || return 0

  local ext
  ext="${file##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

  is_supported_extension "$ext" || return 0

  local dir current artist title base new_name new_path

  dir=$(dirname "$file")
  current=$(basename "$file")
  base="${current%.*}"

  artist=$(clean "$(get_metadata artist "$file")")
  title=$(clean "$(get_metadata title "$file")")

  # -------------------------
  # 🔥 FIX: fallback to filename parsing
  # -------------------------
  if [[ -z "$artist" && -z "$title" ]]; then
    if [[ "$base" == *" - "* ]]; then
      artist="${base%% - *}"
      title="${base#* - }"
    else
      artist="Unknown Artist"
      title="$base"
    fi
  fi

  [[ -z "$artist" ]] && artist="Unknown Artist"
  [[ -z "$title" ]] && title="Unknown Title"

  new_name="$(sanitize_filename "${artist} - ${title}").${ext}"
  new_path="${dir}/${new_name}"

  # skip same
  [[ "$current" == "$new_name" ]] && {
    log "⏭️ Skip: $current"
    return 0
  }

  echo
  echo "🎵 Current : $current"
  echo "✨ Rename  : $new_name"

  if [[ -e "$new_path" ]]; then
    warn "Target exists: $new_name"
    return 0
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    echo "🧪 Dry-run: $current → $new_name"
    return 0
  fi

  if [[ "${AUTO_YES}" == false ]]; then
    printf "Apply rename? [Y/n]: "
    read -r confirm </dev/tty || true
    confirm=$(echo "$confirm" | xargs)

    [[ -n "$confirm" && ! "$confirm" =~ ^[Yy]$ ]] && return 0
  fi

  mv -- "$file" "$new_path"
  success "Renamed"
}

# -------------------------
# PROCESS TARGET (FIXED: NO PIPE SUBSHELL BUG)
# -------------------------
process_target() {
  local target="$1"

  if [[ -f "$target" ]]; then
    process_file "$target"
    return 0
  fi

  if [[ -d "$target" ]]; then

    while IFS= read -r -d '' file; do
      process_file "$file"
    done < <(
      find "$target" -type f \( \
        -iname "*.mp3" -o \
        -iname "*.m4a" -o \
        -iname "*.flac" -o \
        -iname "*.wav" -o \
        -iname "*.aac" -o \
        -iname "*.ogg" \
      \) -print0
    )

    return 0
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
    error "ffprobe not found. Install ffmpeg first."
    exit 1
  }

  process_target "$target"
}

main "$@"