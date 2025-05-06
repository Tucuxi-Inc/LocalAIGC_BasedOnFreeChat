# Project Renaming: FreeChat → LocalAIGC

This document provides step-by-step instructions for renaming the FreeChat project to LocalAIGC.

## Preparation

1. **Make a backup** of your entire project:
   ```bash
   cp -R mac mac-backup
   ```

2. **Close Xcode** completely before starting.

## Automatic Renaming

1. **Run the renaming script:**
   ```bash
   cd mac
   chmod +x rename_project.sh
   ./rename_project.sh
   ```

2. **The script will handle:**
   - Renaming directories
   - Renaming files that contain "FreeChat" in their name
   - Updating references to "FreeChat" in file contents
   - Handling special files like Info.plist and project.pbxproj
   - Updating app group identifiers and entitlements

## Manual Updates

After running the script, you'll need to check some items manually:

1. **Open the project in Xcode** (you may need to double-click the `.xcodeproj` file)
   ```bash
   open LocalAIGC.xcodeproj
   ```

2. **Check the Target Settings:**
   - Product Name should be "LocalAIGC"
   - Bundle Identifier should be "ai.tucuxi.LocalAIGC"
   - Development Team should be correct
   - Signing & Capabilities should be properly configured

3. **Check CoreData Model:**
   - Rename the `.xcdatamodeld` file if it's still named "FreeChat"
   - Update any entity names if needed
   - Consider using the provided `CoreDataFix.swift` helper if needed

4. **Check App Group Identifiers:**
   - Make sure any app group identifiers are updated
   - Check app extensions and their entitlements

5. **Clean and Build:**
   - Clean the project (Shift+Cmd+K)
   - Try to build (Cmd+B)
   - Fix any remaining errors

## Possible Issues and Solutions

### CoreData Issues

If you encounter CoreData errors after renaming:

1. Add the `coredata_fix.swift` file to your project
2. Update the `PersistenceController` to use this helper
3. Build and run

### App Groups and Keychain Issues

If you experience keychain or app group issues:

1. Delete the app from the simulator/device
2. Clean build folder
3. Build and run fresh

### Bundle Identifier Issues

If your app is already on the App Store, be careful with Bundle ID changes. Consider:

1. Keeping the original Bundle ID
2. Creating a new app record in App Store Connect
3. Using App Groups to share data between versions

## Restore from Backup

If something goes wrong:

```bash
cd ..
rm -rf mac
cp -R mac-backup mac
```

## Next Steps

After successful renaming:

1. Update app screenshots and marketing materials
2. Update any documentation references
3. Update CI/CD configurations if applicable 