#!/bin/bash

# Configuration - Modify these paths if necessary
BACKUP_DIR="/path/to/backup/dir"
STORAGE_DIR="/var/lib/libvirt/images"
NVRAM_DIR="/var/lib/libvirt/nvram"
LIBVIRT_URI="qemu:///system"

# Ensure the script runs as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root or with sudo."
  exit 1
fi

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

usage() {
    echo "Usage: $0 {archive|restore} <vm_name>"
    exit 1
}

if [ $# -ne 2 ]; then
    usage
fi

ACTION=$1
VM_NAME=$2

archive_vm() {
    echo "=== Starting Archive for VM: $VM_NAME ==="
    
    # 1. Check if VM exists
    if ! virsh -c "$LIBVIRT_URI" dominfo "$VM_NAME" &>/dev/null; then
        echo "Error: VM '$VM_NAME' not found."
        exit 1
    fi

    # 2. Shut down VM if running
    VM_STATE=$(virsh -c "$LIBVIRT_URI" domstate "$VM_NAME")
    if [ "$VM_STATE" = "running" ]; then
        echo "Shutting down $VM_NAME gracefully..."
        virsh -c "$LIBVIRT_URI" shutdown "$VM_NAME"
        
        # Wait up to 60 seconds for shutdown
        for i in {1..60}; do
            if [ "$(virsh -c "$LIBVIRT_URI" domstate "$VM_NAME")" = "shut off" ]; then
                break
            fi
            sleep 1
        done
    fi

    # Force destroy if still running
    if [ "$(virsh -c "$LIBVIRT_URI" domstate "$VM_NAME")" != "shut off" ]; then
        echo "VM failed to shut down gracefully. Forcing shutdown..."
        virsh -c "$LIBVIRT_URI" destroy "$VM_NAME"
    fi

    # 3. Export XML configuration
    echo "Exporting XML configuration..."
    virsh -c "$LIBVIRT_URI" dumpxml "$VM_NAME" > "$BACKUP_DIR/${VM_NAME}.xml"

    # 4. Copy Virtual Disk
    echo "Archiving virtual disk image..."
    if [ -f "$STORAGE_DIR/${VM_NAME}.qcow2" ]; then
        cp --sparse=always "$STORAGE_DIR/${VM_NAME}.qcow2" "$BACKUP_DIR/"
    else
        echo "Warning: Standard disk $STORAGE_DIR/${VM_NAME}.qcow2 not found. Checking virsh domblklist..."
        DISK_PATH=$(virsh -c "$LIBVIRT_URI" domblklist "$VM_NAME" | awk '/vda|sda/ {print $2}')
        if [ -n "$DISK_PATH" ] && [ -f "$DISK_PATH" ]; then
            cp --sparse=always "$DISK_PATH" "$BACKUP_DIR/"
        else
            echo "Error: Could not locate virtual disk."
            exit 1
        fi
    fi

    # 5. Copy NVRAM file
    echo "Archiving NVRAM file..."
    if [ -f "$NVRAM_DIR/${VM_NAME}_VARS.fd" ]; then
        cp "$NVRAM_DIR/${VM_NAME}_VARS.fd" "$BACKUP_DIR/"
    else
        echo "Notice: NVRAM file not found at default path. Skipping NVRAM copy."
    fi

    # 6. Undefine VM from libvirt
    echo "Removing VM definition from hypervisor..."
    virsh -c "$LIBVIRT_URI" undefine "$VM_NAME" --nvram

    echo "=== Archive complete! Files saved to $BACKUP_DIR ==="
}

restore_vm() {
    echo "=== Starting Restore for VM: $VM_NAME ==="

    # 1. Check if backup files exist
    if [ ! -f "$BACKUP_DIR/${VM_NAME}.xml" ] || [ ! -f "$BACKUP_DIR/${VM_NAME}.qcow2" ]; then
        echo "Error: Backup XML or QCOW2 files missing from $BACKUP_DIR"
        exit 1
    fi

    # 2. Restore NVRAM if it was backed up
    if [ -f "$BACKUP_DIR/${VM_NAME}_VARS.fd" ]; then
        echo "Restoring NVRAM profile..."
        cp "$BACKUP_DIR/${VM_NAME}_VARS.fd" "$NVRAM_DIR/"
    fi

    # 3. Restore Virtual Disk
    echo "Restoring virtual disk image..."
    cp --sparse=always "$BACKUP_DIR/${VM_NAME}.qcow2" "$STORAGE_DIR/"

    # 4. Define and Register VM
    echo "Registering VM configuration with libvirt..."
    virsh -c "$LIBVIRT_URI" define "$BACKUP_DIR/${VM_NAME}.xml"

    echo "=== Restore complete! You can now start the VM with: sudo virsh start $VM_NAME ==="
}

case "$ACTION" in
    archive)
        archive_vm
        ;;
    restore)
        restore_vm
        ;;
    *)
        usage
        ;;
esac
