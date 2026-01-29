#!/usr/bin/env bash
# OS detection helper script
# Returns: debian, ubuntu, alpine, arch, or unknown

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            debian)
                echo "debian"
                ;;
            ubuntu)
                echo "ubuntu"
                ;;
            alpine)
                echo "alpine"
                ;;
            arch)
                echo "arch"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# If script is executed directly, output OS
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    detect_os
fi
