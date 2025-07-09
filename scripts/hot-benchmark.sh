#!/usr/bin/env bash
set -euo pipefail

# AI Model Performance Benchmarking Tool
# Benchmarks ollama models for OpenCommit usage with "hot" performance testing
#
# HOT BENCHMARKING CONCEPT:
# 1. WARMUP: Each model is loaded with a simple query first
# 2. BENCHMARK: Then performance is measured on the warmed-up model  
# This eliminates cold-start bias and measures true inference performance.

# Default configuration - Auto-detect available models
MODELS=()  # Will be populated from ollama list
RESULTS_DIR="results"
ITERATIONS=3
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Auto-detect available models
detect_models() {
    log "Detecting available ollama models..."
    
    local available_models
    available_models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -v '^$' || echo "")
    
    if [ -z "$available_models" ]; then
        error "No ollama models found. Please install models first."
        log "Example: ollama pull qwen3:8b"
        exit 1
    fi
    
    # Convert to array
    readarray -t MODELS <<< "$available_models"
    
    log "Found ${#MODELS[@]} models: ${MODELS[*]}"
}

# Verify all models are available
verify_all_models() {
    log "Verifying model availability..."
    local available_models_list
    available_models_list=$(ollama list 2>/dev/null)
    
    if [ -z "$available_models_list" ]; then
        error "Failed to get model list from ollama"
        exit 1
    fi
    
    local verified_models=()
    for model in "${MODELS[@]}"; do
        if echo "$available_models_list" | grep -q "$model"; then
            verified_models+=("$model")
            if [ "$VERBOSE" = true ]; then
                log "✓ $model verified"
            fi
        else
            warn "Model $model not found - skipping"
            log "  Run 'ollama pull $model' to install it"
        fi
    done
    
    if [ ${#verified_models[@]} -eq 0 ]; then
        error "No valid models found for benchmarking"
        exit 1
    fi
    
    # Update MODELS array with only verified models
    MODELS=("${verified_models[@]}")
    log "Verified ${#MODELS[@]} models: ${MODELS[*]}"
}

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v ollama &> /dev/null; then
        error "ollama is not installed or not in PATH"
        exit 1
    fi
    
    if ! pgrep -f ollama &> /dev/null; then
        error "ollama service is not running. Please start it first."
        exit 1
    fi
    
    if ! command -v oco &> /dev/null; then
        warn "opencommit (oco) not found. Some tests may be skipped."
    fi
    
    # Auto-detect available models
    detect_models
    
    # Verify all detected models are actually available
    verify_all_models
    
    success "Dependencies check passed"
}

# Generate test files
create_test_files() {
    local test_dir="$1"
    mkdir -p "$test_dir"
    
    # Simple test file
    cat > "$test_dir/simple.js" << 'EOF'
const app = require("express")();
app.get("/test", (req, res) => res.json({status: "ok"}));
module.exports = app;
EOF

    # Complex test file
    cat > "$test_dir/complex.py" << 'EOF'
import asyncio
import logging
from typing import Dict, List, Optional, Union
from dataclasses import dataclass
from pathlib import Path

@dataclass
class Config:
    """Application configuration with validation and type hints"""
    database_url: str
    redis_url: str
    log_level: str = "INFO"
    max_connections: int = 100
    
    def __post_init__(self):
        if not self.database_url.startswith(('postgresql://', 'sqlite://')):
            raise ValueError("Invalid database URL format")

class DatabaseManager:
    """Async database manager with connection pooling and retry logic"""
    
    def __init__(self, config: Config):
        self.config = config
        self.pool = None
        self.logger = logging.getLogger(__name__)
    
    async def initialize(self) -> None:
        """Initialize database connection pool with retry logic"""
        max_retries = 3
        for attempt in range(max_retries):
            try:
                # Connection pool initialization logic here
                self.logger.info(f"Database connected on attempt {attempt + 1}")
                break
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                await asyncio.sleep(2 ** attempt)
    
    async def execute_query(self, query: str, params: Optional[Dict] = None) -> List[Dict]:
        """Execute database query with proper error handling"""
        if not self.pool:
            raise RuntimeError("Database not initialized")
        
        try:
            # Query execution logic
            return []
        except Exception as e:
            self.logger.error(f"Query failed: {e}")
            raise

# Main application class with comprehensive error handling
class Application:
    def __init__(self, config_path: Union[str, Path]):
        self.config = self._load_config(config_path)
        self.db_manager = DatabaseManager(self.config)
    
    def _load_config(self, path: Union[str, Path]) -> Config:
        """Load and validate configuration from file"""
        # Config loading implementation
        return Config(
            database_url="postgresql://localhost/app",
            redis_url="redis://localhost:6379"
        )
EOF

}

# Warmup a model to ensure it's loaded in memory
warmup_model() {
    local model="$1"
    
    if [ "$VERBOSE" = true ]; then
        log "🔥 Warming up ${PURPLE}$model${NC}..." >&2
    fi
    
    # Simple warmup query to load model into memory
    ollama run "$model" --think=false "Hello" > /dev/null 2>&1
    
    if [ "$VERBOSE" = true ]; then
        log "✓ Model ${PURPLE}$model${NC} is now hot and ready" >&2
    fi
}

# Benchmark a specific model
benchmark_model() {
    local model="$1"
    local test_file="$2"
    local test_type="$3"
    
    log "Testing ${PURPLE}$model${NC} on ${BLUE}$test_type${NC} file..." >&2
    
    # Model availability already verified at startup - proceed with benchmark
    
    local total_time=0
    local successful_runs=0
    
    for i in $(seq 1 $ITERATIONS); do
        if [ "$VERBOSE" = true ]; then
            log "  Run $i/$ITERATIONS..." >&2
        fi
        
        # Create git staged changes for testing
        git add "$test_file" 2>/dev/null || true
        
        # Time the model's response (simulate opencommit usage)
        local start_time=$(date +%s.%N)
        
        # Use direct ollama test with disabled thinking mode for faster response
        # Note: Bypassing OpenCommit to ensure --think=false flag is applied
        ollama run "$model" --think=false "Generate a conventional commit message for these changes: $(head -10 "$test_file")" > /dev/null 2>&1
        
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)
        
        if [ "$?" -eq 0 ]; then
            total_time=$(echo "$total_time + $duration" | bc -l)
            ((successful_runs++))
            
            if [ "$VERBOSE" = true ]; then
                printf "    Time: %.2fs\n" "$duration" >&2
            fi
        else
            warn "Run $i failed for $model" >&2
        fi
        
        # Small delay between runs
        sleep 1
    done
    
    if [ "$successful_runs" -gt 0 ]; then
        local avg_time=$(echo "scale=2; $total_time / $successful_runs" | bc -l)
        printf "%.2f" "$avg_time"
        return 0
    else
        error "All runs failed for $model on $test_type" >&2
        echo "ERROR"
        return 1
    fi
}

