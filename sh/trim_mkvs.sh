#!/usr/bin/env bash
# Usage:
#   ./trim_mkvs.sh "/path/to/folder" 4 [--dry-run]
#
# - Trims first N seconds from all .mkv files (default: 4s)
# - Recurses into subfolders
# - Keeps originals as *.orig.mkv
# - Supports --dry-run to preview actions

set -euo pipefail

root_dir="${1:-.}"
trim_seconds="${2:-4}"
dry_run="${3:-}"

root_dir="$(realpath "$root_dir")"

echo "🔍 Scanning: $root_dir"
echo "✂️  Trimming first $trim_seconds seconds"
[[ "$dry_run" == "--dry-run" ]] && echo "💡 Dry-run mode: no files will be changed"
echo

find "$root_dir" -type f -iname '*.mkv' -print0 |
while IFS= read -r -d '' file; do
  dir="$(dirname "$file")"
  base="$(basename "$file")"
  trimmed="${dir}/trimmed_${base}"
  backup="${file%.mkv}.orig.mkv"

  if [[ -e "$backup" ]]; then
    echo "⚠️  Skipping (backup exists): $file"
    continue
  fi

  echo "Processing: $file"

  if [[ "$dry_run" == "--dry-run" ]]; then
    echo "  → Would run:"
    echo "    ffmpeg -ss $trim_seconds -i \"$file\" -map 0 -c:v copy -c:a copy -fflags +genpts -avoid_negative_ts make_zero \"$trimmed\""
    echo "  → Would rename \"$file\" → \"$backup\" and \"$trimmed\" → \"$file\""
  else
    if ffmpeg -loglevel warning \
        -ss "$trim_seconds" -i "$file" \
        -map 0 -c:v copy -c:a copy \
        -fflags +genpts -avoid_negative_ts make_zero \
        "$trimmed"; then

      if [[ -s "$trimmed" ]]; then
        mv -- "$file" "$backup"
        mv -- "$trimmed" "$file"
        echo "  ✔ Trimmed → replaced; original saved as:"
        echo "    $backup"
      else
        echo "  ✖ Empty output; keeping original."
        rm -f -- "$trimmed"
      fi
    else
      echo "  ✖ FFmpeg failed; keeping original."
      rm -f -- "$trimmed" 2>/dev/null || true
    fi
  fi

  echo
done

echo "✅ Done."
