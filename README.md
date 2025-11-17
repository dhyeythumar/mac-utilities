# MacBook Utilities

Opinionated scripts to setup and configure a new MacBook with developer tools and personalized settings.

## Quick Setup Guide

**Steps for MacBook Setup & Configuration**

-   Step 0: Power on the machine and complete the initial macOS setup wizard.

-   Step 1: `Manual process` Log in to iCloud & App Store.

-   Step 2. CLI tools setup:

    ```bash
    curl -fsSL https://raw.githubusercontent.com/dhyeythumar/mac-utilities/refs/heads/main/scripts/cli-tools.setup.sh | bash
    ```

-   Step 3: Apps setup (download & install):

    ```bash
    curl -fsSL https://raw.githubusercontent.com/dhyeythumar/mac-utilities/refs/heads/main/scripts/apps.setup.sh | bash
    ```

-   Step 4: `Manual process` Log into OneDrive, Bitbucket & GitHub (for SSH setup).

-   Step 5. MacBook customisations (such as Terminal app, Finder app, etc)

    ```bash
    curl -fsSL https://raw.githubusercontent.com/dhyeythumar/mac-utilities/refs/heads/main/scripts/customisation.sh | bash
    ```

-   Step 6: `Manual process` Individual app configuration (such as login).

## ✨ Features

-   🎨 **Color-coded output** for better readability
-   🔄 **Idempotent scripts** - safe to run multiple times
-   📦 **Automatic backups** of existing configurations
-   ⚡ **Interactive prompts** for manual steps when needed
-   🛡️ **Error handling** with retry logic for network operations

## 📦 What Gets Installed

### `cli-tools.setup.sh`

-   **Xcode Command Line Tools** - Required for Git and compilation
-   **Oh My Zsh** - Enhanced Zsh framework
-   **Homebrew** - Package manager for macOS
-   **Node.js** - Latest LTS version (via NVM)
-   **CLI Tools**:
    -   `nvm` - Node Version Manager
    -   `awscli` - AWS Command Line Interface
    -   `mysides` - Finder sidebar manager
    -   `dockutil` - Dock management tool
    -   `mas` - Mac App Store CLI
    -   `netcat` - Network utility
    -   `stskeygen` - AWS STS key generator (custom tap)

### `apps.setup.sh`

-   **Google Chrome** - Web browser
-   **Postman** - API development tool
-   **Microsoft Teams** - Collaboration platform
-   **Adobe Creative Cloud** - Creative suite
-   **Cursor** - AI-powered code editor
-   **Visual Studio Code** - Code editor
-   **Slack** - Team communication
-   **OneDrive** - Cloud storage

### `customisation.sh`

-   **Terminal**
    -   Monokai Pro (Filter Spectrum) theme
    -   Source Code Pro for Powerline fonts
    -   Zsh plugins (autosuggestions, syntax highlighting)
    -   Agnoster prompt theme
-   **Shell Aliases**
    -   Network utilities (myip, localip, tcp, udp)
    -   Development shortcuts (dev, build, start, test)
    -   Git shortcuts (pull, push, fetch, branch, status, log)
    -   Directory shortcuts (cdw, cdp)
    -   Utilities (weather, hosts)
-   **Git Configuration**
    -   Dual profiles (GitHub personal + Bitbucket work)
    -   Auto-switching based on directory
    -   Separate SSH keys for each account
    -   Global gitignore file
-   **Finder Customization**
    -   Custom sidebar favorites
    -   Show file extensions and path bar
    -   Default to list view
    -   Folders in tabs
-   **System Settings**
    -   Custom Dock apps arrangement
    -   Hot corners (Mission Control, Lock Screen)
    -   Screenshot folder location
    -   Mission Control preferences
    -   Manual guides for Night Shift, Trackpad, MenuBar, and Privacy settings

## 🎨 Terminal Features

-   **Theme:** Monokai Pro (Filter Spectrum)
-   **Font:** Source Code Pro for Powerline
-   **Plugins:** zsh-autosuggestions, zsh-syntax-highlighting
-   **Prompt:** Agnoster (shows username, directory, git status)

## ⚡ Key Aliases

```bash
# Network
myip        # Get external IP address
localip     # Get local IP address
tcp         # Show TCP connections
udp         # Show UDP connections

# Development
gs-awscreds # Generate AWS credentials (Goldstar)
np-awscreds # Generate AWS credentials (National Pen)
dev         # npm run dev
build       # npm run build
start       # npm run start
test        # npm run test
python      # python3
py          # python3
pip         # pip3

# Git shortcuts
pull        # git pull
push        # git push
fetch       # git fetch
branch      # git branch
status      # git status
log         # git log

# Directory shortcuts
cdw         # cd ~/bitbucket (work projects)
cdp         # cd ~/github (personal projects)

# Utilities
c           # clear
q           # exit
weather     # Show weather in terminal
```

## 🔐 Git Profile Setup

Projects are automatically configured based on directory:

```
~/github/     → Personal (GitHub)
~/personal/   → Personal (GitHub)
~/bitbucket/  → Work (Bitbucket)
~/work/       → Work (Bitbucket)
```

**Test SSH connections:**

```bash
ssh -T git@github.com
ssh -T git@bitbucket.org
```

## 🛠️ Script Architecture

All scripts use shared utilities from `scripts/common.sh` which provides:

-   **Color-coded output functions**: `success()`, `warning()`, `error()`, `info()`, `action()`
-   **Section headers**: `section_header()`, `script_notification()`
-   **Sudo management**: Keeps sudo session alive during long-running scripts
-   **Service management**: `restart_service()` for system services
-   **User interaction**: `wait_for_user()`, `manual_action()` for guided steps

## 📝 Notes

-   ✅ Scripts are **idempotent** - safe to run multiple times
-   💾 Existing configs are **backed up automatically** (with timestamps)
-   🔑 SSH keys generated **without passphrases** for convenience
-   🔄 **Retry logic** for network operations (Homebrew, Oh My Zsh)
-   🎨 **Color-coded output** for better readability (green=success, yellow=warning, red=error, blue=info, cyan=action)
-   ⚠️ Some settings require **manual configuration** due to macOS security restrictions (Night Shift, Trackpad, Privacy permissions)
-   🚀 Terminal restart handled automatically after CLI tools setup

## 🤝 Contributing

Feel free to fork and customize for your own setup! The modular structure makes it easy to:

-   Add/remove applications in the `apps.setup.sh` arrays
-   Customize aliases in `customisation.sh`
-   Modify system settings to your preference
-   Extend `common.sh` with your own utility functions
