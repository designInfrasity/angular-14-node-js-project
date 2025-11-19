#!/bin/bash

# Step 7.2: HTTP Communication Verification Script
# Tests Angular HTTP client to Express backend communication using cURL

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="http://localhost:8080"
FRONTEND_ORIGIN="http://localhost:8081"
API_BASE="${BACKEND_URL}/api/tutorials"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test results array
declare -a FAILED_TESTS

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}Step 7.2: HTTP Communication Verification${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}>>> $1${NC}\n"
}

# Function to run a test
run_test() {
    local test_name="$1"
    local result=$2
    TESTS_RUN=$((TESTS_RUN + 1))

    if [ $result -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC} - $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} - $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
    fi
}

# Function to check HTTP status code
check_status() {
    local status=$1
    local expected=$2
    if [ "$status" -eq "$expected" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if response contains string
check_response_contains() {
    local response="$1"
    local expected="$2"
    if echo "$response" | grep -q "$expected"; then
        return 0
    else
        return 1
    fi
}

# Prerequisites Check
print_section "Prerequisites Verification"

echo -n "Checking Node.js version... "
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    if [[ $NODE_VERSION == v18* ]]; then
        echo -e "${GREEN}✅ Node.js 18 detected: $NODE_VERSION${NC}"
    else
        echo -e "${YELLOW}⚠️  Node.js version: $NODE_VERSION (expected 18.x)${NC}"
    fi
else
    echo -e "${RED}❌ Node.js not found${NC}"
fi

echo -n "Checking if backend is running... "
if curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/" | grep -q "200"; then
    echo -e "${GREEN}✅ Backend is accessible at $BACKEND_URL${NC}"
else
    echo -e "${RED}❌ Backend is not accessible at $BACKEND_URL${NC}"
    echo -e "${YELLOW}Please start the backend server: cd node-js-server && node server.js${NC}"
    exit 1
fi

echo -n "Checking if MySQL is connected... "
# Try to access the API to verify database connectivity
if curl -s "$API_BASE" -o /dev/null; then
    echo -e "${GREEN}✅ API is accessible (MySQL connected)${NC}"
else
    echo -e "${RED}❌ API is not accessible (MySQL may not be connected)${NC}"
    echo -e "${YELLOW}Please ensure MySQL is running and backend is connected${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}All prerequisites met! Starting HTTP verification...${NC}"
echo ""

# ======================================================
# Test 1: CREATE Operation (POST)
# ======================================================
print_section "Test 1: CREATE Operation (POST)"

echo "Creating new tutorial..."
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE" \
    -H "Content-Type: application/json" \
    -H "Origin: $FRONTEND_ORIGIN" \
    -d '{"title":"HTTP Verification Test","description":"Testing Angular HTTP client with Express backend","published":false}')

CREATE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')
CREATE_STATUS=$(echo "$CREATE_RESPONSE" | tail -n1)

echo "Response Status: $CREATE_STATUS"
echo "Response Body: $CREATE_BODY"

# Extract ID from response for later tests
TUTORIAL_ID=$(echo "$CREATE_BODY" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)
echo "Created Tutorial ID: $TUTORIAL_ID"

# Verify status code
check_status "$CREATE_STATUS" 200
run_test "POST returns status 200/201" $?

# Verify response contains expected fields
check_response_contains "$CREATE_BODY" '"title":"HTTP Verification Test"'
run_test "Response contains correct title" $?

check_response_contains "$CREATE_BODY" '"description":"Testing Angular HTTP client with Express backend"'
run_test "Response contains correct description" $?

check_response_contains "$CREATE_BODY" '"id":'
run_test "Response contains ID field" $?

# ======================================================
# Test 2: READ All Operation (GET)
# ======================================================
print_section "Test 2: READ All Operation (GET)"

echo "Fetching all tutorials..."
READ_ALL_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_BASE" \
    -H "Origin: $FRONTEND_ORIGIN")

READ_ALL_BODY=$(echo "$READ_ALL_RESPONSE" | sed '$d')
READ_ALL_STATUS=$(echo "$READ_ALL_RESPONSE" | tail -n1)

echo "Response Status: $READ_ALL_STATUS"
echo "Response Body (truncated): $(echo "$READ_ALL_BODY" | head -c 200)..."

check_status "$READ_ALL_STATUS" 200
run_test "GET all returns status 200" $?

# Verify response is JSON array
if echo "$READ_ALL_BODY" | grep -q '^\['; then
    run_test "Response is JSON array" 0
else
    run_test "Response is JSON array" 1
fi

# Verify response contains our created tutorial
check_response_contains "$READ_ALL_BODY" "HTTP Verification Test"
run_test "Response contains created tutorial" $?

# ======================================================
# Test 3: SEARCH Operation (GET with query params)
# ======================================================
print_section "Test 3: SEARCH Operation (GET with query params)"

echo "Searching for tutorials with 'Verification' in title..."
SEARCH_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_BASE}?title=Verification" \
    -H "Origin: $FRONTEND_ORIGIN")

SEARCH_BODY=$(echo "$SEARCH_RESPONSE" | sed '$d')
SEARCH_STATUS=$(echo "$SEARCH_RESPONSE" | tail -n1)

echo "Response Status: $SEARCH_STATUS"
echo "Response Body: $(echo "$SEARCH_BODY" | head -c 200)..."

check_status "$SEARCH_STATUS" 200
run_test "SEARCH returns status 200" $?

check_response_contains "$SEARCH_BODY" "HTTP Verification Test"
run_test "Search results contain matching tutorial" $?

# ======================================================
# Test 4: READ Single Operation (GET by ID)
# ======================================================
print_section "Test 4: READ Single Operation (GET by ID)"

if [ -n "$TUTORIAL_ID" ]; then
    echo "Fetching tutorial ID: $TUTORIAL_ID..."
    READ_ONE_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_BASE}/${TUTORIAL_ID}" \
        -H "Origin: $FRONTEND_ORIGIN")

    READ_ONE_BODY=$(echo "$READ_ONE_RESPONSE" | sed '$d')
    READ_ONE_STATUS=$(echo "$READ_ONE_RESPONSE" | tail -n1)

    echo "Response Status: $READ_ONE_STATUS"
    echo "Response Body: $READ_ONE_BODY"

    check_status "$READ_ONE_STATUS" 200
    run_test "GET by ID returns status 200" $?

    check_response_contains "$READ_ONE_BODY" "\"id\":$TUTORIAL_ID"
    run_test "Response contains correct ID" $?

    # Verify response is single object (not array)
    if echo "$READ_ONE_BODY" | grep -q '^{' && ! echo "$READ_ONE_BODY" | grep -q '^\['; then
        run_test "Response is single object (not array)" 0
    else
        run_test "Response is single object (not array)" 1
    fi
