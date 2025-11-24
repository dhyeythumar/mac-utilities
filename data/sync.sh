#!/usr/bin/env bash
set -e

# Opinionated Data Sync Service that does all the data sync on MacBook machine. And its idempotent, so it can be run multiple times without any issues.

SCRIPT_NAME="Data Sync Service"
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
sync_dir() {
    local src="$1"
    local dest="$2"
    shift 2
    local exclude_args=("$@")

    if [ -d "$src" ]; then
        action "Syncing '$src' to '$dest'"
        mkdir -p "$(dirname "$dest")"
        
        # Build rsync command with optional exclude patterns
        local rsync_cmd="rsync -av --delete --progress"
        for exclude in "${exclude_args[@]}"; do
            rsync_cmd="$rsync_cmd --exclude=$exclude"
        done
        rsync_cmd="$rsync_cmd \"$src/\" \"$dest/\""
        
        # Execute rsync command
        eval $rsync_cmd
        
        success "Synced '$src' to '$dest'"
    else
        warning "Source directory not found: $src"
    fi
}


APP_1_NAME="Cursor"
CURSOR_BACKUP_ROOT="${BACKUP_ROOT}/${APP_1_NAME}"
section_header "Syncing ${APP_1_NAME} Data" \
    "Backup destination: ${CURSOR_BACKUP_ROOT}"

mkdir -p "${CURSOR_BACKUP_ROOT}" # Create destination directory if it doesn't exist

# 1. Export Extensions list using Cursor CLI
if command -v cursor &>/dev/null; then
    action "Exporting Cursor extensions list..."
    cursor --list-extensions > "${CURSOR_BACKUP_ROOT}/extensions.txt"
    success "Exported extensions list to extensions.txt"
else
    warning "Cursor CLI not found. Skipping extensions export." \
        "To enable extensions sync, ensure 'cursor' command is available in PATH."
fi

# 2. User Data (Settings, Keybindings, Snippets, etc.)
sync_dir "${HOME}/Library/Application Support/Cursor/User" "${CURSOR_BACKUP_ROOT}/User" \
    "History" \
    "workspaceStorage" \
    "globalStorage/*.vscdb" \
    "globalStorage/*.vscdb.backup"

success "${APP_1_NAME} sync completed!"

script_notification "✅ $SCRIPT_NAME completed successfully!"
