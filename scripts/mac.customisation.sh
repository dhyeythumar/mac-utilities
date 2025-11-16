#!/usr/bin/env bash
set -e

# Opinionated MacOS customisation script that does all the MacOS customisation on MacBook machine. And its idempotent, so it can be run multiple times without any issues.

echo "--------------------------------------------"
echo "Customizing Terminal"
echo "--------------------------------------------"

echo ""
echo "1. 📦 Setting up Agnoster theme..."
if [ -f "$HOME/.zshrc" ]; then
    if grep -q '^ZSH_THEME="agnoster"' ~/.zshrc; then
        echo "   ✅ Agnoster theme is already configured, skipping..."
    else
        echo "   📝 Configuring Agnoster theme..."
        sed -i.bak 's/^ZSH_THEME=".*"/ZSH_THEME="agnoster"/' ~/.zshrc
        echo "   ✅ Agnoster theme configured successfully"
    fi
fi

echo ""
echo "2. 📦 Customizing prompt to show only username..."
if grep -q 'prompt_context()' ~/.zshrc; then
    echo "   ✅ Prompt customization already exists, skipping..."
else
    echo "   📝 Customizing prompt to show only username..."
    echo "" >> ~/.zshrc
    echo "# Customize prompt to show only username" >> ~/.zshrc
    echo 'prompt_context() {' >> ~/.zshrc
    echo '  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then' >> ~/.zshrc
    echo '    prompt_segment black default "%(!.%{%F{yellow}%}.)%n"' >> ~/.zshrc
    echo '  fi' >> ~/.zshrc
    echo '}' >> ~/.zshrc
    echo "   ✅ Prompt customization added successfully"
fi

echo ""
echo "3. 📦 Setting up Oh My Zsh plugins..."
echo ""
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Install zsh-autosuggestions plugin
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "   ✅ zsh-autosuggestions plugin is already installed"
else
    echo "   📦 Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    echo "   ✅ zsh-autosuggestions plugin installed successfully!"
fi

echo ""
# Install zsh-syntax-highlighting plugin
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "   ✅ zsh-syntax-highlighting plugin is already installed"
else
    echo "   📦 Installing zsh-syntax-highlighting plugin..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    echo "   ✅ zsh-syntax-highlighting plugin installed successfully!"
fi

# Enable plugins in .zshrc
if grep -q '^plugins=(' ~/.zshrc; then
    echo ""
    # Check and add zsh-autosuggestions
    if grep -q 'zsh-autosuggestions' ~/.zshrc; then
        echo "   ✅ zsh-autosuggestions plugin is already enabled"
    else
        echo "   📝 Enabling zsh-autosuggestions plugin..."
        sed -i.bak 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions)/' ~/.zshrc
        echo "   ✅ zsh-autosuggestions enabled!"
    fi
    
    echo ""
    # Check and add zsh-syntax-highlighting
    if grep -q 'zsh-syntax-highlighting' ~/.zshrc; then
        echo "   ✅ zsh-syntax-highlighting plugin is already enabled"
    else
        echo "   📝 Enabling zsh-syntax-highlighting plugin..."
        sed -i.bak 's/^plugins=(\(.*\))/plugins=(\1 zsh-syntax-highlighting)/' ~/.zshrc
        echo "   ✅ zsh-syntax-highlighting enabled!"
    fi
fi

echo ""
echo "4. 📦 Installing Terminal color theme: Monokai Pro (Filter Spectrum)"
THEME_NAME="Monokai Pro"
THEME_FILE="$HOME/${THEME_NAME}.terminal"

if [ -f "$THEME_FILE" ]; then
    echo "   ✅ $THEME_NAME theme file already downloaded, skipping..."
else
    echo "   📦 Downloading $THEME_NAME theme..."
    curl -fsSL "https://raw.githubusercontent.com/lysyi3m/macos-terminal-themes/master/themes/Monokai%20Pro%20(Filter%20Spectrum).terminal" -o "$THEME_FILE"
    echo "   ✅ Theme downloaded successfully!"
fi

