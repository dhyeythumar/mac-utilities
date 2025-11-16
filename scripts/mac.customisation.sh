#!/usr/bin/env bash
set -e

# Opinionated MacOS customisation script that does all the MacOS customisation on MacBook machine. And its idempotent, so it can be run multiple times without any issues.

SCRIPT_NAME="MacOS Customisation"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/common.sh"

script_notification "🎬 Starting $SCRIPT_NAME" \
    "This script will open various system settings for you to configure manually."


section_header "Customizing Terminal"

action "1. Setting up Agnoster theme..."
if [ -f "$HOME/.zshrc" ]; then
    if grep -q '^ZSH_THEME="agnoster"' ~/.zshrc; then
        info "Agnoster theme is already configured, skipping..."
    else
        action "Configuring Agnoster theme..."
        sed -i.bak 's/^ZSH_THEME=".*"/ZSH_THEME="agnoster"/' ~/.zshrc
        success "Agnoster theme configured successfully!"
    fi
fi

action "2. Customizing prompt to show only username..."
if grep -q 'prompt_context()' ~/.zshrc; then
    info "Prompt customization already exists, skipping..."
else
    action "Customizing prompt to show only username..."
    echo "" >> ~/.zshrc
    echo "# Customize prompt to show only username" >> ~/.zshrc
    echo 'prompt_context() {' >> ~/.zshrc
    echo '  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then' >> ~/.zshrc
    echo '    prompt_segment black default "%(!.%{%F{yellow}%}.)%n"' >> ~/.zshrc
    echo '  fi' >> ~/.zshrc
    echo '}' >> ~/.zshrc
    success "Prompt customization added successfully!"
fi

action "3. Setting up Oh My Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Install zsh-autosuggestions plugin
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    info "zsh-autosuggestions plugin is already installed, skipping..."
else
    action "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    success "zsh-autosuggestions plugin installed successfully!"
fi

# Install zsh-syntax-highlighting plugin
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    info "zsh-syntax-highlighting plugin is already installed, skipping..."
else
    action "Installing zsh-syntax-highlighting plugin..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    success "zsh-syntax-highlighting plugin installed successfully!"
fi

# Enable plugins in .zshrc
if grep -q '^plugins=(' ~/.zshrc; then
    # Check and add zsh-autosuggestions
    if grep -q 'zsh-autosuggestions' ~/.zshrc; then
        info "zsh-autosuggestions plugin is already enabled, skipping..."
    else
        action "Enabling zsh-autosuggestions plugin..."
        sed -i.bak 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions)/' ~/.zshrc
        success "zsh-autosuggestions enabled!"
    fi

    # Check and add zsh-syntax-highlighting
    if grep -q 'zsh-syntax-highlighting' ~/.zshrc; then
        info "zsh-syntax-highlighting plugin is already enabled, skipping..."
    else
        action "Enabling zsh-syntax-highlighting plugin..."
        sed -i.bak 's/^plugins=(\(.*\))/plugins=(\1 zsh-syntax-highlighting)/' ~/.zshrc
        success "zsh-syntax-highlighting enabled!"
    fi
fi

action "4. Installing Terminal color theme: Monokai Pro (Filter Spectrum)"
THEME_NAME="Monokai Pro"
THEME_FILE="$HOME/${THEME_NAME}.terminal"

if [ -f "$THEME_FILE" ]; then
    info "$THEME_NAME theme file already downloaded, skipping..."
else
    action "Downloading $THEME_NAME theme..."
    curl -fsSL "https://raw.githubusercontent.com/lysyi3m/macos-terminal-themes/master/themes/Monokai%20Pro%20(Filter%20Spectrum).terminal" -o "$THEME_FILE"
    success "Theme downloaded successfully!"
fi

action "5. Installing Powerline fonts: Source Code Pro for Powerline"
FONT_NAME="Source Code Pro for Powerline"
FONT_SIZE=12

if [ -d "$HOME/Library/Fonts" ] && ls "$HOME/Library/Fonts" | grep -q "$FONT_NAME"; then
    info "$FONT_NAME is already installed, skipping..."
else
    action "Installing $FONT_NAME font..."
    brew install --cask font-source-code-pro-for-powerline
    success "Font installed successfully!"
fi

action "6. Configuring Terminal.app using osascript..."
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
success "Terminal.app configured successfully!"


section_header "Setting up Shell Aliases"
ALIAS_MARKER="# === Custom Aliases ==="

# Check if aliases are already added
if grep -q "$ALIAS_MARKER" ~/.zshrc 2>/dev/null; then
    info "Shell aliases already configured, skipping..."
else
    action "Adding useful shell aliases to ~/.zshrc..."
    
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

# Git
alias pull='git pull'
alias push='git push'
alias fetch='git fetch'
alias branch='git branch'
alias status='git status'
alias log='git log'

# Utilities
alias cdw='cd ~/bitbucket'
alias cdp='cd ~/github'
alias c='clear'
alias q='exit'

# Fun stuff
alias weather='curl wttr.in'
alias 

EOF

    success "Shell aliases added successfully!"
fi