# Performance rating based on time
get_performance_rating() {
    local time="$1"
    local rating=""
    
    if (( $(echo "$time < 2.0" | bc -l) )); then
        rating="⚡ Excellent"
    elif (( $(echo "$time < 4.0" | bc -l) )); then
        rating="🚀 Good"
    elif (( $(echo "$time < 6.0" | bc -l) )); then
        rating="✅ Average"
    elif (( $(echo "$time < 10.0" | bc -l) )); then
        rating="⏱️ Slow"
    else
        rating="🐌 Very Slow"
    fi
    
    echo "$rating"
}

# Generate results report
generate_report() {
    local results_file="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local test_env="$(uname -s) $(uname -m)"
    
    log "Generating comprehensive report..."
    
    cat > "$results_file" << EOF
# AI Model Performance Benchmark Results

**Generated:** $timestamp  
**Environment:** $test_env  
**Iterations per test:** $ITERATIONS

## Test Configuration

- **Simple File**: Basic Express.js server (3 lines)
- **Complex File**: Python async database manager with error handling (~70 lines)
- **Hot Benchmarking**: Each model is warmed up with a simple query before testing

## Performance Results

EOF

    # Read results and generate summary tables
    local temp_results="/tmp/benchmark_results.tmp"
    
    # Sort models by average performance
    {
        echo "| Model | Simple (s) | Complex (s) | Avg (s) | Rating |"
        echo "|-------|------------|-------------|---------|--------|"
        
        while IFS=',' read -r model simple complex avg; do
            [ "$model" = "Model" ] && continue  # Skip header
            local rating=$(get_performance_rating "$avg")
            printf "| \`%s\` | %.2f | %.2f | %.2f | %s |\n" \
                "$model" "$simple" "$complex" "$avg" "$rating"
        done < "$RESULTS_DIR/raw_results.csv" | sort -t'|' -k5 -n
    } >> "$results_file"
    
    cat >> "$results_file" << 'EOF'

## Recommendations

### For OpenCommit Usage:
- **Best Overall**: Models with < 4s average response time
- **Quick Commits**: Use models rated ⚡ Excellent for rapid development
- **Complex Projects**: Models with good complex file performance

### Model Selection Guide:
- **Smaller models (1b-8b)**: Faster responses, good for commit messages
- **Medium models (7b-14b)**: Better code understanding with reasonable speed
- **Large models (32b+)**: Maximum capability for complex tasks but slower

## Technical Notes

- **Hot Benchmarking**: Each model is warmed up with a simple query before performance testing
- Tests measure true inference time (not cold-start time) for realistic usage patterns
- Results may vary based on system resources and model cache status  
- All measurements use the `--think=false` flag to disable verbose internal reasoning

EOF
}

