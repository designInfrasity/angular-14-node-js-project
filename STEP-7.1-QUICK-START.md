# Step 7.1: Full Application Integration Test - Quick Start Guide

## Quick Execution Steps

### 1. Run Prerequisites Check
```bash
chmod +x run-integration-test.sh
./run-integration-test.sh
```

### 2. Start Backend Server (Terminal 1)
```bash
cd node-js-server
node server.js
```
**Wait for:** "Server is running on port 8080." and "Synced db."

### 3. Start Frontend Server (Terminal 2)
```bash
cd angular-14-client
ng serve --port 8081
```
**Wait for:** "Compiled successfully."

### 4. Open Browser
Navigate to: **http://localhost:8081**

### 5. Test CRUD Workflow

✅ **Create:** Click "Add" → Fill form → Submit → Verify appears in list

✅ **Search:** Enter search term → Click "Search" → Verify filtering works

✅ **View:** Click tutorial in list → Verify details page loads

✅ **Update:** Edit fields → Click "Update" → Verify changes saved

✅ **Publish:** Click "Publish"/"UnPublish" → Verify status changes

✅ **Delete:** Click "Delete" → Verify removed from list

✅ **CORS:** Open DevTools (F12) → Network tab → Verify no CORS errors

### 6. Verify Success
- [ ] No errors in backend console (Terminal 1)
- [ ] No errors in frontend console (Terminal 2)
- [ ] No errors in browser console (F12 → Console)
- [ ] All CRUD operations successful
- [ ] Changes persist correctly

## Troubleshooting

**MySQL not running?**
```bash
sudo systemctl start mysql
# or
brew services start mysql
```

**Port already in use?**
```bash
lsof -ti:8080 | xargs kill -9  # Kill backend
lsof -ti:8081 | xargs kill -9  # Kill frontend
```

**CORS errors?**
- Ensure backend is on port 8080
- Ensure frontend is on port 8081
- Check `node-js-server/server.js` lines 6-8

## Detailed Documentation

For complete instructions, see:
- **STEP-7.1-INTEGRATION-TEST-VERIFICATION.md** - Full testing guide with troubleshooting
- **STEP-7.1-IMPLEMENTATION-SUMMARY.md** - Implementation overview

## Expected Versions

- Node.js: v18.x.x
- express: 4.18.2
- mysql2: 3.6.0
- sequelize: 6.33.0
- Angular: 14.2.0

**Verify versions:** Check output from `./run-integration-test.sh`

---

**Status:** Ready for manual testing execution
**Time:** ~15-20 minutes
**Complexity:** Medium (requires careful UI verification)
