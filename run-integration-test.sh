#!/bin/bash

# Step 7.1: Full Application Integration Test
# This script provides manual testing guidance and automated verification

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 7.1: Full Application Integration Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Prerequisites Verification
echo -e "${YELLOW}Verifying Prerequisites...${NC}"

# Check Node.js version
NODE_VERSION=$(node --version 2>/dev/null || echo "not found")
if [[ $NODE_VERSION == v18.* ]]; then
    echo -e "${GREEN}✓${NC} Node.js version: $NODE_VERSION"
else
    echo -e "${RED}✗${NC} Node.js 18 required, found: $NODE_VERSION"
    exit 1
fi

# Check MySQL connectivity
echo -e "\n${YELLOW}Checking MySQL connectivity...${NC}"
if command -v mysql &> /dev/null; then
    if mysql -h localhost -u root -p123456 -e "SELECT 1;" testdb &> /dev/null; then
        echo -e "${GREEN}✓${NC} MySQL is accessible (localhost, user: root, database: testdb)"
    else
        echo -e "${YELLOW}⚠${NC} MySQL connection test failed. Attempting to create database..."
        mysql -h localhost -u root -p123456 -e "CREATE DATABASE IF NOT EXISTS testdb;" 2>/dev/null || true
        if mysql -h localhost -u root -p123456 -e "SELECT 1;" testdb &> /dev/null; then
            echo -e "${GREEN}✓${NC} MySQL database created and accessible"
        else
            echo -e "${RED}✗${NC} MySQL is not accessible with credentials from db.config.js"
            echo -e "${YELLOW}  Expected: host=localhost, user=root, password=123456, database=testdb${NC}"
            echo -e "${YELLOW}  Please ensure MySQL is running and credentials are correct${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} MySQL client not installed, skipping connection test"
    echo -e "${YELLOW}  Please ensure MySQL is running with credentials: host=localhost, user=root, password=123456${NC}"
fi

# Check backend dependencies
echo -e "\n${YELLOW}Checking backend dependencies...${NC}"
if [ ! -d "node-js-server/node_modules" ]; then
    echo -e "${RED}✗${NC} Backend dependencies not installed"
    echo -e "${YELLOW}  Run: cd node-js-server && npm install${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Backend dependencies installed"

# Check frontend dependencies
echo -e "${YELLOW}Checking frontend dependencies...${NC}"
if [ ! -d "angular-14-client/node_modules" ]; then
    echo -e "${RED}✗${NC} Frontend dependencies not installed"
    echo -e "${YELLOW}  Run: cd angular-14-client && npm install${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Frontend dependencies installed"