# Update README.md with results
update_readme() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local test_env="$(uname -s) $(uname -m)"
    local model_count=$(wc -l < "$RESULTS_DIR/raw_results.csv" | tr -d ' ')
    ((model_count--))  # Subtract header line
    
    log "Updating README.md with latest results..."
    
    # Create the benchmark results section
    local temp_section="/tmp/benchmark_section.tmp"
    
    cat > "$temp_section" << EOF
**Last Updated:** $timestamp  
**Models Tested:** $model_count  
**Test Environment:** $test_env

### 🏆 Top Performers

#### Simple Files (Fastest)
| Rank | Model | Time | Performance |
|------|-------|------|-------------|
EOF

    # Add top 3 performers for simple files
    tail -n +2 "$RESULTS_DIR/raw_results.csv" | sort -t',' -k2 -n | head -3 | \
    awk -F',' 'BEGIN{rank=1} {
        rating = ($2 < 2.0) ? "⚡ Excellent" : ($2 < 4.0) ? "🚀 Good" : "✅ Average"
        printf "| %d | `%s` | %.2fs | %s |\n", rank++, $1, $2, rating
    }' >> "$temp_section"
    
    cat >> "$temp_section" << EOF

#### Complex Files (Fastest)
| Rank | Model | Time | Performance |
|------|-------|------|-------------|
EOF

    # Add top 3 performers for complex files
    tail -n +2 "$RESULTS_DIR/raw_results.csv" | sort -t',' -k3 -n | head -3 | \
    awk -F',' 'BEGIN{rank=1} {
        rating = ($3 < 2.0) ? "⚡ Excellent" : ($3 < 4.0) ? "🚀 Good" : "✅ Average"
        printf "| %d | `%s` | %.2fs | %s |\n", rank++, $1, $3, rating
    }' >> "$temp_section"
    
    cat >> "$temp_section" << EOF

### 📈 All Models Summary
| Model | Simple (s) | Complex (s) | Avg (s) |
|-------|------------|-------------|---------|
EOF

    # Add all models summary
    tail -n +2 "$RESULTS_DIR/raw_results.csv" | sort -t',' -k4 -n | \
    awk -F',' '{
        printf "| `%s` | %.2f | %.2f | %.2f |\n", $1, $2, $3, $4
    }' >> "$temp_section"
    
    echo >> "$temp_section"
    echo "**📋 For detailed analysis and recommendations, see:** \`results/benchmark-results-all.md\`" >> "$temp_section"
    
    # Replace the section in README.md
    sed -i.bak '/<!-- BENCHMARK_RESULTS_START -->/,/<!-- BENCHMARK_RESULTS_END -->/c\
<!-- BENCHMARK_RESULTS_START -->\
'"$(cat "$temp_section" | sed 's/$/\\/')"'
<!-- BENCHMARK_RESULTS_END -->' README.md
    
    rm "$temp_section"
    success "README.md updated with latest benchmark results"
}

