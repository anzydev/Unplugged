#!/bin/bash
# create_dmg.sh
# Unplugged
#
# Generates a premium, styled macOS DMG for Unplugged.
# Copies Unplugged.app, creates a symlink to /Applications,
# and configures the Finder window layout via AppleScript.

set -e

PROJECT_NAME="Unplugged"
DMG_NAME="${PROJECT_NAME}.dmg"
TEMP_DMG="temp.dmg"
STAGING_DIR="dmg_staging"
VOLUME_NAME="${PROJECT_NAME}"
MOUNT_DIR="/Volumes/${VOLUME_NAME}"

echo "🧹 Cleaning up previous artifacts..."
rm -f "${DMG_NAME}" "${TEMP_DMG}"
rm -rf "${STAGING_DIR}"

echo "📂 Creating staging directory..."
mkdir -p "${STAGING_DIR}"

if [ ! -d "${PROJECT_NAME}.app" ]; then
    echo "❌ Error: ${PROJECT_NAME}.app not found in the current directory."
    echo "Please build the application first (e.g., using Xcode)."
    exit 1
fi

echo "sf Copying ${PROJECT_NAME}.app to staging..."
cp -R "${PROJECT_NAME}.app" "${STAGING_DIR}/"

echo "🔗 Creating Applications symlink..."
ln -s /Applications "${STAGING_DIR}/Applications"

echo "💿 Creating temporary read-write disk image..."
hdiutil create -srcfolder "${STAGING_DIR}" -volname "${VOLUME_NAME}" -fs HFS+ -format UDRW temp.dmg

echo "🔌 Attaching temporary disk image..."
# Mount the DMG
hdiutil attach -readwrite -noverify -noautoopen temp.dmg

# Wait for mount
echo "⏳ Waiting for volume to mount..."
while [ ! -d "${MOUNT_DIR}" ]; do
    sleep 1
done

echo "🎨 Styling DMG layout via AppleScript..."
osascript <<EOF
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        delay 1
        set theView to container window
        set current view of theView to icon view
        set toolbar visible of theView to false
        set statusbar visible of theView to false
        
        -- Set window size and position {left, top, right, bottom}
        set bounds of theView to {400, 200, 920, 520}
        
        -- Set icon options
        set theOptions to icon view options of theView
        set icon size of theOptions to 100
        set arrangement of theOptions to not arranged
        
        -- Position items
        set position of item "${PROJECT_NAME}.app" of theView to {130, 150}
        set position of item "Applications" of theView to {390, 150}
        
        delay 2
        close
    end tell
end tell
EOF

echo "🔌 Detaching temporary disk image..."
hdiutil detach "${MOUNT_DIR}"

echo "📦 Converting to compressed read-only DMG..."
hdiutil convert temp.dmg -format UDZO -imagekey zlib-level=9 -o "${DMG_NAME}"

echo "🧹 Cleaning up temporary files..."
rm -f temp.dmg
rm -rf "${STAGING_DIR}"

echo "✅ DMG successfully created: ${DMG_NAME}"
echo "🎉 You can distribute this file to your users!"
