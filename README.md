# nix-dotfiles

A cross-platform Nix configuration for macOS (nix-darwin) and Linux (NixOS) with Home Manager integration.

## ✨ Features

- 🍎 **macOS Support**: nix-darwin with AeroSpace window manager, Homebrew integration
- 🐧 **Linux Ready**: NixOS configuration structure (example included)
- 🏠 **Home Manager**: User-level configuration management
- 🔒 **Secrets Management**: SOPS-encrypted secrets with age
- 📦 **Package Management**: Organized cross-platform and platform-specific packages
- 🛠️ **Development Tools**: Go, PHP, Neovim, tmux, and more
- 🤖 **AI-Powered Tools**: Local LLM with ollama + AI commit messages via opencommit
- 🎨 **Modern Terminal**: WezTerm with custom configuration
- ⌨️ **Automation**: Hammerspoon-based macOS window management and shortcuts

## 📋 Requirements

### Nix Installation
You need to install Nix, but we are not using their official installer. Instead, we are using the Determinate Systems Nix Installer. You can download it [here](https://install.determinate.systems/determinate-pkg/stable/Universal)!

**Important**: Determinate Systems provides two separate operations:
- **Configuration Application**: Use `sudo darwin-rebuild switch` to apply your dotfiles changes
- **System Upgrades**: Use `sudo determinate-nixd upgrade` to upgrade the Determinate Nix system itself

To update your Determinate Nix system to the latest release:
```bash
sudo determinate-nixd upgrade
```

To apply your configuration changes:
```bash
sudo darwin-rebuild switch --flake ~/.config/nix-dotfiles --show-trace
```

### Platform-Specific Requirements

#### macOS
- **Homebrew**: Some applications require Homebrew installation
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

#### SOPS Secrets Management (Optional)

SOPS (Secrets OPerationS) encrypts secrets using age keys for secure storage in the repository.

##### Initial Setup

1. **Install required tools**:
   ```bash
   # SOPS and age are included in the nix packages, but for initial setup you might need:
   nix-shell -p sops age
   ```

2. **Generate age key pair**:
   ```bash
   # Generate a new age key
   age-keygen -o ~/.config/sops/age/keys.txt
   
   # On macOS, use the appropriate path:
   mkdir -p "~/Library/Application Support/sops/age"
   age-keygen -o "~/Library/Application Support/sops/age/keys.txt"
   ```

3. **Note your public key**:
   ```bash
   # Your public key will be displayed during generation, save it!
   # It looks like: age1abc123def456...
   ```

4. **Configure .sops.yaml** (already configured in this repo):
   ```yaml
   keys:
     - &admin_key age1abc123def456...  # Your public key here
   creation_rules:
     - path_regex: secrets/.*\.yaml$
       key_groups:
         - age:
           - *admin_key
   ```

##### Managing Secrets

**Adding new secrets**:
```bash
# Create/edit encrypted file
sops home/features/secrets/example.yaml

# The file will open in your editor, add secrets in YAML format:
# api_key: "your-secret-value"
# database_password: "another-secret"
```

**Editing existing secrets**:
```bash
# Edit encrypted secrets file
sops home/features/secrets/example.yaml
```

**Viewing secrets** (for debugging):
```bash
# Decrypt and view (don't commit output!)
sops -d home/features/secrets/example.yaml
```

**Adding secrets to your configuration**:
```nix
# In any nix file where you need secrets:
sops.secrets.api_key = {
  sopsFile = ./secrets/example.yaml;
  owner = "C.Hessel";
};

# Use in configuration:
programs.some-app.apiKey = config.sops.secrets.api_key.path;
```

##### Key Management

**Backup your private key**:
```bash
# IMPORTANT: Backup your private key securely!
# Without it, you cannot decrypt your secrets
cp ~/.config/sops/age/keys.txt ~/backup-location/
# Or on macOS:
cp "~/Library/Application Support/sops/age/keys.txt" ~/backup-location/
```

**Adding team members**:
1. Get their age public key
2. Add to `.sops.yaml` keys section
3. Re-encrypt all secrets:
   ```bash
   # Re-encrypt all secrets with new keys
   find . -name "*.yaml" -path "./home/features/secrets/*" -exec sops updatekeys {} \;
   ```

**Key Locations by Platform**:
- **macOS**: `~/Library/Application Support/sops/age/keys.txt`
- **Linux**: `~/.config/sops/age/keys.txt`

##### Troubleshooting

**Common Issues**:
- **"no key could decrypt"**: Check if your private key is in the correct location
- **"failed to decrypt"**: Ensure your public key is in `.sops.yaml` and secrets were encrypted with it
- **"age: error"**: Verify age is installed and keys.txt has correct permissions (600)

**Verify setup**:
```bash
# Check if age key exists and has correct permissions
ls -la ~/.config/sops/age/keys.txt  # Linux
ls -la "~/Library/Application Support/sops/age/keys.txt"  # macOS

# Test encryption/decryption
echo "test: secret" | sops -e /dev/stdin
```

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone <your-repo-url> ~/.config/nix-dotfiles
cd ~/.config/nix-dotfiles
```

### 2. Initial Setup

#### Using the Install Script (Recommended)
```bash
./install.sh
```

#### Manual Setup (macOS)
```bash
nix run nix-darwin -- switch --flake ~/.config/nix-dotfiles
```

#### Manual Setup (Linux)
```bash
sudo nixos-rebuild switch --flake ~/.config/nix-dotfiles/
```

### 3. System Updates

Use the comprehensive update workflow to keep your system current:

#### Complete System Update (Recommended)
```bash
# Run the complete update workflow
./scripts/update-system.sh

# Or follow the manual steps below:
```

#### Manual Update Workflow

**Step 1: Check System Health**
```bash
# Check Determinate Systems daemon status
sudo determinate-nixd status

# Verify current configuration is valid
nix flake check
```

**Step 2: Update Determinate Systems (if needed)**
```bash
# Upgrade Determinate Nix to latest version
sudo determinate-nixd upgrade

# Verify upgrade completed successfully
sudo determinate-nixd status
```

**Step 3: Update Configuration**
```bash
# Update flake inputs to latest versions
nix flake update

# Validate updated configuration
nix flake check
```

**Step 4: Apply Changes**
```bash
# macOS: Apply configuration changes
sudo darwin-rebuild switch --flake ~/.config/nix-dotfiles/ --show-trace

# Linux: Apply configuration changes  
sudo nixos-rebuild switch --flake ~/.config/nix-dotfiles/ --show-trace
```

**Step 5: Verify System Health**
```bash
# Confirm Determinate Systems is healthy
sudo determinate-nixd status

# Test new functionality
# ... test your applications and tools
```

#### Quick Updates (Configuration Only)
```bash
# When you only need to apply configuration changes:
sudo darwin-rebuild switch --flake ~/.config/nix-dotfiles/ --show-trace  # macOS
sudo nixos-rebuild switch --flake ~/.config/nix-dotfiles/ --show-trace   # Linux
```

## 🤖 AI Tools Quick Start

After installation, you have local AI-powered development tools ready to use:

### OpenCommit - AI Commit Messages
```bash
# Generate AI-powered commit messages (no OpenAI API key needed!)
git add .
oco                    # Generate and commit with local AI

# Preview messages without committing
oco --dry-run         # See what message would be generated

# Check status and configuration
oco-check             # Validate AI setup and service status
oco-model             # List and switch between model presets

# Conventional commit types
oco-feat              # Generate feat: commit
oco-fix               # Generate fix: commit
oco-docs              # Generate docs: commit
```

### Ollama - Local LLM Server
```bash
# Check if local AI server is running
ollama-health         # Service status and available models
ollama-setup          # Initial setup and model download

# Interactive AI chat
ollama run qwen2.5-coder:3b "Explain this code:"
ollama run qwen2.5-coder:7b "Help me debug this function:"

# Model management
ollama list           # Show downloaded models
ollama pull qwen2.5-coder:7b  # Download coding model
```

### Model Selection
- **qwen2.5-coder:3b** (~2GB): Fast responses, optimized for commit messages
- **qwen2.5-coder:7b** (~4GB): Advanced coding assistance, better for complex tasks

**🔧 For detailed AI tools usage, see [TOOLS_CHEATSHEET.md](./TOOLS_CHEATSHEET.md#-ai--llm-tools)**

## 📊 AI Model Performance

Latest benchmark results for OpenCommit AI models (updated automatically):

<!-- BENCHMARK_RESULTS_START -->
**Last Updated:** 2025-06-23 23:47:32  
**Models Tested:** 5  
**Test Environment:** Darwin arm64

### 🏆 Top Performers

#### Simple Files (Fastest)
| Rank | Model | Time | Performance |
|------|-------|------|-------------|
| 1 | `llama3.2:3b` | 1.86s | ⚡ Excellent |
| 2 | `qwen2.5-coder:1.5b` | 4.15s | ✅ Average |
| 3 | `llama3.2:1b` | 4.39s | ✅ Average |

#### Complex Files (Fastest)
| Rank | Model | Time | Performance |
|------|-------|------|-------------|
| 1 | `llama3.2:3b` | 3.66s | 🚀 Good |
| 2 | `qwen2.5-coder:1.5b` | 4.86s | 🚀 Good |
| 3 | `llama3.2:1b` | 5.03s | 🚀 Good |

### 📈 All Models Summary
| Model | Simple (s) | Complex (s) | Hot (s) | Avg (s) |
|-------|------------|-------------|---------|---------|
| `llama3.2:1b` | 4.39 | 5.03 | 4.46 | 4.63 |
| `llama3.2:3b` | 1.86 | 3.66 | 1.73 | 2.42 |
| `qwen2.5-coder:1.5b` | 4.15 | 4.86 | 4.11 | 4.37 |
| `qwen2.5-coder:3b` | 4.98 | 5.62 | 4.95 | 5.18 |
| `qwen2.5-coder:7b` | 11.25 | 10.89 | 8.49 | 10.21 |

**📋 For detailed analysis and recommendations, see:** `results/benchmark-results-all.md`
<!-- BENCHMARK_RESULTS_END -->

**🎯 Run your own benchmarks:**
```bash
# Test all available models
scripts/hot-benchmark.sh

# Test specific models
scripts/hot-benchmark.sh -m qwen2.5-coder:3b,llama3.2:3b
```

## 🏗️ Architecture

This configuration is organized using a modular, cross-platform architecture:

```
├── hosts/           # System configurations per machine
├── home/            # Home Manager user configurations  
├── modules/         # System-level modules (darwin/nixos/shared)
├── lib/             # Helper functions
└── overlays/        # Package overlays
```

**📖 For detailed architecture documentation, see [ARCHITECTURE.md](./ARCHITECTURE.md)**

## ⚙️ Configuration

### Adding a New Host
1. Create `hosts/new-host/default.nix`
2. Add host configuration to `flake.nix`
3. Create user-specific file `home/new-host.nix` if needed

### Adding Features
1. Create feature module:
   - **Simple feature**: `home/features/feature-name.nix`
   - **Complex feature**: `home/features/feature-name/default.nix`
2. Add import to `home/features/default.nix`
3. Configure feature-specific settings

### Adding Packages
Packages are organized by categories with emoji headers for easy navigation:

#### Cross-Platform Packages (`home/features/packages.nix`)
Add to appropriate category:
- 📦 Development Environment & Package Managers
- 🔐 Security & Secrets Management
- 🛠️ System Utilities & CLI Tools
- ☁️ Cloud & Infrastructure Tools
- 💻 Development Languages & Runtimes
- 🔧 Development Tools & Version Control
- And more categorized sections...

#### Platform-Specific Packages
- **macOS**: Add to `home/features/darwin/packages.nix` (Communication, AI Tools, IDEs, Design, etc.)
- **Linux**: Add to `home/features/linux/packages.nix` (Browsers, Desktop Environment, Games, etc.)

### Platform-Specific Customization
- **System Level**: Add modules to `modules/darwin/` or `modules/nixos/`
- **User Level**: Add features to `home/features/darwin/` or `home/features/linux/`
- **Conditional Logic**: Use `lib.mkIf pkgs.stdenv.isDarwin` for conditional activation

## 🍎 macOS-Specific Setup

### Keyboard Layout
1. Go to "System Settings > Keyboard > Text Input"
2. Click "Edit" to change layout
3. Add "German - Standard" layout if using German keyboard

### Key Remapping (External Keyboards)
1. Go to "System Settings > Keyboard > Keyboard Shortcuts..."
2. Switch to "Modifier Keys" tab
3. Select your external keyboard
4. Swap Control ↔ Command keys

### Shell Configuration
Change default shell to the Nix-managed version:
```bash
# Find your shell path (look for Nix-managed shells)
cat /etc/shells

# Change default shell
chsh -s /run/current-system/sw/bin/fish  # or your preferred shell
```

### 🖥️ Monitor Management (AeroSpace + Hammerspoon)

This configuration includes intelligent monitor detection and automatic window layout management for external displays.

#### Features
- **Automatic Detection**: Detects when external monitors are connected/disconnected
- **Smart Layouts**: Automatically applies appropriate window layouts based on monitor orientation
- **LG HDR 4K Support**: Special handling for portrait-oriented displays

#### How It Works
- **Portrait Display (LG HDR 4K)**: Automatically uses horizontal splits (windows stack vertically)
- **Laptop Display**: Uses vertical splits (windows arrange side-by-side)
- **Hot-Plugging**: Detects monitor changes and reapplies layouts automatically

#### Manual Control
- **`Alt + Shift + M`**: Manually trigger layout detection and application
- **Debug**: Check Hammerspoon console for detailed monitoring logs

#### Configuration Files
- **AeroSpace**: `modules/darwin/aerospace/default.nix` (keyboard shortcuts)
- **Monitor Logic**: `home/features/darwin/keybindings/hammerspoon/config/MonitorManager.lua`
- **Workspaces**: Workspaces 6, 7, 8 are assigned to external monitors

#### Troubleshooting
```bash
# Check if AeroSpace is running
pgrep -fl aerospace

# View Hammerspoon console logs
# Open Hammerspoon app → Console (to see monitor detection messages)

# Test manual trigger
# Press Alt + Shift + M or run in Hammerspoon console:
MonitorManager.applyLayouts()
```

## 🧪 Testing

### Validate Configuration
```bash
nix flake check
```

### Test Build (Dry Run)
```bash
# macOS
nix build .#darwinConfigurations.zoidberg.system --dry-run

# Linux  
nix build .#nixosConfigurations.example-linux.config.system.build.toplevel --dry-run
```

## 🔧 Troubleshooting

### 🛡️ Safety First: Nix Cannot Break Your System

**Nix is designed to be extremely safe** - you cannot break your macOS system with these configurations:

#### ✅ What CANNOT Be Broken:
- **Core macOS system** - Nix doesn't touch `/System/`, `/usr/`, etc.
- **Boot process** - Your Mac will always boot normally
- **Existing applications** - Non-Nix apps remain untouched
- **User data** - Documents, photos, etc. are completely safe
- **System recovery** - macOS recovery mode always works

### 🔄 Rollback Mechanisms

If anything doesn't work as expected, you have multiple safety nets:

#### System (nix-darwin) Rollback
```bash
# List available system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nix-env --rollback --profile /nix/var/nix/profiles/system

# Switch to specific generation (replace 42 with desired number)
sudo nix-env --switch-generation 42 --profile /nix/var/nix/profiles/system
```

#### Home Manager Rollback
```bash
# List Home Manager generations
home-manager generations

# Rollback to previous generation (copy the path from generations output)
/nix/store/[hash]-home-manager-generation/activate
```

#### Emergency Fallback
```bash
# Use original shell if new shell doesn't work
/bin/bash

# Check system status
launchctl list | grep nix-daemon
```

### 🔍 Common Issues & Solutions

| **Issue** | **Symptoms** | **Solution** |
|-----------|--------------|--------------|
| **Build Failures** | `nix flake check` fails | Run with `--show-trace` for details |
| **Shell Issues** | Terminal doesn't start properly | Use `/bin/bash`, then rollback |
| **Missing Secrets** | SOPS decryption errors | Check age key location and permissions |
| **Platform Detection** | Wrong packages installed | Verify `pkgs.stdenv.isDarwin` logic |
| **Determinate Daemon Issues** | Service not responding | Check with `sudo determinate-nixd status` |
| **Permission Errors** | `/nix/store` access denied | Restart daemon: `sudo launchctl kickstart -k system/org.nixos.nix-daemon` |
| **Generation Not Found** | Rollback fails | List generations first, use valid number |

### 🚨 Step-by-Step Recovery

#### 1. Configuration Won't Build
```bash
# Check for syntax errors
nix flake check --show-trace

# Try building without applying
nix build .#darwinConfigurations.zoidberg.system --show-trace

# If successful, apply normally
sudo darwin-rebuild switch --flake . --show-trace
```

#### 2. System Feels Broken After Apply
```bash
# Check current generation
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous (second-to-last) generation
sudo nix-env --rollback --profile /nix/var/nix/profiles/system

# Reboot if necessary (usually not required)
sudo reboot
```

#### 3. Terminal/Shell Issues
```bash
# Use safe shell
/bin/bash

# Check what shell is set
echo $SHELL

# Reset to bash temporarily
chsh -s /bin/bash

# After fixing config, switch back
chsh -s /run/current-system/sw/bin/fish
```

#### 4. Home Manager Issues
```bash
# Check Home Manager status
home-manager generations

# Rollback Home Manager only
/nix/store/[previous-generation-hash]/activate

# Or rebuild Home Manager separately
home-manager switch --flake .
```

### 🔧 Determinate Systems Troubleshooting

#### Daemon Management
```bash
# Check daemon status and configuration
sudo determinate-nixd status

# Check current version
determinate-nixd version

# Upgrade to latest version
sudo determinate-nixd upgrade

# Restart daemon if needed
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

#### Configuration Issues
```bash
# Check Determinate Systems configuration
cat /etc/nix/nix.conf                    # Managed by Determinate (read-only)
cat /etc/nix/nix.custom.conf             # Your custom settings (if any)

# View your dotfiles Determinate config
cat hosts/shared/determinate.nix

# Test configuration validity
nix eval .#darwinConfigurations.zoidberg.system.config.system.stateVersion
```

#### Service Diagnostics
```bash
# Check if daemon is running
launchctl list | grep nix-daemon

# Check nix store integrity
nix store verify --all

# View daemon logs (if available)
sudo launchctl print system/org.nixos.nix-daemon
```

### 🆘 Recovery Options

#### Safe Recovery (Recommended)
```bash
# 1. Rollback system generation
sudo nix-env --rollback --profile /nix/var/nix/profiles/system

# 2. If daemon issues, restart Determinate service
sudo launchctl kickstart -k system/org.nixos.nix-daemon

# 3. Check daemon status
sudo determinate-nixd status
```

#### Advanced Recovery (If needed)
```bash
# Reset Determinate authentication (if auth issues)
sudo determinate-nixd auth reset

# Reinstall Determinate Nix (preserves configurations)
# Download latest from: https://install.determinate.systems/determinate-pkg/stable/Universal
# Or use command line:
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 📊 Health Check Commands

```bash
# Complete system health check
echo "=== Determinate Systems Status ===" && \
sudo determinate-nixd status && \
echo -e "\n=== Nix Store Health ===" && \
nix store verify --all && \
echo -e "\n=== Configuration Validity ===" && \
nix flake check --show-trace && \
echo -e "\n=== Current Generation ===" && \
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -3
```

### 📞 Getting Help

- **Configuration Errors**: Use `--show-trace` for detailed error messages
- **Architecture Questions**: Review [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Determinate Issues**: Check daemon status with `sudo determinate-nixd status`
- **Platform Problems**: Verify platform detection logic with `uname -a`

**Remember**: 
- **Determinate Systems manages** `/etc/nix/nix.conf` - never modify it manually
- **Use** `/etc/nix/nix.custom.conf` for custom Nix configuration
- **Your dotfiles config** is in `hosts/shared/determinate.nix`
- **Nix is designed for safe experimentation** - you can always roll back!

## 📚 Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.html)
- [nix-darwin Options](https://daiderd.com/nix-darwin/manual/index.html)
- [NixOS Options](https://search.nixos.org/options)
