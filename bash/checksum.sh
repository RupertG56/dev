#!/bin/bash

ROOT_DIR="${1:-.}"
OUTPUT_FILE="${2:-checksums.sha256}"

find "$ROOT_DIR" -type f -print0 | while IFS= read -r -d '' file; do
    sha256sum "$file"
done > "$OUTPUT_FILE"