# Step 7.1: Full Application Integration Test - Verification Document

## Overview

This document provides comprehensive guidance for testing the complete fullstack application (Angular 14 + Express + MySQL) running on Node.js 18. This is the final integration test to verify that all components work together correctly.

## Prerequisites Checklist

Before starting the integration test, ensure:

- [x] Node.js 18 is installed and active (`node --version` shows v18.x.x)
- [x] Backend dependencies installed (Step 3.2 completed)
- [x] Frontend dependencies installed (Step 4.3 completed)
- [x] Backend tests passed (Step 5.3 completed)
- [x] Frontend unit tests passed (Step 6.3 completed)
- [ ] MySQL server is running and accessible
- [ ] MySQL credentials match `node-js-server/app/config/db.config.js`
- [ ] Ports 8080 and 8081 are available

## MySQL Configuration

The application expects MySQL with the following configuration (from `node-js-server/app/config/db.config.js`):

```javascript
{
  HOST: "localhost",
  USER: "root",
  PASSWORD: "123456",
  DB: "testdb",
  dialect: "mysql"
}
```

### Start MySQL

If MySQL is not running, start it:

```bash
# Linux/Ubuntu
sudo systemctl start mysql
# or
sudo service mysql start

# macOS (Homebrew)
brew services start mysql

# Docker
docker run -d --name mysql-test \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -e MYSQL_DATABASE=testdb \
  -p 3306:3306 \
  mysql:8.0
```

### Verify MySQL Connectivity

```bash
mysql -h localhost -u root -p123456 -e "SELECT 1;" testdb
```

## Automated Prerequisites Check

Run the verification script to check all prerequisites:

```bash
chmod +x run-integration-test.sh
./run-integration-test.sh
```

This script will verify:
- Node.js 18 is active
- MySQL is accessible with correct credentials
- Backend dependencies are installed
- Frontend dependencies are installed
- Display installed versions of key packages

## Manual Testing Procedure

### Terminal Setup

You'll need **two terminal windows** for this test:

**Terminal 1: Backend Server**
```bash
cd node-js-server
node server.js
```

Expected output:
```
Server is running on port 8080.
Executed (default): DROP TABLE IF EXISTS `tutorials`;
Executed (default): CREATE TABLE IF NOT EXISTS `tutorials` ...
Synced db.
```

**Terminal 2: Frontend Dev Server**
```bash
cd angular-14-client
ng serve --port 8081
```

Expected output:
```
✔ Browser application bundle generation complete.
...
** Angular Live Development Server is listening on localhost:8081, open your browser on http://localhost:8081/ **
✔ Compiled successfully.
```

### Browser Testing Workflow

#### 1. Load Application

- Open browser to http://localhost:8081
- **Verify:** Application loads showing "Tutorials List" page
- **Verify:** No errors in browser console (F12 -> Console tab)
- **Verify:** Network tab shows no failed requests

#### 2. Test Create Tutorial (Add Button)

**Steps:**
1. Click "Add" button in top navigation bar
2. You should be redirected to http://localhost:8081/tutorials/add
3. Fill in the form:
   - **Title:** "Node.js 18 Integration Test"
   - **Description:** "Testing Angular 14 with Express on Node 18 and mysql2 3.x"
4. Click "Submit" button

**Expected Results:**
- ✅ Success message appears: "The tutorial was submitted successfully!"
- ✅ Form is reset/cleared
- ✅ Can navigate back to list and see the new tutorial

**Verify in Network Tab:**
- POST request to `http://localhost:8080/api/tutorials`
- Status: 201 Created
- Response body contains created tutorial with `id` field

#### 3. Test Search Functionality

**Steps:**
1. Return to tutorials list (click "Tutorials" in navigation)
2. In the search box at top, enter: "Integration"
3. Click "Search" button

**Expected Results:**
- ✅ List filters to show only tutorials matching "Integration" in title
- ✅ Previously created tutorial appears in results
- ✅ Other tutorials (if any) are hidden

**Additional Test:**
1. Clear the search box (delete text)
2. Click "Search" button again

**Expected Results:**
- ✅ All tutorials are displayed again (filter removed)