section_header "Customising Git Profiles with SSH keys" \
    "This script will set up two Git profiles:" \
    "1. Personal (GitHub) - for your personal projects" \
    "2. Work (Bitbucket) - for your work projects"

# Create SSH directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# ========================================
# PERSONAL PROFILE (GitHub)
# ========================================
action "Setting up Personal GitHub Profile..."
PERSONAL_KEY="$HOME/.ssh/id_ed25519_github_personal"
PERSONAL_NAME="dhyeythumar"
PERSONAL_EMAIL="dhyeythumar@gmail.com"

if [ -f "$PERSONAL_KEY" ]; then
    info "Personal SSH key already exists: $PERSONAL_KEY"
else
    echo "⌙  🔐 Generating SSH key for personal GitHub account..."
    ssh-keygen -t ed25519 -C "$PERSONAL_EMAIL" -f "$PERSONAL_KEY" -N ""
    success "Personal SSH key generated!"

    echo ""
    echo "📋 Your PERSONAL GitHub SSH public key (also copied to clipboard)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "${PERSONAL_KEY}.pub"
    cat "${PERSONAL_KEY}.pub" | pbcopy
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    manual_action "Action required:" \
        "1. Opening GitHub SSH settings in Chrome..." \
        "2. Click 'New SSH key'" \
        "3. Paste the key and save"

    open -a "Google Chrome" "https://github.com/settings/keys" 2>/dev/null || open "https://github.com/settings/keys"

    wait_for_user "Press Enter when you've added the key to GitHub..."
fi

# ========================================
# WORK PROFILE (Bitbucket)
# ========================================
action "Setting up Work Bitbucket Profile..."
WORK_KEY="$HOME/.ssh/id_ed25519_bitbucket_work"
WORK_NAME="dhyey.thumar"
WORK_EMAIL="dhyey.thumar@pens.com"

if [ -f "$WORK_KEY" ]; then
    info "Work SSH key already exists: $WORK_KEY"
else
    echo "⌙  🔐 Generating SSH key for work Bitbucket account..."
    ssh-keygen -t ed25519 -C "$WORK_EMAIL" -f "$WORK_KEY" -N ""
    success "Work SSH key generated!"

    echo ""
    echo "📋 Your WORK Bitbucket SSH public key (also copied to clipboard)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "${WORK_KEY}.pub"
    cat "${WORK_KEY}.pub" | pbcopy
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    manual_action "Action required:" \
        "1. Opening Bitbucket SSH settings in Safari..." \
        "2. Click 'Add key'" \
        "3. Paste the key and save"

    open -a "Safari" "https://bitbucket.org/account/settings/ssh-keys/" 2>/dev/null || open "https://bitbucket.org/account/settings/ssh-keys/"

    wait_for_user "Press Enter when you've added the key to Bitbucket..."
fi

# ========================================
# SSH CONFIG SETUP
# ========================================
action "Configuring SSH config file..."
SSH_CONFIG="$HOME/.ssh/config"

# Backup existing config if it exists
if [ -f "$SSH_CONFIG" ]; then
    if ! grep -q "# GitHub Personal" "$SSH_CONFIG"; then
        cp "$SSH_CONFIG" "${SSH_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backed up existing SSH config"
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
    success "Added GitHub Personal SSH config"
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
    success "Added Bitbucket Work SSH config"
fi

chmod 600 "$SSH_CONFIG"
success "SSH config file updated!"

# Add GitHub and Bitbucket to known_hosts automatically
action "Adding GitHub and Bitbucket to known_hosts..."

# Check if github.com is already in known_hosts
if ! ssh-keygen -F github.com >/dev/null 2>&1; then
    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts 2>/dev/null
    success "GitHub host keys added"
else
    info "GitHub already in known_hosts"
fi

# Check if bitbucket.org is already in known_hosts
if ! ssh-keygen -F bitbucket.org >/dev/null 2>&1; then
    ssh-keyscan -t ed25519 bitbucket.org >> ~/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -t rsa bitbucket.org >> ~/.ssh/known_hosts 2>/dev/null
    success "Bitbucket host keys added"
else
    info "Bitbucket already in known_hosts"
fi

# ========================================
# GIT CONFIG SETUP
# ========================================
action "Configuring Git profiles..."

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
success "Created ~/.gitconfig-personal"

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
success "Created ~/.gitconfig-work"

# Setup directories
PERSONAL_DIR="$HOME/github"
WORK_DIR="$HOME/bitbucket"

action "Setting up project directories..."
mkdir -p "$PERSONAL_DIR"
mkdir -p "$WORK_DIR"
success "Created $PERSONAL_DIR (for personal projects)"
success "Created $WORK_DIR (for work projects)"

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
success "Created ~/.gitignore_global"

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

success "Git configuration complete!"
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


section_header "Customising Finder"
SCREENSHOTS_DIR="${HOME}/OneDrive - National Pen Company/Personal Files/MacBook/Screenshots/"
SCREENSHOTS_DIR_ENCODED="${HOME}/OneDrive%20-%20National%20Pen%20Company/Personal%20Files/MacBook/Screenshots/"

