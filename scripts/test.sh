#!/usr/bin/env bash
set -e

SCRIPT_NAME="Test Script"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/common.sh"

script_notification "🎬 Starting $SCRIPT_NAME" \
    "Overview of the script and what it will do."


section_header "Section 1" \
    "Description of section 1."

info "Info message"
success "Success message"
warning "Warning message"
error "Error message" "Optional message to display"

# error_exit "Error message" "Optional message to display"

action "Action message" \
    "Optional message to display."

manual_action "Manual action message" \
    "Optional message to display."

wait_for_user "Press Enter to continue (optional message)..."

script_notification "✅ $SCRIPT_NAME completed successfully!" \
    "Summary of the script and what it did." \
    "Optional message to display."
