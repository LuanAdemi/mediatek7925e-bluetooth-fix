#!/bin/bash
# Fix for MediaTek WiFi/Bluetooth combo card misidentification
# This script prevents GVFS/GIO from mounting the device as a media player
# which causes Bluetooth functionality to crash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

# Check arguments
if [[ "$1" != "--apply" && "$1" != "--undo" ]]; then
    echo -e "${YELLOW}Usage:${NC} $0 --apply   # Apply fix"
    echo "       $0 --undo    # Undo fix"
    exit 1
fi

echo -e "${GREEN}MediaTek WiFi/Bluetooth Fix Script${NC}"
echo "===================================="
echo

# Vendor and Device IDs
SEARCH_STRING="0489pE111"
SEARCH_PATH="/usr/lib/udev/hwdb.d"

# Find files
mapfile -t MATCHED_FILES < <(grep --exclude='*.bak' -Rl "$SEARCH_STRING" "$SEARCH_PATH")

if [[ ${#MATCHED_FILES[@]} -eq 0 ]]; then
    echo -e "${RED}No matching HWDB entries found.${NC}"
    exit 1
fi

printf "Found %s matching file(s):\n" "${#MATCHED_FILES[@]}"
printf '  %s\n' "${MATCHED_FILES[@]}"
echo

###########################################
# APPLY FIX (comment block)
###########################################
if [[ "$1" == "--apply" ]]; then
    echo -e "${YELLOW}Applying fix...${NC}"

    for file in "${MATCHED_FILES[@]}"; do
        echo "Processing $file ..."

        # Comment the block beginning with usb:v0489pE111 until blank line
        sed -i '/^usb:v0489pE111/,/^$/ s/^\([^#]\)/# \1/' "$file"
    done

    exit 0
fi


###########################################
# UNDO FIX (uncomment block)
###########################################
if [[ "$1" == "--undo" ]]; then
    echo -e "${YELLOW}Undoing changes...${NC}"

    for file in "${MATCHED_FILES[@]}"; do
        echo "Processing $file ..."
        # Uncomment previously commented block
        sed -i '/^# usb:v0489pE111/,/^$/ s/^# //' "$file"
    done

    echo -e "${GREEN}Undo complete.${NC}"
    exit 0
fi

# update hwdb
echo -e "${YELLOW}Updating hwdb...${NC}"
udevadm hwdb --update
udevadm trigger

systemd-hwdb update

