#!/usr/bin/env bash

# ============================================================================
# Common Utilities for Mac Setup Scripts
# This file contains shared functions used across multiple setup scripts
# ============================================================================

# Colors for output
readonly RED='\033[0;31m'           # For error messages
readonly GREEN='\033[0;32m'         # For success messages
readonly YELLOW='\033[0;33m'        # For warning messages
readonly BLUE='\033[0;34m'          # For muted text (like info messages)
readonly CYAN='\033[0;36m'          # For automated action messages
readonly PURPLE='\033[0;35m'        # For manual action messages
readonly BRIGHT_WHITE='\033[1;37m'  # For section headers
readonly BOLD='\033[1m'             # For bold text
readonly NC='\033[0m'               # No Color (reset color)

# Global variable to track sudo keeper PID
SUDO_KEEPER_PID=""

# Function to authenticate and keep sudo alive
# This pre-authenticates sudo and keeps it alive in the background
setup_sudo_keepalive() {
    echo -e "${BLUE}🔑 Requesting administrator access...${NC}"
    if ! sudo -v; then
        echo -e "${RED}❌ Error: Administrator access is required to run this script.${NC}"
        echo -e "${YELLOW}   Please run this script in an interactive terminal, not piped from curl.${NC}"
        exit 1
    fi

    # Keep sudo alive in the background
    (while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null) &
    SUDO_KEEPER_PID=$!
}

# Function to cleanup sudo keeper process
cleanup_sudo_keepalive() {
    if [ ! -z "$SUDO_KEEPER_PID" ]; then
        kill "$SUDO_KEEPER_PID" 2>/dev/null || true
    fi
}

# Function to setup cleanup trap
# This ensures sudo keeper is killed when script exits
setup_cleanup_trap() {
    trap cleanup_sudo_keepalive EXIT
}

# Function to display script header
# Usage: script_notification "Script Title" "Optional line 1" "Optional line 2" ...
script_notification() {
    local width=100
    local separator=$(printf "%${width}s" | tr ' ' '=')
    local title="$1"
    shift  # Remove first argument

    echo -e "${BLUE}${BOLD}${separator}"
    local padding=$(( (width - ${#title}) / 2 ))
    printf "%${padding}s%s\n" "" "$title"
    echo "$separator"

    # Display remaining arguments as additional lines
    for line in "$@"; do
        echo "${line}"
    done
    echo -e "${NC}"
}

# Function to display section header
# Usage: section_header "Section Title" "Optional line 1" "Optional line 2" ...
section_header() {
    local title="$1"
    shift  # Remove first argument

    echo -e "${BRIGHT_WHITE}${BOLD}"
    echo "--------------------------------------------"
    echo "🎯 ${title}"
    echo "--------------------------------------------"

        # Display remaining arguments as additional lines
    for line in "$@"; do
        echo "${line}"
    done
    echo -n -e "${NC}"
}

# Function to display message with color
# Usage: _print "color" "message" "optional line 1" "optional line 2" ...
_print() {
    local color="$1"
    local message="$2"
    shift 2
    
    echo -e "\n${color}${message}"
    # Display remaining arguments as additional lines
    for line in "$@"; do
        echo "⌙  ${line}"
    done
    echo -n -e "${NC}"
}

# Function to display info message
# Usage: info "Main message" "Optional line 1" "Optional line 2" ...
info() {
    _print "${BLUE}" "ℹ️  $1" "${@:2}"
}

# Function to display action message
# Usage: action "Main message" "Optional line 1" "Optional line 2" ...
action() {
    _print "${CYAN}" "⚡️ $1" "${@:2}"
}

manual_action() {
    _print "${PURPLE}" "👉 $1" "${@:2}"
}

# Function to display success message
# Usage: success "Success message"
success() { 
    _print "${GREEN}" "✅ $1" "${@:2}"
}

# Function to display warning message
# Usage: warning "Warning message"
warning() {
    _print "${YELLOW}" "⚠️  $1" "${@:2}"
}

# Function to display error message
# Usage: error "Error message" "Optional line 1" "Optional line 2" ...
error() {
    _print "${RED}" "❌ $1" "${@:2}"
}

# Function to display error message and exit
# Usage: error_exit "Error message" "Optional line 1" "Optional line 2" ...
error_exit() {
    error "$@"
    exit 1
}

# Function to restart a service/process
# Usage: restart_service "process_name"
restart_service() {
    local process_name="$1"

    echo -e "${BLUE}${BOLD}"
    echo "🔄 Restarting ${process_name} to apply changes..."
    killall "${process_name}" 2>/dev/null || true
    echo -e "${NC}"
}

# Function to wait for user confirmation
# Usage: wait_for_user "Press Enter to continue"
wait_for_user() {
    local message="${1:-Press ENTER to continue...}"

    echo -e "${PURPLE}${BOLD}"
    read -p ">> ${message} " -r </dev/tty
    echo -e "${NC}"
}
