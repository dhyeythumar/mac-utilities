#!/usr/bin/env bash
set -e

# Opinionated GUI applications setup script that does all the GUI applications setup on MacBook machine. And its idempotent, so it can be run multiple times without any issues.

SCRIPT_NAME="GUI Applications Setup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/common.sh"

script_notification "🎬 Starting $SCRIPT_NAME" \
    "This script requires administrator access. You will be prompted for your password."


# Setup sudo authentication and keep-alive
setup_sudo_keepalive
setup_cleanup_trap


section_header "Setting up App Store applications" \
    "NOTE: mas is not supported on newer macOS versions." \
    "Check https://github.com/mas-cli/mas/issues/1029 issue for more details." \
    "If upstream issue is fixed, this script will be updated to install apps from App Store else this section would be deprecated in future releases."

# Check if mas is installed
if ! command -v mas &>/dev/null; then
    error_exit "mas (Mac App Store CLI) is not installed" \
        "Please run cli-tools.setup.sh first to install mas"
fi

# Note: mas account command is not supported on newer macOS versions
# So we can't reliably check if signed in. If mas install fails, user will need to sign in manually.
warning "Make sure you're signed into the Mac App Store" \
    "If installations fail, please sign in to the App Store and run this script again"

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
        info "$app_display is already installed, skipping..."
    else
        action "$app_display not found, installing..."

        if mas install "$app_id"; then
            success "$app_display installed successfully!"
        else
            warning "Failed to install $app_display, continuing anyway..."
        fi
    fi
done


section_header "Setting up GUI applications via Homebrew Cask"
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

for app in "${brew_cask_apps[@]}"; do
    # Convert cask name to a more readable format for display
    app_display=$(echo "$app" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

    if brew list --cask "$app" &>/dev/null; then
        info "$app_display is already installed, skipping..."
    else
        action "$app_display not found, installing..."

        # Use sudo to leverage the authenticated session and avoid password prompts
        if sudo brew install --cask "$app"; then
            success "$app_display installed successfully!"
        else
            warning "Failed to install $app_display, continuing anyway..."
        fi
    fi
done


section_header "Setting up GUI applications directly from .dmg files"
# Function to install app from DMG
install_from_dmg() {
    local app_name="$1"
    local download_url="$2"
    local dmg_name="$3"
    local app_file="${4:-$app_name.app}"  # Default to app_name.app if not specified

    # Check if app is already installed
    if [ -d "/Applications/$app_file" ]; then
        info "$app_name is already installed, skipping..."
        return 0
    fi

    action "Installing $app_name..."

    # Create temporary directory
    local tmp_dir=$(mktemp -d)
    local dmg_path="$tmp_dir/$dmg_name"

    echo "⌙  📥 Downloading $app_name..."
    if ! curl -L -o "$dmg_path" "$download_url" 2>/dev/null; then
        warning "Failed to download $app_name, skipping..."
        rm -rf "$tmp_dir"
        return 1
    fi

    echo "⌙  💿 Mounting DMG..."
    local mount_point=$(hdiutil attach "$dmg_path" -nobrowse -quiet | grep '/Volumes/' | tail -1 | awk '{print $NF}')

    if [ -z "$mount_point" ]; then
        warning "Failed to mount DMG for $app_name, skipping..."
        rm -rf "$tmp_dir"
        return 1
    fi

    echo "⌙  📋 Copying application to /Applications..."
    if cp -R "$mount_point/$app_file" /Applications/; then
        success "$app_name installed successfully!"
    else
        warning "Failed to copy $app_name to Applications, continuing anyway..."
    fi

    action "Cleaning up..."
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


script_notification "✅ $SCRIPT_NAME completed successfully!" \
    "📌 To apply all changes, your terminal session needs to be restarted." \
    "🔄 Restarting shell session..."

sleep 2
exec zsh -l
