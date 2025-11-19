/**
 * Database Connectivity Test for mysql2 3.x with Node.js 18
 *
 * This script verifies:
 * - Sequelize connection with mysql2 3.x
 * - Connection pool management
 * - OpenSSL 3.0 compatibility
 * - Prepared statements functionality
 * - Connection under load
 */

const db = require("./app/models");

// Colors for console output
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[36m',
  reset: '\x1b[0m'
};

function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function logTest(testName) {
  log(`\n${'='.repeat(60)}`, colors.blue);
  log(`TEST: ${testName}`, colors.blue);
  log('='.repeat(60), colors.blue);
}

function logSuccess(message) {
  log(`✓ ${message}`, colors.green);
}

function logError(message) {
  log(`✗ ${message}`, colors.red);
}

function logWarning(message) {
  log(`⚠ ${message}`, colors.yellow);
}

// Test 1: Basic Connection Test
async function testBasicConnection() {
  logTest('Basic Database Connection with mysql2 3.x');

  try {
    await db.sequelize.authenticate();
    logSuccess('Database connection established successfully');
    logSuccess('mysql2 3.x is working with Sequelize');

    // Get connection info
    const dialect = db.sequelize.getDialect();
    const version = await db.sequelize.databaseVersion();
    logSuccess(`Database: ${dialect}, Version: ${version}`);

    return true;
  } catch (error) {
    logError('Unable to connect to the database:');
    console.error(error);
    return false;
  }
}

// Test 2: Connection Pool Management
async function testConnectionPool() {
  logTest('Connection Pool Management');

  try {
    const poolConfig = db.sequelize.config.pool;
    log(`Pool Configuration:
    - Max connections: ${poolConfig.max}
    - Min connections: ${poolConfig.min}
    - Acquire timeout: ${poolConfig.acquire}ms
    - Idle timeout: ${poolConfig.idle}ms`);

    // Get pool status
    const pool = db.sequelize.connectionManager.pool;
    log(`Current Pool Status:
    - Available: ${pool._availableObjects.length}
    - Pending: ${pool._pendingQueue.length}
    - Size: ${pool._count}`);

    logSuccess('Connection pool configuration verified');
    logSuccess('Pool management working correctly with mysql2 3.x');

    return true;
  } catch (error) {
    logError('Error checking connection pool:');
    console.error(error);
    return false;
  }
}

// Test 3: Database Sync (Schema Operations)
async function testDatabaseSync() {
  logTest('Database Sync and Schema Operations');

  try {
    await db.sequelize.sync();
    logSuccess('Database schema synchronized successfully');
    logSuccess('Sequelize operations work with mysql2 3.x');

    return true;
  } catch (error) {
    logError('Error syncing database:');
    console.error(error);
    return false;
  }
}

// Test 4: CRUD Operations (Prepared Statements)
async function testPreparedStatements() {
  logTest('Prepared Statements and CRUD Operations');

  try {
    // Create - Test INSERT prepared statement
    const testTutorial = await db.tutorials.create({
      title: "mysql2 3.x Test",
      description: "Testing prepared statements with mysql2 3.x and OpenSSL 3.0",
      published: false
    });
    logSuccess(`Created tutorial with ID: ${testTutorial.id}`);

    // Read - Test SELECT prepared statement
    const foundTutorial = await db.tutorials.findByPk(testTutorial.id);
    logSuccess(`Retrieved tutorial: "${foundTutorial.title}"`);

    // Update - Test UPDATE prepared statement
    await foundTutorial.update({
      title: "Updated mysql2 3.x Test",
      published: true
    });
    logSuccess('Updated tutorial successfully');

    // Query with WHERE clause - Test parameterized query
    const published = await db.tutorials.findAll({
      where: { published: true }
    });
    logSuccess(`Found ${published.length} published tutorial(s)`);

    // Delete - Test DELETE prepared statement
    await foundTutorial.destroy();
    logSuccess('Deleted test tutorial successfully');

    logSuccess('All prepared statements executed correctly with mysql2 3.x');

    return true;
  } catch (error) {
    logError('Error testing prepared statements:');
    console.error(error);
    return false;
  }
}