**Verify in Network Tab:**
- GET request to `http://localhost:8080/api/tutorials?title=Integration`
- Status: 200 OK
- Response body contains filtered array

#### 4. Test View Details

**Steps:**
1. In the tutorials list, click on the "Node.js 18 Integration Test" tutorial

**Expected Results:**
- ✅ Redirected to details page: http://localhost:8081/tutorials/[id]
- ✅ Tutorial title displays correctly
- ✅ Tutorial description displays correctly
- ✅ Published status shows "Pending" (unpublished)
- ✅ "Publish" button is visible
- ✅ "Update" button is visible
- ✅ "Delete" button is visible

**Verify in Network Tab:**
- GET request to `http://localhost:8080/api/tutorials/[id]`
- Status: 200 OK
- Response body contains single tutorial object

#### 5. Test Update Tutorial

**Steps:**
1. On the tutorial details page, modify the title field to: "Updated Integration Test"
2. Modify the description field to: "Description updated via Angular frontend on Node.js 18"
3. Click "Update" button

**Expected Results:**
- ✅ Success message appears: "The tutorial was updated successfully!"
- ✅ Changes are reflected immediately on the page

**Verify Changes Persisted:**
1. Navigate back to list (click "Tutorials" in navigation)
2. Verify the tutorial shows updated title in list
3. Click on tutorial again to view details
4. Verify both title and description show updated values

**Verify in Network Tab:**
- PUT request to `http://localhost:8080/api/tutorials/[id]`
- Status: 200 OK
- Response body shows success message

#### 6. Test Publish Toggle

**Steps:**
1. On tutorial details page, note status shows "Pending"
2. Click "Publish" button

**Expected Results:**
- ✅ Status changes to "Published"
- ✅ Button text changes to "UnPublish"
- ✅ Success message may appear

**Steps:**
1. Click "UnPublish" button

**Expected Results:**
- ✅ Status changes back to "Pending"
- ✅ Button text changes back to "Publish"

**Verify in Network Tab:**
- PUT request to `http://localhost:8080/api/tutorials/[id]`
- Request body contains `{"published": true}` or `{"published": false}`
- Status: 200 OK

#### 7. Test Delete Tutorial

**Steps:**
1. On tutorial details page, click "Delete" button

**Expected Results:**
- ✅ Redirected back to tutorials list page
- ✅ The deleted tutorial no longer appears in the list
- ✅ Success message may appear

**Verify in Network Tab:**
- DELETE request to `http://localhost:8080/api/tutorials/[id]`
- Status: 200 OK
- Response body shows success message

#### 8. Test CORS Configuration

**Verification:**
1. Open Browser DevTools (F12)
2. Go to Network tab
3. Perform any CRUD operation (create, read, update, or delete)
4. Click on the API request in Network tab
5. Go to "Headers" section

**Expected Results:**
- ✅ No CORS errors in Console tab
- ✅ Response headers include:
  - `access-control-allow-origin: *` (or specific origin)
  - `access-control-allow-methods: GET, POST, PUT, DELETE`
  - `access-control-allow-headers: Content-Type, Authorization`
- ✅ All requests to `http://localhost:8080/api/tutorials` succeed (status 200, 201, etc.)

**CORS Configuration Location:**
The CORS configuration is in `node-js-server/server.js` lines 6-8:

```javascript
var corsOptions = {
  origin: "http://localhost:8081"
};
```

This allows requests from the Angular dev server on port 8081.

## Edge Case Testing (Optional but Recommended)

### Test Error Handling

**Empty Form Submission:**
1. Navigate to Add Tutorial page
2. Try to submit without filling any fields
3. **Verify:** Validation errors appear (may require frontend validation to be implemented)

**Invalid Data:**
1. Try to update a tutorial with very long title (1000+ characters)
2. **Verify:** Application handles gracefully

**Non-existent Tutorial:**
1. Manually navigate to http://localhost:8081/tutorials/99999
2. **Verify:** Application handles gracefully (error message or redirect)

### Test Multiple Tutorials

**Create 5-10 Tutorials:**
1. Use Add button to create multiple tutorials
2. **Verify:** List renders all tutorials correctly
3. **Verify:** Search works across all tutorials
4. **Verify:** No performance issues with multiple items