echo ""
echo "5. 📦 Installing Powerline fonts: Source Code Pro for Powerline"
FONT_NAME="Source Code Pro for Powerline"
FONT_SIZE=12

if [ -d "$HOME/Library/Fonts" ] && ls "$HOME/Library/Fonts" | grep -q "$FONT_NAME"; then
    echo "   ✅ $FONT_NAME is already installed, skipping..."
else
    echo "   📦 Installing $FONT_NAME font..."
    brew install --cask font-source-code-pro-for-powerline
    echo "   ✅ Font installed successfully!"
fi

echo ""
echo "6. 📝 Configuring Terminal.app using osascript..."
osascript <<EOF
tell application "Terminal"
    set themeName to "$THEME_NAME"

    -- Import the theme if needed
    if not (exists settings set themeName) then
        do shell script "open '$THEME_FILE'"
        delay 1
    end if

    -- Set the default and startup theme
    set default settings to settings set themeName
    set startup settings to settings set themeName

    -- Apply font settings to that theme
    tell settings set themeName
        set font name to "$FONT_NAME"
        set font size to $FONT_SIZE
    end tell
end tell
EOF
echo "   ✅ Terminal.app configured successfully"


echo ""
echo "--------------------------------------------"
echo "Setting up Shell Aliases"
echo "--------------------------------------------"

ALIAS_MARKER="# === Custom Aliases ==="

# Check if aliases are already added
if grep -q "$ALIAS_MARKER" ~/.zshrc 2>/dev/null; then
    echo "✅ Shell aliases already configured, skipping..."
else
    echo "📝 Adding useful shell aliases to ~/.zshrc..."
    
    # Add aliases to .zshrc
    cat >> ~/.zshrc << 'EOF'

# === Custom Aliases ===

# Network
alias myip='curl ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias tcp='netstat -p tcp -an'
alias udp='netstat -p udp -an'

# Development
alias gs-awscreds='stskeygen --account npgoldstar --duration 43200 --role "AWS_Developers_Goldstar"'
alias np-awscreds='stskeygen --account nationalpenabc --duration 43200 --role "AWS_NPDevelopers-ABC"'
alias dev='npm run dev'
alias build='npm run build'
alias start='npm run start'
alias test='npm run test'
alias python='python3'
alias py='python3'
alias pip='pip3'

# Utilities
alias cdw='cd ~/bitbucket'
alias cdp='cd ~/github'
alias c='clear'
alias q='exit'

# Fun stuff
alias weather='curl wttr.in'
alias 

EOF

    echo "✅ Shell aliases added successfully!"
    echo ""
    echo "📋 Available alias categories:"
    echo "   • Network: myip, localip, tcp, udp"
    echo "   • Development: awscreds, dev, build, start, python, pip"
    echo "   • Utilities: c, q, hosts, weather"
    echo ""
    echo "💡 Type 'source ~/.zshrc' to apply changes or restart your terminal"
fi


echo ""
echo "--------------------------------------------"
echo "Customising Git Profiles with SSH keys"
echo "--------------------------------------------"
echo "This script will set up two Git profiles:"
echo "  1️⃣  Personal (GitHub) - for your personal projects"
echo "  2️⃣  Work (Bitbucket) - for your work projects"
echo ""

# Create SSH directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# ========================================
# PERSONAL PROFILE (GitHub)
# ========================================
echo "📦 Setting up Personal GitHub Profile..."
PERSONAL_KEY="$HOME/.ssh/id_ed25519_github_personal"
# Can be accepted as a user input, but this is opinionated setup script.
PERSONAL_NAME="dhyeythumar"
PERSONAL_EMAIL="dhyeythumar@gmail.com"

if [ -f "$PERSONAL_KEY" ]; then
    echo "✅ Personal SSH key already exists: $PERSONAL_KEY"
