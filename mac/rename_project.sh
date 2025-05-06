#!/bin/bash

# Script to rename an Xcode project from FreeChat to LocalAIGC
# Created for Local AI GC project

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting project renaming process from FreeChat to LocalAIGC${NC}"
echo -e "${YELLOW}This will rename your project files. Make sure you have a backup!${NC}"
echo ""

# Set to exit script on error
set -e

# 1. Rename directories
echo -e "${GREEN}Step 1: Renaming directories...${NC}"
if [ -d "FreeChat" ]; then
  mv FreeChat LocalAIGC
  echo "  ✅ Renamed FreeChat directory to LocalAIGC"
else
  echo -e "${RED}  ❌ FreeChat directory not found${NC}"
fi

if [ -d "FreeChatTests" ]; then
  mv FreeChatTests LocalAIGCTests
  echo "  ✅ Renamed FreeChatTests directory to LocalAIGCTests"
else
  echo -e "${RED}  ❌ FreeChatTests directory not found${NC}"
fi

if [ -d "FreeChatUITests" ]; then
  mv FreeChatUITests LocalAIGCUITests
  echo "  ✅ Renamed FreeChatUITests directory to LocalAIGCUITests"
else
  echo -e "${RED}  ❌ FreeChatUITests directory not found${NC}"
fi

if [ -d "FreeChat.xcodeproj" ]; then
  mv FreeChat.xcodeproj LocalAIGC.xcodeproj
  echo "  ✅ Renamed FreeChat.xcodeproj to LocalAIGC.xcodeproj"
else
  echo -e "${RED}  ❌ FreeChat.xcodeproj not found${NC}"
fi

# 2. Rename specific files
echo -e "${GREEN}Step 2: Renaming specific files...${NC}"

# Find and rename files with FreeChat in the name
find . -name "*FreeChat*.swift" -type f | while read file; do
  newfile=$(echo "$file" | sed 's/FreeChat/LocalAIGC/g')
  dir=$(dirname "$newfile")
  mkdir -p "$dir"
  mv "$file" "$newfile"
  echo "  ✅ Renamed $file to $newfile"
done

# Handle entitlements file
if [ -f "LocalAIGC/FreeChat.entitlements" ]; then
  mv LocalAIGC/FreeChat.entitlements LocalAIGC/LocalAIGC.entitlements
  echo "  ✅ Renamed FreeChat.entitlements to LocalAIGC.entitlements"
fi

# 3. Update file contents - replacing "FreeChat" with "LocalAIGC"
echo -e "${GREEN}Step 3: Updating file contents...${NC}"

# This will catch most text replacements but not in binary files
find . -name "*.swift" -o -name "*.h" -o -name "*.m" -o -name "*.plist" -o -name "*.xcscheme" -o -name "*.pbxproj" -o -name "*.entitlements" -type f | while read file; do
  # Skip files that have "build" in the path
  if [[ "$file" == *"build"* ]]; then
    continue
  fi
  
  # Replace FreeChat with LocalAIGC
  if grep -q "FreeChat" "$file"; then
    sed -i '' 's/FreeChat/LocalAIGC/g' "$file"
    echo "  ✅ Updated references in $file"
  fi
  
  # Also replace "Local AI GC" with spacing to match naming formats in code
  if grep -q "Local AI GC" "$file"; then
    sed -i '' 's/Local AI GC/LocalAIGC/g' "$file"
    echo "  ✅ Updated Local AI GC references in $file"
  fi
done

# 4. Special handling for project.pbxproj
echo -e "${GREEN}Step 4: Updating project.pbxproj file...${NC}"
if [ -f "LocalAIGC.xcodeproj/project.pbxproj" ]; then
  # These are critical replacements for the Xcode project file
  sed -i '' 's/PRODUCT_NAME = FreeChat/PRODUCT_NAME = LocalAIGC/g' LocalAIGC.xcodeproj/project.pbxproj
  sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = "ai.tucuxi.Local-AI-GC"/PRODUCT_BUNDLE_IDENTIFIER = "ai.tucuxi.LocalAIGC"/g' LocalAIGC.xcodeproj/project.pbxproj
  sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = ai.tucuxi.FreeChat/PRODUCT_BUNDLE_IDENTIFIER = ai.tucuxi.LocalAIGC/g' LocalAIGC.xcodeproj/project.pbxproj
  
  # Update development team if needed
  # sed -i '' 's/DEVELOPMENT_TEAM = OLDTEAM;/DEVELOPMENT_TEAM = NEWTEAM;/g' LocalAIGC.xcodeproj/project.pbxproj
  
  echo "  ✅ Updated project.pbxproj"
else
  echo -e "${RED}  ❌ project.pbxproj not found${NC}"
fi

# 5. Update Info.plist
echo -e "${GREEN}Step 5: Updating Info.plist file...${NC}"
if [ -f "LocalAIGC/Info.plist" ]; then
  # Make sure display name is correct - both spaced and non-spaced versions
  sed -i '' 's/<string>Local AI GC<\/string>/<string>LocalAIGC<\/string>/g' LocalAIGC/Info.plist
  sed -i '' 's/<string>FreeChat<\/string>/<string>LocalAIGC<\/string>/g' LocalAIGC/Info.plist
  echo "  ✅ Updated Info.plist"
else
  echo -e "${RED}  ❌ Info.plist not found${NC}"
fi

# 6. Update server-watchdog.entitlements
echo -e "${GREEN}Step 6: Updating entitlements files...${NC}"
if [ -f "server-watchdog.entitlements" ]; then
  # Update any app group identifiers
  sed -i '' 's/ai.tucuxi.FreeChat/ai.tucuxi.LocalAIGC/g' server-watchdog.entitlements
  echo "  ✅ Updated server-watchdog.entitlements"
fi

# 7. Handle App Groups and other special capabilities
echo -e "${GREEN}Step 7: Updating App Groups and special capabilities...${NC}"
find . -name "*.entitlements" -type f | while read file; do
  if grep -q "group.ai.tucuxi.FreeChat" "$file"; then
    sed -i '' 's/group.ai.tucuxi.FreeChat/group.ai.tucuxi.LocalAIGC/g' "$file"
    echo "  ✅ Updated App Group identifier in $file"
  fi
done

echo -e "${GREEN}Renaming process completed!${NC}"
echo ""
echo -e "${YELLOW}Important next steps:${NC}"
echo "1. Open the project in Xcode (open LocalAIGC.xcodeproj)"
echo "2. Fix any remaining reference issues in the project settings:"
echo "   - Check Build Settings > Packaging > Product Name"
echo "   - Check Build Settings > Packaging > Bundle Identifier"  
echo "   - Check Signing & Capabilities > App Groups"
echo "3. Clean the build folder (Shift+Cmd+K)"
echo "4. Build and run the project"
echo "5. If you encounter any issues, restore from your backup"
echo ""
echo -e "${RED}Note: You may need to manually update any Keychain references, NSUserDefaults, or CoreData Entity names that used 'FreeChat'${NC}" 