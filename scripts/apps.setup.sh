#!/usr/bin/env bash
set -e

# Opinionated GUI applications setup script that does all the GUI applications setup on MacBook machine. And its idempotent, so it can be run multiple times without any issues.

# Check if running in interactive mode and warn about sudo requirements
echo "--------------------------------------------"
echo "🔧 GUI Applications Setup for MacOS"
echo "--------------------------------------------"
echo "⚠️  This script requires administrator access."
echo "💡 You may be prompted for your password during installation."
echo ""

# Pre-authenticate sudo to avoid issues during installation
echo "🔑 Requesting administrator access..."
if ! sudo -v; then
    echo "❌ Error: Administrator access is required to run this script."
    echo "   Please run this script in an interactive terminal, not piped from curl."
    exit 1
fi

# Keep sudo alive in the background
(while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null) &
SUDO_KEEPER_PID=$!

# Cleanup function to kill the sudo keeper process
cleanup() {
    if [ ! -z "$SUDO_KEEPER_PID" ]; then
        kill "$SUDO_KEEPER_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT


echo "--------------------------------------------"
echo "Setting up App Store applications (NOTE: mas is not supported on newer macOS versions)"
echo "   Check https://github.com/mas-cli/mas/issues/1029 issue for more details."
echo "   If upstream issue is fixed, this script will be updated to install apps from App Store else this section would be deprecated in future releases."
echo ""
echo "--------------------------------------------"

# Check if mas is installed
if ! command -v mas &>/dev/null; then
    echo "❌ Error: mas (Mac App Store CLI) is not installed"
    echo "   Please run cli-tools.setup.sh first to install mas"
    exit 1
fi

# Note: mas account command is not supported on newer macOS versions
# So we can't reliably check if signed in. If mas install fails, user will need to sign in manually.
echo "💡 Note: Make sure you're signed into the Mac App Store"
echo "   If installations fail, please sign in to the App Store and run this script again"
echo ""

echo "📦 Attempting to install Mac App Store applications..."
echo ""

# Array of App Store apps (Display Name and App Store ID)
# Format: "Display Name:App Store ID"
# declare -a app_store_apps=(
#     "Slack:803453959"
#     "OneDrive:823766827"
#     "Keeper Password Manager:414781829"
# )
declare -a app_store_apps=()

for app_entry in "${app_store_apps[@]}"; do
    IFS=':' read -r app_display app_id <<< "$app_entry"
    
    # Check if app is already installed
    if mas list | grep -q "^$app_id"; then
        echo "✅ $app_display is already installed, skipping..."
    else
        echo "📦 Installing $app_display (ID: $app_id)..."
        if mas install "$app_id"; then
            echo "✅ $app_display installed successfully!"
        else
            echo "⚠️  Warning: Failed to install $app_display, continuing anyway..."
        fi
    fi
    echo ""
done


echo ""
echo "--------------------------------------------"
echo "Setting up GUI applications via Homebrew Cask"
echo "--------------------------------------------"

# Array of GUI applications to install & manage via Homebrew Cask
declare -a brew_cask_apps=(
    "google-chrome"
    "postman"
    "microsoft-teams"
    "adobe-creative-cloud"
    "cursor"
    "visual-studio-code"
    "slack"
    "onedrive"
)

echo "📦 Installing GUI applications via Homebrew Cask..."
echo ""

for app in "${brew_cask_apps[@]}"; do
    # Convert cask name to a more readable format for display
    app_display=$(echo "$app" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

    if ! brew list --cask "$app" &>/dev/null; then
        echo "📦 Installing $app_display..."

        # Use sudo to leverage the authenticated session and avoid password prompts
        if sudo brew install --cask "$app"; then
            echo "✅ $app_display installed successfully!"
        else
            echo "⚠️  Warning: Failed to install $app_display, continuing anyway..."
        fi
    else
        echo "✅ $app_display is already installed, skipping..."
    fi
    echo ""
done


echo ""
echo "-----------------------------------------------------"
echo "Setting up GUI applications directly from .dmg files"
echo "-----------------------------------------------------"

# Function to install app from DMG
install_from_dmg() {
    local app_name="$1"
    local download_url="$2"
    local dmg_name="$3"
    local app_file="${4:-$app_name.app}"  # Default to app_name.app if not specified
    
    echo "📦 Installing $app_name..."
    
    # Check if app is already installed
    if [ -d "/Applications/$app_file" ]; then
        echo "✅ $app_name is already installed, skipping..."
        return 0
    fi
    
    # Create temporary directory
    local tmp_dir=$(mktemp -d)
    local dmg_path="$tmp_dir/$dmg_name"
    
    echo "  📥 Downloading $app_name..."
    if ! curl -L -o "$dmg_path" "$download_url" 2>/dev/null; then
        echo "⚠️  Warning: Failed to download $app_name, skipping..."
        rm -rf "$tmp_dir"
        return 1
    fi
    
    echo "  💿 Mounting DMG..."
    local mount_point=$(hdiutil attach "$dmg_path" -nobrowse -quiet | grep '/Volumes/' | tail -1 | awk '{print $NF}')
    
    if [ -z "$mount_point" ]; then
        echo "⚠️  Warning: Failed to mount DMG for $app_name, skipping..."
        rm -rf "$tmp_dir"
        return 1
    fi
    
    echo "  📋 Copying application to /Applications..."
    if cp -R "$mount_point/$app_file" /Applications/; then
        echo "✅ $app_name installed successfully!"
    else
        echo "⚠️  Warning: Failed to copy $app_name to Applications, continuing anyway..."
    fi
    
    echo "  🧹 Cleaning up..."
    hdiutil detach "$mount_point" -quiet
    rm -rf "$tmp_dir"
    
    return 0
}

# echo ""
# echo "Installing Example App..."
# echo "   This is just an example of how to install an app from a DMG file."
# echo "   You can replace this with the actual app you want to install."
# echo ""

# EXAMPLE_APP_DOWNLOAD_URL="https://www.example.com/download-example"

# # Try to install Example App
# if ! install_from_dmg "Example" "$EXAMPLE_APP_DOWNLOAD_URL" "Example.dmg" "Example.app"; then
#     echo ""
#     echo "⚠️  Note: If the download failed, the URL might have changed."
#     echo "   Opening $EXAMPLE_APP_DOWNLOAD_URL to manually download the DMG file..."
#     open "$EXAMPLE_APP_DOWNLOAD_URL"
#     read -p "Press Enter once you've downloaded the DMG file..." </dev/tty
# fi


echo ""
echo "================================================================================"
echo "GUI applications setup complete! 🚀"
echo "================================================================================"