### Test Concurrent Operations

**Multiple Browser Tabs:**
1. Open application in 2 browser tabs
2. Create tutorial in tab 1
3. Refresh list in tab 2
4. **Verify:** New tutorial appears after refresh

## Backend Console Verification

While testing, monitor the backend server console (Terminal 1) for:

- ✅ No error messages or stack traces
- ✅ SQL queries are logged (if logging enabled)
- ✅ No OpenSSL 3.0 warnings or errors
- ✅ No deprecation warnings from mysql2 3.x
- ✅ Connection pool operates correctly

Expected console output examples:
```
Server is running on port 8080.
Synced db.
Executed (default): SELECT ...
```

## Frontend Console Verification

While testing, monitor the Angular dev server console (Terminal 2) for:

- ✅ No compilation errors
- ✅ No TypeScript errors
- ✅ Build completes successfully
- ✅ No Angular runtime errors

## Browser Console Verification

While testing, monitor the browser console (F12 -> Console) for:

- ✅ No JavaScript errors
- ✅ No Angular errors
- ✅ No CORS errors
- ✅ No 404 or 500 HTTP errors
- ✅ No TypeScript compilation errors

## API Endpoint Direct Testing (Optional)

You can also test API endpoints directly with curl while servers are running:

### Create Tutorial
```bash
curl -X POST http://localhost:8080/api/tutorials \
  -H "Content-Type: application/json" \
  -d '{"title":"API Test Tutorial","description":"Testing via curl","published":false}'
```

Expected: Status 201, response body with created tutorial including `id`

### Get All Tutorials
```bash
curl http://localhost:8080/api/tutorials
```

Expected: Status 200, response body with array of tutorials

### Search by Title
```bash
curl "http://localhost:8080/api/tutorials?title=API"
```

Expected: Status 200, response body with filtered tutorials

### Get Tutorial by ID
```bash
curl http://localhost:8080/api/tutorials/1
```

Expected: Status 200 (if exists) or 404 (if not found)

### Update Tutorial
```bash
curl -X PUT http://localhost:8080/api/tutorials/1 \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Title","description":"Updated Description","published":true}'
```

Expected: Status 200, success message

### Delete Tutorial
```bash
curl -X DELETE http://localhost:8080/api/tutorials/1
```

Expected: Status 200, success message

### Delete All Tutorials
```bash
curl -X DELETE http://localhost:8080/api/tutorials
```

Expected: Status 200, message with count of deleted tutorials

## Success Criteria

Step 7.1 is considered **PASSED** when all of the following are true:

- [ ] MySQL is accessible with credentials from db.config.js
- [ ] Backend server starts successfully on port 8080 with no errors
- [ ] Angular dev server starts successfully on port 8081 with no errors
- [ ] Application loads at http://localhost:8081 with no errors
- [ ] Create tutorial workflow completes successfully
- [ ] New tutorial appears in tutorials list after creation
- [ ] Search functionality filters tutorials by title correctly
- [ ] View details displays correct tutorial information
- [ ] Update tutorial saves changes successfully
- [ ] Changes persist after navigation (back to list and back to details)
- [ ] Publish/Unpublish toggle changes status correctly
- [ ] Delete tutorial removes it from list successfully
- [ ] No CORS errors in browser console during any operation
- [ ] All HTTP requests succeed with appropriate status codes (200, 201)
- [ ] No errors in backend server console
- [ ] No errors in Angular dev server console
- [ ] No errors in browser console
- [ ] CORS headers present in API responses

## Troubleshooting

### Issue: MySQL Connection Failed

**Symptoms:** Backend server shows error: "Unable to connect to the database"

**Solutions:**
1. Verify MySQL is running: `sudo systemctl status mysql` or `brew services list | grep mysql`
2. Verify credentials: Check `node-js-server/app/config/db.config.js`
3. Test connection: `mysql -h localhost -u root -p123456 testdb`
4. Create database if missing: `mysql -u root -p123456 -e "CREATE DATABASE testdb;"`
5. Check MySQL port 3306 is available: `netstat -an | grep 3306`

### Issue: Backend Server Port 8080 Already in Use

**Symptoms:** Error: "EADDRINUSE: address already in use :::8080"

