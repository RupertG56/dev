#!/usr/bin/env bash
# realtek-r8125-hardening.sh
#
# One-shot Rocky/RHEL script to force RTL8125 to use r8125 instead of r8169.
# - Installs ELRepo + kmod-r8125
# - Blacklists r8169
# - Adds dracut config to omit r8169 and include r8125
# - Adds udev PCI driver_override rules for detected Realtek NIC(s)
# - Rebuilds initramfs
#
# Usage:
#   sudo bash realtek-r8125-hardening.sh            # apply
#   sudo bash realtek-r8125-hardening.sh --dry-run  # show what it would do
#   sudo bash realtek-r8125-hardening.sh --with-grub-blacklist  # also add kernel cmdline blacklist
#
set -euo pipefail

DRY_RUN=0
WITH_GRUB_BLACKLIST=0

log() { echo "==> $*"; }
warn() { echo "WARNING: $*" >&2; }
die() { echo "ERROR: $*" >&2; exit 1; }

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    run "cp -a '$f' '${f}.bak.${ts}'"
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=1; shift ;;
      --with-grub-blacklist) WITH_GRUB_BLACKLIST=1; shift ;;
      -h|--help)
        sed -n '1,80p' "$0"
        exit 0
        ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

require_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run as root (use sudo)."
}

detect_realtek_pci_devices() {
  # Finds all Realtek Ethernet controllers and returns "BDF vendor device" lines
  # Example: "0000:03:00.0 10ec 8125"
  local out
  out="$(lspci -Dnnd ::0200 2>/dev/null | awk '
    /10ec:/ {
      # format: 0000:03:00.0 Class ...: Vendor Device [10ec:8125]
      bdf=$1
      if (match($0, /\[([0-9a-fA-F]{4}):([0-9a-fA-F]{4})\]/, m)) {
        ven=tolower(m[1]); dev=tolower(m[2])
        print bdf, ven, dev
      }
    }')"
  echo "$out"
}

ensure_elrepo_and_kmod() {
  log "Installing ELRepo release package (if needed) and kmod-r8125..."
  # elrepo-release is safe to install even if present
  run "dnf -y install elrepo-release"
  run "dnf -y install kmod-r8125"
}

write_blacklist() {
  local f="/etc/modprobe.d/blacklist-r8169.conf"
  log "Writing modprobe blacklist for r8169: $f"
  backup_file "$f"
  run "cat > '$f' <<'EOF'
# Prevent the generic in-kernel Realtek driver from binding to RTL8125
blacklist r8169
EOF"
}

write_dracut_conf() {
  local f="/etc/dracut.conf.d/99-realtek-r8125.conf"
  log "Writing dracut config to omit r8169 and include r8125: $f"
  backup_file "$f"
  run "cat > '$f' <<'EOF'
# Ensure initramfs does NOT load r8169 early, and DOES include r8125
omit_drivers+=\" r8169 \"
add_drivers+=\" r8125 \"
EOF"
}

write_udev_overrides() {
  local f="/etc/udev/rules.d/99-r8125-driver-override.rules"
  log "Writing udev PCI driver_override rules: $f"
  backup_file "$f"

  local devices="$1"
  if [[ -z "$devices" ]]; then
    warn "No Realtek PCI Ethernet devices detected via lspci. Writing a generic RTL8125 rule anyway."
    run "cat > '$f' <<'EOF'
# Force Realtek RTL8125 to bind to r8125
ACTION==\"add\", SUBSYSTEM==\"pci\", ATTR{vendor}==\"0x10ec\", ATTR{device}==\"0x8125\", ATTR{driver_override}=\"r8125\"
EOF"
    return
  fi

  # Build rules for each detected Realtek NIC (by vendor/device).
  # If you have multiple Realtek NIC models, this avoids forcing r8125 onto non-8125 devices.
  local tmp
  tmp="$(mktemp)"
  {
    echo "# Auto-generated: force specific Realtek NICs to bind to r8125"
    echo "# Generated on: $(date -Is)"
    echo ""
  } > "$tmp"

  local have_8125=0
  while read -r bdf ven dev; do
    # Only apply to RTL8125 (device id 8125). If you *want* to force all Realtek NICs, adjust here.
    if [[ "$ven" == "10ec" && "$dev" == "8125" ]]; then
      have_8125=1
      cat >> "$tmp" <<EOF
# $bdf [$ven:$dev]
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x$ven", ATTR{device}=="0x$dev", ATTR{driver_override}="r8125"
EOF
    fi
  done <<< "$devices"

  if [[ "$have_8125" -eq 0 ]]; then
    warn "Detected Realtek NIC(s), but none appear to be RTL8125 (10ec:8125). Writing generic RTL8125 rule."
    cat >> "$tmp" <<'EOF'
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10ec", ATTR{device}=="0x8125", ATTR{driver_override}="r8125"
EOF
  fi

  run "install -m 0644 '$tmp' '$f'"
  rm -f "$tmp"
}

rebuild_initramfs() {
  log "Rebuilding initramfs with dracut..."
  run "dracut -f"
}

optional_grub_blacklist() {
  [[ "$WITH_GRUB_BLACKLIST" -eq 1 ]] || return 0

  # On Rocky, best practice is grubby to update all installed kernels.
  need_cmd grubby
  log "Adding kernel cmdline modprobe.blacklist=r8169 via grubby (extra belt-and-suspenders)..."
  run "grubby --update-kernel=ALL --args='modprobe.blacklist=r8169'"
}

show_status() {
  log "Post-change verification commands (run after reboot):"
  cat <<'EOF'
  # Verify driver binding
  lspci -k | grep -A3 -i ethernet

  # Verify modules
  lsmod | egrep 'r8169|r8125' || true

  # Verify initramfs doesn't contain r8169 (optional)
  lsinitrd | egrep 'r8169|r8125' || true

  # Kernel log hints
  dmesg | egrep 'r8169|r8125' || true
EOF
}

secure_boot_note() {
  if command -v mokutil >/dev/null 2>&1; then
    local sb
    sb="$(mokutil --sb-state 2>/dev/null || true)"
    if echo "$sb" | grep -qi "enabled"; then
      log "Secure Boot appears ENABLED. ELRepo kmod packages are typically signed; if r8125 still won’t load,"
      log "check dmesg for 'Lockdown' / 'Required key not available' messages."
    fi
  fi
}

main() {
  parse_args "$@"
  require_root

  need_cmd dnf
  need_cmd lspci
  need_cmd dracut

  log "Detecting Realtek PCI Ethernet devices..."
  local devices
  devices="$(detect_realtek_pci_devices || true)"
  if [[ -n "$devices" ]]; then
    echo "$devices" | while read -r bdf ven dev; do
      log "Found Realtek NIC: $bdf [$ven:$dev]"
    done
  else
    warn "No Realtek Ethernet controllers found via lspci -Dnnd ::0200 (continuing anyway)."
  fi

  ensure_elrepo_and_kmod
  write_blacklist
  write_dracut_conf
  write_udev_overrides "$devices"
  optional_grub_blacklist
  rebuild_initramfs
  secure_boot_note

  log "Done."
  log "You should reboot now for the binding to fully take effect."
  show_status
}

main "$@"