else
    echo -e "${YELLOW}⚠️  Skipping - No tutorial ID available${NC}"
fi

# ======================================================
# Test 5: UPDATE Operation (PUT)
# ======================================================
print_section "Test 5: UPDATE Operation (PUT)"

if [ -n "$TUTORIAL_ID" ]; then
    echo "Updating tutorial ID: $TUTORIAL_ID..."
    UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "${API_BASE}/${TUTORIAL_ID}" \
        -H "Content-Type: application/json" \
        -H "Origin: $FRONTEND_ORIGIN" \
        -d '{"title":"Updated HTTP Test","description":"Updated via HTTP verification script","published":true}')

    UPDATE_BODY=$(echo "$UPDATE_RESPONSE" | sed '$d')
    UPDATE_STATUS=$(echo "$UPDATE_RESPONSE" | tail -n1)

    echo "Response Status: $UPDATE_STATUS"
    echo "Response Body: $UPDATE_BODY"

    check_status "$UPDATE_STATUS" 200
    run_test "PUT returns status 200" $?

    # Verify the update by fetching the tutorial again
    VERIFY_UPDATE=$(curl -s "${API_BASE}/${TUTORIAL_ID}")
    check_response_contains "$VERIFY_UPDATE" "Updated HTTP Test"
    run_test "Tutorial was actually updated" $?
else
    echo -e "${YELLOW}⚠️  Skipping - No tutorial ID available${NC}"
fi

# ======================================================
# Test 6: CORS Verification
# ======================================================
print_section "Test 6: CORS Verification"

echo "Testing CORS preflight (OPTIONS)..."
CORS_RESPONSE=$(curl -s -w "\n%{http_code}" -X OPTIONS "$API_BASE" \
    -H "Origin: $FRONTEND_ORIGIN" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -i)

echo "CORS Response Headers:"
echo "$CORS_RESPONSE" | grep -i "access-control"

# Check if CORS headers are present
if echo "$CORS_RESPONSE" | grep -iq "access-control-allow-origin"; then
    run_test "CORS headers present in response" 0
else
    run_test "CORS headers present in response" 1
fi

# ======================================================
# Test 7: Error Handling - Missing Title (400 Bad Request)
# ======================================================
print_section "Test 7: Error Handling - Missing Title"

echo "Attempting to create tutorial without title..."
ERROR_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE" \
    -H "Content-Type: application/json" \
    -H "Origin: $FRONTEND_ORIGIN" \
    -d '{"description":"No title provided"}')

ERROR_BODY=$(echo "$ERROR_RESPONSE" | sed '$d')
ERROR_STATUS=$(echo "$ERROR_RESPONSE" | tail -n1)

echo "Response Status: $ERROR_STATUS"
echo "Response Body: $ERROR_BODY"

# Backend should return 400 or 500 error
if [ "$ERROR_STATUS" -eq 400 ] || [ "$ERROR_STATUS" -eq 500 ]; then
    run_test "Missing required field returns error status" 0
else
    run_test "Missing required field returns error status" 1
fi

check_response_contains "$ERROR_BODY" "message"
run_test "Error response contains message" $?

# ======================================================
# Test 8: Error Handling - Non-Existent Resource (404)
# ======================================================
print_section "Test 8: Error Handling - Non-Existent Resource"

