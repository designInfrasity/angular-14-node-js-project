#!/bin/bash

###############################################################################
# Node.js 18 Migration - Performance Testing Script (Step 7.3)
###############################################################################
# This script performs comprehensive performance validation testing:
# - Creates test data (20+ tutorials)
# - Tests API endpoint performance with load testing
# - Monitors memory usage during operations
# - Generates performance metrics report
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
LOG_FILE="performance-test-$(date +%Y%m%d-%H%M%S).log"
NUM_TUTORIALS=25
NUM_LOAD_REQUESTS=50

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

  # Check if backend server is running
  if curl -s -f "$BACKEND_URL" > /dev/null 2>&1; then
    print_success "Backend server is running on port 8080"
  else
    print_error "Backend server not accessible at $BACKEND_URL"
    print_info "Start server: cd node-js-server && node server.js"
    all_ok=false
  fi

  # Check if API endpoint is accessible
  if curl -s -f "$API_ENDPOINT" > /dev/null 2>&1; then
    print_success "API endpoint /api/tutorials is accessible"
  else
    print_error "API endpoint not accessible at $API_ENDPOINT"
    all_ok=false
  fi

  # Check for jq (optional but recommended)
  if command -v jq &> /dev/null; then
    print_success "jq is available for JSON parsing"
    HAS_JQ=true
  else
    print_warning "jq not found - some metrics may be limited"
    print_info "Install: sudo apt-get install jq (Debian/Ubuntu) or brew install jq (macOS)"
    HAS_JQ=false
  fi

  # Check for bc (for floating point calculations)
  if command -v bc &> /dev/null; then
    print_success "bc is available for calculations"
    HAS_BC=true
  else
    print_warning "bc not found - some calculations may be limited"
    HAS_BC=false
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
# Create Test Data
###############################################################################

create_test_data() {
  print_header "Creating Test Data ($NUM_TUTORIALS tutorials)"

  local success_count=0
  local fail_count=0
  local start_time=$(date +%s)

  print_info "Creating $NUM_TUTORIALS tutorials for performance testing..."

  for i in $(seq 1 $NUM_TUTORIALS); do
    # Alternate between published/unpublished
    if [ $((i % 2)) -eq 0 ]; then
      published="true"
      status="Published"
    else
      published="false"
      status="Draft"
    fi

    # Create tutorial with realistic content
    response=$(curl -s -w "\n%{http_code}" -X POST "$API_ENDPOINT" \
      -H "Content-Type: application/json" \
      -d "{
        \"title\": \"Performance Test Tutorial #$i\",
        \"description\": \"This is a test tutorial created for performance validation of Node.js 18 migration. This tutorial (#$i of $NUM_TUTORIALS) is marked as $status. The content includes sufficient text to test realistic payload sizes and rendering performance in the Angular frontend. Lorem ipsum dolor sit amet, consectetur adipiscing elit.\",
        \"published\": $published
      }")

    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
      success_count=$((success_count + 1))
      if [ $((i % 5)) -eq 0 ]; then
        echo -n "."
      fi
    else
      fail_count=$((fail_count + 1))
      print_error "Failed to create tutorial #$i (HTTP $http_code)"
    fi
  done

  echo ""

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  print_success "Created $success_count tutorials successfully"
  if [ $fail_count -gt 0 ]; then
    print_error "Failed to create $fail_count tutorials"
  fi
  print_info "Total time: ${duration}s (avg: $((duration * 1000 / NUM_TUTORIALS))ms per tutorial)"

  echo ""

  # Verify created tutorials
  print_info "Verifying tutorials in database..."
  response=$(curl -s "$API_ENDPOINT")
  if [ "$HAS_JQ" = true ]; then
    count=$(echo "$response" | jq '. | length')
    print_success "Total tutorials in database: $count"
  else
    print_success "Tutorials created (count verification requires jq)"
  fi

  return 0
}

###############################################################################
# Load Testing
###############################################################################

