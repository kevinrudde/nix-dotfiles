{ pkgs, lib, ... }: {
  
  # OpenCommit configuration via Home Manager activation
  home.activation.opencommitConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Configure OpenCommit for local ollama usage
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_API_URL=http://127.0.0.1:11434/v1
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_MODEL=qwen2.5-coder:3b
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_API_KEY=ollama
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_TOKENS_MAX_INPUT=8192
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_TOKENS_MAX_OUTPUT=300
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_DESCRIPTION=false
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_EMOJI=true
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_LANGUAGE=en
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_GITPUSH=false
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_ONE_LINE_COMMIT=false
    $DRY_RUN_CMD ${pkgs.opencommit}/bin/opencommit config set OCO_PROMPT_MODULE=conventional-commit
  '';
  
  # Simple aliases for opencommit usage
  home.shellAliases = {
    # Main commands - simple and direct
    "oco" = "opencommit";
    "oc" = "opencommit";
    
    # Jira integration
    "oco-jira" = "oco-jira-commit";
    "oco-ticket" = "oco-jira-commit";
    
    # Quick commit types
    "oco-feat" = "opencommit 'feat: '";
    "oco-fix" = "opencommit 'fix: '";
    "oco-docs" = "opencommit 'docs: '";
    "oco-refactor" = "opencommit 'refactor: '";
    "oco-test" = "opencommit 'test: '";
    "oco-chore" = "opencommit 'chore: '";
    
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
    
    # Model switcher
    (writeShellScriptBin "oco-model" ''
      #!/usr/bin/env bash
      
      declare -A models=(
        ["fast"]="qwen2.5-coder:1.5b"
        ["default"]="qwen2.5-coder:3b"
        ["detailed"]="qwen2.5-coder:7b"
        ["creative"]="llama3.2:3b"
      )
      
      if [ $# -eq 0 ]; then
        current=$(opencommit config get OCO_MODEL 2>/dev/null | grep "OCO_MODEL=" | cut -d'=' -f2 || echo "not set")
        echo "🤖 Current model: $current"
        echo ""
        echo "Available presets:"
        for preset in "''${!models[@]}"; do
          echo "  $preset: ''${models[$preset]}"
        done
        echo ""
        echo "Usage: oco-model <preset>"
        exit 0
      fi
      
      preset="$1"
      if [[ -n "''${models[$preset]}" ]]; then
        model="''${models[$preset]}"
        echo "🔄 Switching to: $model"
        
        # Pull model if needed
        if ! curl -s http://127.0.0.1:11434/api/tags | ${jq}/bin/jq -r '.models[]?.name' | grep -q "^$model$"; then
          echo "📦 Downloading model..."
          ollama pull "$model"
        fi
        
        # Update config
        opencommit config set OCO_MODEL="$model"
        echo "✅ Model switched to: $model"
      else
        echo "❌ Unknown preset: $preset"
        echo "Available: ''${!models[*]}"
      fi
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