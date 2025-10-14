#!/bin/bash
# Usage: ./create_plex_dataset.sh <dataset> [recordsize]
# Default recordsize = 1M if not provided

DS=$1
RS=${2:-1M}   # second parameter if given, otherwise default to 1M

if [ -z "$DS" ]; then
  echo "Usage: $0 <dataset> [recordsize]"
  echo "Example: $0 tank/plex/media 1M"
  echo "Default recordsize is 1M if not specified."
  exit 1
fi

# Check if dataset exists
if zfs list -H -o name "$DS" >/dev/null 2>&1; then
  echo "Dataset $DS already exists. Applying properties..."
else
  echo "Creating dataset $DS..."
  zfs create "$DS"
fi

# Apply Plex-tuned properties with samba acltyoe
zfs set compression=lz4        "$DS"
zfs set atime=off              "$DS"
zfs set recordsize=$RS         "$DS"
zfs set xattr=sa               "$DS"
zfs set dnodesize=auto         "$DS"
zfs set acltype=nfsv4          "$DS"
zfs set aclinherit=passthrough "$DS"
zfs set aclmode=passthrough    "$DS"
zfs set sync=standard          "$DS"

echo "Dataset $DS configured with recordsize=$RS and Plex-optimized settings."