else    
    echo ""
    echo "🔐 Generating SSH key for personal GitHub account..."
    ssh-keygen -t ed25519 -C "$PERSONAL_EMAIL" -f "$PERSONAL_KEY" -N ""
    echo "✅ Personal SSH key generated!"

    echo ""
    echo "📋 Your PERSONAL GitHub SSH public key (also copied to clipboard)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "${PERSONAL_KEY}.pub"
    cat "${PERSONAL_KEY}.pub" | pbcopy
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📝 Action required:"
    echo "   1. Opening GitHub SSH settings in Chrome..."
    echo "   2. Click 'New SSH key'"
    echo "   3. Paste the key and save"
    open -a "Google Chrome" "https://github.com/settings/keys" 2>/dev/null || open "https://github.com/settings/keys"
    read -p "Press Enter when you've added the key to GitHub..." </dev/tty
fi

# ========================================
# WORK PROFILE (Bitbucket)
# ========================================
echo -e "\n📦 Setting up Work Bitbucket Profile..."
WORK_KEY="$HOME/.ssh/id_ed25519_bitbucket_work"
# Can be accepted as a user input, but this is opinionated setup script.
WORK_NAME="dhyey.thumar"
WORK_EMAIL="dhyey.thumar@pens.com"

if [ -f "$WORK_KEY" ]; then
    echo "✅ Work SSH key already exists: $WORK_KEY"
else    
    echo ""
    echo "🔐 Generating SSH key for work Bitbucket account..."
    ssh-keygen -t ed25519 -C "$WORK_EMAIL" -f "$WORK_KEY" -N ""
    echo "✅ Work SSH key generated!"
    
    echo ""
    echo "📋 Your WORK Bitbucket SSH public key (also copied to clipboard)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "${WORK_KEY}.pub"
    cat "${WORK_KEY}.pub" | pbcopy
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📝 Action required:"
    echo "   1. Opening Bitbucket SSH settings in Safari..."
    echo "   2. Click 'Add key'"
    echo "   3. Paste the key and save"
    open -a "Safari" "https://bitbucket.org/account/settings/ssh-keys/" 2>/dev/null || open "https://bitbucket.org/account/settings/ssh-keys/"
    read -p "Press Enter when you've added the key to Bitbucket..." </dev/tty
fi

# ========================================
# SSH CONFIG SETUP
# ========================================
echo -e "\n📝 Configuring SSH config file..."
SSH_CONFIG="$HOME/.ssh/config"

# Backup existing config if it exists
if [ -f "$SSH_CONFIG" ]; then
    if ! grep -q "# GitHub Personal" "$SSH_CONFIG"; then
        cp "$SSH_CONFIG" "${SSH_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "   📦 Backed up existing SSH config"
    fi
fi

# Add GitHub Personal config if not exists
if ! grep -q "# GitHub Personal" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << 'EOF'
# GitHub Personal
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_personal
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes

EOF
    echo "   ✅ Added GitHub Personal SSH config"
fi

# Add Bitbucket Work config if not exists
if ! grep -q "# Bitbucket Work" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << 'EOF'
# Bitbucket Work
Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_ed25519_bitbucket_work
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes

EOF
    echo "   ✅ Added Bitbucket Work SSH config"
fi

chmod 600 "$SSH_CONFIG"
echo "✅ SSH config file updated!"

# Add GitHub and Bitbucket to known_hosts automatically
echo -e "\n📝 Adding GitHub and Bitbucket to known_hosts..."

# Check if github.com is already in known_hosts
if ! ssh-keygen -F github.com >/dev/null 2>&1; then
    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts 2>/dev/null
    echo "   ✅ GitHub host keys added"
else
    echo "   ✅ GitHub already in known_hosts"
fi

# Check if bitbucket.org is already in known_hosts
if ! ssh-keygen -F bitbucket.org >/dev/null 2>&1; then
    ssh-keyscan -t ed25519 bitbucket.org >> ~/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -t rsa bitbucket.org >> ~/.ssh/known_hosts 2>/dev/null
    echo "   ✅ Bitbucket host keys added"
else
    echo "   ✅ Bitbucket already in known_hosts"
fi

# ========================================
# GIT CONFIG SETUP
# ========================================
echo -e "\n📝 Configuring Git profiles..."

