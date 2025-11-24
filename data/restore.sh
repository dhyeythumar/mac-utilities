#!/usr/bin/env bash
set -e

# Opinionated Data Restore Service that does all the data restore on MacBook machine. And its idempotent, so it can be run multiple times without any issues.

SCRIPT_NAME="Data Restore Service"
SCRIPT_DIR=$(pwd)

# Determine if running from repo or standalone
# Check if we're in the repo structure (utils/common.sh exists relative to script)
if [ -f "${SCRIPT_DIR}/utils/common.sh" ]; then
    # Running from within the repo
    COMMON_SCRIPT="${SCRIPT_DIR}/utils/common.sh"
else
    # Running standalone (downloaded via curl | bash)
    # Use ~/.mac-utilities for dependencies
    MAC_UTILS_DIR="${HOME}/.mac-utilities"
    COMMON_SCRIPT="${MAC_UTILS_DIR}/common.sh"
    
    if [ ! -f "${COMMON_SCRIPT}" ]; then
        echo "📥 Downloading common utilities to ${MAC_UTILS_DIR}..."
        mkdir -p "${MAC_UTILS_DIR}"
        curl -fsSL https://raw.githubusercontent.com/dhyeythumar/mac-utilities/refs/heads/main/utils/common.sh -o "${COMMON_SCRIPT}"
    fi
fi

# Source common utilities
source "${COMMON_SCRIPT}"

script_notification "🎬 Starting $SCRIPT_NAME" \
    "This script will sync your data to the backup directory."


BACKUP_ROOT="${HOME}/OneDrive - National Pen Company/Personal Files/MacBook/App Data"
restore_dir() {
    local src="$1"
    local dest="$2"

    if [ -d "$src" ]; then
        action "Restoring '$src' to '$dest'"
        
        # Create destination if it doesn't exist
        mkdir -p "$dest"
        
        # Sync from backup to local (merge mode - no --delete)
        # This preserves existing files/folders not in backup (like History, workspaceStorage)
        rsync -av --progress "$src/" "$dest/"
        
        success "Restored '$src' to '$dest'"
    else
        warning "Backup not found at $src"
    fi
}


APP_1_NAME="Cursor"
CURSOR_BACKUP_ROOT="${BACKUP_ROOT}/${APP_1_NAME}"
section_header "Restoring ${APP_1_NAME} Data" \
    "Backup source: ${CURSOR_BACKUP_ROOT}"

if [ -d "${CURSOR_BACKUP_ROOT}" ]; then
    # Check if Cursor is running
    if pgrep -x "Cursor" >/dev/null; then
        manual_action "Cursor is currently running." \
            "Please close Cursor to ensure data is restored correctly."
        wait_for_user "Press ENTER once Cursor is closed..."
    fi

    # 1. Install Extensions using Cursor CLI
    if [ -f "${CURSOR_BACKUP_ROOT}/extensions.txt" ]; then
        if command -v cursor &>/dev/null; then
            action "Installing Cursor extensions from backup..."
            
            # Read each extension from the file and install it
            while IFS= read -r extension; do
                # Skip empty lines
                [ -z "$extension" ] && continue
                
                info "Installing extension: $extension"
                cursor --install-extension "$extension" 2>&1 | grep -v "is already installed" || true
            done < "${CURSOR_BACKUP_ROOT}/extensions.txt"
            
            success "Extensions installation completed!"
        else
            warning "Cursor CLI not found. Skipping extensions installation." \
                "To enable extensions restore, ensure 'cursor' command is available in PATH."
        fi
    else
        warning "Extensions list not found at ${CURSOR_BACKUP_ROOT}/extensions.txt"
    fi

    # 2. User Data (Settings, Keybindings, Snippets, Workspace Storage, etc.)
    restore_dir "${CURSOR_BACKUP_ROOT}/User" "${HOME}/Library/Application Support/Cursor/User"

    success "${APP_1_NAME} restore completed!"
else
    error "Backup source not found at ${CURSOR_BACKUP_ROOT}!"
fi

script_notification "✅ $SCRIPT_NAME completed successfully!"
