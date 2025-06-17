# 🛠️ Development Tools Cheatsheet

A comprehensive reference for all the enhanced tools in your nix-dotfiles configuration.

## 📋 Table of Contents

- [🔧 Git Workflow](#-git-workflow)
- [🖥️ Enhanced Tmux](#️-enhanced-tmux)
- [⚡ Workflow Automation](#-workflow-automation)
- [📊 System Monitoring](#-system-monitoring)
- [🌐 Network Tools](#-network-tools)
- [💻 Development Environment](#-development-environment)
- [🧪 Code Quality & Testing](#-code-quality--testing)
- [📝 Documentation & Viewing](#-documentation--viewing)
- [🚀 Productivity Utilities](#-productivity-utilities)

---

## 🔧 Git Workflow

### Lazygit - Terminal Git UI
```bash
# Start lazygit in current repo
lazygit

# Key bindings inside lazygit:
# j/k          - Navigate up/down
# h/l          - Navigate left/right between panels
# space        - Stage/unstage files
# c            - Commit
# P            - Push
# p            - Pull
# enter        - View diff/details
# q            - Quit
# ?            - Help
```

### Delta - Enhanced Git Diff (Already configured!)
```bash
# Your git is already configured to use delta automatically
git diff              # Shows beautiful syntax-highlighted diffs
git log -p            # Shows commit history with enhanced diffs
git show HEAD         # Shows last commit with delta formatting
```

---

## 🖥️ Enhanced Tmux

### New Prefix: `Ctrl+A` (instead of Ctrl+B)

### Essential Commands
```bash
# Session management
tmux new-session -s myproject    # Create named session
tmux attach -t myproject         # Attach to session
tmux list-sessions              # List all sessions
tmux kill-session -t myproject  # Kill session

# Your custom function (already configured)
t                               # Fuzzy-find and attach to session
```

### Key Bindings (Prefix = Ctrl+A)
```bash
# Window/Pane Management
Ctrl+A |             # Split horizontally (new!)
Ctrl+A -             # Split vertically (new!)
Ctrl+A c             # Create new window
Ctrl+A &             # Kill window
Ctrl+A x             # Kill pane

# Navigation (No prefix needed!)
Alt + Arrow Keys     # Navigate between panes
Shift + Arrow Keys   # Navigate between windows

# Copy Mode (Vim-style)
Ctrl+A [             # Enter copy mode
v                    # Start selection (in copy mode)
y                    # Copy selection (in copy mode)
Ctrl+A ]             # Paste

# Useful Commands
Ctrl+A r             # Reload tmux config
Ctrl+A z             # Zoom/unzoom current pane
Ctrl+A ,             # Rename window
Ctrl+A $             # Rename session
```

---

## ⚡ Workflow Automation

### Just - Modern Command Runner
```bash
# List available commands
just --list
just -l

# Run commands
just build           # Run build task
just test            # Run test task
just dev             # Run dev server

# Create a justfile example:
# build:
#     echo "Building project..."
#     npm run build
# 
# test:
#     echo "Running tests..."
#     npm test
```

### Watchexec - File Watcher
```bash
# Watch for changes and run command
watchexec -e .js npm test                    # Run tests when JS files change
watchexec -e .ts -e .tsx npm run build      # Build when TS files change
watchexec -w src npm run dev                 # Watch src directory
watchexec -i node_modules npm test          # Ignore node_modules

# Advanced options
watchexec -r npm run dev                     # Restart long-running processes
watchexec -d 1000 npm test                   # Debounce for 1 second
```

### Hyperfine - Benchmarking
```bash
# Compare command performance
hyperfine 'grep -r "pattern" .' 'rg "pattern"'

# Benchmark with warmup runs
hyperfine --warmup 3 'npm run build'

# Export results
hyperfine --export-markdown results.md 'command1' 'command2'
hyperfine --export-json results.json 'command1' 'command2'

# Multiple runs for statistical accuracy
hyperfine --runs 10 'your-command'
```

---

## 📊 System Monitoring

### Bottom - Modern System Monitor
```bash
# Start bottom (better than htop)
btm
bottom

# Key bindings in bottom:
# q            - Quit
# /            - Search processes
# dd           - Kill selected process
# Tab          - Switch between widgets
# +/-          - Zoom in/out on graphs
# e            - Expand/collapse process tree
```

### Duf - Disk Usage (Better df)
```bash
# Show disk usage for all mounted filesystems
duf

# Show specific filesystems
duf /home /var

# Hide specific filesystem types
duf --hide-fs tmpfs,devtmpfs

# JSON output
duf --json
```

### Dust - Directory Size (Better du)
```bash
# Show directory sizes in current directory
dust

# Analyze specific directory
dust ~/Projects

# Limit depth
dust -d 3

# Show sizes in different units
dust -b          # Bytes
dust -k          # Kilobytes
dust -m          # Megabytes
dust -g          # Gigabytes

# Number of files to show
dust -n 20
```

### Ncdu - Visual Disk Usage
```bash
# Analyze current directory (interactive)
ncdu

# Analyze specific directory
ncdu ~/Downloads

# Key bindings in ncdu:
# j/k or ↑/↓   - Navigate
# Enter        - Enter directory
# d            - Delete selected item
# g            - Show item graph
# i            - Show item info
# r            - Recalculate
# q            - Quit
```

---

## 🌐 Network Tools

### Bandwhich - Network Usage by Process
```bash
# Show network usage (requires sudo on some systems)
sudo bandwhich

# Show specific interface
bandwhich -i eth0

# Key bindings:
# q            - Quit
# space        - Pause
# tab          - Switch between views
```

### Ngrok - Secure Tunnels
```bash
# Expose local port to internet
ngrok http 3000                    # Expose port 3000
ngrok http 8080                    # Expose port 8080

# With custom subdomain (paid plans)
ngrok http -subdomain=myapp 3000

# TCP tunneling
ngrok tcp 22                       # Expose SSH

# Configuration file at ~/.ngrok2/ngrok.yml
```

### Nmap - Network Discovery
```bash
# Scan local network
nmap 192.168.1.0/24

# Scan specific host
nmap example.com

# Port scan
nmap -p 22,80,443 example.com

# Service detection
nmap -sV example.com

# OS detection
nmap -O example.com
```

---

## 💻 Development Environment

### Mise - Runtime Version Manager
```bash
# Install runtime versions
mise install node@20              # Install Node.js 20
mise install python@3.11          # Install Python 3.11
mise install go@1.21              # Install Go 1.21

# Use specific versions
mise use node@20                  # Use Node 20 in current project
mise use python@3.11              # Use Python 3.11
mise global node@20               # Set global Node version

# List available versions
mise list-remote node             # Available Node versions
mise list node                    # Installed Node versions

# Current versions
mise current                      # Show all current versions

# Configuration
# Create .mise.toml in project root:
# [tools]
# node = "20"
# python = "3.11"
```

### ASDF-VM - Alternative Runtime Manager
```bash
# Add plugins
asdf plugin add nodejs
asdf plugin add python

# Install versions
asdf install nodejs 20.0.0
asdf install python 3.11.0

# Set versions
asdf local nodejs 20.0.0          # For current project
asdf global nodejs 20.0.0         # Globally

# List versions
asdf list nodejs                  # Installed versions
asdf list all nodejs              # Available versions
```

### Mkcert - Local HTTPS Certificates
```bash
# Install local CA
mkcert -install

# Create certificates
mkcert localhost                   # For localhost
mkcert example.local              # For custom domain
mkcert '*.example.local'          # Wildcard certificate

# Multiple domains
mkcert localhost 127.0.0.1 ::1

# Custom certificate authority
mkcert -CAROOT                     # Show CA location
```

---

## 🧪 Code Quality & Testing

### Shellcheck - Shell Script Analysis
```bash
# Check shell script
shellcheck script.sh

# Check with specific shell
shellcheck -s bash script.sh
shellcheck -s zsh script.sh

# Exclude specific warnings
shellcheck -e SC2034 script.sh     # Exclude unused variable warning

# Different output formats
shellcheck -f json script.sh       # JSON output
shellcheck -f gcc script.sh        # GCC-style output

# Check multiple files
shellcheck *.sh
```

### Shfmt - Shell Script Formatter
```bash
# Format and display
shfmt script.sh

# Format in place
shfmt -w script.sh

# Format with specific options
shfmt -i 2 script.sh               # 2-space indentation
shfmt -ci script.sh                # Indent case statements
shfmt -bn script.sh                # Put binary operators at start of line

# Format all shell files
shfmt -w *.sh

# Check if files are formatted
shfmt -d *.sh
```

### Yamllint - YAML Validation
```bash
# Validate YAML file
yamllint config.yaml

# Validate multiple files
yamllint *.yaml *.yml

# Custom config
yamllint -c .yamllint.yaml file.yml

# Different output formats
yamllint -f parsable config.yaml   # Machine-readable format
yamllint -f colored config.yaml    # Colored output

# Disable specific rules
yamllint -d '{extends: default, rules: {line-length: disable}}' file.yml
```

### K6 - Load Testing
```bash
# Run load test
k6 run script.js

# With virtual users and duration
k6 run --vus 10 --duration 30s script.js

# With different stages
k6 run --stage 5m:10 --stage 10m:20 --stage 5m:0 script.js

# Output results
k6 run --out json=results.json script.js
```

---

## 📝 Documentation & Viewing

### Glow - Markdown Viewer
```bash
# View markdown file
glow README.md

# View with pager
glow -p README.md

# View from URL
glow https://raw.githubusercontent.com/user/repo/main/README.md

# Style options
glow -s dark README.md             # Dark theme
glow -s light README.md            # Light theme

# List available styles
glow -l

# Word wrap
glow -w 80 README.md               # Wrap at 80 characters
```

### Tldr - Simplified Man Pages
```bash
# Get quick examples for commands
tldr git
tldr curl
tldr ssh
tldr docker

# Update tldr database
tldr --update

# List all available pages
tldr --list

# Random example
tldr --random

# Different platforms
tldr -p linux git
tldr -p osx git
```

### Tree - Directory Structure
```bash
# Show directory tree
tree

# Limit depth
tree -L 2                          # Show 2 levels deep
tree -L 3 ~/Projects              # Show 3 levels in specific directory

# Show hidden files
tree -a

# Show only directories
tree -d

# Ignore patterns
tree -I 'node_modules|.git'

# File size information
tree -s

# Output to file
tree > directory_structure.txt
```

---

## 🚀 Productivity Utilities

### Tokei - Code Statistics
```bash
# Count lines of code in current directory
tokei

# Specific directory
tokei ~/Projects/myapp

# Specific languages
tokei --type rust
tokei -t javascript -t typescript

# Exclude files/directories
tokei --exclude '*.json' --exclude node_modules

# Output formats
tokei --output json               # JSON output
tokei --output yaml               # YAML output

# Sort by lines of code
tokei --sort code
```

### Procs - Modern Process Viewer
```bash
# Show all processes
procs

# Search processes
procs nginx                       # Show processes containing "nginx"
procs -c cpu                     # Sort by CPU usage
procs -c mem                     # Sort by memory usage

# Tree view
procs --tree

# Show specific columns
procs --only pid,name,cpu,mem

# Watch mode (like top)
procs --watch
```

### Sd - Find and Replace
```bash
# Basic find and replace
sd 'old_text' 'new_text' file.txt

# In-place replacement
sd -p 'old_text' 'new_text' file.txt

# Regular expressions
sd '\b\d{3}-\d{2}-\d{4}\b' '[REDACTED]' file.txt

# Multiple files
sd 'old_text' 'new_text' *.txt

# Preview changes (dry run)
sd 'old_text' 'new_text' file.txt  # Shows changes without applying

# Case insensitive
sd -s 'Old_Text' 'new_text' file.txt
```

### Fd - Fast File Find (Already in shell config)
```bash
# Find files by name
fd pattern

# Find in specific directory
fd pattern ~/Documents

# Find by extension
fd -e js                          # Find JavaScript files
fd -e md -e txt                   # Find markdown and text files

# Include hidden files
fd -H pattern

# Execute command on results
fd -e js -x wc -l                 # Count lines in JS files
```

### Ripgrep - Fast Text Search (Already configured)
```bash
# Search for text
rg pattern

# Search in specific file types
rg pattern -t js                  # Search in JavaScript files
rg pattern -t py                  # Search in Python files

# Case insensitive
rg -i pattern

# Show context
rg -C 3 pattern                   # 3 lines of context
rg -A 2 -B 2 pattern             # 2 lines after and before

# Search and replace preview
rg pattern --replace replacement
```

---

## 🔄 Integration Examples

### Combining Tools for Powerful Workflows

```bash
# Monitor project while developing
watchexec -e .js -e .css 'npm run build && echo "Build complete!"'

# Analyze project structure and size
echo "=== Project Overview ===" && \
tree -I 'node_modules|.git' -L 3 && \
echo -e "\n=== Code Statistics ===" && \
tokei

# Git workflow with enhanced tools
lazygit                           # Interactive git management
# Then use your existing git aliases with delta

# System monitoring combination
btm                              # Overall system view
# In another pane: bandwhich      # Network usage
# In another pane: ncdu           # Disk usage

# Development environment setup
mise use node@20 python@3.11     # Set up runtimes
mkcert localhost                  # Create HTTPS cert
ngrok http 3000                   # Expose to internet if needed
```

---

## 💡 Pro Tips

1. **Tmux + Tools**: Use tmux panes to run multiple monitoring tools simultaneously
2. **Aliases**: Create aliases for frequently used commands in your shell config
3. **Just + Watchexec**: Combine for automatic task running during development
4. **Hyperfine**: Use for A/B testing different implementations
5. **Mise**: Prefer over nvm/rbenv for consistent cross-language version management
6. **Glow**: Perfect for reading project READMEs without leaving terminal

---

*This cheatsheet covers the enhanced tools added to your nix-dotfiles configuration. All tools are installed and ready to use in your development environment.* 