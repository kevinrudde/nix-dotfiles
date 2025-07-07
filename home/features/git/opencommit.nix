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
      $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_MODEL=qwen3:8b
    fi
  '';
  
  # Environment variables for dynamic model switching
  home.sessionVariables = {
    OCO_DEFAULT_MODEL = "qwen3:8b";
  };
  
  # Simple aliases for opencommit usage
  home.shellAliases = {
    # Main commands - OpenCommit with native conventional commits
    "oco" = "opencommit";
    
    # Jira integration
    "oco-jira" = "oco-jira-commit";
    "oco-ticket" = "oco-jira-commit";
    
    # Quick commit types (conventional)
    "oco-feat" = "opencommit --context='feat: feature implementation'";
    "oco-fix" = "opencommit --context='fix: bug fix'";
    "oco-docs" = "opencommit --context='docs: documentation update'";
    "oco-refactor" = "opencommit --context='refactor: code refactoring'";
    "oco-test" = "opencommit --context='test: testing changes'";
    "oco-chore" = "opencommit --context='chore: maintenance task'";
    
    # Configuration
    "oco-config" = "opencommit config";
    "oco-status" = "opencommit config get";
  };
  
  # Essential scripts only
  home.packages = with pkgs; [
    # Simple health check
    (writeShellScriptBin "oco-check" ''
      #!/usr/bin/env bash
      
      echo "🔍 OpenCommit Health Check"
      echo ""
      
      # Check ollama service
      if curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        echo "✅ Ollama: Running"
        
        # Check model
        model=$(opencommit config get OCO_MODEL 2>/dev/null | grep "OCO_MODEL=" | cut -d'=' -f2 || echo "qwen3:8b")
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
    
    # Enhanced model switcher with persistence - Updated for Qwen3
    (writeShellScriptBin "oco-model" ''
      #!/usr/bin/env bash
      
      declare -A models=(
        ["fast"]="qwen3:8b"
        ["default"]="qwen3:8b"
        ["detailed"]="qwen3:14b"
        ["advanced"]="qwen3:32b-q4_K_M"
        ["creative"]="llama3.2:3b"
      )
      
      if [ $# -eq 0 ]; then
        current=$(opencommit config get OCO_MODEL 2>/dev/null | grep "OCO_MODEL=" | cut -d'=' -f2 || echo "''${OCO_DEFAULT_MODEL:-not set}")
        echo "🤖 Current model: $current"
        echo "🏠 Default model: ''${OCO_DEFAULT_MODEL:-qwen3:8b}"
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
          default_model="''${OCO_DEFAULT_MODEL:-qwen3:8b}"
          echo "🔄 Resetting to default model: $default_model"
          opencommit config set OCO_MODEL="$default_model"
          echo "✅ Reset to default model"
          ;;
        "status")
          current=$(opencommit config get OCO_MODEL 2>/dev/null | grep "OCO_MODEL=" | cut -d'=' -f2 || echo "not set")
          echo "🤖 Current model: $current"
          echo "🏠 Default model: ''${OCO_DEFAULT_MODEL:-qwen3:8b}"
          
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
      
      echo "🎫 OpenCommit with Jira Integration"
      echo ""
      
      # Get current branch
      branch=$(git rev-parse --abbrev-ref HEAD)
      echo "📋 Current branch: $branch"
      
      # Extract Jira ticket from branch name (flexible patterns)
      # Supports: task/ABC-1234, feature/PROJ-123-description, PROJ-123-description, etc.
      jira_ticket=$(echo "$branch" | grep -oE '[A-Z]+-[0-9]+' | head -1)
      
      if [[ -n "$jira_ticket" ]]; then
        echo "🎫 Found ticket: $jira_ticket"
        
        # Quick pre-check
        if ! curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
          echo "❌ Ollama not running"
          echo "💡 Start with: launchctl start org.nixos.ollama"
          exit 1
        fi
        
        # Generate message and add Jira prefix
        echo "🤖 Generating commit message..."
        
        # Let opencommit run normally and commit, then amend with Jira prefix
        echo "Running opencommit (will commit, then we'll amend with Jira prefix)..."
        
        if timeout 60s opencommit; then
          # Get the commit message that was just created
          last_msg=$(git log -1 --pretty=format:"%s")
          
          # Create new message with Jira prefix
          full_msg="$jira_ticket: $last_msg"
          
          echo ""
          echo "📝 Original message: $last_msg"
          echo "📝 New message: $full_msg"
          echo ""
          read -p "🚀 Amend commit with Jira prefix? (y/N): " -n 1 -r
          echo
          
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            git commit --amend -m "$full_msg"
            echo "✅ Amended commit with Jira prefix!"
          else
            echo "ℹ️  Commit kept as-is without Jira prefix"
          fi
        else
          exit_code=$?
          echo ""
          if [ $exit_code -eq 124 ]; then
            echo "❌ Timeout: OpenCommit took too long (>60s)"
            echo "💡 Try a faster model: oco-model fast"
          else
            echo "❌ Failed to generate message (exit code: $exit_code)"
            echo "💡 Check: oco-check"
          fi
        fi
      else
        echo "❌ No Jira ticket in branch: $branch"
        echo ""
        echo "💡 Supported formats:"
        echo "   • task/ABC-1234"
        echo "   • feature/PROJ-123-description"
        echo "   • PROJ-123-description"
        echo "   • bugfix/TEAM-456-fix"
        echo "   • any-branch-with-TICKET-123-anywhere"
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
      model="qwen3:8b"
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