# Show usage information
show_usage() {
    cat << EOF
${CYAN}AI Model Performance Benchmarking Tool${NC}

${YELLOW}Usage:${NC}
  $0 [OPTIONS]

${YELLOW}Options:${NC}
  -m, --models MODEL1,MODEL2    Comma-separated list of models to test
  -i, --iterations N            Number of iterations per test (default: $ITERATIONS)
  -v, --verbose                 Verbose output
  -h, --help                    Show this help message
  --no-readme                   Skip README.md update
  --list-models                 List available ollama models and exit

${YELLOW}Examples:${NC}
  # Test all default models
  $0

  # Test specific models (use 'ollama list' to see available)
  $0 -m "qwen3:8b,qwen3:14b"

  # Verbose testing with more iterations
  $0 -v -i 5

  # Quick test without updating README
  $0 --no-readme -i 1

${YELLOW}Available Models:${NC}
  (Auto-detected from 'ollama list')

${YELLOW}Output:${NC}
  - Raw results: ${RESULTS_DIR}/raw_results.csv
  - Detailed report: ${RESULTS_DIR}/benchmark-results-all.md
  - README.md updated with summary (unless --no-readme)
EOF
}

# Parse command line arguments - modifies global variables
parse_args() {
    UPDATE_README=true
    CUSTOM_MODELS=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--models)
                IFS=',' read -ra MODELS <<< "$2"
                CUSTOM_MODELS=true
                shift 2
                ;;
            -i|--iterations)
                ITERATIONS="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --no-readme)
                UPDATE_README=false
                shift
                ;;
            --list-models)
                echo "Available ollama models:"
                ollama list
                exit 0
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main benchmarking function
main() {
    parse_args "$@"
    
    log "${CYAN}AI Model Performance Benchmarking Tool${NC}"
    
    # Check dependencies (will auto-detect models if not custom)
    if [ "$CUSTOM_MODELS" = "true" ]; then
        log "Using custom models: ${PURPLE}${MODELS[*]}${NC}"
        # Basic dependency check without model detection
        if ! command -v ollama &> /dev/null; then
            error "ollama is not installed or not in PATH"
            exit 1
        fi
        if ! pgrep -f ollama &> /dev/null; then
            error "ollama service is not running. Please start it first."
            exit 1
        fi
        
        # Verify custom models
        verify_all_models
        success "Dependencies check passed"
    else
        check_dependencies  # This will auto-detect and verify models
    fi
    
    log "Models to test: ${PURPLE}${MODELS[*]}${NC}"
    log "Iterations per test: ${YELLOW}$ITERATIONS${NC}"
    log "Verbose mode: ${YELLOW}$VERBOSE${NC}"
    
    # Setup
    mkdir -p "$RESULTS_DIR"
    local test_dir="$RESULTS_DIR/test_files"
    rm -rf "$test_dir"
    create_test_files "$test_dir"
    
    # Initialize results file
    local raw_results="$RESULTS_DIR/raw_results.csv"
    echo "Model,Simple,Complex,Average" > "$raw_results"
    
    # Benchmark each model
    local total_models=${#MODELS[@]}
    local current_model=0
    
    for model in "${MODELS[@]}"; do
        current_model=$((current_model + 1))
        log "${YELLOW}[$current_model/$total_models]${NC} Benchmarking ${PURPLE}$model${NC}..."
        
        # Step 1: Warmup the model (ensure it's "hot")
        warmup_model "$model"
        
        # Step 2: Benchmark on warmed-up model  
        local simple_time complex_time
        
        simple_time=$(benchmark_model "$model" "$test_dir/simple.js" "simple")
        complex_time=$(benchmark_model "$model" "$test_dir/complex.py" "complex")
        
        # Calculate average
        if [[ "$simple_time" != "ERROR" && "$complex_time" != "ERROR" ]]; then
            local avg_time=$(echo "scale=2; ($simple_time + $complex_time) / 2" | bc -l)
            
            # Save results
            echo "$model,$simple_time,$complex_time,$avg_time" >> "$raw_results"
            
            success "Model $model completed - Avg: ${avg_time}s"
        else
            warn "Model $model had errors - skipping from results"
        fi
        
        # Brief pause between models
        sleep 1
        
        echo  # Empty line for readability
    done
    
    # Generate reports
    generate_report "$RESULTS_DIR/benchmark-results-all.md"
    
    if [ "$UPDATE_README" = true ]; then
        update_readme
    fi
    
    # Cleanup
    rm -rf "$test_dir"
    
    success "Benchmarking completed!"
    log "Results saved to: ${CYAN}$RESULTS_DIR/${NC}"
    log "View detailed report: ${CYAN}$RESULTS_DIR/benchmark-results-all.md${NC}"
    
    if [ "$UPDATE_README" = true ]; then
        log "README.md updated with latest results"
    fi
}

# Run main function with all arguments
main "$@" 