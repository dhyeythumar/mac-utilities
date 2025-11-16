#!/usr/bin/env bash
set -e

# Opinionated CLI tools setup script that does all the CLI tools setup on MacBook machine. And its idempotent, so it can be run multiple times without any issues.

# Check if running in interactive mode and warn about sudo requirements
echo "--------------------------------------------"
echo "🔧 CLI Tools Setup for MacOS"
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


echo ""
echo "--------------------------------------------"
echo "Installing Xcode Command Line Tools"
echo "--------------------------------------------"

if xcode-select -p &>/dev/null; then
    echo "✅ Xcode Command Line Tools are already installed, skipping..."
else
    echo "📦 Installing Xcode Command Line Tools..."
    echo "   A dialog will appear - please click 'Install' and wait for it to complete."
    echo "   This may take 5-10 minutes depending on your internet connection."
    xcode-select --install
    
    # Wait for user confirmation
    echo ""
    read -p "⏳ Press ENTER once the installation is complete... " -r
    
    # Verify installation completed successfully
    if xcode-select -p &>/dev/null; then
        echo "✅ Xcode Command Line Tools installed successfully!"
    else
        echo "❌ Error: Xcode Command Line Tools installation was not detected."
        echo "   Please ensure the installation completed successfully and try again."
        exit 1
    fi
fi


echo ""
echo "--------------------------------------------"
echo "Setting up Oh My Zsh"
echo "--------------------------------------------"

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "✅ Oh My Zsh is already installed, skipping..."
else
    echo "📦 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ Oh My Zsh installed successfully!"
fi


echo ""
echo "--------------------------------------------"
echo "Setting up Homebrew (Package Manager)"
echo "--------------------------------------------"

if command -v brew &>/dev/null; then
    echo "✅ Homebrew is already installed, skipping..."
else
    echo "📦 Homebrew not found. Installing..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        echo "✅ Homebrew installed successfully!"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        echo "❌ Failed to install Homebrew"
        exit 1
    fi
fi

echo -e "\n📦 Updating Homebrew packages..."
if brew update; then
    echo "✅ Homebrew packages updated successfully!"
else
    echo "⚠️  Warning: Failed to update Homebrew, continuing anyway..."
fi


echo ""
echo "--------------------------------------------"
echo "Setting up CLI tools via Homebrew"
echo "--------------------------------------------"

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

    if ! brew list "$tool" &>/dev/null; then
        echo "📦 Installing $tool_display..."
        
        # Install and wait for completion
        if brew install "$tool" 2>&1; then
            # Explicitly wait for any background processes
            wait
            
            # Verify installation completed
            if brew list "$tool" &>/dev/null; then
                echo "✅ $tool_display installed successfully!"
            else
                echo "⚠️  Warning: $tool_display installation reported success but package not found, continuing anyway..."
            fi
        else
            echo "⚠️  Warning: Failed to install $tool_display, continuing anyway..."
        fi
    else
        echo "✅ $tool_display is already installed, skipping..."
    fi

    # Show installed version
    if brew list "$tool" &>/dev/null; then
        echo "   $tool_display installed version: $(brew list "$tool" --versions)"
    else
        echo "   $tool_display version: Not available"
    fi
    echo ""
done

# Final sync point - ensure all background processes are complete
echo "⏳ Ensuring all installations are complete..."
wait
echo "✅ All CLI tools installation completed!"


echo ""
echo "--------------------------------------------"
echo "Setting up Node.js (LTS version)"
echo "--------------------------------------------"

# Setup NVM environment
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"

# Add nvm to shell profile if not already present
if ! grep -q 'NVM_DIR' ~/.zshrc; then
    echo "📝 Adding NVM to ~/.zshrc file..."
    echo "" >> ~/.zshrc
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
    echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc
    echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"' >> ~/.zshrc
fi

# Load nvm in current session
if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
    \. "/opt/homebrew/opt/nvm/nvm.sh"
    
    # Install latest Node.js LTS version
    echo "📦 Installing latest Node.js LTS version..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    echo "✅ Node.js $(node -v) installed and set as default!"
else
    echo -e "\n⚠️  Warning: NVM script not found. Please restart your terminal and run 'nvm install --lts' manually."
fi


echo ""
echo "--------------------------------------------"
echo "Setting up stskeygen (AWS STS key generator)"
echo "--------------------------------------------"

if command -v stskeygen &>/dev/null; then
    echo "✅ stskeygen is already installed, skipping..."
else
    echo "📦 Installing stskeygen..."
    # Add the tap if not already added
    if ! brew tap | grep -q "cimpress-mcp/stskeygen-installers"; then
        echo "   Adding Cimpress-MCP tap..."
        if ! brew tap Cimpress-MCP/stskeygen-installers https://github.com/Cimpress-MCP/stskeygen-installers.git; then
            echo "❌ Failed to add tap"
            exit 1
        fi
    fi
    
    if brew install Cimpress-MCP/stskeygen-installers/stskeygen; then
        echo "✅ stskeygen installed successfully!"
    else
        echo "❌ Failed to install stskeygen"
        exit 1
    fi
fi


echo ""
echo "================================================================================"
echo "✅ CLI Tools Setup Complete!"
echo "================================================================================"
echo ""
echo "📌 To apply all changes, your terminal session needs to be restarted."
echo "🔄 Restarting shell session..."
echo "   All changes will be available in the new session."
sleep 2
exec zsh -l