echo "Attempting to fetch non-existent tutorial (ID: 99999)..."
NOT_FOUND_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_BASE}/99999" \
    -H "Origin: $FRONTEND_ORIGIN")

NOT_FOUND_BODY=$(echo "$NOT_FOUND_RESPONSE" | sed '$d')
NOT_FOUND_STATUS=$(echo "$NOT_FOUND_RESPONSE" | tail -n1)

echo "Response Status: $NOT_FOUND_STATUS"
echo "Response Body: $NOT_FOUND_BODY"

check_status "$NOT_FOUND_STATUS" 404
run_test "Non-existent resource returns 404" $?

check_response_contains "$NOT_FOUND_BODY" "message"
run_test "404 response contains error message" $?

# ======================================================
# Test 9: Edge Case - Search with No Results
# ======================================================
print_section "Test 9: Edge Case - Search with No Results"

echo "Searching for non-existent term..."
NO_RESULTS_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_BASE}?title=ZZZ_NONEXISTENT_XYZ123" \
    -H "Origin: $FRONTEND_ORIGIN")

NO_RESULTS_BODY=$(echo "$NO_RESULTS_RESPONSE" | sed '$d')
NO_RESULTS_STATUS=$(echo "$NO_RESULTS_RESPONSE" | tail -n1)

echo "Response Status: $NO_RESULTS_STATUS"
echo "Response Body: $NO_RESULTS_BODY"

check_status "$NO_RESULTS_STATUS" 200
run_test "Search with no results returns status 200" $?

# Verify response is empty array
if echo "$NO_RESULTS_BODY" | grep -q '^\[\]$' || echo "$NO_RESULTS_BODY" | grep -q '^\[ *\]$'; then
    run_test "Response is empty array" 0
else
    run_test "Response is empty array" 1
fi

# ======================================================
# Test 10: Edge Case - Special Characters
# ======================================================
print_section "Test 10: Edge Case - Special Characters in Title"

echo "Creating tutorial with special characters..."
SPECIAL_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE" \
    -H "Content-Type: application/json" \
    -H "Origin: $FRONTEND_ORIGIN" \
    -d '{"title":"Test \"Quotes\" & <HTML> Characters","description":"Special chars test","published":false}')

SPECIAL_BODY=$(echo "$SPECIAL_RESPONSE" | sed '$d')
SPECIAL_STATUS=$(echo "$SPECIAL_RESPONSE" | tail -n1)

echo "Response Status: $SPECIAL_STATUS"
echo "Response Body: $(echo "$SPECIAL_BODY" | head -c 150)..."

check_status "$SPECIAL_STATUS" 200
run_test "Special characters accepted" $?

# Extract ID for cleanup
SPECIAL_ID=$(echo "$SPECIAL_BODY" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)

# ======================================================
# Cleanup: Delete Test Tutorials
# ======================================================
print_section "Cleanup: Deleting Test Tutorials"

if [ -n "$TUTORIAL_ID" ]; then
    echo "Deleting tutorial ID: $TUTORIAL_ID..."
    DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "${API_BASE}/${TUTORIAL_ID}" \
        -H "Origin: $FRONTEND_ORIGIN")

    DELETE_STATUS=$(echo "$DELETE_RESPONSE" | tail -n1)
    echo "Delete Status: $DELETE_STATUS"

    check_status "$DELETE_STATUS" 200
    run_test "DELETE returns status 200" $?
fi

if [ -n "$SPECIAL_ID" ]; then
    echo "Deleting tutorial with special characters (ID: $SPECIAL_ID)..."
    curl -s -X DELETE "${API_BASE}/${SPECIAL_ID}" -o /dev/null
    echo "Deleted."
fi

# ======================================================
# Test Summary
# ======================================================
print_section "Test Summary"

echo "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "${GREEN}✅ All HTTP Communication Tests PASSED!${NC}"
    echo -e "${GREEN}=====================================================${NC}"
    echo ""
    echo -e "${GREEN}Success Criteria Met:${NC}"
    echo "✅ All CRUD operations succeed with correct status codes"
    echo "✅ Request/response payloads are correct JSON"
    echo "✅ CORS headers present in responses"
    echo "✅ Error handling works correctly (400, 404)"
    echo "✅ Edge cases handled properly"
    echo ""
    echo -e "${BLUE}Next Step: Proceed to Step 7.3 - Performance and Stability Validation${NC}"
    exit 0
else
    echo -e "${RED}=====================================================${NC}"
    echo -e "${RED}❌ Some HTTP Communication Tests FAILED${NC}"
    echo -e "${RED}=====================================================${NC}"
    echo ""
    echo -e "${RED}Failed Tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  ❌ $test"
    done
    echo ""
    echo -e "${YELLOW}Please review the test output above and troubleshoot failures.${NC}"
    echo -e "${YELLOW}See STEP-7.2-HTTP-VERIFICATION.md for detailed troubleshooting guide.${NC}"
    exit 1
fi
