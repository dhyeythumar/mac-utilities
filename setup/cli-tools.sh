#!/usr/bin/env bash
set -e

# Opinionated CLI tools setup script that does all the CLI tools setup on MacBook machine. And its idempotent, so it can be run multiple times without any issues.

SCRIPT_NAME="CLI Tools Setup"
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
    "This script requires administrator access. You will be prompted for your password."


# Setup sudo authentication and keep-alive
setup_sudo_keepalive
setup_cleanup_trap


section_header "Installing Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
    info "Xcode Command Line Tools are already installed, skipping..."
else
    action "Installing Xcode Command Line Tools..." \
        "A dialog will appear - please click 'Install' and wait for it to complete." \
        "This may take 5-10 minutes depending on your internet connection."

    xcode-select --install
    wait_for_user "Press ENTER once the installation is complete..."

    # Verify installation completed successfully
    if xcode-select -p &>/dev/null; then
        success "Xcode Command Line Tools installed successfully!"
    else
        error_exit "Xcode Command Line Tools installation was not detected" \
            "Please ensure the installation completed successfully and try again."
    fi
fi


section_header "Installing Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    info "Oh My Zsh is already installed, skipping..."
else
    action "Oh My Zsh not found, installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    success "Oh My Zsh installed successfully!"
fi


section_header "Installing Homebrew (Package Manager)"

# Determine the correct Homebrew path based on system architecture
SYSTEM_ARCH=$(uname -m)
if [ "$SYSTEM_ARCH" = "arm64" ]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

if [ -f "$HOMEBREW_PREFIX/bin/brew" ]; then
    info "Homebrew is already installed at $HOMEBREW_PREFIX, skipping installation..."
elif command -v brew &>/dev/null; then
    # Homebrew exists but at wrong location for this architecture
    CURRENT_BREW=$(which brew)
    warning "Homebrew found at $CURRENT_BREW but expected at $HOMEBREW_PREFIX/bin/brew" \
        "This may cause architecture mismatches when installing packages" \
        "Consider reinstalling Homebrew for your $SYSTEM_ARCH architecture"
else
    action "Homebrew not found, installing..."

    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        success "Homebrew installed successfully!"
    else
        error_exit "Failed to install Homebrew"
    fi
fi

# Always ensure the correct Homebrew is in PATH for this session
if [ -f "$HOMEBREW_PREFIX/bin/brew" ]; then
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
    info "Using Homebrew at $HOMEBREW_PREFIX/bin/brew"
fi


section_header "Updating Homebrew packages"
if brew update; then
    success "Homebrew packages updated successfully!"
else
    warning "Failed to update Homebrew, continuing anyway..."
fi


section_header "Installing CLI tools via Homebrew"
# Array of CLI tools to install & manage via Homebrew
declare -a cli_tools=(
    "nvm"
    "awscli"
    "mysides"
    "dockutil"
    "mas"
    "netcat"
)

for tool in "${cli_tools[@]}"; do
    # Convert tool name to a more readable format for display
    tool_display=$(echo "$tool" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

    if brew list "$tool" &>/dev/null; then
        info "$tool_display is already installed, skipping..."
    else
        action "$tool_display not found, installing..."
        
        # Install and wait for completion
        if brew install "$tool" 2>&1; then
            # Explicitly wait for any background processes
            wait
            
            # Verify installation completed
            if brew list "$tool" &>/dev/null; then
                success "$tool_display installed successfully!"
            else
                warning "$tool_display installation reported success but package not found, continuing anyway..."
            fi
        else
            warning "Failed to install $tool_display, continuing anyway..."
        fi
    fi

    # Show installed version
    if brew list "$tool" &>/dev/null; then
        echo "⌙  $tool_display installed version: $(brew list "$tool" --versions)"
    else
        echo "⌙  $tool_display version: Not available"
    fi
done

# Final sync point - ensure all background processes are complete
action "Ensuring all CLI tools installations & background processes are completed..."
wait


section_header "Setting up Node.js (LTS version)"
# Setup NVM environment
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"

# Add nvm to shell profile if not already present
if ! grep -q 'NVM_DIR' ~/.zshrc; then
    action "Adding NVM to ~/.zshrc file..."
    echo "" >> ~/.zshrc
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
    echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc
    echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"' >> ~/.zshrc
fi

# Load nvm in current session
if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
    \. "/opt/homebrew/opt/nvm/nvm.sh"
    
    # Install latest Node.js LTS version
    action "Installing latest Node.js LTS version..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    success "Node.js $(node -v) installed and set as default!"
else
    warning "NVM script not found. Please restart your terminal and run 'nvm install --lts' manually."
fi


script_notification "✅ $SCRIPT_NAME completed successfully!" \
    "📌 To apply all changes, your terminal session needs to be restarted." \
    "🔄 Restarting shell session..."

sleep 2
exec zsh -l