**Solutions:**
1. Find and kill process using port 8080: `lsof -ti:8080 | xargs kill -9`
2. Or use different port: Modify `node-js-server/server.js` PORT constant

### Issue: Angular Dev Server Port 8081 Already in Use

**Symptoms:** Error: "Port 8081 is already in use"

**Solutions:**
1. Find and kill process: `lsof -ti:8081 | xargs kill -9`
2. Or use different port: `ng serve --port 8082` (update CORS config in server.js)

### Issue: CORS Errors in Browser

**Symptoms:** Console error: "Access to XMLHttpRequest ... has been blocked by CORS policy"

**Solutions:**
1. Verify backend server is running on port 8080
2. Verify frontend is accessing http://localhost:8081
3. Check CORS configuration in `node-js-server/server.js` lines 6-8
4. Verify origin matches: `origin: "http://localhost:8081"`
5. Restart backend server after any CORS config changes

### Issue: API Returns 404 Not Found

**Symptoms:** Network tab shows 404 for API requests

**Solutions:**
1. Verify backend server is running and accessible
2. Check API URL in browser Network tab (should be http://localhost:8080/api/tutorials)
3. Verify frontend service uses correct baseURL (check `angular-14-client/src/app/services/tutorial.service.ts`)

### Issue: Tutorial List Shows Empty

**Symptoms:** No tutorials appear even after creating them

**Solutions:**
1. Check browser console for errors
2. Verify API response in Network tab (should return array)
3. Check database: `mysql -u root -p123456 testdb -e "SELECT * FROM tutorials;"`
4. Verify Sequelize sync completed successfully in backend console

### Issue: OpenSSL Errors in Backend

**Symptoms:** Backend console shows OpenSSL related errors

**Solutions:**
1. Verify Node.js 18 is active: `node --version`
2. Verify mysql2 3.6.0+ is installed: `cd node-js-server && npm list mysql2`
3. Reinstall dependencies: `rm -rf node_modules package-lock.json && npm install`

## Cleanup After Testing

After completing the integration test:

1. **Stop Servers:**
   - Terminal 1 (backend): Press Ctrl+C
   - Terminal 2 (frontend): Press Ctrl+C

2. **Clean Test Data (Optional):**
   ```bash
   mysql -u root -p123456 testdb -e "DELETE FROM tutorials;"
   ```

3. **Stop MySQL (Optional):**
   ```bash
   # Linux/Ubuntu
   sudo systemctl stop mysql

   # macOS
   brew services stop mysql

   # Docker
   docker stop mysql-test && docker rm mysql-test
   ```

## Next Steps

After successfully completing Step 7.1:

1. Document any issues encountered and how they were resolved
2. Note any performance observations
3. Proceed to Step 7.2: Verify HTTP Communication
4. Update `.aviator/current_session_learnings.md` with integration testing learnings

## Documentation Files

Related files for this step:
- `run-integration-test.sh` - Automated prerequisites verification script
- `STEP-7.1-INTEGRATION-TEST-VERIFICATION.md` - This document
- `node-js-server/app/config/db.config.js` - Database configuration
- `node-js-server/server.js` - CORS configuration (lines 6-8)

## Checklist Summary

Quick checklist for completion:

```
Prerequisites:
[ ] Node.js 18 active
[ ] MySQL running and accessible
[ ] Backend dependencies installed
[ ] Frontend dependencies installed

Environment:
[ ] Backend server started (port 8080)
[ ] Frontend dev server started (port 8081)
[ ] Browser opened to http://localhost:8081

Testing:
[ ] Application loads without errors
[ ] Create tutorial successful
[ ] Search functionality works
[ ] View details works
[ ] Update tutorial works
[ ] Publish/Unpublish toggle works
[ ] Delete tutorial works
[ ] CORS configuration verified

Verification:
[ ] No errors in backend console
[ ] No errors in frontend console
[ ] No errors in browser console
[ ] All HTTP requests succeed
[ ] Changes persist correctly
```

---

**Step 7.1 Status:** Ready for execution
**Requires:** Manual browser testing (cannot be fully automated)
**Duration:** Approximately 15-20 minutes
**Complexity:** Medium (requires careful verification of UI interactions)