# Display installed versions
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Installed Versions${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Node.js: $NODE_VERSION"
echo -e "OpenSSL: $(node -p 'process.versions.openssl' 2>/dev/null || echo 'unknown')"
cd node-js-server
echo -e "express: $(npm list express 2>/dev/null | grep express@ | head -1 | awk '{print $2}' || echo 'unknown')"
echo -e "mysql2: $(npm list mysql2 2>/dev/null | grep mysql2@ | head -1 | awk '{print $2}' || echo 'unknown')"
echo -e "sequelize: $(npm list sequelize 2>/dev/null | grep sequelize@ | head -1 | awk '{print $2}' || echo 'unknown')"
cd ../angular-14-client
echo -e "Angular: $(npm list @angular/core 2>/dev/null | grep @angular/core@ | head -1 | awk '{print $2}' || echo 'unknown')"
echo -e "Angular CLI: $(npm list @angular/cli 2>/dev/null | grep @angular/cli@ | head -1 | awk '{print $2}' || echo 'unknown')"
cd ..

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Manual Testing Instructions${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}This step requires MANUAL testing through the browser UI.${NC}"
echo -e "${YELLOW}Follow these steps to complete the integration test:${NC}"
echo ""
echo -e "${GREEN}1. Start Backend Server (Terminal 1):${NC}"
echo -e "   cd node-js-server && node server.js"
echo -e "   ${YELLOW}Wait for: 'Server is running on port 8080.' message${NC}"
echo ""
echo -e "${GREEN}2. Start Angular Dev Server (Terminal 2):${NC}"
echo -e "   cd angular-14-client && ng serve --port 8081"
echo -e "   ${YELLOW}Wait for: 'Compiled successfully.' message${NC}"
echo ""
echo -e "${GREEN}3. Open Browser:${NC}"
echo -e "   Navigate to: ${BLUE}http://localhost:8081${NC}"
echo ""
echo -e "${GREEN}4. Test Create Tutorial:${NC}"
echo -e "   - Click 'Add' button in navigation"
echo -e "   - Fill in Title: 'Integration Test Tutorial'"
echo -e "   - Fill in Description: 'Testing with Node.js 18'"
echo -e "   - Click 'Submit' button"
echo -e "   - ${YELLOW}Verify:${NC} Success message appears and tutorial shows in list"
echo ""
echo -e "${GREEN}5. Test Search Functionality:${NC}"
echo -e "   - Enter 'Integration' in search box"
echo -e "   - Click 'Search' button"
echo -e "   - ${YELLOW}Verify:${NC} Only matching tutorials appear"
echo -e "   - Clear search and search again to see all tutorials"
echo ""
echo -e "${GREEN}6. Test View Details:${NC}"
echo -e "   - Click on the created tutorial in the list"
echo -e "   - ${YELLOW}Verify:${NC} Tutorial details page loads with title and description"
echo ""
echo -e "${GREEN}7. Test Update Tutorial:${NC}"
echo -e "   - On details page, modify Title to 'Updated Integration Test'"
echo -e "   - Modify Description to 'Updated via UI'"
echo -e "   - Click 'Update' button"
echo -e "   - ${YELLOW}Verify:${NC} Success message appears"
echo -e "   - Navigate back to list and verify changes persisted"
echo ""
echo -e "${GREEN}8. Test Publish Toggle:${NC}"
echo -e "   - On details page, click 'Publish' button"
echo -e "   - ${YELLOW}Verify:${NC} Status changes to 'Published'"
echo -e "   - Click 'UnPublish' button"
echo -e "   - ${YELLOW}Verify:${NC} Status changes to 'Pending'"
echo ""
echo -e "${GREEN}9. Test Delete:${NC}"
echo -e "   - On details page, click 'Delete' button"
echo -e "   - ${YELLOW}Verify:${NC} Redirected to list and tutorial is removed"
echo ""
echo -e "${GREEN}10. Verify CORS Configuration:${NC}"
echo -e "   - Open Browser DevTools (F12) -> Network tab"
echo -e "   - Perform any CRUD operation"
echo -e "   - ${YELLOW}Verify:${NC} Requests to http://localhost:8080/api/tutorials succeed (status 200)"
echo -e "   - ${YELLOW}Verify:${NC} No CORS errors in browser console"
echo -e "   - ${YELLOW}Check:${NC} Response headers include 'access-control-allow-origin'"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Verification Checklist${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Before marking Step 7.1 as complete, verify:"
echo -e "[ ] MySQL is running and accessible"
echo -e "[ ] Backend server starts successfully on port 8080"
echo -e "[ ] Angular dev server starts successfully on port 8081"
echo -e "[ ] Application loads at http://localhost:8081"
echo -e "[ ] Create tutorial works and tutorial appears in list"
echo -e "[ ] Search functionality filters tutorials correctly"
echo -e "[ ] View details displays tutorial information"
echo -e "[ ] Update tutorial saves changes successfully"
echo -e "[ ] Publish/Unpublish toggle works correctly"
echo -e "[ ] Delete tutorial removes it from list"
echo -e "[ ] No CORS errors in browser console"
echo -e "[ ] All HTTP requests succeed (status 200)"
echo -e "[ ] No errors in backend server console"
echo -e "[ ] No errors in Angular dev server console"
echo -e "[ ] No errors in browser console"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}API Endpoint Verification (Optional)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}You can also test API endpoints directly with curl:${NC}"
echo ""
echo -e "${GREEN}Test Create:${NC}"
echo -e "curl -X POST http://localhost:8080/api/tutorials \\"
echo -e "  -H 'Content-Type: application/json' \\"
echo -e "  -d '{\"title\":\"API Test\",\"description\":\"Testing API\"}'"
echo ""
echo -e "${GREEN}Test Read All:${NC}"
echo -e "curl http://localhost:8080/api/tutorials"
echo ""
echo -e "${GREEN}Test Search:${NC}"
echo -e "curl 'http://localhost:8080/api/tutorials?title=API'"
echo ""

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Prerequisites verification completed!${NC}"
echo -e "${GREEN}Follow the manual testing instructions above.${NC}"
echo -e "${GREEN}========================================${NC}"
