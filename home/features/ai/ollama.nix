{ pkgs, lib, ... }: {
  
  # Enable ollama service for local LLM hosting
  services.ollama = {
    enable = true;
    package = pkgs.ollama;
    
    # Configure network settings
    host = "127.0.0.1";  # localhost only for security
    port = 11434;        # default ollama port
    
    # Set up environment variables for optimal performance
    environmentVariables = {
      # Optimize for local development use
      OLLAMA_NUM_PARALLEL = "1";          # Limit parallel requests for stability
      OLLAMA_MAX_LOADED_MODELS = "1";     # Keep memory usage reasonable
      OLLAMA_FLASH_ATTENTION = "1";       # Enable if supported by model
      
      # Enable logging for debugging if needed
      OLLAMA_DEBUG = "0";  # Set to "1" for debugging
    };
    
    # Hardware acceleration detection
    acceleration = 
      if pkgs.stdenv.isDarwin then false  # macOS: use CPU for stability
      else if pkgs.config.cudaSupport or false then "cuda"
      else if pkgs.config.rocmSupport or false then "rocm" 
      else false;
  };
  
  # Add helpful aliases for ollama management
  home.shellAliases = {
    # Model management
    "ollama-pull" = "ollama pull";
    "ollama-list" = "ollama list";
    "ollama-rm" = "ollama rm";
    
    # Quick model pulls for development
    "ollama-setup-coding" = "ollama pull codellama:7b && ollama pull llama3.2:3b";
    "ollama-setup-opencommit" = "ollama pull llama3.2:3b";  # Good for commit messages
    
    # Service management
    "ollama-status" = "ollama ps";
    "ollama-stop" = "ollama stop";
  };
  
  # Create a simple script to check if ollama is running and ready
  home.packages = with pkgs; [
    (writeShellScriptBin "ollama-health" ''
      #!/usr/bin/env bash
      
      echo "🔍 Checking ollama service status..."
      
      # Check if service is running
      if curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        echo "✅ Ollama service is running on http://127.0.0.1:11434"
        
        # List available models
        echo "📚 Available models:"
        curl -s http://127.0.0.1:11434/api/tags | ${jq}/bin/jq -r '.models[]?.name // "No models found"' 2>/dev/null || echo "   No models found - run 'ollama pull <model-name>' to download models"
      else
        echo "❌ Ollama service is not responding"
        echo "💡 Try: 'launchctl restart org.nixos.ollama' or check service logs"
      fi
    '')
    
    (writeShellScriptBin "ollama-setup" ''
      #!/usr/bin/env bash
      
      echo "🚀 Setting up ollama for development use..."
      
      # Wait for service to be ready
      echo "⏳ Waiting for ollama service to start..."
      timeout=30
      while ! curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1 && [ $timeout -gt 0 ]; do
        sleep 1
        ((timeout--))
      done
      
      if [ $timeout -eq 0 ]; then
        echo "❌ Ollama service failed to start within 30 seconds"
        exit 1
      fi
      
      echo "✅ Ollama service is ready"
      
      # Pull recommended models for development
      echo "📦 Pulling recommended models for coding and commit messages..."
      echo "   This may take a while for the first time..."
      
      # Pull primary model for commit messages
      if ollama pull llama3.2:3b; then
        echo "✅ Successfully pulled llama3.2:3b (fast, good for commit messages)"
      else
        echo "⚠️  Failed to pull llama3.2:3b - you may need to pull it manually later"
      fi
      
      echo ""
      echo "🎉 Setup complete! Available commands:"
      echo ""
      echo "🔧 Management:"
      echo "   • ollama-health     - Check service status"
      echo "   • ollama list       - List downloaded models"
      echo "   • ollama pull <model> - Download additional models"
      echo ""
      echo "🤖 OpenCommit:"
      echo "   • oco               - Generate commit messages"
      echo "   • oco-check         - Validate configuration"
      echo "   • oco-model         - Switch between model presets"
      echo "   • oco-hook-enable   - Enable git hook integration"
      echo ""
      echo "💡 Try 'oco-model' to see available model presets for different use cases"
    '')
  ];
} 