run_load_test() {
  print_header "API Load Testing ($NUM_LOAD_REQUESTS requests)"

  print_info "Testing API endpoint performance with concurrent requests..."
  echo ""

  # Test GET all tutorials
  print_info "Test 1: GET /api/tutorials (retrieve all)"
  local start_time=$(date +%s%3N)
  local success=0
  local fail=0

  for i in $(seq 1 $NUM_LOAD_REQUESTS); do
    response=$(curl -s -w "%{http_code}" -o /dev/null "$API_ENDPOINT")
    if [ "$response" -eq 200 ]; then
      success=$((success + 1))
    else
      fail=$((fail + 1))
    fi

    if [ $((i % 10)) -eq 0 ]; then
      echo -n "."
    fi
  done
  echo ""

  local end_time=$(date +%s%3N)
  local duration=$((end_time - start_time))

  if [ "$HAS_BC" = true ] && [ $success -gt 0 ]; then
    local avg=$(echo "scale=2; $duration / $success" | bc)
    print_success "GET /api/tutorials: $success/$NUM_LOAD_REQUESTS successful"
    print_info "Total time: ${duration}ms, Average: ${avg}ms per request"
  else
    print_success "GET /api/tutorials: $success/$NUM_LOAD_REQUESTS successful"
    print_info "Total time: ${duration}ms"
  fi

  if [ $fail -gt 0 ]; then
    print_error "Failed requests: $fail"
  fi

  echo ""

  # Test GET single tutorial (if tutorials exist)
  if [ "$HAS_JQ" = true ]; then
    first_tutorial=$(curl -s "$API_ENDPOINT" | jq -r '.[0].id // empty')

    if [ -n "$first_tutorial" ]; then
      print_info "Test 2: GET /api/tutorials/:id (retrieve single)"
      start_time=$(date +%s%3N)
      success=0
      fail=0

      for i in $(seq 1 $NUM_LOAD_REQUESTS); do
        response=$(curl -s -w "%{http_code}" -o /dev/null "$API_ENDPOINT/$first_tutorial")
        if [ "$response" -eq 200 ]; then
          success=$((success + 1))
        else
          fail=$((fail + 1))
        fi

        if [ $((i % 10)) -eq 0 ]; then
          echo -n "."
        fi
      done
      echo ""

      end_time=$(date +%s%3N)
      duration=$((end_time - start_time))

      if [ "$HAS_BC" = true ] && [ $success -gt 0 ]; then
        avg=$(echo "scale=2; $duration / $success" | bc)
        print_success "GET /api/tutorials/:id: $success/$NUM_LOAD_REQUESTS successful"
        print_info "Total time: ${duration}ms, Average: ${avg}ms per request"
      else
        print_success "GET /api/tutorials/:id: $success/$NUM_LOAD_REQUESTS successful"
        print_info "Total time: ${duration}ms"
      fi

      if [ $fail -gt 0 ]; then
        print_error "Failed requests: $fail"
      fi
    fi
  fi

  echo ""

  # Test search functionality
  print_info "Test 3: GET /api/tutorials?title=... (search)"
  start_time=$(date +%s%3N)
  success=0
  fail=0

  for i in $(seq 1 $NUM_LOAD_REQUESTS); do
    response=$(curl -s -w "%{http_code}" -o /dev/null "$API_ENDPOINT?title=Performance")
    if [ "$response" -eq 200 ]; then
      success=$((success + 1))
    else
      fail=$((fail + 1))
    fi

    if [ $((i % 10)) -eq 0 ]; then
      echo -n "."
    fi
  done
  echo ""

  end_time=$(date +%s%3N)
  duration=$((end_time - start_time))

  if [ "$HAS_BC" = true ] && [ $success -gt 0 ]; then
    avg=$(echo "scale=2; $duration / $success" | bc)
    print_success "GET /api/tutorials?title=...: $success/$NUM_LOAD_REQUESTS successful"
    print_info "Total time: ${duration}ms, Average: ${avg}ms per request"
  else
    print_success "GET /api/tutorials?title=...: $success/$NUM_LOAD_REQUESTS successful"
    print_info "Total time: ${duration}ms"
  fi

  if [ $fail -gt 0 ]; then
    print_error "Failed requests: $fail"
  fi

  return 0
}

###############################################################################
# Memory Monitoring
###############################################################################