# Get or prompt for profile information
if [ -z "$PERSONAL_NAME" ]; then
    PERSONAL_NAME=$(git config --file ~/.gitconfig-personal user.name 2>/dev/null || echo "")
    PERSONAL_EMAIL=$(git config --file ~/.gitconfig-personal user.email 2>/dev/null || echo "")
    
    if [ -z "$PERSONAL_NAME" ]; then
        read -p "👤 Enter your PERSONAL name: " PERSONAL_NAME </dev/tty
        read -p "📧 Enter your PERSONAL email: " PERSONAL_EMAIL </dev/tty
    fi
fi

if [ -z "$WORK_NAME" ]; then
    WORK_NAME=$(git config --file ~/.gitconfig-work user.name 2>/dev/null || echo "")
    WORK_EMAIL=$(git config --file ~/.gitconfig-work user.email 2>/dev/null || echo "")
    
    if [ -z "$WORK_NAME" ]; then
        read -p "👤 Enter your WORK name: " WORK_NAME </dev/tty
        read -p "📧 Enter your WORK email: " WORK_EMAIL </dev/tty
    fi
fi

# Create personal Git config
cat > ~/.gitconfig-personal << EOF
# ============================================================================
# This file is managed by dhyeythumar's mac-utilities repository
# Repository: https://github.com/dhyeythumar/mac-utilities
# Do not edit manually - changes will be overwritten on next script run
# ============================================================================

[user]
    name = $PERSONAL_NAME
    email = $PERSONAL_EMAIL
EOF
echo "   ✅ Created ~/.gitconfig-personal"

# Create work Git config
cat > ~/.gitconfig-work << EOF
# ============================================================================
# This file is managed by dhyeythumar's mac-utilities repository
# Repository: https://github.com/dhyeythumar/mac-utilities
# Do not edit manually - changes will be overwritten on next script run
# ============================================================================

[user]
    name = $WORK_NAME
    email = $WORK_EMAIL
EOF
echo "   ✅ Created ~/.gitconfig-work"

# Setup directories
PERSONAL_DIR="$HOME/github"
WORK_DIR="$HOME/bitbucket"

echo -e "\n📁 Setting up project directories..."
mkdir -p "$PERSONAL_DIR"
mkdir -p "$WORK_DIR"
echo "   ✅ Created $PERSONAL_DIR (for personal projects)"
echo "   ✅ Created $WORK_DIR (for work projects)"

# Create global gitignore file
cat > ~/.gitignore_global << EOF
# ============================================================================
# Global Git Ignore
# This file is managed by dhyeythumar's mac-utilities repository
# Repository: https://github.com/dhyeythumar/mac-utilities
# Do not edit manually - changes will be overwritten on next script run
# ============================================================================

.DS_Store
node_modules/

EOF
echo "   ✅ Created ~/.gitignore_global"

# Configure global gitconfig with conditional includes
cat > ~/.gitconfig << EOF
# ============================================================================
# This file is managed by dhyeythumar's mac-utilities repository
# Repository: https://github.com/dhyeythumar/mac-utilities
# Do not edit manually - changes will be overwritten on next script run
# ============================================================================
# 
# Global Git Configuration
# This file uses conditional includes to load different configs based on directory

[init]
    defaultBranch = main

[pull]
    rebase = false

[core]
    autocrlf = input
    editor = vim
    ignorecase = false
    excludesfile = ~/.gitignore_global

[color]
    ui = auto

[push]
    default = current
    autoSetupRemote = true

[help]
	autocorrect = prompt

# Personal Projects (GitHub)
[includeIf "gitdir:~/personal/"]
    path = ~/.gitconfig-personal

[includeIf "gitdir:~/github/"]
    path = ~/.gitconfig-personal

# Work Projects (Bitbucket)
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work

[includeIf "gitdir:~/bitbucket/"]
    path = ~/.gitconfig-work
EOF

echo ""
echo "✅ Git configuration complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 How to use your Git profiles:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🏠 PERSONAL projects (GitHub):"
echo "   → Clone/create projects in: $PERSONAL_DIR/"
echo "   → Example: git clone git@github.com:user/repo.git $PERSONAL_DIR/repo"
echo ""
echo "💼 WORK projects (Bitbucket):"
echo "   → Clone/create projects in: $WORK_DIR/"
echo "   → Example: git clone git@bitbucket.org:team/repo.git $WORK_DIR/repo"
echo ""
echo "🧪 Test your SSH connections:"
echo "   → GitHub:    ssh -T git@github.com"
echo "   → Bitbucket: ssh -T git@bitbucket.org"
echo ""
echo "🔍 Verify Git config in any repo:"
echo "   → cd into a repo and run: git config user.email"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


