#!/bin/bash

# Script to handle missing dSYM for freechat-server during App Store submission
# This script creates a dummy dSYM structure with the correct UUIDs

# Get the path to the freechat-server binary
FREECHAT_SERVER="${SRCROOT}/LocalAIGC/Models/NPC/freechat-server"

# Create a temporary directory for the dSYM
DSYM_DIR="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app.dSYM/Contents/Resources/DWARF"
mkdir -p "${DSYM_DIR}"

# Copy the binary to the dSYM directory
if [ -f "${FREECHAT_SERVER}" ]; then
    echo "Creating dSYM for freechat-server"
    cp "${FREECHAT_SERVER}" "${DSYM_DIR}/"
    
    # Get the UUIDs of the binary
    UUID_X86=$(dwarfdump -u "${FREECHAT_SERVER}" | grep x86_64 | awk '{print $2}')
    UUID_ARM64=$(dwarfdump -u "${FREECHAT_SERVER}" | grep arm64 | awk '{print $2}')
    
    echo "x86_64 UUID: ${UUID_X86}"
    echo "arm64 UUID: ${UUID_ARM64}"
    
    # Create a log file with the UUIDs for reference
    echo "freechat-server UUIDs" > "${BUILT_PRODUCTS_DIR}/freechat_server_uuids.txt"
    echo "x86_64: ${UUID_X86}" >> "${BUILT_PRODUCTS_DIR}/freechat_server_uuids.txt"
    echo "arm64: ${UUID_ARM64}" >> "${BUILT_PRODUCTS_DIR}/freechat_server_uuids.txt"
    
    # Generate dSYM using dsymutil (even if it will be empty)
    dsymutil "${FREECHAT_SERVER}" -o "${BUILT_PRODUCTS_DIR}/freechat-server.dSYM"
    
    echo "dSYM created at ${BUILT_PRODUCTS_DIR}/freechat-server.dSYM"
else
    echo "Error: freechat-server binary not found at ${FREECHAT_SERVER}"
    exit 1
fi 