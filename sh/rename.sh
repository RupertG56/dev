#!/usr/bin/env bash

set -euo pipefail

series="${1:?Usage: $0 <series-name> <path>}"
path="${2:?Usage: $0 <series-name> <path>}"

find "$path" -maxdepth 1 -type f -name 'S*E*.mp4' | while read -r f; do
    filename="$(basename "$f")"
    dir="$(dirname "$f")"

    if [[ $filename =~ ^S([0-9]+)E([0-9]+)[[:space:]]+(.*)\.mp4$ ]]; then
        season=$(printf "%02d" "${BASH_REMATCH[1]}")
        episode=$(printf "%02d" "${BASH_REMATCH[2]}")
        title="${BASH_REMATCH[3]}"

        newname="${series}.S${season}E${episode}.${title}.mp4"

        # dry run
        mv -- "$f" "$dir/$newname"
    fi
done
