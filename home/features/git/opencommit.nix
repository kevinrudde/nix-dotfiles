{ pkgs, lib, ... }: {
  
  # OpenCommit initial configuration (only sets defaults if not already configured)
  home.activation.opencommitConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Configure OpenCommit for local ollama usage with conventional commits
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_API_URL=http://127.0.0.1:11434/v1
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_API_KEY=ollama
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_TOKENS_MAX_INPUT=8192
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_TOKENS_MAX_OUTPUT=200
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_DESCRIPTION=false
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_EMOJI=false
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_LANGUAGE=en
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_GITPUSH=false
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_ONE_LINE_COMMIT=true
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_PROMPT_MODULE=conventional-commit
    
    # Only set default model if not already configured
    if ! ${pkgs.opencommit}/bin/opencommit config get OCO_MODEL >/dev/null 2>&1; then
      $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_MODEL=qwen2.5-coder:3b
    fi
  '';
  
  # Environment variables for dynamic model switching
  home.sessionVariables = {
    OCO_DEFAULT_MODEL = "qwen2.5-coder:3b";
  };
  
  # Simple aliases for opencommit usage
  home.shellAliases = {
    # Main commands - conventional commits enforced
    "oco" = "oco-conventional";
    "oc" = "oco-conventional";
    "oco-raw" = "opencommit";  # Direct access if needed
    
    # Jira integration
    "oco-jira" = "oco-jira-commit";
    "oco-ticket" = "oco-jira-commit";
    
    # Quick commit types (conventional)
    "oco-feat" = "oco-conventional --context='feat: feature implementation'";
    "oco-fix" = "oco-conventional --context='fix: bug fix'";
    "oco-docs" = "oco-conventional --context='docs: documentation update'";
    "oco-refactor" = "oco-conventional --context='refactor: code refactoring'";
    "oco-test" = "oco-conventional --context='test: testing changes'";
    "oco-chore" = "oco-conventional --context='chore: maintenance task'";
    
    # Configuration
    "oco-config" = "opencommit config";
    "oco-status" = "opencommit config get";
  };
  
  # Essential scripts only
  home.packages = with pkgs; [
    # Conventional commit wrapper
    (writeShellScriptBin "oco-conventional" ''
      #!/usr/bin/env bash
      
      # Ensure we're in a git repository
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ Not in a git repository"
        exit 1
      fi
      
      # Check for staged changes
      if git diff --cached --quiet; then
        echo "❌ No staged changes"
        echo "💡 Run: git add <files>"
        exit 1
      fi
      
      echo "🤖 Generating conventional commit message..."
      
      # Run opencommit and capture output
      if output=$(opencommit "$@" --dry-run 2>/dev/null); then
        # Extract just the commit message part (after "Generated commit message:")
        commit_msg=$(echo "$output" | sed -n '/Generated commit message:/,/^$/p' | sed '1d;$d' | sed 's/^—*$//' | grep -v '^$' | head -1)
        
        # If message doesn't start with conventional format, try to fix it
        if [[ ! "$commit_msg" =~ ^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?!?:\ .+ ]]; then
          echo "⚠️  Non-conventional format detected, reformatting..."
          
          # Determine type based on file changes
          files=$(git diff --cached --name-only)
          if echo "$files" | grep -q "\\.md$\|README\|CHANGELOG"; then
            type="docs"
          elif echo "$files" | grep -q "test\|spec"; then
            type="test"
          elif echo "$files" | grep -q "package\\.json\|flake\\.nix\|Cargo\\.toml"; then
            type="chore"
          else
            type="feat"
          fi
          
          # Clean and format the message
          clean_msg=$(echo "$commit_msg" | sed 's/^[^a-zA-Z]*//' | sed 's/^[[:space:]]*//')
          commit_msg="$type: $clean_msg"
        fi
        
        echo ""
        echo "📝 Conventional commit message:"
        echo "   $commit_msg"
        echo ""
        read -p "🚀 Commit with this message? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          git commit -m "$commit_msg"
          echo "✅ Committed with conventional format!"
        else
          echo "❌ Commit cancelled"
        fi
      else
        echo "❌ Failed to generate commit message"
        echo "💡 Check: oco-check"
        exit 1
      fi
    '')
    
    # Simple health check
    (writeShellScriptBin "oco-check" ''
      #!/usr/bin/env bash
      
      echo "🔍 OpenCommit Health Check"
      echo ""
      
      # Check ollama service
      if curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        echo "✅ Ollama: Running"
        
        # Check model
        model=$(opencommit config get OCO_MODEL 2>/dev/null | grep "OCO_MODEL=" | cut -d'=' -f2 || echo "qwen2.5-coder:3b")
        if curl -s http://127.0.0.1:11434/api/tags | ${jq}/bin/jq -r '.models[]?.name' | grep -q "^$model$"; then
          echo "✅ Model: $model available"
        else
          echo "⚠️  Model: $model not found"
          echo "💡 Run: ollama pull $model"
        fi
      else
        echo "❌ Ollama: Not running"
        echo "💡 Run: launchctl start org.nixos.ollama"
      fi
      
      # Check git repo
      if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "✅ Git: Repository detected"
        if git diff --cached --quiet; then
          echo "ℹ️  Staged: No changes (run 'git add .' first)"
        else
          echo "✅ Staged: Ready for commit"
        fi
      else
        echo "ℹ️  Git: Not in repository"
      fi
    '')
    
    # Enhanced model switcher with persistence
    (writeShellScriptBin "oco-model" ''
      #!/usr/bin/env bash
      
      declare -A models=(
        ["fast"]="qwen2.5-coder:1.5b"
        ["default"]="qwen2.5-coder:3b"
        ["detailed"]="qwen2.5-coder:7b"
        ["creative"]="llama3.2:3b"
      )
      
      if [ $# -eq 0 ]; then
        current=$(opencommit config get OCO_MODEL 2>/dev/null | grep "OCO_MODEL=" | cut -d'=' -f2 || echo "''${OCO_DEFAULT_MODEL:-not set}")
        echo "🤖 Current model: $current"
        echo "🏠 Default model: ''${OCO_DEFAULT_MODEL:-qwen2.5-coder:3b}"
        echo ""
        echo "Available presets:"
        for preset in "''${!models[@]}"; do
          echo "  $preset: ''${models[$preset]}"
        done
        echo ""
        echo "Commands:"
        echo "  oco-model <preset>  - Switch to preset model"
        echo "  oco-model reset     - Reset to default model"
        echo "  oco-model status    - Show current configuration"
        exit 0
      fi
      
      case "$1" in
        "reset")
          default_model="''${OCO_DEFAULT_MODEL:-qwen2.5-coder:3b}"
          echo "🔄 Resetting to default model: $default_model"
          opencommit config set OCO_MODEL="$default_model"
          echo "✅ Reset to default model"
          ;;
        "status")
          current=$(opencommit config get OCO_MODEL 2>/dev/null | grep "OCO_MODEL=" | cut -d'=' -f2 || echo "not set")
          echo "🤖 Current model: $current"
          echo "🏠 Default model: ''${OCO_DEFAULT_MODEL:-qwen2.5-coder:3b}"
          
          # Check if model is available
          if curl -s http://127.0.0.1:11434/api/tags | ${jq}/bin/jq -r '.models[]?.name' | grep -q "^$current$"; then
            echo "✅ Model status: Available"
          else
            echo "⚠️  Model status: Not downloaded"
            echo "💡 Run: ollama pull $current"
          fi
          ;;
        *)
          preset="$1"
          if [[ -n "''${models[$preset]}" ]]; then
            model="''${models[$preset]}"
            echo "🔄 Switching to $preset model: $model"
            
            # Pull model if needed
            if ! curl -s http://127.0.0.1:11434/api/tags | ${jq}/bin/jq -r '.models[]?.name' | grep -q "^$model$"; then
              echo "📦 Downloading model..."
              ollama pull "$model" || {
                echo "❌ Failed to download model"
                exit 1
              }
            fi
            
            # Update config
            opencommit config set OCO_MODEL="$model"
            echo "✅ Model switched to: $model"
            echo "💡 This setting persists across system rebuilds"
          else
            echo "❌ Unknown preset: $preset"
            echo "Available: ''${!models[*]} reset status"
          fi
          ;;
      esac
    '')
    
    # Jira integration
    (writeShellScriptBin "oco-jira-commit" ''
      #!/usr/bin/env bash
      
      # Check git repo
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ Not in a git repository"
        exit 1
      fi
      
      # Check staged changes
      if git diff --cached --quiet; then
        echo "❌ No staged changes"
        echo "💡 Run: git add <files>"
        exit 1
      fi
      
      # Extract Jira ticket from branch
      branch=$(git rev-parse --abbrev-ref HEAD)
      jira_ticket=""
      
      # Try multiple patterns
      jira_ticket=$(echo "$branch" | sed -nr 's,^[a-z]+/([A-Z0-9]+-[0-9]+)-.+,\1,p')
      if [[ -z "$jira_ticket" ]]; then
        jira_ticket=$(echo "$branch" | sed -nr 's,^([A-Z0-9]+-[0-9]+).*,\1,p')
      fi
      
      if [[ -n "$jira_ticket" ]]; then
        echo "🎫 Found ticket: $jira_ticket"
        echo "🤖 Generating commit message..."
        
        # Generate message and add Jira prefix
        if msg=$(opencommit --dry-run 2>/dev/null); then
          full_msg="$jira_ticket: $msg"
          echo ""
          echo "📝 Commit message:"
          echo "   $full_msg"
          echo ""
          read -p "🚀 Commit? (y/N): " -n 1 -r
          echo
          
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            git commit -m "$full_msg"
            echo "✅ Committed!"
          else
            echo "❌ Cancelled"
          fi
        else
          echo "❌ Failed to generate message"
          echo "💡 Check: oco-check"
        fi
      else
        echo "❌ No Jira ticket in branch: $branch"
        echo ""
        echo "💡 Supported formats:"
        echo "   • feature/PROJ-123-description"
        echo "   • PROJ-123-description"
        echo "   • bugfix/TEAM-456-fix"
        echo ""
        echo "💡 Or use regular commit: oco"
      fi
    '')
    
    # Simple setup script
    (writeShellScriptBin "opencommit-setup" ''
      #!/usr/bin/env bash
      
      echo "🔧 OpenCommit Setup"
      echo ""
      
      # Check ollama
      if ! curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        echo "❌ Ollama not running"
        echo "💡 Start with: launchctl start org.nixos.ollama"
        exit 1
      fi
      
      # Check/pull model
      model="qwen2.5-coder:3b"
      if ! curl -s http://127.0.0.1:11434/api/tags | ${jq}/bin/jq -r '.models[]?.name' | grep -q "^$model$"; then
        echo "📦 Pulling model: $model"
        ollama pull "$model" || exit 1
      fi
      
      echo "✅ Setup complete!"
      echo ""
      echo "📖 Usage:"
      echo "   1. Stage changes: git add ."
      echo "   2. Generate commit: oco"
      echo "   3. Jira integration: oco-jira"
      echo ""
      echo "🔧 Commands:"
      echo "   • oco-check    - Health check"
      echo "   • oco-model    - Switch models"
      echo "   • oco-config   - View config"
    '')
  ];
} 