action "1. Configuring Finder to open Downloads folder in new windows..."
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"

action "2. Configuring Finder to open folders in tabs instead of new windows..."
defaults write com.apple.finder FinderSpawnTab -bool true

action "3. Configuring Finder to show file extensions..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

action "4. Configuring Finder to show path bar..."
defaults write com.apple.finder ShowPathbar -bool true

action "5. Configuring Finder to show status bar..."
defaults write com.apple.finder ShowStatusBar -bool true

action "6. Configuring Finder to enable warning when changing file extensions..."
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true

action "7. Configuring Finder to set default view to list view..."
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

action "8. Configuring Finder sidebar favorites (⚠️  Important: Accept the access permission when prompted)..."

info "Clearing existing favorites..."
mysides list | awk -F' -> ' '{print $1}' | xargs -I {} mysides remove {}
# NOTE: If mysides clear approach doesn't work, then use this ultimate way to clear existing favorites
# sfltool clear com.apple.LSSharedFileList.FavoriteItems

info "Adding new favorites..."
mysides add Applications file:///Applications/
mysides add "Desktop (iCloud)" file://${HOME}/Library/Mobile%20Documents/com~apple~CloudDocs/Desktop/
mysides add "Documents (iCloud)" file://${HOME}/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/
mysides add "Screenshots (OneDrive)" file://${SCREENSHOTS_DIR_ENCODED}
mysides add "Documents (OneDrive)" file://${HOME}/OneDrive%20-%20National%20Pen%20Company/Personal%20Files/MacBook/Documents/
mysides add Downloads file://${HOME}/Downloads/
mysides add Home file://${HOME}/

restart_service "Finder"

# Check if iCloud Desktop & Documents is enabled
ICLOUD_DESKTOP_ENABLED=$(defaults read com.apple.finder FXICloudDriveDesktop 2>/dev/null || echo "0")

if [ "$ICLOUD_DESKTOP_ENABLED" = "1" ]; then
    info "iCloud Desktop & Documents sync is already enabled"
else
    warning "iCloud Desktop & Documents sync (this cannot be automated - please enable manually)"
    manual_action "Action required:" \
        "1. Opening System Settings > iCloud section" \
        "2. Click 'iCloud Drive' options" \
        "3. Enable 'Desktop & Documents Folders'"
    open "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane?iCloud"
    wait_for_user "Press Enter when you've done with the changes..."
fi


section_header "Customising System Settings"

action "1. Configuring Screenshots folder..."
defaults write com.apple.screencapture location "${SCREENSHOTS_DIR}"

restart_service "SystemUIServer"

action "2. Configuring Mission Control (Disable automatic spaces rearrangement)..."
defaults write com.apple.dock "mru-spaces" -bool "false"

action "3. Configuring Mission Control (Enable group exposure of apps)..."
defaults write com.apple.dock "expose-group-apps" -bool "true"

action "4. Configuring Hot Corners..."
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

action "5. Configuring Apps' sequence in Dock..."

info "Removing all apps from Dock..."
dockutil --remove all --no-restart

info "Adding apps in desired order..."
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

restart_service "Dock"

action "6. Configuring Night Shift..."
warning "Night Shift settings require manual configuration due to automation difficulties."
manual_action "Action required:" \
    "0. Opening System Settings > Displays section..." \
    "1. Set Night Shift schedule to Sunset to Sunrise" \
    "2. Adjust color temperature as desired"
open "x-apple.systempreferences:com.apple.Displays-Settings.extension"
wait_for_user "Press Enter after configuring Night Shift..."


action "7. Configuring Trackpad..."
warning "Trackpad settings require manual configuration due to automation difficulties."
manual_action "Action required:" \
    "0. Opening System Settings > Trackpad section..." \
    "1. Enable Tap to Click"
open "x-apple.systempreferences:com.apple.Trackpad-Settings.extension"
wait_for_user "Press Enter after configuring Trackpad..."


action "8. Configuring MenuBar..."
warning "Note: Apple removed automation support for Control Center items in macOS Monterey+"
manual_action "Action required:" \
    "0. Opening System Settings > Control Center section..." \
    "1. Enable Battery - Show in Menu Bar (with percentage)" \
    "2. Enable Bluetooth - Show in Menu Bar" \
    "3. Enable WiFi - Show in Menu Bar"
open "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension"
wait_for_user "Press Enter after configuring MenuBar..."


action "9. Configuring Privacy Permissions for Microsoft Teams..."
warning "Screen & System Audio recording permissions must be manually granted for security reasons."
manual_action "Action required:" \
    "0. Opening System Settings > Privacy & Security section..." \
    "1. Enable Screen & System Audio Recording"
open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
wait_for_user "Press Enter after configuring Privacy Permissions for Microsoft Teams..."

warning "If you don't see Microsoft Teams in the list, then try the following:" \
    "1. Launch Microsoft Teams at least once" \
    "2. Try to share screen or record - this will trigger permission prompts" \
    "3. Then grant the permissions when prompted"


script_notification "✅ $SCRIPT_NAME completed successfully!" \
    "🚀 Please restart your MacOS to verify the changes have been applied."