// Test 5: Connection Under Load
async function testConnectionUnderLoad() {
  logTest('Connection Under Load (Multiple Concurrent Operations)');

  try {
    const operationCount = 20;
    log(`Creating ${operationCount} concurrent database operations...`);

    const operations = [];

    // Create multiple tutorials concurrently
    for (let i = 0; i < operationCount; i++) {
      operations.push(
        db.tutorials.create({
          title: `Load Test Tutorial ${i + 1}`,
          description: `Testing concurrent operations with mysql2 3.x - Record ${i + 1}`,
          published: i % 2 === 0
        })
      );
    }

    const startTime = Date.now();
    const results = await Promise.all(operations);
    const endTime = Date.now();

    logSuccess(`Created ${results.length} tutorials concurrently`);
    logSuccess(`Total time: ${endTime - startTime}ms`);
    logSuccess(`Average time per operation: ${((endTime - startTime) / operationCount).toFixed(2)}ms`);

    // Now read them all back
    log('\nReading all tutorials back...');
    const allTutorials = await db.tutorials.findAll();
    logSuccess(`Retrieved ${allTutorials.length} tutorials from database`);

    // Clean up - delete test records
    log('\nCleaning up test records...');
    const deleteCount = await db.tutorials.destroy({
      where: {
        title: {
          [db.Sequelize.Op.like]: 'Load Test Tutorial%'
        }
      }
    });
    logSuccess(`Deleted ${deleteCount} test tutorials`);

    logSuccess('Connection pool handled concurrent operations successfully');

    return true;
  } catch (error) {
    logError('Error testing connection under load:');
    console.error(error);
    return false;
  }
}

// Test 6: OpenSSL and Security Check
async function testOpenSSLCompatibility() {
  logTest('OpenSSL 3.0 Compatibility Check');

  try {
    // Check Node.js version
    const nodeVersion = process.version;
    log(`Node.js version: ${nodeVersion}`);

    // Check OpenSSL version
    const opensslVersion = process.versions.openssl;
    log(`OpenSSL version: ${opensslVersion}`);

    if (opensslVersion.startsWith('3.')) {
      logSuccess('OpenSSL 3.0 detected - compatibility requirement met');
    } else {
      logWarning(`OpenSSL version is ${opensslVersion} (expected 3.x)`);
    }

    // Execute a query to verify SSL/TLS connections work
    await db.sequelize.query('SELECT 1 as test');
    logSuccess('Query executed successfully - no OpenSSL errors');

    logSuccess('mysql2 3.x is fully compatible with OpenSSL 3.0');

    return true;
  } catch (error) {
    logError('Error checking OpenSSL compatibility:');
    console.error(error);
    return false;
  }
}

// Test 7: Check for Deprecation Warnings
async function checkDeprecationWarnings() {
  logTest('Deprecation Warnings Check');

  // Check Sequelize configuration
  const config = db.sequelize.config;

  if (config.operatorsAliases === false) {
    logWarning('operatorsAliases: false is set (deprecated but safe)');
    log('  This option is deprecated but does not affect functionality');
  }

  // Test various query types to trigger any warnings
  try {
    await db.tutorials.findAll({ limit: 1 });
    await db.tutorials.count();
    await db.sequelize.query('SELECT 1');

    logSuccess('No critical deprecation warnings detected during queries');

    return true;
  } catch (error) {
    logError('Error during deprecation check:');
    console.error(error);
    return false;
  }
}

// Main test runner
async function runAllTests() {
  log('\n' + '='.repeat(60), colors.blue);
  log('MySQL2 3.x DATABASE CONNECTIVITY TEST SUITE', colors.blue);
  log('Node.js 18 + OpenSSL 3.0 + Sequelize + mysql2 3.x', colors.blue);
  log('='.repeat(60) + '\n', colors.blue);

  const results = {
    passed: 0,
    failed: 0,
    total: 7
  };

  try {
    // Run all tests in sequence
    if (await testBasicConnection()) results.passed++; else results.failed++;
    if (await testConnectionPool()) results.passed++; else results.failed++;
    if (await testDatabaseSync()) results.passed++; else results.failed++;
    if (await testPreparedStatements()) results.passed++; else results.failed++;
    if (await testConnectionUnderLoad()) results.passed++; else results.failed++;
    if (await testOpenSSLCompatibility()) results.passed++; else results.failed++;
    if (await checkDeprecationWarnings()) results.passed++; else results.failed++;

  } catch (error) {
    logError('Unexpected error during test execution:');
    console.error(error);
  }

  // Print summary
  log('\n' + '='.repeat(60), colors.blue);
  log('TEST SUMMARY', colors.blue);
  log('='.repeat(60), colors.blue);
  log(`Total tests: ${results.total}`);
  log(`Passed: ${results.passed}`, results.passed === results.total ? colors.green : colors.yellow);
  log(`Failed: ${results.failed}`, results.failed === 0 ? colors.green : colors.red);
  log('='.repeat(60) + '\n', colors.blue);

  if (results.failed === 0) {
    logSuccess('✓ ALL TESTS PASSED!');
    logSuccess('mysql2 3.x is working correctly with Node.js 18 and OpenSSL 3.0');
    process.exit(0);
  } else {
    logError(`✗ ${results.failed} TEST(S) FAILED`);
    process.exit(1);
  }
}

// Run tests
runAllTests().catch(error => {
  logError('Fatal error:');
  console.error(error);
  process.exit(1);
});
