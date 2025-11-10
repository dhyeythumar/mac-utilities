# MacOS Utilities

Opinionated scripts to setup and configure a new MacBook with developer tools and personalized settings.

## Quick Guide

**Steps for MacBook Setup & Configuration**

-   Step 0: Power on the machine and go through initial macOS setup.

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
    curl -fsSL https://raw.githubusercontent.com/dhyeythumar/mac-utilities/refs/heads/main/scripts/mac.customisation.sh | bash
    ```

-   Step 6: `Manual process` Individual app configuration (such as login).

## 📦 What Gets Installed

### `cli-tools.setup.sh`

-   Oh My Zsh
-   Homebrew
-   Git
-   Node.js (via NVM)
-   AWS CLI & stskeygen
-   mysides & dockutil

### `mac.customisation.sh`

-   **Terminal** - Monokai Pro theme, Powerline fonts, zsh plugins (autosuggestions, syntax highlighting)
-   **Shell Aliases** - Network, development, git, docker shortcuts
-   **Dual Git Profiles** - Auto-switching between GitHub (personal) and Bitbucket (work)
-   **SSH Keys** - Separate keys for personal and work accounts
-   **Finder** - Enhanced productivity settings, custom sidebar
-   **System Settings** - Dock apps, hot corners, menubar items

## 🎨 Terminal Features

-   **Theme:** Monokai Pro (Filter Spectrum)
-   **Font:** Source Code Pro for Powerline
-   **Plugins:** zsh-autosuggestions, zsh-syntax-highlighting
-   **Prompt:** Agnoster (shows username, directory, git status)

## ⚡ Key Aliases

```bash
# Network
myip        # Get external IP
localip     # Get local IP
tcp         # Show TCP connections
udp         # Show UDP connections

# Development
gs-awscreds # Generate AWS credentials (Goldstar)
np-awscreds # Generate AWS credentials (National Pen)
dev         # npm run dev
build       # npm run build
start       # npm run start

# Utilities
c           # clear
q           # exit
hosts       # Edit /etc/hosts file
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

## 📝 Notes

-   Scripts are **idempotent** - safe to run multiple times
-   Existing configs are backed up automatically, whenever necessary
-   SSH keys generated without passphrases for convenience
