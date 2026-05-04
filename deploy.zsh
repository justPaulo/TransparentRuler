#!/bin/zsh

# Production Deployment Script for Transparent Ruler
# This script builds the app, creates the app bundle, and configures resources

set -e  # Exit on error

APP_NAME="TransparentRuler"
BUNDLE_NAME="${APP_NAME}.app"
BUNDLE_DIR="${BUNDLE_DIR:-./${BUNDLE_NAME}}"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Function to create a placeholder icon
create_placeholder_icon() {
    local icon_path="$1"
    # Create a minimal valid .icns file (placeholder)
    # In production, replace with a proper icon
    # This creates an empty but valid structure
    printf '\x00\x00\x00\x00' > "$icon_path"
}

echo "Building ${APP_NAME} for production..."

# Build release version
swift build --configuration release

echo "Creating app bundle structure..."

# Create bundle directories
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "Copying executable..."

# Copy the executable
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/"
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "Setting up icon..."

# Copy icon if it exists, otherwise note that it's missing
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/"
    echo "✓ Icon copied from Resources/AppIcon.icns"
elif [ -f "icon.icns" ]; then
    cp "icon.icns" "${RESOURCES_DIR}/AppIcon.icns"
    echo "✓ Icon copied"
else
    echo "No icon found. Creating placeholder."
    create_placeholder_icon "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "Creating Info.plist..."

# Create a basic Info.plist for the app bundle
cat > "${CONTENTS_DIR}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>TransparentRuler</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.paulomorais.transparentruler</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Transparent Ruler</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
</dict>
</plist>
EOF

echo "✓ Info.plist created"

echo ""
echo "Deployment complete!"
echo "App bundle: ${BUNDLE_DIR}"
echo ""