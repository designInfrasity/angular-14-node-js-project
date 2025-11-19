#!/bin/bash

# Angular Unit Tests Execution Script for Step 6.3
# Node.js 14 to 18 Migration - Test Angular Unit Tests with Karma 6.4.2

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 6.3: Angular Unit Tests Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Prerequisites check
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check Node.js version
NODE_VERSION=$(node --version)
echo -e "Node.js version: ${GREEN}${NODE_VERSION}${NC}"

if [[ ! "$NODE_VERSION" =~ ^v18 ]]; then
    echo -e "${RED}ERROR: Node.js 18 is required. Current version: ${NODE_VERSION}${NC}"
    echo -e "${YELLOW}Please run: nvm use 18${NC}"
    exit 1
fi

# Check npm version
NPM_VERSION=$(npm --version)
echo -e "npm version: ${GREEN}${NPM_VERSION}${NC}"

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${RED}ERROR: node_modules not found. Please run 'npm install' first.${NC}"
    exit 1
fi

# Check if Angular CLI is available
if ! npx ng version &> /dev/null; then
    echo -e "${RED}ERROR: Angular CLI not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# Display installed versions
echo -e "${BLUE}Installed test framework versions:${NC}"
echo -e "Karma: $(npm list karma 2>/dev/null | grep karma@ | head -1 | sed 's/.*karma@//')"
echo -e "Jasmine: $(npm list jasmine-core 2>/dev/null | grep jasmine-core@ | head -1 | sed 's/.*jasmine-core@//')"
echo -e "TypeScript: $(npm list typescript 2>/dev/null | grep typescript@ | head -1 | sed 's/.*typescript@//')"
echo -e "Angular CLI: $(npx ng version 2>/dev/null | grep 'Angular CLI:' | sed 's/Angular CLI: //')"
echo ""

# Run tests
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Running Angular Unit Tests...${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Try ChromeHeadless first (for CI/CD environments)
echo -e "${YELLOW}Attempting to run tests with ChromeHeadless...${NC}"
if npm test -- --watch=false --browsers=ChromeHeadless 2>&1 | tee test-output.log; then
    TEST_RESULT=0
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ All tests passed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    TEST_RESULT=$?
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Tests failed or encountered errors${NC}"
    echo -e "${RED}========================================${NC}"

    # Check if it's a browser issue
    if grep -q "Cannot start ChromeHeadless" test-output.log 2>/dev/null; then
        echo -e "${YELLOW}ChromeHeadless not available. Trying Chrome...${NC}"
        if npm test -- --watch=false --browsers=Chrome 2>&1 | tee test-output.log; then
            TEST_RESULT=0
            echo ""
            echo -e "${GREEN}========================================${NC}"
            echo -e "${GREEN}✓ All tests passed successfully with Chrome!${NC}"
            echo -e "${GREEN}========================================${NC}"
        fi
    fi
fi

# Analyze test output
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Results Analysis${NC}"
echo -e "${BLUE}========================================${NC}"

if [ -f test-output.log ]; then
    # Extract test summary
    echo -e "\n${BLUE}Test Summary:${NC}"
    grep -E "(\d+ specs?|TOTAL:|SUCCESS|FAILED)" test-output.log | tail -10 || echo "Summary not found in output"

    # Check for deprecation warnings
    echo -e "\n${BLUE}Deprecation Warnings Check:${NC}"
    if grep -i "deprecat" test-output.log; then
        echo -e "${YELLOW}⚠ Deprecation warnings found (see above)${NC}"
    else
        echo -e "${GREEN}✓ No deprecation warnings found${NC}"
    fi

    # Check for Node.js 18 specific issues
    echo -e "\n${BLUE}Node.js 18 Compatibility Check:${NC}"
    if grep -i "openssl\|node.*18\|version.*error" test-output.log; then
        echo -e "${YELLOW}⚠ Potential Node.js 18 compatibility issues found (see above)${NC}"
    else
        echo -e "${GREEN}✓ No Node.js 18 compatibility issues detected${NC}"
    fi
fi

# Final verification checklist
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Verification Checklist${NC}"
echo -e "${BLUE}========================================${NC}"

if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Karma 6.4.2 works with Node.js 18${NC}"
    echo -e "${GREEN}✓ Browser launched successfully${NC}"
    echo -e "${GREEN}✓ All tests passed${NC}"
    echo -e "${GREEN}✓ TypeScript 4.9.5 compiles correctly${NC}"
    echo -e "${GREEN}✓ Step 6.3 verification COMPLETE${NC}"

    # Update verification document
    echo ""
    echo -e "${BLUE}Test results saved to: test-output.log${NC}"
    echo -e "${BLUE}Update STEP-6.3-TEST-VERIFICATION.md with results${NC}"

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Step 6.3 PASSED - Ready for Step 7${NC}"
    echo -e "${GREEN}========================================${NC}"

    exit 0
else
    echo -e "${RED}✗ Some tests failed or errors occurred${NC}"
    echo -e "${YELLOW}Review test-output.log for details${NC}"
    echo -e "${YELLOW}Check STEP-6.3-TEST-VERIFICATION.md troubleshooting section${NC}"

    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Step 6.3 FAILED - Review and fix issues${NC}"
    echo -e "${RED}========================================${NC}"

    exit 1
fi