echo ""
echo "--------------------------------------------"
echo "Customising Finder"
echo "--------------------------------------------"
echo ""

SCREENSHOTS_DIR="${HOME}/OneDrive - National Pen Company/Personal Files/MacBook/Screenshots/"
SCREENSHOTS_DIR_ENCODED="${HOME}/OneDrive%20-%20National%20Pen%20Company/Personal%20Files/MacBook/Screenshots/"

echo "1. 📝 Configuring Finder to open Downloads folder in new windows..."
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"

echo "2. 📝 Configuring Finder to open folders in tabs instead of new windows..."
defaults write com.apple.finder FinderSpawnTab -bool true

echo "3. 📝 Configuring Finder to show file extensions..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "4. 📝 Configuring Finder to show path bar..."
defaults write com.apple.finder ShowPathbar -bool true

echo "5. 📝 Configuring Finder to show status bar..."
defaults write com.apple.finder ShowStatusBar -bool true

echo "6. 📝 Configuring Finder to enable warning when changing file extensions..."
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true

echo "7. 📝 Configuring Finder to set default view to list view..."
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

echo "8. 📝 Configuring Finder sidebar favorites (⚠️  Important: Accept the access permission when prompted)..."

echo -e "\n  Clearing existing favorites..."
mysides list | awk -F' -> ' '{print $1}' | xargs -I {} mysides remove {}
# NOTE: If mysides clear approach doesn't work, then use this ultimate way to clear existing favorites
# sfltool clear com.apple.LSSharedFileList.FavoriteItems

echo -e "\n  Adding new favorites..."
mysides add Applications file:///Applications/
mysides add "Desktop (iCloud)" file://${HOME}/Library/Mobile%20Documents/com~apple~CloudDocs/Desktop/
mysides add "Documents (iCloud)" file://${HOME}/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/
mysides add "Screenshots (OneDrive)" file://${SCREENSHOTS_DIR_ENCODED}
mysides add "Documents (OneDrive)" file://${HOME}/OneDrive%20-%20National%20Pen%20Company/Personal%20Files/MacBook/Documents/
mysides add Downloads file://${HOME}/Downloads/
mysides add Home file://${HOME}/

echo -e "\nRestarting Finder to apply changes!"
killall Finder 2>/dev/null || true

# Check if iCloud Desktop & Documents is enabled
ICLOUD_DESKTOP_ENABLED=$(defaults read com.apple.finder FXICloudDriveDesktop 2>/dev/null || echo "0")

if [ "$ICLOUD_DESKTOP_ENABLED" = "1" ]; then
    echo -e "\nℹ️  iCloud Desktop & Documents sync is already enabled"
else
    echo -e "\n ⚠️ iCloud Desktop & Documents sync (this cannot be automated - please enable manually)"
    echo "   → Script will open System Settings > iCloud section"
    echo "   → Click 'iCloud Drive' options"
    echo "   → Enable 'Desktop & Documents Folders'"
    open "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane?iCloud"
    read -p "Press Enter when you've done with the changes..." </dev/tty
fi


echo ""
echo "--------------------------------------------"
echo "Customising System Settings"
echo "--------------------------------------------"

echo -e "\n1. 📝 Configuring Screenshots folder..."
defaults write com.apple.screencapture location "${SCREENSHOTS_DIR}"

echo -e "\nRestarting SystemUIServer to apply changes..."
killall SystemUIServer 2>/dev/null || true

echo -e "\n2. 📝 Configuring Mission Control (Disable automatic spaces rearrangement)..."
defaults write com.apple.dock "mru-spaces" -bool "false"

echo -e "\n3. 📝 Configuring Mission Control (Enable group exposure of apps)..."
defaults write com.apple.dock "expose-group-apps" -bool "true" && killall Dock

