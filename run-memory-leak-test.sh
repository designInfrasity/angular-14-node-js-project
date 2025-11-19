#!/bin/bash

###############################################################################
# Node.js 18 Migration - Memory Leak Detection Script (Step 7.3)
###############################################################################
# This script detects memory leaks by repeatedly creating and deleting
# tutorials while monitoring Node.js server memory usage.
###############################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="http://localhost:8080"
API_ENDPOINT="$BACKEND_URL/api/tutorials"
NUM_CYCLES=10
TUTORIALS_PER_CYCLE=10
LOG_FILE="memory-leak-test-$(date +%Y%m%d-%H%M%S).log"

###############################################################################
# Helper Functions
###############################################################################

print_header() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ $1${NC}"
}

###############################################################################
# Prerequisites Check
###############################################################################

check_prerequisites() {
  print_header "Checking Prerequisites"

  local all_ok=true

  # Check Node.js version
  if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    if [[ "$NODE_VERSION" =~ ^v18 ]]; then
      print_success "Node.js 18 detected: $NODE_VERSION"
    else
      print_error "Node.js 18 required, found: $NODE_VERSION"
      all_ok=false
    fi
  else
    print_error "Node.js not found in PATH"
    all_ok=false
  fi

  # Check curl availability
  if command -v curl &> /dev/null; then
    print_success "curl is available"
  else
    print_error "curl not found - required for API testing"
    all_ok=false
  fi

  # Check backend server
  if curl -s -f "$BACKEND_URL" > /dev/null 2>&1; then
    print_success "Backend server is running on port 8080"
  else
    print_error "Backend server not accessible at $BACKEND_URL"
    print_info "Start server: cd node-js-server && node server.js"
    all_ok=false
  fi

  # Check ps command
  if command -v ps &> /dev/null; then
    print_success "ps command is available for memory monitoring"
  else
    print_error "ps command not found - required for memory monitoring"
    all_ok=false
  fi

  echo ""

  if [ "$all_ok" = false ]; then
    print_error "Prerequisites check failed. Please address the issues above."
    exit 1
  fi

  print_success "All prerequisites satisfied"
  return 0
}

###############################################################################
# Memory Monitoring
###############################################################################

get_server_pid() {
  # Find Node.js server process
  local pid=$(pgrep -f "node.*server\.js" | head -n 1)
  echo "$pid"
}

get_memory_usage() {
  local pid=$1

  if [ -z "$pid" ]; then
    echo "0"
    return 1
  fi

  # Get RSS memory in KB
  local mem_kb=$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ')

  if [ -n "$mem_kb" ]; then
    # Convert to MB
    local mem_mb=$((mem_kb / 1024))
    echo "$mem_mb"
  else
    echo "0"
    return 1
  fi
}

###############################################################################
# Memory Leak Testing
###############################################################################

