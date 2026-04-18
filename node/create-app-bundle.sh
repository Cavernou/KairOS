#!/bin/bash

# Create macOS .app bundle for KairOS Node
# This creates a proper double-clickable application

APP_NAME="KairOS Node"
APP_DIR="KairOS Node.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Remove existing app bundle if it exists
if [ -d "$APP_DIR" ]; then
    rm -rf "$APP_DIR"
fi

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launch-node</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.kairos.node</string>
    <key>CFBundleName</key>
    <string>KairOS Node</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.1</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Create the launcher script
cat > "$MACOS_DIR/launch-node" << 'EOF'
#!/bin/bash

# KairOS Node Launcher
# This script is executed when the .app is double-clicked

# Get the directory where the .app is located
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_DIR="$( cd "$APP_DIR/../../../node" && pwd )"

# Change to the node directory
cd "$SCRIPT_DIR"

# Check if config file exists
if [ ! -f "config.yaml" ]; then
    osascript -e 'display dialog "Error: config.yaml not found in the node directory. Please copy config.example.yaml to config.yaml and configure it." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Check if node binary exists
if [ ! -f "kairos-node" ]; then
    osascript -e 'display dialog "Error: kairos-node binary not found. Please build the node first with: go build ./cmd/kairos-node" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Open Terminal and run the node
osascript -e 'tell application "Terminal"
    activate
    do script "cd '"$SCRIPT_DIR"' && ./kairos-node -config config.yaml"
end tell'
EOF

# Make the launcher script executable
chmod +x "$MACOS_DIR/launch-node"

echo "Created $APP_DIR"
echo "You can now double-click $APP_DIR to launch the KairOS Node"
