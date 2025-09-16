#!/bin/bash

# Recursively rename files that start with a possibly padded digit and a space
find . -type f -regextype posix-extended -regex '.*/[0-9]+[ ]+.*' | while read -r file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    # Remove leading digits (possibly padded) and a space
    newbase=$(echo "$base" | sed -E 's/^[0-9]+ +//')
    if [[ "$base" != "$newbase" ]]; then
        mv -i "$file" "$dir/$newbase"
    fi
done