run_memory_leak_test() {
  print_header "Memory Leak Detection Test"

  # Find server process
  SERVER_PID=$(get_server_pid)

  if [ -z "$SERVER_PID" ]; then
    print_error "Could not find running Node.js server process"
    print_info "Make sure server is running: cd node-js-server && node server.js"
    exit 1
  fi

  print_success "Found Node.js server process (PID: $SERVER_PID)"
  echo ""

  # Get baseline memory
  print_info "Taking baseline memory measurement..."
  sleep 2
  BASELINE_MEMORY=$(get_memory_usage "$SERVER_PID")

  if [ "$BASELINE_MEMORY" -eq 0 ]; then
    print_error "Failed to get baseline memory usage"
    exit 1
  fi

  print_success "Baseline memory: ${BASELINE_MEMORY}MB"
  echo ""

  # Store memory measurements
  declare -a MEMORY_READINGS
  MEMORY_READINGS+=("$BASELINE_MEMORY")

  # Run test cycles
  print_info "Running $NUM_CYCLES cycles of create/delete operations..."
  print_info "Each cycle: Create $TUTORIALS_PER_CYCLE tutorials, then delete all"
  echo ""

  for cycle in $(seq 1 $NUM_CYCLES); do
    echo -e "${YELLOW}--- Cycle $cycle/$NUM_CYCLES ---${NC}"

    # Create tutorials
    print_info "Creating $TUTORIALS_PER_CYCLE tutorials..."
    local create_success=0
    local create_fail=0

    for i in $(seq 1 $TUTORIALS_PER_CYCLE); do
      response=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$API_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d "{\"title\":\"Memory Leak Test Cycle $cycle Item $i\",\"description\":\"Testing for memory leaks in Node.js 18 with mysql2 3.x\"}")

      if [ "$response" -eq 200 ] || [ "$response" -eq 201 ]; then
        create_success=$((create_success + 1))
      else
        create_fail=$((create_fail + 1))
      fi
    done

    if [ $create_success -eq $TUTORIALS_PER_CYCLE ]; then
      print_success "Created $create_success tutorials"
    else
      print_warning "Created $create_success tutorials ($create_fail failed)"
    fi

    # Check memory after creation
    sleep 1
    MEMORY_AFTER_CREATE=$(get_memory_usage "$SERVER_PID")
    print_info "Memory after create: ${MEMORY_AFTER_CREATE}MB (Δ $((MEMORY_AFTER_CREATE - BASELINE_MEMORY))MB)"

    # Delete all tutorials
    print_info "Deleting all tutorials..."
    response=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE "$API_ENDPOINT")

    if [ "$response" -eq 200 ]; then
      print_success "Deleted all tutorials"
    else
      print_warning "Delete operation returned HTTP $response"
    fi

    # Check memory after deletion
    sleep 2
    MEMORY_AFTER_DELETE=$(get_memory_usage "$SERVER_PID")
    MEMORY_READINGS+=("$MEMORY_AFTER_DELETE")

    memory_delta=$((MEMORY_AFTER_DELETE - BASELINE_MEMORY))
    print_info "Memory after delete: ${MEMORY_AFTER_DELETE}MB (Δ ${memory_delta}MB from baseline)"

    # Assess memory trend
    if [ "$MEMORY_AFTER_DELETE" -gt $((BASELINE_MEMORY + 50)) ]; then
      print_warning "Memory increased significantly from baseline (${memory_delta}MB)"
    elif [ "$MEMORY_AFTER_DELETE" -gt $((BASELINE_MEMORY + 20)) ]; then
      print_warning "Memory slightly elevated from baseline (${memory_delta}MB)"
    else
      print_success "Memory close to baseline (${memory_delta}MB difference)"
    fi

    echo ""

    # Optional: pause between cycles
    if [ $cycle -lt $NUM_CYCLES ]; then
      sleep 1
    fi
  done

  # Final memory check
  print_header "Final Memory Assessment"

  sleep 3
  FINAL_MEMORY=$(get_memory_usage "$SERVER_PID")
  TOTAL_DELTA=$((FINAL_MEMORY - BASELINE_MEMORY))

  print_info "Baseline memory: ${BASELINE_MEMORY}MB"
  print_info "Final memory: ${FINAL_MEMORY}MB"
  print_info "Total memory increase: ${TOTAL_DELTA}MB"
  print_info "Operations completed: $((NUM_CYCLES * TUTORIALS_PER_CYCLE)) creates, $NUM_CYCLES bulk deletes"
  echo ""

  # Memory leak assessment
  print_info "Memory Leak Assessment:"

  if [ $TOTAL_DELTA -lt 20 ]; then
    print_success "No significant memory leak detected (< 20MB increase)"
    print_success "Memory management is healthy"
    LEAK_STATUS="PASS"
  elif [ $TOTAL_DELTA -lt 50 ]; then
    print_warning "Minor memory increase detected (${TOTAL_DELTA}MB)"
    print_warning "This may be normal garbage collection behavior"
    print_info "Monitor in production with longer test duration"
    LEAK_STATUS="MINOR"
  elif [ $TOTAL_DELTA -lt 100 ]; then
    print_warning "Moderate memory increase detected (${TOTAL_DELTA}MB)"
    print_warning "Potential memory leak - requires investigation"
    print_info "Recommendations:"
    print_info "  - Check database connection pool configuration"
    print_info "  - Review Sequelize model definitions for memory leaks"
    print_info "  - Ensure all promises are properly handled"
    LEAK_STATUS="MODERATE"
  else
    print_error "Significant memory leak detected (${TOTAL_DELTA}MB)"
    print_error "This requires immediate investigation"
    print_info "Recommendations:"
    print_info "  - Review all database connection handling"
    print_info "  - Check for event listener leaks"
    print_info "  - Verify mysql2 3.x connection pool configuration"
    print_info "  - Add memory profiling with --inspect flag"
    LEAK_STATUS="FAIL"
  fi

  echo ""

  # Memory trend analysis
  print_info "Memory Trend Analysis:"
  echo ""

  local max_memory=$BASELINE_MEMORY
  local min_memory=$BASELINE_MEMORY

  for reading in "${MEMORY_READINGS[@]}"; do
    if [ "$reading" -gt "$max_memory" ]; then
      max_memory=$reading
    fi
    if [ "$reading" -lt "$min_memory" ]; then
      min_memory=$reading
    fi
  done

  print_info "  Minimum memory: ${min_memory}MB"
  print_info "  Maximum memory: ${max_memory}MB"
  print_info "  Memory range: $((max_memory - min_memory))MB"

  # Calculate average (approximate)
  local total=0
  local count=0
  for reading in "${MEMORY_READINGS[@]}"; do
    total=$((total + reading))
    count=$((count + 1))
  done
  local average=$((total / count))
  print_info "  Average memory: ${average}MB"

  echo ""

  return 0
}

