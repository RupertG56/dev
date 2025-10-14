#!/usr/bin/env bash
# zfs_samba_check.sh - verify recommended ZFS properties for Samba datasets

POOL="nas"   # change to your pool name

echo "Checking Samba dataset properties under pool: $POOL"
echo ""

for ds in $(zfs list -H -o name -r "$POOL"); do
    echo "Dataset: $ds"

    for prop in \
        "acltype nfs4" \
        "aclinherit passthrough" \
        "aclmode passthrough" \
        "xattr sa" \
        "dnodesize auto" \
        "atime off" \
        "sync standard" \
        "recordsize 128K"
    do
        key=$(echo "$prop" | awk '{print $1}')
        expected=$(echo "$prop" | awk '{print $2}')
        current=$(zfs get -H -o value $key "$ds")

        if [[ "$current" == "$expected" ]]; then
            echo "  ✔ $key = $current"
        else
            echo "  ✘ $key = $current (recommended: $expected)"
        fi
    done
    echo ""
done
