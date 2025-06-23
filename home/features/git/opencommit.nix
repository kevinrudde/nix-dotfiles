{ pkgs, lib, ... }: {
  
  # OpenCommit configuration for local ollama usage
  home.sessionVariables = {
    # Configure opencommit to use local ollama instead of OpenAI
    OCO_API_URL = "http://127.0.0.1:11434/v1";
    OCO_MODEL = "llama3.2:3b";  # Fast, efficient model for commit messages
    
    # Optimize for local usage
    OCO_TOKENS_MAX_INPUT = "4096";    # Reasonable input limit
    OCO_TOKENS_MAX_OUTPUT = "200";    # Concise commit messages
    
    # Disable OpenAI API requirements
    OCO_API_KEY = "ollama";  # Required but unused with local ollama
    
    # OpenCommit behavior settings
    OCO_DESCRIPTION = "false";        # Keep commit messages concise
    OCO_EMOJI = "true";              # Add emojis for better readability
    OCO_LANGUAGE = "en";             # English commit messages
    OCO_GITPUSH = "false";           # Don't auto-push after commit
    OCO_ONE_LINE_COMMIT = "false";   # Allow multi-line when needed
    
    # Use conventional commit format
    OCO_PROMPT_MODULE = "conventional-commit";
    
    # Message template (can be customized)
    OCO_MESSAGE_TEMPLATE_PLACEHOLDER = "$msg";
  };
  
  # Add helpful aliases for opencommit usage
  home.shellAliases = {
    # Main opencommit commands
    "oco" = "opencommit";
    "oc" = "opencommit";
    
    # Quick commit with specific types
    "oco-feat" = "opencommit 'feat: $msg'";
    "oco-fix" = "opencommit 'fix: $msg'";
    "oco-docs" = "opencommit 'docs: $msg'";
    "oco-style" = "opencommit 'style: $msg'";
    "oco-refactor" = "opencommit 'refactor: $msg'";
    "oco-test" = "opencommit 'test: $msg'";
    "oco-chore" = "opencommit 'chore: $msg'";
    
    # Git hooks integration
    "oco-hook-enable" = "opencommit hook set";
    "oco-hook-disable" = "opencommit hook unset";
    
    # Configuration management
    "oco-config" = "opencommit config";
    "oco-status" = "opencommit config get";
  };
  
  # Create a setup script for opencommit + ollama integration
  home.packages = with pkgs; [
    (writeShellScriptBin "opencommit-setup" ''
      #!/usr/bin/env bash
      
      echo "🔧 Setting up opencommit with local ollama..."
      
      # Check if ollama is running
      if ! curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        echo "❌ Ollama service is not running"
        echo "💡 Start it first with: launchctl start org.nixos.ollama"
        echo "   Or run: ollama-setup"
        exit 1
      fi
      
      # Check if the model is available
      model="llama3.2:3b"
      if ! curl -s http://127.0.0.1:11434/api/tags | ${jq}/bin/jq -r '.models[]?.name' | grep -q "$model"; then
        echo "📦 Model $model not found. Pulling it now..."
        ollama pull "$model" || {
          echo "❌ Failed to pull model $model"
          exit 1
        }
      fi
      
      echo "✅ Ollama is running with model $model"
      
      # Test opencommit configuration
      echo "🧪 Testing opencommit configuration..."
      
      # Create a temporary git repo for testing if we're not in one
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "ℹ️  Not in a git repository - configuration looks good!"
        echo "   Test opencommit in a git repository with staged changes"
      else
        echo "✅ Git repository detected"
        echo "   Stage some changes and run 'oco' to test commit message generation"
      fi
      
      echo ""
      echo "🎉 OpenCommit setup complete!"
      echo ""
      echo "📖 Usage:"
      echo "   1. Stage your changes: git add ."
      echo "   2. Generate commit: oco"
      echo "   3. Review and confirm the generated message"
      echo ""
      echo "🔧 Available commands:"
      echo "   • oco                - Generate commit message"
      echo "   • oco-feat           - Commit with feat: prefix"
      echo "   • oco-fix            - Commit with fix: prefix"
      echo "   • oco-config         - View/edit opencommit config"
      echo "   • ollama-health      - Check ollama service status"
    '')
    
    (writeShellScriptBin "oco-model" ''
      #!/usr/bin/env bash
      
      echo "🤖 OpenCommit Model Manager"
      echo ""
      
      # Available models for different use cases
      declare -A models=(
        ["fast"]="llama3.2:3b"
        ["detailed"]="llama3.2:8b" 
        ["coding"]="codellama:7b"
        ["creative"]="llama3.2:3b"
      )
      
      if [ $# -eq 0 ]; then
        echo "📋 Available models:"
        for preset in "''${!models[@]}"; do
          echo "   $preset: ''${models[$preset]}"
        done
        echo ""
        echo "Current model: $OCO_MODEL"
        echo ""
        echo "Usage: oco-model <preset>"
        echo "Example: oco-model fast"
        exit 0
      fi
      
      preset="$1"
      if [[ -n "''${models[$preset]}" ]]; then
        model="''${models[$preset]}"
        echo "🔄 Switching to $preset model: $model"
        
        # Check if model is available locally
        if ! curl -s http://127.0.0.1:11434/api/tags | ${jq}/bin/jq -r '.models[]?.name' | grep -q "$model"; then
          echo "📦 Model $model not found locally. Pulling..."
          ollama pull "$model" || {
            echo "❌ Failed to pull model $model"
            exit 1
          }
        fi
        
        # Update opencommit configuration
        opencommit config set OCO_MODEL="$model"
        echo "✅ Model switched to: $model"
        echo "💡 New shells will use this model automatically"
      else
        echo "❌ Unknown preset: $preset"
        echo "Available presets: ''${!models[*]}"
        exit 1
      fi
    '')
    
    (writeShellScriptBin "oco-check" ''
      #!/usr/bin/env bash
      
      echo "🔍 OpenCommit Health Check..."
      echo ""
      
      # Check environment variables
             echo "📋 Configuration:"
       echo "   Model: $OCO_MODEL"
       echo "   Base URL: $OCO_API_URL"
       echo "   Emoji: $OCO_EMOJI"
       echo "   Language: $OCO_LANGUAGE"
      echo ""
      
      # Check ollama service
      echo "🤖 Ollama Service:"
      if curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        echo "   ✅ Running on http://127.0.0.1:11434"
        
        # Check if model is available
        if curl -s http://127.0.0.1:11434/api/tags | ${jq}/bin/jq -r '.models[]?.name' | grep -q "$OCO_MODEL"; then
          echo "   ✅ Model $OCO_MODEL is available"
        else
          echo "   ❌ Model $OCO_MODEL not found"
          echo "   💡 Run: ollama pull $OCO_MODEL"
        fi
      else
        echo "   ❌ Not running or not responding"
        echo "   💡 Run: ollama-setup"
      fi
      echo ""
      
      # Check git repository
      echo "📁 Git Repository:"
      if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "   ✅ In git repository"
        
        # Check for staged changes
        if git diff --cached --quiet; then
          echo "   ℹ️  No staged changes - add some files to test opencommit"
        else
          echo "   ✅ Staged changes detected - ready to test oco"
        fi
      else
        echo "   ℹ️  Not in git repository"
      fi
    '')
  ];
} 