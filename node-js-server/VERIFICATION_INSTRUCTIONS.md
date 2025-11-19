# Step 5.3: Database Connectivity Verification Instructions

## Prerequisites

Before running the database connectivity tests, you must:

1. **Install dependencies** (if not already done):
   ```bash
   cd /code/node-js-server
   npm install
   ```

2. **Ensure MySQL is running and accessible** with the following credentials:
   - Host: localhost
   - User: root
   - Password: 123456
   - Database: testdb

   To start MySQL (if not running):
   ```bash
   # Using systemd
   sudo systemctl start mysql

   # Or using service
   sudo service mysql start

   # Or using Docker
   docker run -d --name mysql-test \
     -e MYSQL_ROOT_PASSWORD=123456 \
     -e MYSQL_DATABASE=testdb \
     -p 3306:3306 \
     mysql:8.0
   ```

3. **Verify MySQL is accessible**:
   ```bash
   # Test connection (enter password: 123456)
   mysql -u root -p -h localhost testdb -e "SELECT 'MySQL is running' as status;"
   ```

## Running the Verification Tests

### Option 1: Automated Test Suite (Recommended)

Run the comprehensive test suite that verifies all requirements:

```bash
cd /code/node-js-server
node test-db-connectivity.js
```

This test suite verifies:
- ✓ Basic database connection with mysql2 3.x
- ✓ Connection pool management (app/models/index.js config)
- ✓ Database sync and schema operations
- ✓ Prepared statements with CRUD operations
- ✓ Connection under load (20 concurrent operations)
- ✓ OpenSSL 3.0 compatibility
- ✓ Deprecation warnings check

**Expected Output:** All tests should pass with green checkmarks.

### Option 2: Manual Server Testing

Start the server manually and monitor logs:

```bash
cd /code/node-js-server
node server.js
```

**Expected output:**
```
Server is running on port 8080.
Synced db.
```

**What to verify:**
1. ✓ No error messages during startup
2. ✓ "Synced db." message appears (confirms connection)
3. ✓ No OpenSSL warnings or errors
4. ✓ No deprecation warnings from Sequelize

**Then test API endpoints:**

```bash
# In another terminal, test CRUD operations:

# Create
curl -X POST http://localhost:8080/api/tutorials \
  -H "Content-Type: application/json" \
  -d '{"title":"mysql2 3.x Test","description":"Testing with Node 18","published":false}'

# Read all
curl http://localhost:8080/api/tutorials

# Update (replace :id with actual ID from create)
curl -X PUT http://localhost:8080/api/tutorials/1 \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated","published":true}'

# Delete (replace :id)
curl -X DELETE http://localhost:8080/api/tutorials/1
```

**Stop the server:**
Press `Ctrl+C` in the server terminal.

## Verification Checklist

After running tests, confirm:

- [ ] Server starts without errors on Node.js 18
- [ ] Database connection established successfully
- [ ] "Synced db." message appears
- [ ] No OpenSSL 3.0 related errors
- [ ] No SSL/TLS connection failures
- [ ] Connection pool configuration loads correctly (max: 5, min: 0, acquire: 30000ms, idle: 10000ms)
- [ ] CRUD operations work correctly
- [ ] Prepared statements execute without errors
- [ ] Multiple concurrent operations succeed
- [ ] No memory leaks or connection pool exhaustion
- [ ] No deprecation warnings from mysql2 or Sequelize

## Expected Results

### ✓ Success Indicators:
- mysql2 3.6.0+ installed and working
- express 4.18.2+ handling requests
- sequelize 6.33.0+ managing ORM operations
- OpenSSL 3.0 compatibility confirmed
- All connection pool operations functional
- No errors in console output

### ✗ Failure Indicators:
- "Cannot find module" errors → Run `npm install`
- "ECONNREFUSED" errors → MySQL is not running
- "Access denied" errors → Check MySQL credentials in app/config/db.config.js
- "Unknown database" errors → Create `testdb` database in MySQL
- OpenSSL errors → mysql2 version may not be 3.x

## Troubleshooting

### Issue: Dependencies not installed
**Solution:**
```bash
cd /code/node-js-server
rm -rf node_modules package-lock.json
npm install
```

### Issue: MySQL not running
**Solution:**
```bash
# Start MySQL service
sudo systemctl start mysql
# OR
sudo service mysql start
# OR use Docker (see prerequisites above)
```

### Issue: Database 'testdb' doesn't exist
**Solution:**
```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS testdb;"
```

### Issue: Wrong MySQL credentials
**Solution:**
Edit `/code/node-js-server/app/config/db.config.js` with your MySQL credentials.

## Next Steps

Once verification is complete and all tests pass:

1. ✓ Mark Step 5.3 as complete
2. Continue to Step 6.1: Test Angular Development Build
3. Document any issues encountered in the learnings file

## Additional Notes

- The test script creates and deletes test records automatically
- Existing tutorial data will not be affected by the tests
- Connection pool is configured with max 5 connections (suitable for development)
- Tests run sequentially to provide clear feedback
- All tests must pass to confirm mysql2 3.x is fully functional with Node.js 18