echo -e "\n4. 📝 Configuring Hot Corners..."
# Top-left: Mission Control
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0

# Top-right: No action
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-tr-modifier -int 0

# Bottom-left: Lock Screen
defaults write com.apple.dock wvous-bl-corner -int 13
defaults write com.apple.dock wvous-bl-modifier -int 0

# Bottom-right: No action
defaults write com.apple.dock wvous-br-corner -int 0
defaults write com.apple.dock wvous-br-modifier -int 0

echo -e "\n5. 📝 Configuring Apps' sequence in Dock..."

echo -e "\n  Removing all apps from Dock..."
dockutil --remove all --no-restart

echo -e "\n  Adding apps in desired order..."
dockutil --add "/System/Applications/Apps.app" --no-restart
dockutil --add "/System/Applications/System Settings.app" --no-restart
dockutil --add "/System/Applications/Utilities/Activity Monitor.app" --no-restart
dockutil --add "/System/Applications/Calendar.app" --no-restart
dockutil --add "/System/Applications/Reminders.app" --no-restart
dockutil --add "/System/Applications/Utilities/Terminal.app" --no-restart
dockutil --add "/System/Applications/Notes.app" --no-restart
dockutil --add "/Applications/Microsoft Teams.app" --no-restart
dockutil --add "/Applications/Visual Studio Code.app" --no-restart
dockutil --add "/Applications/Cursor.app" --no-restart
dockutil --add "/Applications/Safari.app" --no-restart
dockutil --add "/Applications/Google Chrome.app" --no-restart

echo -e "\nRestarting Dock to apply all changes!"
killall Dock 2>/dev/null || true

echo -e "\n6. 👨‍💻 [Manually] Configuring Night Shift..."
echo "   ⚠️  Night Shift settings require manual configuration due to difficulties in automation."
echo "   📝 Please manually enable these in Displays settings:"
echo "      • Schedule: Sunset to Sunrise"
echo "      • Adjust color temperature as desired"
echo ""
echo "   Opening Displays settings..."
open "x-apple.systempreferences:com.apple.Displays-Settings.extension"
read -p "   Press Enter after configuring Night Shift..." </dev/tty


echo -e "\n7. 👨‍💻 [Manually] Configuring Trackpad..."
echo "   ⚠️  Trackpad settings require manual configuration due to difficulties in automation."
echo "   📝 Please manually enable these in Trackpad settings:"
echo "      • Tap to Click"
echo ""
echo "   Opening Trackpad settings..."
open "x-apple.systempreferences:com.apple.Trackpad-Settings.extension"
read -p "   Press Enter after configuring Trackpad..." </dev/tty


echo -e "\n8. 👨‍💻 [Manually] Configuring MenuBar..."
echo "   ⚠️  Note: Apple removed automation support for Control Center items in macOS Monterey+"
echo "   📝 Please manually enable these in Control Center settings:"
echo "      • Battery - Show in Menu Bar (with percentage)"
echo "      • Bluetooth - Show in Menu Bar"
echo "      • WiFi - Show in Menu Bar"
echo ""
echo "   Opening Control Center settings..."
open "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension"
read -p "   Press Enter after configuring MenuBar..." </dev/tty


echo -e "\n9. 👨‍💻 [Manually] Configuring Privacy Permissions for Microsoft Teams..."
echo "   ⚠️  Screen & System Audio recording permissions must be manually granted for security reasons."
echo "   📝 Please enable the following permissions for Microsoft Teams:"
echo "      • Screen & System Audio Recording"
echo ""
echo "   Opening Privacy & Security settings..."
open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
read -p "   Press Enter after configuring Privacy Permissions for Microsoft Teams... " </dev/tty

echo "   💡 Note: If you don't see Microsoft Teams in the list:"
echo "      • Launch Microsoft Teams at least once"
echo "      • Try to share screen or record - this will trigger permission prompts"
echo "      • Then grant the permissions when prompted"


echo ""
echo "===================================================================================================="
echo "MacOS Customisation complete! Please restart your MacOS to verify the changes have been applied. 🚀"
echo "===================================================================================================="