###############################################################################
# Generate Report
###############################################################################

generate_report() {
  print_header "Memory Leak Test Summary"

  echo ""
  print_info "Test completed at: $(date)"
  print_info "Test configuration:"
  print_info "  - Cycles: $NUM_CYCLES"
  print_info "  - Tutorials per cycle: $TUTORIALS_PER_CYCLE"
  print_info "  - Total operations: $((NUM_CYCLES * TUTORIALS_PER_CYCLE)) creates"
  echo ""

  case "$LEAK_STATUS" in
    PASS)
      print_success "Memory Leak Test: PASSED"
      print_success "No significant memory leaks detected"
      ;;
    MINOR)
      print_warning "Memory Leak Test: MINOR INCREASE"
      print_warning "Monitor memory in production environment"
      ;;
    MODERATE)
      print_warning "Memory Leak Test: MODERATE INCREASE"
      print_warning "Investigation recommended before production deployment"
      ;;
    FAIL)
      print_error "Memory Leak Test: FAILED"
      print_error "Critical memory leak detected - requires immediate attention"
      ;;
  esac

  echo ""

  print_info "Next Steps:"
  echo "  1. Review test results above"
  echo "  2. If memory leak detected, investigate:"
  echo "     - Database connection pool: node-js-server/app/models/index.js"
  echo "     - Controller implementations: node-js-server/app/controllers/"
  echo "     - Middleware: node-js-server/server.js"
  echo "  3. For detailed memory profiling, run:"
  echo "     node --inspect --expose-gc server.js"
  echo "     Then use Chrome DevTools for heap snapshots"
  echo "  4. Document findings in STEP-7.3-IMPLEMENTATION-SUMMARY.md"
  echo ""

  print_info "Detailed documentation: STEP-7.3-PERFORMANCE-VERIFICATION.md"

  return 0
}

###############################################################################
# Main Execution
###############################################################################

show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --cycles N       Number of create/delete cycles (default: 10)"
  echo "  --items N        Tutorials to create per cycle (default: 10)"
  echo "  --help           Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                       # Run with default settings"
  echo "  $0 --cycles 20           # Run 20 cycles"
  echo "  $0 --items 20            # Create 20 items per cycle"
  echo "  $0 --cycles 50 --items 5 # 50 cycles, 5 items each"
  echo ""
}

main() {
  print_header "Node.js 18 Migration - Memory Leak Detection (Step 7.3)"

  # Parse command line arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --cycles)
        NUM_CYCLES="$2"
        shift 2
        ;;
      --items)
        TUTORIALS_PER_CYCLE="$2"
        shift 2
        ;;
      --help|-h)
        show_usage
        exit 0
        ;;
      *)
        print_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done

  # Validate numeric arguments
  if ! [[ "$NUM_CYCLES" =~ ^[0-9]+$ ]] || [ "$NUM_CYCLES" -lt 1 ]; then
    print_error "Invalid number of cycles: $NUM_CYCLES"
    exit 1
  fi

  if ! [[ "$TUTORIALS_PER_CYCLE" =~ ^[0-9]+$ ]] || [ "$TUTORIALS_PER_CYCLE" -lt 1 ]; then
    print_error "Invalid number of items per cycle: $TUTORIALS_PER_CYCLE"
    exit 1
  fi

  # Check prerequisites
  check_prerequisites

  # Run memory leak test
  run_memory_leak_test

  # Generate report
  generate_report

  # Exit with status based on leak detection
  case "$LEAK_STATUS" in
    PASS|MINOR)
      exit 0
      ;;
    MODERATE)
      exit 0  # Non-critical, but documented
      ;;
    FAIL)
      exit 1  # Critical issue
      ;;
    *)
      exit 1
      ;;
  esac
}

# Run main function
main "$@"
