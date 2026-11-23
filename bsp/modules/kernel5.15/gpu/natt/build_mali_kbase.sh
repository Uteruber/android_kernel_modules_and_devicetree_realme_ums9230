#!/usr/bin/env bash
# Build the Mali kbase external kernel module using the driver's existing Makefile.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MALI_DIR="$SCRIPT_DIR/mali"

usage() {
    cat <<'EOF'
Usage:
  build_mali_kbase.sh <kernel-build-dir> <platform-name> [build|clean]

Arguments:
  kernel-build-dir  Configured/prepared Linux kernel source or output directory
  platform-name     Platform directory under ../../sprd/natt/platform/
                    (for example, the name used by CONFIG_MALI_PLATFORM_NAME)
  build|clean       Action; defaults to build

Environment:
  ARCH              Kernel architecture (defaults to arm64)
  CROSS_COMPILE     Optional cross-compiler prefix, e.g. aarch64-linux-gnu-
  JOBS              Parallel jobs (defaults to the number of online CPUs)
  CONFIG_MALI_CSF_SUPPORT  Set to y for a CSF GPU; defaults to n

Example:
  ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
    ./build_mali_kbase.sh /path/to/kernel/out devicetree
EOF
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
    usage >&2
    exit 2
fi

KERNEL_DIR="$(realpath -m -- "$1")"
PLATFORM_NAME="$2"
ACTION="${3:-build}"

if [[ "$ACTION" != "build" && "$ACTION" != "clean" ]]; then
    echo "Error: action must be 'build' or 'clean'." >&2
    usage >&2
    exit 2
fi
if [[ ! -f "$KERNEL_DIR/Makefile" ]]; then
    echo "Error: no kernel Makefile found in: $KERNEL_DIR" >&2
    exit 1
fi
if [[ ! -f "$MALI_DIR/Makefile" || ! -f "$MALI_DIR/Kbuild" ]]; then
    echo "Error: Mali kbase Makefile/Kbuild not found under: $MALI_DIR" >&2
    exit 1
fi

export ARCH="${ARCH:-arm64}"
if [[ -n "${CROSS_COMPILE:-}" ]]; then
    export CROSS_COMPILE
fi
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}"

make -C "$MALI_DIR" \
    KDIR="$KERNEL_DIR" \
    CONFIG_MALI_PLATFORM_NAME="$PLATFORM_NAME" \
    CONFIG_MALI_CSF_SUPPORT="${CONFIG_MALI_CSF_SUPPORT:-n}" \
    -j"$JOBS" \
    "$ACTION"