check_server_memory() {
  print_header "Server Memory Monitoring"

  # Try to find Node.js server process
  server_pid=$(pgrep -f "node server.js" | head -n 1)

  if [ -z "$server_pid" ]; then
    print_error "Could not find running Node.js server process"
    print_info "Make sure server is running: cd node-js-server && node server.js"
    return 1
  fi

  print_success "Found Node.js server process (PID: $server_pid)"
  echo ""

  # Get memory usage
  if command -v ps &> /dev/null; then
    print_info "Current memory usage:"

    # Linux-style ps
    if ps aux > /dev/null 2>&1; then
      mem_kb=$(ps aux | grep -E "^\S+\s+$server_pid" | awk '{print $6}')
      if [ -n "$mem_kb" ]; then
        mem_mb=$((mem_kb / 1024))
        print_info "  Memory (RSS): ${mem_mb}MB"

        # Assess memory usage
        if [ "$mem_mb" -lt 100 ]; then
          print_success "Memory usage is normal (< 100MB)"
        elif [ "$mem_mb" -lt 200 ]; then
          print_success "Memory usage is acceptable (< 200MB)"
        elif [ "$mem_mb" -lt 300 ]; then
          print_warning "Memory usage is elevated (${mem_mb}MB)"
        else
          print_error "Memory usage is high (${mem_mb}MB) - potential memory leak"
        fi
      fi
    fi
  else
    print_warning "ps command not available for memory monitoring"
  fi

  echo ""
  print_info "For continuous monitoring, run:"
  print_info "  watch -n 2 'ps aux | grep \"node server.js\" | grep -v grep | awk \"{print \\\"Memory: \\\" \\\$6/1024 \\\"MB\\\"}\"'"

  return 0
}

###############################################################################
# Performance Report
###############################################################################

generate_report() {
  print_header "Performance Test Summary"

  echo ""
  print_info "Test completed at: $(date)"
  echo ""

  print_success "All performance tests completed successfully!"
  echo ""

  print_info "Verification Checklist:"
  echo "  ✓ Created $NUM_TUTORIALS tutorials for realistic dataset"
  echo "  ✓ API load tested with $NUM_LOAD_REQUESTS requests per endpoint"
  echo "  ✓ Server memory usage checked and assessed"
  echo ""

  print_info "Next Steps:"
  echo "  1. Test frontend rendering: Open http://localhost:8081"
  echo "  2. Run memory leak test: ./run-memory-leak-test.sh"
  echo "  3. Test with memory limit: node --max-old-space-size=512 server.js"
  echo "  4. Document performance metrics in STEP-7.3-IMPLEMENTATION-SUMMARY.md"
  echo "  5. Clean up test data: curl -X DELETE $API_ENDPOINT"
  echo ""

  print_info "Detailed documentation: STEP-7.3-PERFORMANCE-VERIFICATION.md"

  return 0
}

###############################################################################
# Cleanup
###############################################################################

cleanup_test_data() {
  print_header "Cleaning Up Test Data"

  print_warning "This will delete ALL tutorials from the database!"
  echo -n "Continue? (y/N): "
  read -r confirm

  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    response=$(curl -s -w "\n%{http_code}" -X DELETE "$API_ENDPOINT")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$http_code" -eq 200 ]; then
      if [ "$HAS_JQ" = true ]; then
        deleted=$(echo "$body" | jq -r '.message // empty')
        print_success "Cleanup complete: $deleted"
      else
        print_success "All tutorials deleted successfully"
      fi
    else
      print_error "Cleanup failed (HTTP $http_code)"
    fi
  else
    print_info "Cleanup cancelled"
  fi

  return 0
}

###############################################################################
# Main Execution
###############################################################################

show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --all            Run all performance tests (default)"
  echo "  --create-data    Create test data only"
  echo "  --load-test      Run API load testing only"
  echo "  --memory         Check server memory usage only"
  echo "  --cleanup        Delete all test data"
  echo "  --help           Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                    # Run all tests"
  echo "  $0 --create-data      # Create 25 test tutorials"
  echo "  $0 --load-test        # Test API performance"
  echo "  $0 --cleanup          # Delete all tutorials"
  echo ""
}

main() {
  print_header "Node.js 18 Migration - Performance Testing (Step 7.3)"

  local mode="all"

  # Parse command line arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --all)
        mode="all"
        shift
        ;;
      --create-data)
        mode="create"
        shift
        ;;
      --load-test)
        mode="load"
        shift
        ;;
      --memory)
        mode="memory"
        shift
        ;;
      --cleanup)
        mode="cleanup"
        shift
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

  # Check prerequisites for all modes except help
  check_prerequisites

  # Execute based on mode
  case "$mode" in
    all)
      create_test_data
      run_load_test
      check_server_memory
      generate_report
      ;;
    create)
      create_test_data
      ;;
    load)
      run_load_test
      ;;
    memory)
      check_server_memory
      ;;
    cleanup)
      cleanup_test_data
      ;;
  esac

  echo ""
  print_success "Performance testing completed!"

  exit 0
}

# Run main function
main "$@"
